# Build standalone HTML file per LP section (download folder)
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$indexPath = Join-Path $root 'index.html'
$cssPath = Join-Path $root 'styles.css'
$outDir = Join-Path $root 'download'

$sections = @(
    @{ File = 'hero.html';            Title = 'Hero';                    Start = '<section class="hero"' }
    @{ File = 'sobre.html';           Title = 'Sobre';                   Start = '<section class="about"' }
    @{ File = 'funcionalidades.html'; Title = 'Funcionalidades';         Start = '<section class="features"' }
    @{ File = 'em-breve.html';        Title = 'O que vem por aí';        Start = '<section class="coming-soon"' }
    @{ File = 'como-funciona.html';   Title = 'Como funciona';           Start = '<section class="how-it-works"' }
    @{ File = 'beneficios.html';      Title = 'Benefícios';              Start = '<section class="benefits"' }
    @{ File = 'configure.html';       Title = 'Configure seu salão';     Start = '<section class="setup"' }
    @{ File = 'suporte.html';         Title = 'Suporte';                 Start = '<section class="support"' }
    @{ File = 'precos.html';          Title = 'Preços';                  Start = '<section class="pricing"' }
    @{ File = 'faq.html';             Title = 'Perguntas frequentes';    Start = '<section class="faq"' }
    @{ File = 'rodape.html';          Title = 'Rodapé';                  Start = '<footer class="site-footer"'; IsFooter = $true }
)

$pricingJs = @'
const pricingSection = document.querySelector('.pricing');
const pricingToggleBtns = document.querySelectorAll('.pricing-toggle__btn');

pricingToggleBtns.forEach((btn) => {
    btn.addEventListener('click', () => {
        const billing = btn.dataset.billing;
        if (!billing || !pricingSection) return;

        pricingSection.dataset.billing = billing;
        pricingToggleBtns.forEach((b) => {
            const active = b === btn;
            b.classList.toggle('is-active', active);
            b.setAttribute('aria-pressed', String(active));
        });
    });
});
'@

if (-not (Test-Path $indexPath)) { throw "index.html not found" }
if (-not (Test-Path $cssPath)) { throw "styles.css not found" }

New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$indexHtml = [IO.File]::ReadAllText($indexPath, [Text.Encoding]::UTF8)
$css = [IO.File]::ReadAllText($cssPath, [Text.Encoding]::UTF8)
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$imageCache = @{}

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
    if ($imageCache.ContainsKey($normalized)) {
        return $imageCache[$normalized]
    }

    $fullPath = Join-Path $root ($normalized -replace '/', [IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $fullPath)) {
        Write-Warning "Image not found: $RelativePath"
        return $null
    }

    $bytes = [IO.File]::ReadAllBytes($fullPath)
    $b64 = [Convert]::ToBase64String($bytes)
    $mime = Get-MimeType -Path $fullPath
    $uri = "data:$mime;base64,$b64"
    $imageCache[$normalized] = $uri
    return $uri
}

function Embed-LocalImages {
    param([string]$HtmlFragment)

    $result = [regex]::Replace($HtmlFragment, 'src="([^"]+)"', {
        param($match)
        $path = $match.Groups[1].Value
        if ($path -match '^(https?:|data:|#|/)') { return $match.Value }
        $dataUri = Convert-LocalPathToDataUri -RelativePath $path
        if ($null -eq $dataUri) { return $match.Value }
        return "src=`"$dataUri`""
    })

    $result = [regex]::Replace($result, 'url\(\s*["'']?([^"'')]+)["'']?\s*\)', {
        param($match)
        $path = $match.Groups[1].Value.Trim()
        if ($path -match '^(https?:|data:)') { return $match.Value }
        $dataUri = Convert-LocalPathToDataUri -RelativePath $path
        if ($null -eq $dataUri) { return $match.Value }
        return "url(""$dataUri"")"
    })

    return $result
}

function Get-SectionFragment {
    param(
        [string]$Html,
        [string]$Start,
        [bool]$IsFooter
    )

    $escaped = [regex]::Escape($Start)
    if ($IsFooter) {
        $pattern = "(?s)($escaped.*?</footer>)"
    } else {
        $pattern = "(?s)($escaped.*?</section>)"
    }

    $m = [regex]::Match($Html, $pattern)
    if (-not $m.Success) {
        throw "Could not extract section starting with: $Start"
    }
    return $m.Groups[1].Value
}

function New-StandaloneSectionHtml {
    param(
        [string]$Fragment,
        [string]$Title,
        [string]$FileName,
        [string]$ExtraJs = ''
    )

    $embedded = Embed-LocalImages -HtmlFragment $Fragment

    $comment = @"
<!--
  ClickEpico LP - Secao: $Title
  Arquivo: $FileName
  Autocontido: CSS inline, imagens em base64, JavaScript quando necessario.
  WordPress: cole no bloco HTML personalizado (pagina full-width).
  Regenerar: powershell -ExecutionPolicy Bypass -File scripts/build-section-html.ps1
-->
"@

    $jsBlock = ''
    if ($ExtraJs.Trim().Length -gt 0) {
        $jsBlock = "<script>`n$ExtraJs`n</script>"
    }

    return @"
<!DOCTYPE html>
<html lang="pt-BR">
<head>
$comment
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ClickEpico | $Title</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@600;700;800&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
    <style>
$css
    </style>
</head>
<body>
    <div id="clickepico-section">
$embedded
    </div>
$jsBlock
</body>
</html>
"@
}

Write-Host "Building section files into $outDir ..."
Write-Host ""

foreach ($sec in $sections) {
    $isFooter = $false
    if ($sec.ContainsKey('IsFooter')) { $isFooter = [bool]$sec.IsFooter }

    $fragment = Get-SectionFragment -Html $indexHtml -Start $sec.Start -IsFooter $isFooter
    $extraJs = ''
    if ($sec.File -eq 'precos.html') {
        $extraJs = $pricingJs
    }

    $doc = New-StandaloneSectionHtml -Fragment $fragment -Title $sec.Title -FileName $sec.File -ExtraJs $extraJs
    $outPath = Join-Path $outDir $sec.File
    [IO.File]::WriteAllText($outPath, $doc, $utf8NoBom)

    $sizeMB = [math]::Round((Get-Item $outPath).Length / 1MB, 2)
    Write-Host ("  {0,-22} {1,8} MB" -f $sec.File, $sizeMB)
}

Write-Host ""
Write-Host "Done. $($sections.Count) files in download/"
Write-Host "Unique images cached: $($imageCache.Count)"
