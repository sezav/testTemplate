# Builds all Revit code configurations (R2019-R2027, via the BuildNET48/BuildNET8/BuildNET10
# meta-configurations) and then packages the combined InstallerWIX MSI.

$sln = "$PSScriptRoot\test_template.sln"
$installerProj = "$PSScriptRoot\InstallerWIX\InstallerWIX.wixproj"

$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$msbuild = $null
if (Test-Path $vswhere) {
    $vsPath = & $vswhere -latest -requires Microsoft.Component.MSBuild -find "MSBuild\**\Bin\MSBuild.exe" | Select-Object -First 1
    if ($vsPath) { $msbuild = $vsPath }
}
if (-not $msbuild) {
    $cmd = Get-Command msbuild.exe -ErrorAction SilentlyContinue
    if ($cmd) { $msbuild = $cmd.Source }
}
if (-not $msbuild) {
    Write-Host "MSBuild.exe not found (checked vswhere and PATH). Run this script from a Developer PowerShell for VS." -ForegroundColor Red
    exit 1
}

# Each meta-configuration recursively rebuilds the real R20xx configs via an
# AfterTargets="Build" target defined in every code csproj (see test_template.csproj etc.):
#   BuildNET48 -> R2019;R2020;R2021;R2022;R2023;R2024 (net48)
#   BuildNET8  -> R2025;R2026                          (net8.0-windows)
#   BuildNET10 -> R2027                                (net10.0-windows)
$metaConfigs = @("R2022")

$allOk = $true
foreach ($cfg in $metaConfigs) {
    Write-Host "=== Building $cfg (solution) ===" -ForegroundColor Cyan
    & $msbuild $sln /restore /t:Build /p:Configuration=$cfg /p:Platform=x64
    if ($LASTEXITCODE -eq 0) {
        Write-Host "OK: $cfg" -ForegroundColor Green
    } else {
        Write-Host "FAIL: $cfg" -ForegroundColor Red
        $allOk = $false
    }
}

if (-not $allOk) {
    Write-Host "=== Skipping InstallerWIX: one or more code builds failed ===" -ForegroundColor Red
    exit 1
}

Write-Host "=== Building InstallerWIX ===" -ForegroundColor Cyan
& $msbuild $installerProj /t:Build /p:Configuration=Release /p:Platform=x86
if ($LASTEXITCODE -eq 0) {
    Write-Host "OK: InstallerWIX" -ForegroundColor Green
    $msi = Get-ChildItem "$PSScriptRoot\InstallerWIX\bin\Release\*.msi" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($msi) {
        Write-Host "=== Done. MSI: $($msi.FullName) ===" -ForegroundColor Green
    } else {
        Write-Host "=== Done, but no MSI file was found in InstallerWIX\bin\Release ===" -ForegroundColor Yellow
    }
} else {
    Write-Host "FAIL: InstallerWIX" -ForegroundColor Red
    exit 1
}
