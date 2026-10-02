<#
    Download-GoogleDriveFiles.ps1

    Скачивает набор файлов с Google Drive по их ID или прямым ссылкам,
    без Google API, OAuth или сторонних утилит (rclone и т.п.).

    ОГРАНИЧЕНИЯ:
    - Работает только с файлами, у которых доступ открыт "Все, у кого есть ссылка"
      (или полностью публичными). Приватные файлы так скачать нельзя.
    - Скрипт НЕ умеет получить список файлов внутри папки Google Drive —
      Google не отдаёт такой список без официального API. Поэтому список
      файлов (ID или ссылки) нужно подготовить заранее самостоятельно.
    - Обход промежуточной страницы "Google Диск не может проверить файл
      на вирусы" для больших файлов (~100 МБ+) основан на текущей разметке
      страницы подтверждения Google и может потребовать правок, если Google
      изменит эту страницу.

    ПРИМЕРЫ ИСПОЛЬЗОВАНИЯ:

    # По списку ID/ссылок прямо в команде
    .\Download-GoogleDriveFiles.ps1 -FileIds "1AbCdEfGhIjKlMnOpQrStUvWxYz","https://drive.google.com/file/d/1XyZ.../view" -DestinationFolder "C:\Downloads\Drive"

    # По текстовому файлу со списком (один ID/ссылка на строку)
    .\Download-GoogleDriveFiles.ps1 -InputFile ".\links.txt" -DestinationFolder ".\Downloads"

    # С перезаписью уже скачанных файлов
    .\Download-GoogleDriveFiles.ps1 -InputFile ".\links.txt" -Force
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string[]] $FileIds,

    [Parameter(Mandatory = $false)]
    [string] $InputFile,

    [Parameter(Mandatory = $false)]
    [string] $DestinationFolder = ".\Downloads",

    [Parameter(Mandatory = $false)]
    [switch] $Force
)

$ErrorActionPreference = "Stop"

# Чтобы кириллица в именах файлов корректно отображалась в консоли
# (на сохранение файлов на диск это не влияет, только на вывод).
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

function Get-GoogleDriveFileId {
    param([Parameter(Mandatory)] [string] $LinkOrId)

    $value = $LinkOrId.Trim()
    if ($value.Length -eq 0) {
        return $null
    }

    # https://drive.google.com/file/d/<ID>/view?...
    if ($value -match '/file/d/([^/?#]+)') {
        return $Matches[1]
    }

    # https://drive.google.com/open?id=<ID>  или  ...?id=<ID>&export=download
    if ($value -match '[?&]id=([^&#]+)') {
        return $Matches[1]
    }

    # Уже похоже на голый ID (без пробелов и слэшей)
    if ($value -notmatch '[\s/]') {
        return $value
    }

    Write-Warning "Не удалось извлечь ID файла из значения: '$value'"
    return $null
}

function ConvertTo-FixedUtf8String {
    # .NET разбирает HTTP-заголовки как ISO-8859-1, поэтому сырые UTF-8 байты
    # (например, кириллица в filename="...") приходят "кракозябрами".
    # Восстанавливаем исходные байты и декодируем их заново как UTF-8.
    param([Parameter(Mandatory)] [string] $Value)

    $bytes = [System.Text.Encoding]::GetEncoding(28591).GetBytes($Value)
    return [System.Text.Encoding]::UTF8.GetString($bytes)
}

function Get-SanitizedFileName {
    param([Parameter(Mandatory)] [string] $FileName)

    $invalidChars = [System.IO.Path]::GetInvalidFileNameChars()
    $sanitized = -join ($FileName.ToCharArray() | ForEach-Object {
        if ($invalidChars -contains $_) { "_" } else { $_ }
    })
    return $sanitized
}

