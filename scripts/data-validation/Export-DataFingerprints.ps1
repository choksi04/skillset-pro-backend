[CmdletBinding()]
param(
 [Parameter(Mandatory)][ValidateSet('Rehearsal','Development','Recovery')][string]$Database,
 [Parameter(Mandatory)][string]$OutputPath,
 [string]$PsqlPath='C:\Program Files\PostgreSQL\18\bin\psql.exe'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repository=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$destination=[IO.Path]::GetFullPath($OutputPath)
if($destination.StartsWith($repository+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {
 throw 'Store fingerprints outside Git; they are comparison evidence.'
}
if(Test-Path -LiteralPath $destination){throw 'Output exists. Use a new filename; do not overwrite evidence.'}
if($Database -eq 'Rehearsal'){$db='skillset_pro_rehearsal_20261112';$owner='skillset_rehearsal_owner'}
elseif($Database -eq 'Development'){$db='skillset_pro_backend_dev';$owner='skillset_dev_owner'}
else{$db='skillset_pro_recovery_test';$owner='skillset_recovery_owner'}
$psql=(Resolve-Path -LiteralPath $PsqlPath).Path
[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
Write-Output "Read-only fingerprints: 127.0.0.1:5432/$db as $owner"
$argsForPsql=@('-X','-q','-A','-t','-P','pager=off','-h','127.0.0.1','-p','5432',
 '-U',$owner,'-d',$db,'-W','--set=ON_ERROR_STOP=1',
 '--file',(Join-Path $PSScriptRoot 'data-fingerprints.sql'),'--output',$destination)
& $psql @argsForPsql
if($LASTEXITCODE -ne 0){throw 'Fingerprint export failed; do not use any partial output.'}
$result=Get-Content -Raw -LiteralPath $destination | ConvertFrom-Json
if($result.database -ne $db -or $result.format_version -ne 1 -or @($result.tables).Count -ne 31) {
 throw 'Unexpected fingerprint output identity/format.'
}
Write-Output "Saved 31 table fingerprints: $destination"
Write-Output 'No employee values or per-row hashes were exported. No database changes made.'
