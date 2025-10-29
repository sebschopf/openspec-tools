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

Exemples et conseils
--------------------

- Utiliser `-GeminiCmdTemplate` si ta CLI Gemini a des flags spécifiques :

```powershell
# Exemple : la CLI attend le prompt positionnel et accepte -m pour le model
pwsh -File .\scripts\generate-openspec.ps1 -Title "ma-change" -GeminiCmdTemplate "gemini {promptfile} -m code-assist -o text > {outfile}" -Verbose
```

- Si tu préfères générer la sortie manuellement (debug) :

```powershell
# 1) Génére la sortie LLM dans un fichier (adapte selon ta CLI)
gemini -m code-assist -p "@C:\chemin\vers\tmpfile" -o text > C:\projet\openspec\changes\ma-change\stdout.txt

# 2) Demande au script d'utiliser ce stdout
pwsh -File .\scripts\generate-openspec.ps1 -Title "ma-change" -StdoutFile "C:\projet\openspec\changes\ma-change\stdout.txt" -Verbose
```

- Débogage rapide :
	- Exécute le script avec `-Verbose` pour voir les messages d'information.
	- Si la validation CI échoue, le workflow poste une copie tronquée de la sortie dans un commentaire de PR et sauvegarde l'artifact `validation-output.txt` (téléchargeable depuis l'onglet Actions).