function Get-FileNameFromContentDisposition {
    param([string] $ContentDisposition)

    if (-not $ContentDisposition) {
        return $null
    }

    if ($ContentDisposition -match 'filename\*=UTF-8''''([^;]+)') {
        $decoded = [System.Uri]::UnescapeDataString($Matches[1])
        return Get-SanitizedFileName -FileName $decoded
    }
    if ($ContentDisposition -match 'filename="?([^";]+)"?') {
        $fixed = ConvertTo-FixedUtf8String -Value $Matches[1]
        return Get-SanitizedFileName -FileName $fixed
    }
    return $null
}

function Save-GoogleDriveFile {
    param(
        [Parameter(Mandatory)] [string] $FileId,
        [Parameter(Mandatory)] [string] $DestinationFolder,
        [switch] $Force
    )

    $session = $null
    $baseUri = "https://drive.google.com/uc?export=download&id=$FileId"

    $response = Invoke-WebRequest -Uri $baseUri -SessionVariable session -UseBasicParsing

    $contentType = $response.Headers["Content-Type"]
    $isHtml = $contentType -and ($contentType -match "text/html")

    if ($isHtml) {
        # Большой файл: показана страница подтверждения. Извлекаем токен.
        $confirmToken = $null

        $warningCookie = $session.Cookies.GetCookies("https://drive.google.com") |
            Where-Object { $_.Name -like "download_warning*" } |
            Select-Object -First 1
        if ($warningCookie) {
            $confirmToken = $warningCookie.Value
        }

        if (-not $confirmToken -and $response.Content -match 'confirm=([0-9A-Za-z_-]+)') {
            $confirmToken = $Matches[1]
        }

        if (-not $confirmToken) {
            throw "Не удалось найти confirm-токен для файла $FileId (возможно, файл приватный или страница подтверждения изменилась)."
        }

        $confirmUri = "https://drive.google.com/uc?export=download&confirm=$confirmToken&id=$FileId"
        $response = Invoke-WebRequest -Uri $confirmUri -WebSession $session -UseBasicParsing
    }

    $fileName = Get-FileNameFromContentDisposition -ContentDisposition $response.Headers["Content-Disposition"]
    if (-not $fileName) {
        $fileName = "$FileId.bin"
        Write-Warning "Не удалось определить имя файла для ID $FileId, использую '$fileName'."
    }

    $outPath = Join-Path $DestinationFolder $fileName

    if ((Test-Path $outPath) -and -not $Force) {
        Write-Host "Пропущен (уже существует): $fileName" -ForegroundColor Yellow
        return [PSCustomObject]@{ FileId = $FileId; FileName = $fileName; Status = "Skipped" }
    }

    [System.IO.File]::WriteAllBytes($outPath, $response.Content)
    Write-Host "Скачан: $fileName" -ForegroundColor Green
    return [PSCustomObject]@{ FileId = $FileId; FileName = $fileName; Status = "Downloaded" }
}

# --- Основной блок ---

$allInputs = New-Object System.Collections.Generic.List[string]

if ($FileIds) {
    foreach ($item in $FileIds) { $allInputs.Add($item) }
}

if ($InputFile) {
    if (-not (Test-Path $InputFile)) {
        throw "Файл со списком ссылок/ID не найден: $InputFile"
    }
    Get-Content -Path $InputFile | ForEach-Object {
        $line = $_.Trim()
        if ($line.Length -gt 0 -and -not $line.StartsWith("#")) {
            $allInputs.Add($line)
        }
    }
}

if ($allInputs.Count -eq 0) {
    throw "Не указано ни одного файла для скачивания. Используйте параметр -FileIds или -InputFile."
}

if (-not (Test-Path $DestinationFolder)) {
    New-Item -ItemType Directory -Path $DestinationFolder -Force | Out-Null
}

$results = @()

foreach ($input in $allInputs) {
    $fileId = Get-GoogleDriveFileId -LinkOrId $input
    if (-not $fileId) {
        $results += [PSCustomObject]@{ FileId = $input; FileName = $null; Status = "Error: bad id/link" }
        continue
    }

    try {
        $result = Save-GoogleDriveFile -FileId $fileId -DestinationFolder $DestinationFolder -Force:$Force
        $results += $result
    }
    catch {
        Write-Warning "Ошибка при скачивании $fileId : $($_.Exception.Message)"
        $results += [PSCustomObject]@{ FileId = $fileId; FileName = $null; Status = "Error: $($_.Exception.Message)" }
    }
}

Write-Host ""
Write-Host "=== Итог ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize

$downloaded = ($results | Where-Object { $_.Status -eq "Downloaded" }).Count
$skipped = ($results | Where-Object { $_.Status -eq "Skipped" }).Count
$errors = ($results | Where-Object { $_.Status -like "Error*" }).Count

Write-Host "Скачано: $downloaded, Пропущено: $skipped, Ошибок: $errors"
