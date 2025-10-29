Param(
  [string]$Title = "new-change",
  [string]$PromptFile = "",
  [string]$TargetRoot = ".\openspec\changes",
  [string]$StdoutFile = ""
)

function Write-Info($m){ Write-Host "[info] $m" -ForegroundColor Cyan }
function Write-Err($m){ Write-Host "[err] $m" -ForegroundColor Red }

$workDir = Join-Path (Get-Location) $TargetRoot
if(-not (Test-Path $workDir)) { New-Item -ItemType Directory -Path $workDir -Force | Out-Null }
$dest = Join-Path $workDir $Title
if(-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }

if($StdoutFile -and (Test-Path $StdoutFile)){
  Write-Info "Fichier stdout fourni : $StdoutFile — on sautera l'appel à gemini et on parsers ce fichier."
  $stdoutPath = (Resolve-Path $StdoutFile).Path
} else {
  if(-not (Get-Command gemini -ErrorAction SilentlyContinue)){
    Write-Err "La CLI 'gemini' n'est pas trouvée sur le PATH. Installez-la ou fournissez le paramètre -StdoutFile <file> contenant la sortie du modèle."
    exit 2
  }
}

# prepare prompt
if($PromptFile -and (Test-Path $PromptFile)){
  $prompt = Get-Content -Raw -Path $PromptFile
} else {
  $prompt = @"
---
Role: Tu es un assistant expert en ingénierie logicielle...
Task: Génère purpose.md, task.md, spec.md encadrés par des délimiteurs BEGIN/END.
---
## Input
${Title}
"@
}

# write temp prompt
$tmp = [System.IO.Path]::GetTempFileName()
Set-Content -Path $tmp -Value $prompt -Encoding UTF8

if(-not $stdoutPath){
  Write-Info "Appel de gemini CLI..."
  $stdoutPath = Join-Path $dest 'stdout.txt'
  $geminiArgs = @('chat','--model','code-assist','--temperature','0','--input-file',$tmp)
  try {
    & gemini @geminiArgs | Out-File -FilePath $stdoutPath -Encoding UTF8
  } catch {
    Write-Err "Erreur lors de l'appel à la CLI 'gemini': $_"
    exit 2
  }
} else {
  Write-Info "Utilisation du fichier stdout existant : $stdoutPath"
}

Write-Info "Sortie sauvegardée dans $dest\stdout.txt. Tentative d'extraction automatique des sections..."

# Lecture du contenu
$stdout = Get-Content -Raw -Path $stdoutPath -ErrorAction Stop

function Extract-And-Save([string]$text, [string]$begin, [string]$end, [string]$outfile){
  $pattern = [Regex]::Escape($begin) + '(.*?)' + [Regex]::Escape($end)
  $m = [Regex]::Match($text, $pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
  if($m.Success){
    $content = $m.Groups[1].Value.Trim()
    if($content.Length -gt 0){
      Set-Content -Path $outfile -Value $content -Encoding UTF8
      Write-Info "Extrait et sauvegardé: $outfile"
      return $true
    } else {
      Write-Err "Bloc trouvé mais vide: $outfile"
      return $false
    }
  } else {
    return $false
  }
}

$foundAny = $false
if(Extract-And-Save $stdout '--- BEGIN: purpose.md ---' '--- END: purpose.md ---' (Join-Path $dest 'purpose.md')){ $foundAny = $true }
if(Extract-And-Save $stdout '--- BEGIN: task.md ---' '--- END: task.md ---' (Join-Path $dest 'task.md')){ $foundAny = $true }
if(Extract-And-Save $stdout '--- BEGIN: spec.md ---' '--- END: spec.md ---' (Join-Path $dest 'spec.md')){ $foundAny = $true }

# metadata JSON optional
$metaPattern = '---metadata---\s*(\{.*?\})\s*$'
$mmeta = [Regex]::Match($stdout, $metaPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
if($mmeta.Success){
  $metaJson = $mmeta.Groups[1].Value.Trim()
  try{
    $parsed = $metaJson | ConvertFrom-Json -ErrorAction Stop
    Set-Content -Path (Join-Path $dest 'metadata.json') -Value $metaJson -Encoding UTF8
    Write-Info "metadata.json extrait"
  } catch {
    Write-Err "Bloc metadata JSON présent mais non valide: $_"
  }
}

if(-not $foundAny){
  Write-Err "Aucune section BEGIN/END reconnue dans la sortie. Vérifie le format du prompt et les marqueurs (--- BEGIN: ... ---)."
  Write-Info "La sortie est disponible dans: $stdoutPath"
  exit 3
} else {
  Write-Info "Extraction terminée. Lancement de la validation locale (npm run validate:openspec)"
  try{
    & npm run validate:openspec
  } catch {
    Write-Err "Erreur lors de l'exécution de la validation: $_"
    exit 4
  }
}
