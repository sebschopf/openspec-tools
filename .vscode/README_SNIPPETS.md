Utilisation des snippets et tâches OpenSpec

1) Snippet
- Ouvrez un fichier Markdown ou un nouvel onglet, tapez `metaspec` puis pressez `Tab` pour insérer le prompt standardisé.

2) Tâches VS Code
- Ouvrez la palette (Ctrl+Shift+P) -> Tasks: Run Task
- Choisissez "OpenSpec: Init" pour lancer `openspec init` (via npm script).
- Choisissez "OpenSpec: Validate" pour exécuter le validateur local `validate:openspec`.

3) Validation CI
- Le script `scripts/validate-openspec.js` vérifie que `openspec/changes/*` contient des fichiers typiques (purpose/proposal, task/tasks, spec).
- Ajoutez `npm run validate:openspec` dans votre pipeline CI ou GitHub Action pour rejeter les PRs qui ne respectent pas la structure.

4) Personnalisation
- Adaptez le snippet dans `.vscode/snippets/openspec.code-snippets` pour changer les noms de fichiers ou les marqueurs si votre workflow diffère.
