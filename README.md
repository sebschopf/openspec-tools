# OpenSpec tools

Ce dépôt contient des utilitaires pour faciliter la génération et la validation d'OpenSpec (snippets VS Code, tâches, scripts de validation et génération via CLI LLM).

[![Validate OpenSpec](https://github.com/sebschopf/openspec-tools/actions/workflows/validate-openspec.yml/badge.svg)](https://github.com/sebschopf/openspec-tools/actions/workflows/validate-openspec.yml)

Validation CI: cette action exécute la validation OpenSpec (via `npm run validate:openspec`) sur chaque pull request.

Fichiers inclus:
- `.vscode/snippets/openspec.code-snippets` — snippet VS Code pour générer un prompt OpenSpec standardisé
- `.vscode/tasks.json` — tâches VS Code pour init/validate
- `scripts/validate-openspec.js` — validateur local
- `scripts/run-validate-wrapper.js` — wrapper qui tente la validation officielle puis la locale
- `scripts/generate-openspec.ps1` — helper PowerShell pour appeler la CLI LLM ou parser un stdout
- `scripts/bootstrap-openspec.ps1` — copie ces fichiers dans un projet cible

Usage rapide:

1. Copier les fichiers dans un projet:

```powershell
pwsh -File "./scripts/bootstrap-openspec.ps1" -TargetDir "C:\chemin\vers\mon-projet"
```

2. Générer une OpenSpec (si `gemini` est installé):

```powershell
pwsh -File .\scripts\generate-openspec.ps1 -Title "ma-change"
```

3. Valider la structure:

```powershell
npm run validate:openspec
```
