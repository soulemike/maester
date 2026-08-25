[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingWriteHost',
    '',
    Justification = 'Runner script provides status output.'
)]
[CmdletBinding()]
param(
    [Parameter()]
    [switch]$ConnectActiveDirectory,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$TargetName,

    [Parameter()]
    [string]$MaesterModulePath = (Join-Path $PSScriptRoot "..\..\powershell"),

    [Parameter()]
    [string]$TestPath = (Join-Path $PSScriptRoot "..\..\tests"),

    [Parameter()]
    [string]$OutputFolder = (Join-Path $PSScriptRoot "..\..\test-results"),

    [Parameter()]
    [string]$TargetFolder = $PSScriptRoot,

    [Parameter()]
    [switch]$ExportCsv,

    [Parameter()]
    [switch]$ExportExcel
)

if (-not $ConnectActiveDirectory.IsPresent) {
    throw 'Active Directory testing is opt-in. Re-run with -ConnectActiveDirectory to explicitly connect to Active Directory and run AD tests.'
}

$ErrorActionPreference = 'Stop'
$startTime = Get-Date

Write-Host '=== Maester Active Directory Test Runner (Single Target) ===' -ForegroundColor Cyan
Write-Host "Start Time: $startTime" -ForegroundColor Gray
Write-Host "TargetName: $TargetName" -ForegroundColor Gray
Write-Host ''

Write-Host 'Protocol prerequisites reminder:' -ForegroundColor Yellow
Write-Host "  Run Test-ADProtocolPrerequisites.ps1 first for DirectoryServer '$TargetName'." -ForegroundColor Yellow
Write-Host 'Single-target rule:' -ForegroundColor Yellow
Write-Host '  This script runs one isolated endpoint per Connect-Maester / Invoke-Maester cycle.' -ForegroundColor Yellow
Write-Host ''

# Resolve paths
$MaesterModulePath = Resolve-Path $MaesterModulePath -ErrorAction Stop
$TestPath = Resolve-Path $TestPath -ErrorAction Stop

if (-not (Test-Path $OutputFolder)) {
    New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
}
$OutputFolder = Resolve-Path $OutputFolder -ErrorAction Stop

if (-not (Test-Path $TargetFolder)) {
    New-Item -Path $TargetFolder -ItemType Directory -Force | Out-Null
}
$TargetFolder = Resolve-Path $TargetFolder -ErrorAction Stop

# Import Maester module
$manifestPath = Join-Path $MaesterModulePath 'Maester.psd1'
if (-not (Test-Path $manifestPath)) {
    throw "Maester module manifest not found at: $manifestPath"
}

Import-Module $manifestPath -Force

# Validate the explicit Active Directory connection before any tests run.
Write-Host 'Validating Active Directory connection...' -ForegroundColor Yellow
Connect-Maester -Service ActiveDirectory | Out-Null

# Verify AD tests paths
$adTestPaths = @(
    (Join-Path $TestPath 'Maester\ad'),
    (Join-Path $TestPath 'ad')
)
$validTestPaths = @($adTestPaths | Where-Object { Test-Path $_ })
if (-not $validTestPaths -or $validTestPaths.Count -eq 0) {
    throw "No AD test paths found under: $TestPath"
}

Write-Host 'Running Maester AD tests (Tag: AD) and generating reports...' -ForegroundColor Yellow
$timestamp = Get-Date -Format 'yyyy-MM-dd-HHmmss'
$outputPrefix = "AD-TestResults-$TargetName-$timestamp"

$invokeParams = @{
    Path = $validTestPaths[0]
    Tag = 'AD'
    OutputFolder = $OutputFolder
    OutputFolderFileName = $outputPrefix
    NonInteractive = $true
    SkipGraphConnect = $true
    PassThru = $true
}

if ($ExportCsv.IsPresent) {
    $invokeParams.ExportCsv = $true
}

if ($ExportExcel.IsPresent) {
    $invokeParams.ExportExcel = $true
}

$results = Invoke-Maester @invokeParams

# Copy reports
Write-Host "Copying generated reports to: $TargetFolder" -ForegroundColor Yellow

$patterns = @(
    "$outputPrefix*.html",
    "$outputPrefix*.md",
    "$outputPrefix*.json"
)

if ($ExportCsv.IsPresent) {
    $patterns += "$outputPrefix*.csv"
}

if ($ExportExcel.IsPresent) {
    $patterns += "$outputPrefix*.xlsx"
}

$copiedFiles = @()
foreach ($pattern in $patterns) {
    $files = Get-ChildItem -Path $OutputFolder -Filter $pattern -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        Copy-Item -Path $file.FullName -Destination (Join-Path $TargetFolder $file.Name) -Force
        $copiedFiles += (Join-Path $TargetFolder $file.Name)
        Write-Host "  ✓ Copied: $($file.Name)" -ForegroundColor Green
    }
}

if ($copiedFiles.Count -eq 0) {
    Write-Warning "No reports were copied. Ensure Invoke-Maester generated output files with prefix '$outputPrefix'."
}

$endTime = Get-Date
Write-Host ''
Write-Host '=== Execution Summary ===' -ForegroundColor Cyan
Write-Host "Duration: $($endTime - $startTime)" -ForegroundColor Gray
Write-Host "Reports saved to: $TargetFolder" -ForegroundColor Gray
Write-Host "Report prefix: $outputPrefix" -ForegroundColor Gray
