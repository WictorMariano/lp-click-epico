# Build single-file HTML bundle for ClickEpico LP (WordPress / download)
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$indexPath = Join-Path $root 'index.html'
$cssPath = Join-Path $root 'styles.css'
$jsPath = Join-Path $root 'main.js'
$outDir = Join-Path $root 'download'
$outPath = Join-Path $outDir 'clickepico-lp.html'

if (-not (Test-Path $indexPath)) { throw "index.html not found at $indexPath" }
if (-not (Test-Path $cssPath)) { throw "styles.css not found at $cssPath" }
if (-not (Test-Path $jsPath)) { throw "main.js not found at $jsPath" }

New-Item -ItemType Directory -Force -Path $outDir | Out-Null

function Get-MimeType {
    param([string]$Path)
    switch ([IO.Path]::GetExtension($Path).ToLowerInvariant()) {
        '.png' { return 'image/png' }
        '.jpg' { return 'image/jpeg' }
        '.jpeg' { return 'image/jpeg' }
        '.webp' { return 'image/webp' }
        '.gif' { return 'image/gif' }
        '.svg' { return 'image/svg+xml' }
        default { return 'application/octet-stream' }
    }
}

function Convert-LocalPathToDataUri {
    param([string]$RelativePath)

    $normalized = ($RelativePath -replace '\\', '/').Trim()
    $fullPath = Join-Path $root ($normalized -replace '/', [IO.Path]::DirectorySeparatorChar)

    if (-not (Test-Path -LiteralPath $fullPath)) {
        Write-Warning "Image not found: $RelativePath"
        return $null
    }

    $bytes = [IO.File]::ReadAllBytes($fullPath)
    $b64 = [Convert]::ToBase64String($bytes)
    $mime = Get-MimeType -Path $fullPath
    return "data:$mime;base64,$b64"
}

Write-Host "Reading source files..."
$html = [IO.File]::ReadAllText($indexPath, [Text.Encoding]::UTF8)
$css = [IO.File]::ReadAllText($cssPath, [Text.Encoding]::UTF8)
$js = [IO.File]::ReadAllText($jsPath, [Text.Encoding]::UTF8)

# WordPress-friendly scoping
$css = $css -replace '(?m)^body\s*\{', '#clickepico-lp {'

# Remove external stylesheet and script references
$html = $html -replace '\s*<link rel="stylesheet" href="styles\.css">\s*', "`n"

# Inline CSS after Google Fonts link
$styleBlock = "<style>`n$css`n</style>"
$html = $html -replace '(<link href="https://fonts\.googleapis\.com/css2[^"]+" rel="stylesheet">)', "`$1`n$styleBlock"

# Wrap header + main in WordPress wrapper
$html = $html -replace '<body>\s*', "<body>`n    <div id=`"clickepico-lp`">`n"
$html = $html -replace '</main>\s*', "</main>`n    </div>`n"

# Add usage comment in head
$usageComment = @"
<!--
  ClickEpico LP - Arquivo unico autocontido
  - Abra direto no navegador para preview
  - WordPress: use bloco HTML personalizado em pagina full-width (sem header/footer do tema)
  - Tamanho estimado: ~34 MB (imagens embutidas em base64)
  - Regenerar: powershell -ExecutionPolicy Bypass -File scripts/build-single-html.ps1
-->
"@
$html = $html -replace '<head>', "<head>`n$usageComment"

# Inline JS before </body>
$scriptBlock = "<script>`n$js`n</script>"
$html = $html -replace '</body>', "$scriptBlock`n</body>"

# Remove external script if still present
$html = $html -replace '\s*<script src="main\.js"></script>\s*', "`n"

# Embed local images
$imageCount = 0

function Replace-LocalImagePath {
    param([string]$Path)

    if ($Path -match '^(https?:|data:|#|/)') {
        return $Path
    }

    $dataUri = Convert-LocalPathToDataUri -RelativePath $Path
    if ($null -eq $dataUri) {
        return $Path
    }

    $script:imageCount++
    return $dataUri
}

$html = [regex]::Replace($html, 'src="([^"]+)"', {
    param($match)
    $newPath = Replace-LocalImagePath -Path $match.Groups[1].Value
    return "src=`"$newPath`""
})

$html = [regex]::Replace($html, 'url\(\s*["'']?([^"'')]+)["'']?\s*\)', {
    param($match)
    $newPath = Replace-LocalImagePath -Path $match.Groups[1].Value.Trim()
    return "url(""$newPath"")"
})

Write-Host "Writing $outPath ..."
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[IO.File]::WriteAllText($outPath, $html, $utf8NoBom)

$fileSize = (Get-Item -LiteralPath $outPath).Length
$sizeMB = [math]::Round($fileSize / 1MB, 2)

Write-Host ""
Write-Host "Done."
Write-Host "  Output: $outPath"
Write-Host "  Size:   $sizeMB MB ($fileSize bytes)"
Write-Host "  Images embedded: $imageCount"
