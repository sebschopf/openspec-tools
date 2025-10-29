#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const openspecDir = path.join(root, 'openspec');
let failed = false;

function err(msg){
  console.error('✖', msg);
  failed = true;
}

function ok(msg){
  console.log('✔', msg);
}

if(!fs.existsSync(openspecDir)){
  err('Le dossier `openspec/` est introuvable. Exécutez `openspec init` ou créez-le.');
}

const requiredRootFiles = ['project.md', 'AGENTS.md', 'agents.md'];
for(const name of requiredRootFiles){
  const p = path.join(openspecDir, name);
  if(fs.existsSync(p)){
    ok(`Présent: openspec/${name}`);
    break;
  }
}

const changesDir = path.join(openspecDir, 'changes');
// If OPEN_SPEC_ONLY is set (comma-separated list of change-set names), only validate those
const onlyEnv = process.env.OPEN_SPEC_ONLY || '';
const onlyList = onlyEnv.split(',').map(s=>s.trim()).filter(Boolean);
if(!fs.existsSync(changesDir)){
  err('Le dossier `openspec/changes/` est introuvable ou vide.');
} else {
  let subs = fs.readdirSync(changesDir, {withFileTypes:true}).filter(d=>d.isDirectory()).map(d=>d.name);
  if(onlyList.length>0){
    subs = subs.filter(s=> onlyList.includes(s));
    if(subs.length===0){
      err('Aucun change-set trouvé correspondant à OPEN_SPEC_ONLY: ' + onlyList.join(','));
    }
  }
  if(subs.length===0){
    err('Aucun sous-dossier trouvé dans `openspec/changes/`.');
  } else {
    for(const sub of subs){
      const dpath = path.join(changesDir, sub);
      const files = fs.readdirSync(dpath);
      // check for purpose/proposal
      const hasPurpose = files.includes('purpose.md') || files.includes('proposal.md');
      const hasTasks = files.includes('task.md') || files.includes('tasks.md');
      const hasSpec = files.includes('spec.md');
      if(!hasPurpose) err(`Dans changes/${sub}: manque 'purpose.md' ou 'proposal.md'`);
      else ok(`Dans changes/${sub}: trouvé purpose/proposal`);
      if(!hasTasks) err(`Dans changes/${sub}: manque 'task.md' ou 'tasks.md'`);
      else ok(`Dans changes/${sub}: trouvé task/tasks`);
      if(!hasSpec) {
        // spec may be optional depending on your workflow, warn instead of error
        console.warn('⚠', `Dans changes/${sub}: pas de 'spec.md' détecté (optionnel selon workflow)`);
      } else ok(`Dans changes/${sub}: trouvé spec.md`);

      // ensure required files are non-empty
      const checkNonEmpty = ['purpose.md','proposal.md','task.md','tasks.md','spec.md'].filter(f=>files.includes(f));
      for(const f of checkNonEmpty){
        const content = fs.readFileSync(path.join(dpath,f),'utf8').trim();
        if(content.length===0) err(`Le fichier ${sub}/${f} est vide.`);
      }
    }
  }
}

if(failed){
  console.error('\nValidation OpenSpec: ÉCHEC. Corrigez les erreurs ci-dessus.');
  process.exit(2);
} else {
  console.log('\nValidation OpenSpec: OK ✅');
  process.exit(0);
}
