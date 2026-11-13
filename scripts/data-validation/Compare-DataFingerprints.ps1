[CmdletBinding()]
param(
 [Parameter(Mandatory)][Alias('ReferenceFile')][string]$RehearsalFile,
 [Parameter(Mandatory)][Alias('CandidateFile')][string]$DevelopmentFile,
 [Parameter(Mandatory)][string]$ReportPath,
 [ValidateSet('RehearsalDevelopment','DevelopmentRecovery')][string]$ComparisonKind='RehearsalDevelopment'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repository=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$output=[IO.Path]::GetFullPath($ReportPath)
if($output.StartsWith($repository+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {
 throw 'Save comparison evidence outside Git.'
}
if(Test-Path -LiteralPath $output){throw 'Comparison report already exists; use a new filename.'}
$left=Get-Content -Raw -LiteralPath $RehearsalFile | ConvertFrom-Json
$right=Get-Content -Raw -LiteralPath $DevelopmentFile | ConvertFrom-Json
if($left.format_version -ne 1 -or $right.format_version -ne 1 -or
 $left.algorithm -ne 'sha256-jsonb-row-multiset-v1' -or $right.algorithm -ne $left.algorithm) {
 throw 'Fingerprint format/algorithm mismatch.'
}
$expectedReference=if($ComparisonKind -eq 'DevelopmentRecovery'){'skillset_pro_backend_dev'}else{'skillset_pro_rehearsal_20261112'}
$expectedCandidate=if($ComparisonKind -eq 'DevelopmentRecovery'){'skillset_pro_recovery_test'}else{'skillset_pro_backend_dev'}
if($left.database -ne $expectedReference -or $right.database -ne $expectedCandidate) {
 throw 'Wrong databases for the selected fingerprint comparison kind.'
}
if(($left.server_version -split '\.')[0] -ne ($right.server_version -split '\.')[0]) {
 throw 'Different PostgreSQL majors need canonicalization review.'
}
$expected=@{}
Import-Csv -LiteralPath (Join-Path $PSScriptRoot '..\restore-rehearsal\archive-20261112\expected-row-counts.csv') |
 ForEach-Object {$expected[$_.table]=[long]$_.expected_rows}
$leftMap=@{};$rightMap=@{}
foreach($entry in $left.tables){
 if($leftMap.ContainsKey($entry.table) -or -not $expected.ContainsKey($entry.table) -or
    $entry.sha256 -cnotmatch '^[a-f0-9]{64}$'){throw 'Invalid or duplicate rehearsal table fingerprint.'}
 $leftMap[$entry.table]=$entry
}
foreach($entry in $right.tables){
 if($rightMap.ContainsKey($entry.table) -or -not $expected.ContainsKey($entry.table) -or
    $entry.sha256 -cnotmatch '^[a-f0-9]{64}$'){throw 'Invalid or duplicate development table fingerprint.'}
 $rightMap[$entry.table]=$entry
}
$rows=@();$passed=($leftMap.Count -eq 31 -and $rightMap.Count -eq 31)
foreach($name in ($expected.Keys | Sort-Object)){
 if(-not $leftMap.ContainsKey($name) -or -not $rightMap.ContainsKey($name)){throw "Missing fingerprint table: $name"}
 $a=$leftMap[$name];$b=$rightMap[$name]
 $matches=([long]$a.rows -eq $expected[$name] -and [long]$b.rows -eq $expected[$name] -and $a.sha256 -ceq $b.sha256)
 if(-not $matches){$passed=$false}
 $rows+=[PSCustomObject]@{Table=$name;RehearsalRows=[long]$a.rows;DevelopmentRows=[long]$b.rows;Matches=$matches}
}
$report=[ordered]@{
 formatVersion=1;status=$(if($passed){'PASS'}else{'DIFFERENCES'});
 checkedAtUtc=[DateTime]::UtcNow.ToString('o');algorithm=$left.algorithm;
 rehearsalDatabase=$left.database;developmentDatabase=$right.database;
 rehearsalFile=(Resolve-Path -LiteralPath $RehearsalFile).Path;
 rehearsalFileSha256=(Get-FileHash -LiteralPath $RehearsalFile).Hash;
 developmentFile=(Resolve-Path -LiteralPath $DevelopmentFile).Path;
 developmentFileSha256=(Get-FileHash -LiteralPath $DevelopmentFile).Hash;
 tables=$rows;scope='31 application tables only; Liquibase history excluded'
}
if($ComparisonKind -eq 'DevelopmentRecovery') {
 $report=[ordered]@{
  formatVersion=1;comparisonKind=$ComparisonKind;status=$(if($passed){'PASS'}else{'DIFFERENCES'});
  checkedAtUtc=[DateTime]::UtcNow.ToString('o');algorithm=$left.algorithm;
  referenceDatabase=$left.database;recoveryDatabase=$right.database;
  referenceFile=(Resolve-Path -LiteralPath $RehearsalFile).Path;
  referenceFileSha256=(Get-FileHash -LiteralPath $RehearsalFile).Hash;
  recoveryFile=(Resolve-Path -LiteralPath $DevelopmentFile).Path;
  recoveryFileSha256=(Get-FileHash -LiteralPath $DevelopmentFile).Hash;
  tables=$rows;scope='31 application tables only; Liquibase history checked separately'
 }
}
[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($output)) | Out-Null
$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $output -Encoding utf8
if($ComparisonKind -eq 'DevelopmentRecovery') {
 $rows | Select-Object Table,@{Name='DevelopmentRows';Expression={$_.RehearsalRows}},@{Name='RecoveryRows';Expression={$_.DevelopmentRows}},Matches | Format-Table -AutoSize | Out-Host
} else { $rows | Format-Table -AutoSize | Out-Host }
if(-not $passed){Write-Output 'DIFFERENCES: keep evidence and investigate before backup acceptance.';exit 1}
Write-Output "PASS: all 31 table counts and content fingerprints match. Report: $output"
