#!/usr/bin/env pwsh

$ErrorActionPreference = 'Stop'

# Check .NET version requirement
Write-Host "Checking .NET SDK version..." -ForegroundColor Cyan

# Read required version from global.json
$globalJsonPath = Join-Path (Get-Location) "global.json"
if (-not (Test-Path $globalJsonPath)) {
    Write-Error "global.json not found. Cannot determine required .NET SDK version."
    exit 1
}

$globalJson = Get-Content $globalJsonPath | ConvertFrom-Json
$requiredVersion = $globalJson.sdk.version
Write-Host "Required .NET SDK version: $requiredVersion" -ForegroundColor Yellow

# Check if dotnet command is available and get version
# We need to run from a different directory to avoid global.json influence
$tempDir = [System.IO.Path]::GetTempPath()
$originalLocation = Get-Location
try {
    Set-Location $tempDir
    $installedVersion = dotnet --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "dotnet command failed"
    }
} catch {
    Write-Error "❌ .NET SDK is not installed or not in PATH. Please install .NET $requiredVersion or later."
    Write-Host "   Download from: https://dotnet.microsoft.com/download" -ForegroundColor Yellow
    exit 1
} finally {
    Set-Location $originalLocation
}

Write-Host "Installed .NET SDK version: $installedVersion" -ForegroundColor Yellow

# Parse version numbers for comparison
$requiredVersionParts = $requiredVersion.Split('.')
$installedVersionParts = $installedVersion.Split('.')

# Compare major version (must be 9 or higher)
$requiredMajor = [int]$requiredVersionParts[0]
$installedMajor = [int]$installedVersionParts[0]

if ($installedMajor -lt $requiredMajor) {
    Write-Error "❌ .NET $requiredMajor is required but .NET $installedMajor is installed."
    Write-Host "   Required: .NET $requiredVersion or compatible" -ForegroundColor Yellow
    Write-Host "   Installed: .NET $installedVersion" -ForegroundColor Yellow
    Write-Host "   Download .NET $requiredMajor from: https://dotnet.microsoft.com/download" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ .NET SDK version check passed" -ForegroundColor Green

# Options
$configuration = 'Release'
$artifactsDir = Join-Path (Resolve-Path .) 'artifacts'
$packagesDir = Join-Path $artifactsDir 'Packages'
$testResultsDir = Join-Path $artifactsDir 'Test results'
$logsDir = Join-Path $artifactsDir 'Logs'

# Ensure directories exist
New-Item -ItemType Directory -Force -Path $artifactsDir, $packagesDir, $testResultsDir, $logsDir | Out-Null

$dotnetArgs = @(
    '--configuration', $configuration
    '/p:CI=' + ($env:CI -or $env:TF_BUILD)
)

# Build
Write-Host "Building..." -ForegroundColor Cyan
dotnet build @dotnetArgs /bl:"$logsDir/build.binlog"
if ($LASTEXITCODE -ne 0) { 
    Write-Error "Build failed with exit code $LASTEXITCODE"
    exit 1 
}

# Pack
Write-Host "Packing..." -ForegroundColor Cyan
if (Test-Path $packagesDir) {
    Remove-Item -Recurse -Force $packagesDir
}
dotnet pack src\Shouldly --no-build --output $packagesDir @dotnetArgs /bl:"$logsDir/pack.binlog"
if ($LASTEXITCODE -ne 0) { 
    Write-Error "Pack failed with exit code $LASTEXITCODE"
    exit 1 
}

# Test
Write-Host "Testing..." -ForegroundColor Cyan
if (Test-Path $testResultsDir) {
    Remove-Item -Recurse -Force $testResultsDir
}

# Define test projects
$testProjects = @("src\Shouldly.Tests\Shouldly.Tests.csproj")

# Add DocumentationExamples project only on Windows
if ($IsWindows) {
    $testProjects += "src\DocumentationExamples\DocumentationExamples.csproj"
    Write-Host "Running on Windows. Including DocumentationExamples project." -ForegroundColor Cyan
} else {
    Write-Host "Not running on Windows. Skipping DocumentationExamples project." -ForegroundColor Yellow
}

# Run tests for each project
foreach ($project in $testProjects) {
    Write-Host "Testing $project..." -ForegroundColor Cyan
    dotnet test $project --no-build @dotnetArgs --logger trx --results-directory $testResultsDir /bl:"$logsDir/test-$(Split-Path $project -Leaf).binlog" --logger "GitHubActions;summary.includePassedTests=true;summary.includeSkippedTests=true" -- RunConfiguration.CollectSourceInformation=true
    if ($LASTEXITCODE -ne 0) { 
        Write-Error "Tests for $project failed with exit code $LASTEXITCODE"
        exit 1 
    }
}

Write-Host "Build completed successfully!" -ForegroundColor Green