[CmdletBinding()]
param(
 [Parameter(Mandatory)][string]$ComparisonReport,
 [Parameter(Mandatory)][string]$OutputDirectory,
 [string]$PgBin='C:\Program Files\PostgreSQL\18\bin'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repository=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$work=[IO.Path]::GetFullPath($OutputDirectory)
if($work.Equals($repository,[StringComparison]::OrdinalIgnoreCase) -or
 $work.StartsWith($repository+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {
 throw 'Sensitive backups must be outside Git in restricted storage.'
}
$report=Get-Content -Raw -LiteralPath $ComparisonReport | ConvertFrom-Json
if($report.formatVersion -ne 1 -or $report.status -ne 'PASS' -or
 $report.developmentDatabase -ne 'skillset_pro_backend_dev' -or
 $report.rehearsalDatabase -ne 'skillset_pro_rehearsal_20261112' -or @($report.tables).Count -ne 31 -or
 @($report.tables | Where-Object {-not $_.Matches}).Count -gt 0) {throw 'A passing 31-table comparison is required.'}
foreach($side in @('rehearsal','development')){
 $file=$report.PSObject.Properties[$side+'File'].Value
 $hash=$report.PSObject.Properties[$side+'FileSha256'].Value
 if((Get-FileHash -LiteralPath $file).Hash -ne $hash){throw 'Fingerprint evidence changed after comparison.'}
}
$pgDump=(Resolve-Path -LiteralPath (Join-Path $PgBin 'pg_dump.exe')).Path
$pgRestore=(Resolve-Path -LiteralPath (Join-Path $PgBin 'pg_restore.exe')).Path
[IO.Directory]::CreateDirectory($work) | Out-Null
$backup=Join-Path $work 'skillset-pro-backend-dev_validated.backup'
$checkpointPath=Join-Path $work 'migration-checkpoint.json'
$evidencePath=Join-Path $work 'fingerprint-comparison.json'
foreach($path in @($backup,$checkpointPath,$evidencePath)){
 if(Test-Path -LiteralPath $path){throw 'Checkpoint output exists; choose a new directory.'}
}
Write-Output 'Keep both databases free of application writes until this checkpoint finishes.'
Write-Output 'Backing up 127.0.0.1:5432/skillset_pro_backend_dev as skillset_dev_owner.'
$argsForDump=@('-h','127.0.0.1','-p','5432','-U','skillset_dev_owner','-d','skillset_pro_backend_dev',
 '-W','--format=custom','--no-owner','--no-acl','--file',$backup)
& $pgDump @argsForDump
if($LASTEXITCODE -ne 0){throw 'Backup failed; do not accept a partial archive.'}
$toc=@(& $pgRestore --list $backup)
if($LASTEXITCODE -ne 0){throw 'Backup inventory cannot be read.'}
$tables=@($toc | Where-Object {$_ -match '^\d+;\s+\d+\s+\d+\s+TABLE public '})
$data=@($toc | Where-Object {$_ -match '^\d+;\s+\d+\s+\d+\s+TABLE DATA public '})
if($tables.Count -ne 33 -or $data.Count -ne 33){throw 'Expected 31 application tables plus two Liquibase history tables/data sections.'}
Copy-Item -LiteralPath $ComparisonReport -Destination $evidencePath
$gitCommit=(& git -C $repository rev-parse HEAD) -join ''
if($LASTEXITCODE -ne 0){throw 'Could not record repository revision.'}
$checkpoint=[ordered]@{
 status='backup-created-not-restore-tested';createdAtUtc=[DateTime]::UtcNow.ToString('o');
 database='skillset_pro_backend_dev';host='127.0.0.1';port=5432;owner='skillset_dev_owner';
 sourceArchiveSha256='80412501C7B34BD272CFF49D2CFCF4CD2CC36492CAA08BEF7C1B14E3C4CD0A1D';
 backupFile=$backup;backupBytes=(Get-Item -LiteralPath $backup).Length;backupSha256=(Get-FileHash -LiteralPath $backup).Hash;
 publicTables=$tables.Count;publicDataSections=$data.Count;liquibaseHistoryIncluded=$true;
 fingerprintEvidence=$evidencePath;fingerprintEvidenceSha256=(Get-FileHash -LiteralPath $evidencePath).Hash;
 migrationFileHashes=@(Get-ChildItem -LiteralPath (Join-Path $repository 'src\main\resources\db\changelog') -Recurse -File |
 ForEach-Object { [ordered]@{path=$_.FullName.Substring($repository.Length+1);sha256=(Get-FileHash -LiteralPath $_.FullName).Hash} });
 repositoryCommit=$gitCommit;workingTreeChanges=@(& git -C $repository status --short);
 limitations='No writes permitted between comparison and backup. Separate commands do not share one snapshot. TOC readability is not restore proof.'
}
$checkpoint | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $checkpointPath -Encoding utf8
Write-Output 'Development backup and checkpoint created; archive inventory readable (33 tables/data sections).'
Write-Output "Checkpoint: $checkpointPath"
Write-Output 'Backup contains employee records. Keep it outside Git. Restore testing remains required.'
