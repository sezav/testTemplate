<#
    Copy-FolderContents.ps1

    Копирует все файлы из указанной папки в другую папку.

    ПАРАМЕТРЫ:
    -SourceFolder      Папка-источник (обязательный).
    -DestinationFolder Папка назначения, создаётся автоматически, если не существует (обязательный).
    -Recurse           Копировать также файлы из всех подпапок (сохраняя структуру подпапок).
                        Без этого флага копируются только файлы верхнего уровня SourceFolder.
    -Force             Перезаписывать файлы, если в DestinationFolder уже есть файл с таким именем.
                        Без этого флага такие файлы пропускаются.

    ПРИМЕРЫ:
    .\Copy-FolderContents.ps1 -SourceFolder "C:\Src" -DestinationFolder "D:\Dst"
    .\Copy-FolderContents.ps1 -SourceFolder "C:\Src" -DestinationFolder "D:\Dst" -Recurse -Force
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $SourceFolder,

    [Parameter(Mandatory = $true)]
    [string] $DestinationFolder,

    [switch] $Recurse,

    [switch] $Force
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $SourceFolder -PathType Container)) {
    throw "Папка-источник не найдена: $SourceFolder"
}

if (-not (Test-Path -LiteralPath $DestinationFolder)) {
    New-Item -ItemType Directory -Path $DestinationFolder -Force | Out-Null
}

$SourceFolder = (Resolve-Path -LiteralPath $SourceFolder).Path
$DestinationFolder = (Resolve-Path -LiteralPath $DestinationFolder).Path

$files = Get-ChildItem -LiteralPath $SourceFolder -File -Recurse:$Recurse

$copied = 0
$skipped = 0
$errors = 0

foreach ($file in $files) {
    if ($Recurse) {
        $relativePath = $file.FullName.Substring($SourceFolder.Length).TrimStart('\', '/')
        $targetPath = Join-Path $DestinationFolder $relativePath
        $targetDir = Split-Path $targetPath -Parent
        if (-not (Test-Path -LiteralPath $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
    }
    else {
        $targetPath = Join-Path $DestinationFolder $file.Name
    }

    if ((Test-Path -LiteralPath $targetPath) -and -not $Force) {
        Write-Host "Пропущен (уже существует): $($file.Name)" -ForegroundColor Yellow
        $skipped++
        continue
    }

    try {
        Copy-Item -LiteralPath $file.FullName -Destination $targetPath -Force:$Force
        Write-Host "Скопирован: $($file.Name)" -ForegroundColor Green
        $copied++
    }
    catch {
        Write-Warning "Ошибка при копировании $($file.Name): $($_.Exception.Message)"
        $errors++
    }
}

Write-Host ""
Write-Host "=== Итог ===" -ForegroundColor Cyan
Write-Host "Скопировано: $copied, Пропущено: $skipped, Ошибок: $errors"
