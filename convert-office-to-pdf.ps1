<#
.SYNOPSIS
    Конвертирует файлы .docx и .pptx в указанной папке в PDF.

.PARAMETER FolderPath
    Папка, в которой ищутся файлы .docx/.pptx (без вложенных подпапок).

.EXAMPLE
    .\convert-office-to-pdf.ps1 -FolderPath "C:\Documents"
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$FolderPath
)

if ([string]::IsNullOrWhiteSpace($FolderPath)) {
    $FolderPath = Read-Host "Введите путь к папке"
}

if (-not (Test-Path -LiteralPath $FolderPath -PathType Container)) {
    Write-Error "Папка не найдена: $FolderPath"
    exit 1
}

$FolderPath = (Resolve-Path -LiteralPath $FolderPath).Path

$wdFormatPDF = 17
$ppSaveAsPDF = 32

$allFiles = Get-ChildItem -LiteralPath $FolderPath -File | Where-Object { $_.Extension -in '.docx', '.pptx' }

$docxFiles = $allFiles | Where-Object { $_.Extension -eq '.docx' }
$pptxFiles = $allFiles | Where-Object { $_.Extension -eq '.pptx' }

if ($allFiles.Count -eq 0) {
    Write-Host "Файлы .docx или .pptx в папке '$FolderPath' не найдены."
    exit 0
}

$successCount = 0
$failCount = 0

if ($docxFiles.Count -gt 0) {
    Write-Host "Конвертация $($docxFiles.Count) файл(ов) .docx..."
    $word = $null
    try {
        $word = New-Object -ComObject Word.Application
        $word.Visible = $false

        foreach ($file in $docxFiles) {
            $pdfPath = [IO.Path]::ChangeExtension($file.FullName, '.pdf')
            $doc = $null
            $converted = $false
            try {
                $doc = $word.Documents.Open($file.FullName, $false, $true)
                $doc.SaveAs2($pdfPath, $wdFormatPDF)
                $converted = $true
            }
            catch {
                Write-Warning "  Ошибка при конвертации '$($file.Name)': $($_.Exception.Message)"
                $failCount++
            }
            finally {
                if ($doc) {
                    $doc.Close($false)
                    [Runtime.Interopservices.Marshal]::ReleaseComObject($doc) | Out-Null
                }
            }

            if ($converted) {
                try {
                    Remove-Item -LiteralPath $file.FullName -Force
                    Write-Host "  OK: $($file.Name) -> $(Split-Path $pdfPath -Leaf) (оригинал удалён)"
                    $successCount++
                }
                catch {
                    Write-Warning "  PDF создан, но не удалось удалить оригинал '$($file.Name)': $($_.Exception.Message)"
                    $successCount++
                }
            }
        }
    }
    finally {
        if ($word) {
            $word.Quit()
            [Runtime.Interopservices.Marshal]::ReleaseComObject($word) | Out-Null
        }
        [GC]::Collect()
        [GC]::WaitForPendingFinalizers()
    }
}

if ($pptxFiles.Count -gt 0) {
    Write-Host "Конвертация $($pptxFiles.Count) файл(ов) .pptx..."
    $ppt = $null
    try {
        $ppt = New-Object -ComObject PowerPoint.Application

        foreach ($file in $pptxFiles) {
            $pdfPath = [IO.Path]::ChangeExtension($file.FullName, '.pdf')
            $presentation = $null
            $converted = $false
            try {
                $presentation = $ppt.Presentations.Open($file.FullName, $true, $false, $false)
                $presentation.SaveAs($pdfPath, $ppSaveAsPDF)
                $converted = $true
            }
            catch {
                Write-Warning "  Ошибка при конвертации '$($file.Name)': $($_.Exception.Message)"
                $failCount++
            }
            finally {
                if ($presentation) {
                    $presentation.Close()
                    [Runtime.Interopservices.Marshal]::ReleaseComObject($presentation) | Out-Null
                }
            }

            if ($converted) {
                try {
                    Remove-Item -LiteralPath $file.FullName -Force
                    Write-Host "  OK: $($file.Name) -> $(Split-Path $pdfPath -Leaf) (оригинал удалён)"
                    $successCount++
                }
                catch {
                    Write-Warning "  PDF создан, но не удалось удалить оригинал '$($file.Name)': $($_.Exception.Message)"
                    $successCount++
                }
            }
        }
    }
    finally {
        if ($ppt) {
            $ppt.Quit()
            [Runtime.Interopservices.Marshal]::ReleaseComObject($ppt) | Out-Null
        }
        [GC]::Collect()
        [GC]::WaitForPendingFinalizers()
    }
}

Write-Host ""
Write-Host "Готово. Успешно: $successCount, с ошибками: $failCount."

