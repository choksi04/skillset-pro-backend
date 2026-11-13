[CmdletBinding()]
param(
 [Parameter(Mandatory)][ValidateSet('Rehearsal','Development')][string]$Database,
 [Parameter(Mandatory)][string]$OutputPath,
 [string]$PsqlPath='C:\Program Files\PostgreSQL\18\bin\psql.exe'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repositoryRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$destination=[IO.Path]::GetFullPath($OutputPath)
if ($destination.StartsWith($repositoryRoot + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {
 throw 'Save snapshots outside the Git repository.'
}
if (Test-Path -LiteralPath $destination) { throw 'Output exists; choose a new filename rather than overwriting evidence.' }
if ($Database -eq 'Rehearsal') { $databaseName='skillset_pro_rehearsal_20261112'; $databaseUser='skillset_rehearsal_owner' }
else { $databaseName='skillset_pro_backend_dev'; $databaseUser='skillset_dev_owner' }
$psql=(Resolve-Path -LiteralPath $PsqlPath).Path
[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
Write-Output "Read-only metadata export: 127.0.0.1:5432/$databaseName as $databaseUser"
Write-Output 'Enter that database owner password when prompted. No records are exported.'
$arguments=@('-X','-q','-A','-t','-P','pager=off','-h','127.0.0.1','-p','5432',
 '-U',$databaseUser,'-d',$databaseName,'-W','--set=ON_ERROR_STOP=1',
 '--file',(Join-Path $PSScriptRoot 'schema-snapshot.sql'),'--output',$destination)
& $psql @arguments
if ($LASTEXITCODE -ne 0) { throw 'Snapshot failed. Preserve any partial output for diagnosis; do not compare it.' }
$snapshot=Get-Content -Raw -LiteralPath $destination | ConvertFrom-Json
if ($snapshot.database -ne $databaseName -or $snapshot.format_version -ne 1) { throw 'Snapshot identity/format mismatch.' }
Write-Output "Saved metadata snapshot: $destination"
