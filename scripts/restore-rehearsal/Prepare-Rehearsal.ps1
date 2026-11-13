[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ArchivePath,
    [Parameter(Mandatory)][string]$OutputDirectory,
    [Parameter(Mandatory)][string]$PgRestorePath
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# PREPARATION ONLY: no database connection or restore.
$archive = (Resolve-Path -LiteralPath $ArchivePath).Path
$pgRestore = (Resolve-Path -LiteralPath $PgRestorePath).Path
$repositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$outputRoot = [IO.Path]::GetFullPath($OutputDirectory)
if ($outputRoot.Equals($repositoryRoot, [StringComparison]::OrdinalIgnoreCase) -or
    $outputRoot.StartsWith($repositoryRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Use a restricted working directory outside the Git repository.'
}
$referenceDir = Join-Path $PSScriptRoot 'archive-20261112'
$manifest = Get-Content -Raw -LiteralPath (Join-Path $referenceDir 'manifest.json') | ConvertFrom-Json
$actualHash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash
if ($actualHash -ne $manifest.sha256) {
    throw 'Archive does not match the reviewed backup. Generate a new reviewed selection.'
}
$version = (& $pgRestore --version) -join ' '
if ($LASTEXITCODE -ne 0 -or $version -notmatch 'PostgreSQL\)\s+(\d+)' -or [int]$Matches[1] -lt 18) {
    throw 'Use PostgreSQL 18 or newer pg_restore; archive was written by pg_dump 18.'
}
$toc = @(& $pgRestore --list $archive)
if ($LASTEXITCODE -ne 0) { throw 'Could not inspect archive inventory.' }
$tocEntries = @{}
foreach ($line in $toc) {
    if ($line -match '^(\d+);') { $tocEntries[$Matches[1]] = $line.Trim() }
}
$selectionCounts = @{
    'application.list' = 190
    'application-schema.list' = 159
    'application-data.list' = 31
}
foreach ($name in $selectionCounts.Keys) {
    $selection = @(Get-Content -LiteralPath (Join-Path $referenceDir $name))
    $ids = @{}
    foreach ($line in $selection) {
        if ($line -match '^(\d+);') {
            $entryId = $Matches[1]
            if ($ids.ContainsKey($entryId)) { throw "Duplicate selection entry $entryId." }
            $ids[$entryId] = $true
            if (-not $tocEntries.ContainsKey($entryId) -or $tocEntries[$entryId] -ne $line.Trim()) {
                throw "Selection mismatch for archive entry $entryId."
            }
        }
    }
    if ($ids.Count -ne $selectionCounts[$name]) { throw "Unexpected entry count in $name." }
}
$destinations = @('application.list','application-schema.list','application-data.list',
    'manifest.json','expected-row-counts.csv','review-schema.sql','excluded-entries.list')
foreach ($name in $destinations) {
    if (Test-Path -LiteralPath (Join-Path $outputRoot $name)) {
        throw "Output already exists: $name. Choose a new working directory."
    }
}
[IO.Directory]::CreateDirectory($outputRoot) | Out-Null
foreach ($name in @('application.list','application-schema.list','application-data.list','manifest.json','expected-row-counts.csv')) {
    Copy-Item -LiteralPath (Join-Path $referenceDir $name) -Destination (Join-Path $outputRoot $name)
}
$selectedIds = @{}
Get-Content -LiteralPath (Join-Path $referenceDir 'application.list') | ForEach-Object {
    if ($_ -match '^(\d+);') { $selectedIds[$Matches[1]] = $true }
}
$excluded = @($toc | Where-Object { $_ -match '^(\d+);' -and -not $selectedIds.ContainsKey($Matches[1]) })
[IO.File]::WriteAllLines((Join-Path $outputRoot 'excluded-entries.list'), [string[]]$excluded)
$restoreArgs = @('--schema-only','--no-owner','--no-acl','--no-tablespaces',
    '--no-comments','--no-security-labels','--use-list',
    (Join-Path $outputRoot 'application-schema.list'),'--file',
    (Join-Path $outputRoot 'review-schema.sql'),$archive)
& $pgRestore @restoreArgs
if ($LASTEXITCODE -ne 0) { throw 'Schema extraction failed; do not proceed to a restore.' }
Write-Output 'Archive checksum/selection verified. Schema-only SQL generated for review.'
Write-Output "Working directory: $outputRoot"
Write-Output 'No database connection or restore was executed.'
