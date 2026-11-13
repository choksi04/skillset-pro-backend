[CmdletBinding()]
param(
    [ValidateSet('Validate', 'Preview', 'Apply', 'Status')]
    [string]$Action = 'Validate'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$wrapper = Join-Path $repositoryRoot 'mvnw.cmd'
$goal = switch ($Action) {
    'Validate' { 'liquibase:validate' }
    'Preview' { 'liquibase:updateSQL' }
    'Apply' { 'liquibase:update' }
    'Status' { 'liquibase:status' }
}
$secret = Read-Host 'Password for local skillset_dev_owner (not saved)' -AsSecureString
$credential = New-Object System.Net.NetworkCredential('', $secret)
$previousPassword = [Environment]::GetEnvironmentVariable('SKILLSET_DEV_DB_PASSWORD', 'Process')
try {
    # Password stays out of command arguments and files. Do not enable Maven debug logging.
    [Environment]::SetEnvironmentVariable('SKILLSET_DEV_DB_PASSWORD', $credential.Password, 'Process')
    Push-Location $repositoryRoot
    try {
        [IO.Directory]::CreateDirectory((Join-Path $repositoryRoot 'target\liquibase')) | Out-Null
        Write-Output 'Destination: 127.0.0.1:5432/skillset_pro_backend_dev as skillset_dev_owner'
        if ($Action -eq 'Apply') { Write-Output 'Action: Apply (creates the development application schema; no business records imported)' } else { Write-Output "Action: $Action (does not apply application changesets)" }
        Write-Output 'Authentication integration is not started; rehearsal database is not targeted.'
        & $wrapper --batch-mode --no-transfer-progress '-Pliquibase-dev' $goal
        if ($LASTEXITCODE -ne 0) { throw "Liquibase $Action failed. Stop and review the error." }
    } finally {
        Pop-Location
    }
} finally {
    [Environment]::SetEnvironmentVariable('SKILLSET_DEV_DB_PASSWORD', $previousPassword, 'Process')
    $credential = $null
    $secret.Dispose()
}

