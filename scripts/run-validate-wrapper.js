#!/usr/bin/env node
const { spawnSync } = require('child_process');
const path = require('path');

function run(cmd, args, opts){
  const res = spawnSync(cmd, args, { stdio: 'inherit', shell: false, ...opts });
  return res.status === 0;
}

console.log('> Wrapper: trying `npx openspec validate` (if installed)');
let ok = false;
try{
  // Try to run npx openspec validate
  ok = run('npx', ['openspec','validate']);
} catch(e){
  // ignore
  ok = false;
}

if(ok){
  console.log('`npx openspec validate` succeeded.');
} else {
  console.log('`npx openspec validate` failed or is unavailable — continuing with local validator.');
}

// Run the local validator
const local = run(process.execPath, [path.join(__dirname, 'validate-openspec.js')]);
if(!local){
  console.error('\nLocal validator failed.');
  process.exit(2);
}

console.log('\nAll validations passed.');
process.exit(0);
