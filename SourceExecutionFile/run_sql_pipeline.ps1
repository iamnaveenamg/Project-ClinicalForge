# =========================================================================
# Project ClinicalForge: Azure SQL Automation Deployment Script
# =========================================================================

param (
    [Parameter(Mandatory=$true)][string]$ServerName,    # e.g., your-server.database.windows.net
    [Parameter(Mandatory=$true)][string]$DatabaseName,  # e.g., ClinicalForgeProdDB
    [Parameter(Mandatory=$true)][string]$Username,      # e.g., azureadmin
    [Parameter(Mandatory=$true)][string]$Password       # e.g., YourSecureAzurePassword123!
)

# 2. File Array to Execute using $PSScriptRoot for exact location matching
$SqlFiles = @(
    "$PSScriptRoot/CLINICALFORGE-DataGenerator.sql"  
)

# 3. Connection Execution Loop
Write-Host "🚀 Starting Project ClinicalForge Database Deployment Pipeline (Azure SQL)..." -ForegroundColor Cyan

foreach ($File in $SqlFiles) {
    if (Test-Path $File) {
        Write-Host "⏳ Executing: $File against $DatabaseName on $ServerName..." -ForegroundColor Yellow
        
        try {
            # Uses invoke-sqlcmd utility (Requires SqlServer module in PowerShell)
            Invoke-Sqlcmd -ServerInstance $ServerName `
                          -Database $DatabaseName `
                          -Username $Username `
                          -Password $Password `
                          -InputFile $File `
                          -ConnectionTimeout 30 `
                          -ErrorAction Stop
            
            Write-Host "✅ Successfully deployed: $File" -ForegroundColor Green
        }
        catch {
            Write-Error "❌ Deployment failed on file $File. Error: $_"
            break # Stops the pipeline immediately if a file fails
        }
    } else {
        Write-Warning "❌ File not found at path: $File"
    }
}

Write-Host "🏁 Azure Database pipeline deployment completed!" -ForegroundColor Cyan
