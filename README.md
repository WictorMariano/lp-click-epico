# ClickEpico — Landing Page

Landing page para o ClickEpico (gestão para salões e barbearias).

## Estrutura

- `index.html` — página principal
- `styles.css` — estilos
- `main.js` — menu mobile e toggle de preços
- `assets/` — imagens adicionais
- `imagens */` — imagens por seção
- `download/` — HTML autocontido (página completa e por seção)
- `scripts/` — scripts de build dos arquivos em `download/`

## Preview local

Abra `index.html` no navegador ou use um servidor estático na pasta do projeto.

## Gerar arquivos para download / WordPress

```powershell
# Página completa em um arquivo
powershell -ExecutionPolicy Bypass -File scripts/build-single-html.ps1

# Um arquivo por seção
powershell -ExecutionPolicy Bypass -File scripts/build-section-html.ps1
```
