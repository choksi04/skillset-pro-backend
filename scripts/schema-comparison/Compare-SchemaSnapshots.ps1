[CmdletBinding()]
param(
 [Parameter(Mandatory)][string]$RehearsalSnapshot,
 [Parameter(Mandatory)][string]$DevelopmentSnapshot
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$reference=Get-Content -Raw -LiteralPath $RehearsalSnapshot | ConvertFrom-Json
$development=Get-Content -Raw -LiteralPath $DevelopmentSnapshot | ConvertFrom-Json
if ($reference.format_version -ne 1 -or $development.format_version -ne 1) { throw 'Unsupported snapshot format.' }
if ($reference.database -ne 'skillset_pro_rehearsal_20261112' -or $development.database -ne 'skillset_pro_backend_dev') {
 throw 'Snapshots must identify the expected rehearsal and development databases.'
}
if (($reference.server_version -split '\.')[0] -ne ($development.server_version -split '\.')[0]) {
 throw 'Different PostgreSQL majors require separate review of catalog/deparser differences.'
}
$totals=@()
$differences=@()
foreach ($section in @('tables','columns','constraints','indexes','functions','triggers')) {
 $left=@{}; $right=@{}
 foreach ($item in $reference.sections.$section) {
  if ($left.ContainsKey($item.key)) { throw "Duplicate reference key: $section/$($item.key)" }
  $left[$item.key]=$item.definition
 }
 foreach ($item in $development.sections.$section) {
  if ($right.ContainsKey($item.key)) { throw "Duplicate development key: $section/$($item.key)" }
  $right[$item.key]=$item.definition
 }
 $changed=0
 foreach ($key in @(@($left.Keys)+@($right.Keys) | Sort-Object -Unique)) {
  $status=$null
  if (-not $left.ContainsKey($key)) { $status='ExtraInDevelopment' }
  elseif (-not $right.ContainsKey($key)) { $status='MissingInDevelopment' }
  elseif (($left[$key] | ConvertTo-Json -Depth 30 -Compress) -cne ($right[$key] | ConvertTo-Json -Depth 30 -Compress)) {
   $status='DefinitionDiffers'
  }
  if ($null -ne $status) {
   $changed++
   $differences += [PSCustomObject]@{Section=$section;Object=$key;Status=$status}
  }
 }
 $totals += [PSCustomObject]@{Section=$section;Rehearsal=$left.Count;Development=$right.Count;Differences=$changed}
}
$totals | Format-Table -AutoSize | Out-Host
if ($differences.Count -gt 0) {
 $differences | Format-Table -AutoSize | Out-Host
 Write-Output 'DIFFERENCES FOUND. Keep both snapshots and review exact definitions; do not modify applied changesets.'
 exit 1
}
Write-Output 'PASS: all six selected schema-definition sections match.'
Write-Output 'This excludes ownership, grants, policies, extension-owned routines, database settings and row data.'
