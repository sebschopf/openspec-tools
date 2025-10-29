# Onboarding — OpenSpec workflow (FR)

Ce document décrit, étape par étape, comment contribuer au dépôt `openspec-tools` en respectant le workflow OpenSpec : génération, validation locale, PR, et résolution des erreurs CI.

## 1) Objectif

Rendre simple et reproductible la création de change-sets OpenSpec et l'assurance que toute PR contient des OpenSpec valides.

## 2) Générer un OpenSpec localement

1. Dans votre projet cible, si vous avez le script d'initialisation, copiez les outils :

```powershell
pwsh ./scripts/bootstrap-openspec.ps1 -TargetRoot .
```

2. Générer un nouveau change-set avec le générateur PowerShell :

```powershell
pwsh ./scripts/generate-openspec.ps1 -Title "mon-change" -PromptFile ./prompts/mon-prompt.txt
```

Options utiles :
- `-StdoutFile <file>` : si vous avez déjà la sortie du modèle (debug / offline)
- `-GeminiCmdTemplate "...{promptfile}...{outfile}..."` : si votre CLI Gemini a une syntaxe particulière

Le script crée `openspec/changes/mon-change/` et tente d'extraire `purpose.md`, `task.md`, `spec.md`. Il lance ensuite la validation locale.

## 3) Validation locale

1. Installer les dépendances et préparer Husky (une seule fois) :

```powershell
npm install
npm run prepare
```

2. Lancer la validation locale :

```powershell
npm run validate:openspec
```

Le validateur vérifie la structure minimale : présence et contenu non vide de `purpose.md` et `task.md` dans chaque change-set. Il renvoie un code de sortie non‑zéro en cas d'erreur et imprime un log lisible.

## 4) Workflow PR (GitHub Actions)

1. Créez une branche depuis `main` et appliquez vos modifications + `openspec/changes/<title>/`.
2. Poussez la branche et ouvrez une Pull Request vers `main`.

Le workflow `.github/workflows/validate-openspec.yml` se déclenche automatiquement sur PR et :
- Exécute la validation (`npm run validate:openspec`).
- Attache un artefact `validation-output.txt` au run.
- Post un commentaire sur la PR (si l'événement est `pull_request`) avec le résumé.
- Crée un CheckRun **OpenSpec Validator Report** contenant le résumé (améliore l'UX dans l'onglet Checks).

Si la validation échoue, la branche ne pourra pas être mergée car `main` exige le status check `Validate OpenSpec files`.

## 5) Corriger les erreurs CI

1. Téléchargez `validation-output.txt` depuis l'interface Actions pour voir le log complet.
2. Reproduisez localement : `npm run validate:openspec`.
3. Corrigez les fichiers manquants ou vides (ex: ajoutez `purpose.md` et `task.md` correctement formattés), commit et poussez une nouvelle révision. Le workflow relancera automatiquement.

Exemples d'erreurs courantes :
- "Le dossier `openspec/` est introuvable" : créez un change-set avec le script `generate-openspec.ps1`.
- "Aucune section BEGIN/END reconnue" : vérifiez que la sortie du modèle respecte les marqueurs `--- BEGIN: <file> ---` / `--- END: <file> ---`.

## 6) Bonnes pratiques pour rédiger les OpenSpec

- Restez concis dans `purpose.md` (quel problème on résout, pourquoi maintenant).
- `task.md` doit contenir les tâches atomiques et critères d'acceptation.
- `spec.md` est optionnel mais utile pour détails d'implémentation.
- Validez localement avant de pousser pour réduire les aller-retours CI.

## 7) Pour les mainteneurs (activer / vérifier la protection de branche)

- Exécutez une fois le workflow (Actions → Validate OpenSpec → Run workflow) pour que GitHub ajoute le context check.
- Activez la protection de `main` en exigeant le status check `Validate OpenSpec files` (Settings → Branches → Add rule → pattern `main`).

## 8) Ressources et contact

- Fichiers utiles : `scripts/generate-openspec.ps1`, `scripts/validate-openspec.js`, `.github/workflows/validate-openspec.yml`.
- Pour toute question : ouvrez une issue ou mentionnez `@sebschopf` dans la PR.

---

Merci d'aider à rendre OpenSpec la pratique par défaut. Respecter ce workflow améliore la clarté des PR et facilite les revues.
