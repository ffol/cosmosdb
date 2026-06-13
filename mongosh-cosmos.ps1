<#
.SYNOPSIS
    Launches mongosh connected to Cosmos DB for MongoDB vCore using Entra ID auth.

.DESCRIPTION
    Acquires an Azure access token with the correct scope, writes it to a temp file,
    and launches mongosh using the OIDC workload-identity token-file flow.

.PARAMETER Database
    Database to connect to (default: admin).

.EXAMPLE
    .\mongosh-cosmos.ps1
    .\mongosh-cosmos.ps1 -Database myapp

.NOTES
    Requires: az CLI logged in (az login), mongosh.exe in the same folder.
#>
param(
    [string]$Database = "admin"
)

$Cluster = "{mongodb-clustername}.mongocluster.cosmos.azure.com"
$Uri = "mongodb+srv://$Cluster/${Database}?tls=true&authMechanism=MONGODB-OIDC&authMechanismProperties=ENVIRONMENT:test&retrywrites=false&maxIdleTimeMS=120000"

# Acquire token using the correct scope for Cosmos DB for MongoDB vCore
Write-Host "Acquiring Entra ID token..."
$tokenJson = az account get-access-token --resource https://ossrdbms-aad.database.windows.net 2>&1 | ConvertFrom-Json
if (-not $tokenJson -or -not $tokenJson.accessToken) {
    Write-Error "Failed to acquire token. Run 'az login' first and ensure you have access."
    exit 1
}
Write-Host "Token acquired (expires: $($tokenJson.expiresOn))"

# Write raw access token to a temp file (mongosh reads it via OIDC_TOKEN_FILE)
$tokenFile = [System.IO.Path]::GetTempFileName()
[System.IO.File]::WriteAllText($tokenFile, $tokenJson.accessToken)

# Set env var and launch mongosh
$env:OIDC_TOKEN_FILE = $tokenFile

Write-Host "Connecting to $Cluster / $Database ..."
try {
    & "$PSScriptRoot\mongosh.exe" $Uri --oidcTrustedEndpoint @args
}
finally {
    $env:OIDC_TOKEN_FILE = $null
    Remove-Item -Force $tokenFile -ErrorAction SilentlyContinue
}
