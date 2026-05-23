# Publica o projeto no GitHub (rode apos: gh auth login)
$ErrorActionPreference = 'Stop'

$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

$repoName = "lp-click-epico"

gh auth status | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Voce precisa entrar no GitHub primeiro:"
    Write-Host "  gh auth login"
    Write-Host ""
    Write-Host "Siga o codigo no navegador em https://github.com/login/device"
    exit 1
}

git branch -M main 2>$null

$remotes = git remote 2>$null
if ($remotes -notcontains "origin") {
    Write-Host "Criando repositorio $repoName no GitHub..."
    gh repo create $repoName --public --source=. --remote=origin --description "Landing page ClickEpico - gestao para saloes e barbearias"
} else {
    Write-Host "Remote origin ja existe."
}

Write-Host "Enviando para GitHub..."
git push -u origin main

$url = gh repo view --json url -q .url
Write-Host ""
Write-Host "Pronto! Repositorio: $url"
