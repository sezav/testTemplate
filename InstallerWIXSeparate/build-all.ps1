$versions = @(2019, 2020, 2021, 2022, 2023, 2024, 2025, 2026, 2027)
$config = "Release"
$finalDir = "$PSScriptRoot\output"
New-Item -ItemType Directory -Path $finalDir -Force | Out-Null

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

$version = $null
$propsPath = "$PSScriptRoot\..\Directory.Build.props"
if (Test-Path $propsPath) {
    $xml = [xml](Get-Content $propsPath)
    $version = $xml.Project.PropertyGroup.Version | Select-Object -First 1
}
if (-not $version) { $version = "1.0.0.0" }

foreach ($v in $versions) {
    Write-Host "=== Building Revit $v ==="
    & $msbuild "$PSScriptRoot\InstallerWIXSeparate.wixproj" /t:Clean,Build /p:Configuration=$config /p:RevitVersion=$v
    if ($?) {
        $outputRoot = "$PSScriptRoot\bin\$config"
        $msi = "test_template $version Revit $v setup.msi"
        if (Test-Path "$outputRoot\$msi") {
            Move-Item "$outputRoot\$msi" "$finalDir\" -Force
            Write-Host "OK: Revit $v -> $finalDir\$msi" -ForegroundColor Green
        } else {
            Write-Host "WARN: expected MSI not found at $outputRoot\$msi" -ForegroundColor Yellow
        }
    } else {
        Write-Host "FAIL: Revit $v" -ForegroundColor Red
    }
}

Write-Host "=== Done. MSI files in: $finalDir ==="
Read-Host "Press Enter to continue..."
