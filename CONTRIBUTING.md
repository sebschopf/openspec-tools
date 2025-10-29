# CONTRIBUTING — OpenSpec Tools

Ce fichier explique comment utiliser les outils OpenSpec fournis dans ce dépôt, comment générer les fichiers OpenSpec, lancer la validation localement, et corriger les erreurs signalées par la CI.

## Table des matières

- Usage rapide
- Générateur (PowerShell)
- Validation locale
- Workflow CI / Branch protection
- Résolution des erreurs courantes

## Usage rapide

- Pour générer un nouvel OpenSpec dans un projet qui a les scripts :

```powershell
pwsh ./scripts/generate-openspec.ps1 -Title "mon-changement" -PromptFile ./my-prompt.txt
```

- Pour valider localement (pratique avant commit) :

```powershell
npm run validate:openspec
```

Le validateur vérifie la présence et la non-nullité des fichiers `purpose.md`, `task.md`, `spec.md` dans `openspec/changes/*`.

## Générateur

Le script PowerShell `scripts/generate-openspec.ps1` prend plusieurs options :

- `-Title` : nom du change-set (dossier créé dans `openspec/changes/`).
- `-PromptFile` : chemin vers un fichier prompt (optionnel). Si absent, un prompt par défaut est utilisé.
- `-StdoutFile` : chemin vers un fichier contenant déjà la sortie du modèle (utile pour débogage ou offline).
- `-GeminiCmdTemplate` : template de commande pour appeler la CLI Gemini si votre installation utilise une syntaxe custom. Exemple :

```powershell
- Gemin iCmdTemplate "gemini -m code-assist -p '@{promptfile}' -o text > {outfile}"
```

Après exécution, le script écrit `purpose.md`, `task.md`, `spec.md` (si trouvés) et lance la validation locale.

## Validation locale

- Installez les dépendances et préparez Husky :

```powershell
npm install
npm run prepare
```

- Lancer la validation :

```powershell
npm run validate:openspec
```

Le script retourne un code non‑zéro en cas d'erreur et affiche des messages expliquant ce qui manque.

## Workflow CI / Branch protection

Le dépôt contient une GitHub Action `.github/workflows/validate-openspec.yml` qui s'exécute sur les PRs et en `workflow_dispatch`.

- Si la validation échoue :
  - Un artefact `validation-output.txt` est attaché au run.
  - Un commentaire est posté sur la PR avec le résumé de la validation.
  - Un CheckRun nommé **"OpenSpec Validator Report"** est créé avec le contenu résumé (améliore l'UX dans l'onglet Checks).

La branche `main` est protégée et exige que le check `Validate OpenSpec files` passe avant de pouvoir merger.

## Résolution des erreurs courantes

- "Le dossier `openspec/` est introuvable" :
  - Assurez-vous d'avoir ajouté un dossier `openspec/changes/<title>/` contenant au moins `purpose.md` et `task.md`.
  - Utilisez `pwsh ./scripts/generate-openspec.ps1 -Title "..."` pour générer la structure.

- "Bloc BEGIN/END non reconnu" :
  - Vérifiez que le prompt/template de sortie du modèle respecte le format :

```
--- BEGIN: purpose.md ---
...
--- END: purpose.md ---
```

- Si vous utilisez la CLI `gemini`, vérifiez `-StdoutFile` ou `-GeminiCmdTemplate` si votre version de la CLI a des flags différents.

## Bonnes pratiques

- Générez et validez localement avant de pousser.
- Lors d'un échec CI, téléchargez `validation-output.txt` pour plus de détails.
- Si l'annotation dans la CheckRun n'est pas suffisante, lisez le commentaire et l'artefact attaché pour l'intégralité du log.

---

Merci de respecter le workflow OpenSpec — cela nous aide à garder des PRs claires et traçables.
