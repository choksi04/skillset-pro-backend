[CmdletBinding()]
param(
 [Parameter(Mandatory)][string]$WorkDirectory,
 [ValidateSet('Check','Apply')][string]$Action='Check',
 [string]$PsqlPath='C:\Program Files\PostgreSQL\18\bin\psql.exe'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$work=(Resolve-Path -LiteralPath $WorkDirectory).Path
$manifest=Get-Content -Raw -LiteralPath (Join-Path $work 'import-package.json') | ConvertFrom-Json
if ($manifest.formatVersion -ne 1 -or $manifest.database -ne 'skillset_pro_backend_dev' -or
 $manifest.owner -ne 'skillset_dev_owner' -or $manifest.host -ne '127.0.0.1' -or $manifest.port -ne 5432) {
 throw 'Package target does not match approved isolated development destination.'
}
$expectedHash='80412501C7B34BD272CFF49D2CFCF4CD2CC36492CAA08BEF7C1B14E3C4CD0A1D'
if ($manifest.archiveSha256 -ne $expectedHash -or
 (Get-FileHash -LiteralPath $manifest.archive -Algorithm SHA256).Hash -ne $expectedHash) { throw 'Archive integrity check failed.' }
foreach ($name in @('import-order.list','import-guards.sql','application-data.sql','import-finish.sql')) {
 $expected=$manifest.files.PSObject.Properties[$name]
 if ($null -eq $expected -or
  (Get-FileHash -LiteralPath (Join-Path $work $name) -Algorithm SHA256).Hash -ne $expected.Value) {
  throw "Package integrity check failed: $name"
 }
}
# Guards/finalizer must also match the current reviewed repository templates.
foreach ($name in @('import-order.list','import-guards.sql','import-finish.sql')) {
 if ((Get-FileHash -LiteralPath (Join-Path $work $name)).Hash -ne
     (Get-FileHash -LiteralPath (Join-Path $PSScriptRoot $name)).Hash) { throw "Reviewed template differs: $name" }
}
Write-Output 'Package integrity verified for 31 tables / 96106 expected rows.'
if ($Action -eq 'Check') { Write-Output 'Check only: no database connection or import performed.'; return }
$psql=(Resolve-Path -LiteralPath $PsqlPath).Path
Write-Output 'APPLY to 127.0.0.1:5432/skillset_pro_backend_dev as skillset_dev_owner only.'
Write-Output 'One transaction; one archive INSERT guard suspended temporarily; all FK checks remain enabled.'
$arguments=@('-X','-P','pager=off','-h','127.0.0.1','-p','5432','-U','skillset_dev_owner',
 '-d','skillset_pro_backend_dev','-W','--single-transaction','--set=ON_ERROR_STOP=1',
 '--set=VERBOSITY=terse','--set=SHOW_CONTEXT=never',
 '--file',(Join-Path $work 'import-guards.sql'),
 '--file',(Join-Path $work 'application-data.sql'),
 '--file',(Join-Path $work 'import-finish.sql'))
& $psql @arguments
if ($LASTEXITCODE -ne 0) { throw 'Import failed and the connection transaction was rolled back. Keep errors private; do not blindly retry.' }
Write-Output 'Controlled import committed after in-transaction checks. Run post-import validation next.'
