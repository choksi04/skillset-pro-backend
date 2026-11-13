[CmdletBinding()]
param(
 [Parameter(Mandatory)][string]$ArchivePath,
 [Parameter(Mandatory)][string]$OutputDirectory,
 [string]$PgRestorePath='C:\Program Files\PostgreSQL\18\bin\pg_restore.exe'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$archive=(Resolve-Path -LiteralPath $ArchivePath).Path
$pgRestore=(Resolve-Path -LiteralPath $PgRestorePath).Path
$repositoryRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$work=[IO.Path]::GetFullPath($OutputDirectory)
if ($work.Equals($repositoryRoot,[StringComparison]::OrdinalIgnoreCase) -or
 $work.StartsWith($repositoryRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {
 throw 'Generated employee-data SQL must be outside Git in restricted storage.'
}
$expectedHash='80412501C7B34BD272CFF49D2CFCF4CD2CC36492CAA08BEF7C1B14E3C4CD0A1D'
if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $expectedHash) { throw 'Wrong archive checksum.' }
$version=(& $pgRestore --version) -join ' '
if ($LASTEXITCODE -ne 0 -or $version -notmatch 'PostgreSQL\)\s+(\d+)' -or [int]$Matches[1] -lt 18) {
 throw 'PostgreSQL 18 or newer pg_restore is required.'
}
$toc=@(& $pgRestore --list $archive)
if ($LASTEXITCODE -ne 0) { throw 'Archive inventory failed.' }
$selected=@(Get-Content -LiteralPath (Join-Path $PSScriptRoot 'import-order.list') |
 Where-Object { $_ -match '^\d+;' })
if ($selected.Count -ne 31) { throw 'Expected 31 data selections.' }
$tableNames=@{}
foreach ($line in $selected) {
 if ($line -notmatch '^\d+;\s+\d+\s+\d+\s+TABLE DATA public (\w+) postgres$') { throw 'Unexpected data-list entry.' }
 if ($tableNames.ContainsKey($Matches[1])) { throw 'Duplicate selected table.' }
 $tableNames[$Matches[1]]=$true
 if ($line -notin $toc) { throw 'Data entry does not match archive.' }
}
foreach ($name in @('import-order.list','import-guards.sql','import-finish.sql','application-data.sql','import-package.json')) {
 if (Test-Path -LiteralPath (Join-Path $work $name)) { throw "Output already exists: $name. Choose a new folder." }
}
[IO.Directory]::CreateDirectory($work) | Out-Null
foreach ($name in @('import-order.list','import-guards.sql','import-finish.sql')) {
 Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination (Join-Path $work $name)
}
$arguments=@('--data-only','--no-owner','--no-acl','--no-tablespaces',
 '--use-list',(Join-Path $work 'import-order.list'),'--file',(Join-Path $work 'application-data.sql'),$archive)
& $pgRestore @arguments
if ($LASTEXITCODE -ne 0) { throw 'Extraction failed. Do not execute a partial package.' }
$hashes=@{}
foreach ($name in @('import-order.list','import-guards.sql','application-data.sql','import-finish.sql')) {
 $hashes[$name]=(Get-FileHash -LiteralPath (Join-Path $work $name) -Algorithm SHA256).Hash
}
$manifest=[ordered]@{
 formatVersion=1; status='prepared-not-executed'; database='skillset_pro_backend_dev';
 owner='skillset_dev_owner'; host='127.0.0.1'; port=5432; archive=$archive;
 archiveSha256=$expectedHash; files=$hashes; expectedTables=31; expectedRows=96106;
 allowedHistoricalInactiveQuestionRows=22;
 suspendedTrigger='public.assessment_questions.trg_archived_ro_assessment_questions';
}
$manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $work 'import-package.json') -Encoding utf8
Write-Output 'Controlled import package prepared. No database connection or import performed.'
Write-Output "Work directory: $work"
Write-Output 'application-data.sql contains employee data: do not upload, display or commit it.'
