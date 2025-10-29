# BOM: UTF-8 with BOM (required by PSScriptAnalyzer rule PSUseBOMForUnicodeEncodedFile)
Param(
  [string]$Title = "new-change",
  [string]$PromptFile = "",
  [string]$TargetRoot = ".\openspec\changes",
  [string]$StdoutFile = "",
  [string]$GeminiCmdTemplate = ""
)

function Write-Info([string]$m){ Write-Verbose "[info] $m" }
function Write-Err([string]$m){ Write-Error "[err] $m" }

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
  Write-Info "Appel de la CLI 'gemini'..."
  $stdoutPath = Join-Path $dest 'stdout.txt'

  # Try multiple invocation styles to handle different gemini CLI versions.
  $promptText = Get-Content -Raw -Path $tmp -ErrorAction Stop

  $succeeded = $false

  # If the caller provided an exact gemini command template, use it.
  if($GeminiCmdTemplate){
    try{
      $cmd = $GeminiCmdTemplate -replace '\{promptfile\}',$tmp -replace '\{outfile\}',$stdoutPath
      Write-Info "Exécution du template gemini fourni..."
      Invoke-Expression $cmd
      if((Test-Path $stdoutPath) -and ((Get-Item $stdoutPath).Length -gt 0)){ $succeeded = $true }
    } catch {
      Write-Err "Échec de l'exécution du template gemini: $_"
    }
  }

  # Strategy 1: modern 'chat' subcommand with input-file (may not exist on all CLIs)
  try{
    & gemini chat --model code-assist --temperature 0 --input-file $tmp 2>$null | Out-File -FilePath $stdoutPath -Encoding UTF8
    if((Test-Path $stdoutPath) -and ((Get-Item $stdoutPath).Length -gt 0)){ $succeeded = $true }
  } catch { }

  # Strategy 2: fallback to passing the prompt as an argument and capturing stdout
  if(-not $succeeded){
    try{
      $args = @('-m','code-assist','-p', $promptText, '-o','text')
      # Use Start-Process to reliably capture stdout to file
      Start-Process -FilePath (Get-Command gemini).Source -ArgumentList $args -NoNewWindow -Wait -RedirectStandardOutput $stdoutPath -RedirectStandardError ([System.IO.Path]::Combine($dest,'gemini.err'))
      if((Test-Path $stdoutPath) -and ((Get-Item $stdoutPath).Length -gt 0)){ $succeeded = $true }
    } catch {
      # ignore and surface below
    }
  }

  # Strategy 3: try positional prompt first then flags (some gemini CLIs expect the prompt as the first positional arg)
  if(-not $succeeded){
    try{
      $args2 = @($promptText, '-m','code-assist','-o','text')
      Start-Process -FilePath (Get-Command gemini).Source -ArgumentList $args2 -NoNewWindow -Wait -RedirectStandardOutput $stdoutPath -RedirectStandardError ([System.IO.Path]::Combine($dest,'gemini.err2'))
      if((Test-Path $stdoutPath) -and ((Get-Item $stdoutPath).Length -gt 0)){ $succeeded = $true }
    } catch {
      # ignore
    }
  }

  if(-not $succeeded){
    Write-Err "Impossible d'appeler la CLI 'gemini' avec les options connues. Vérifie la version de la CLI ou fournis -StdoutFile <file> contenant la sortie du modèle."
    Write-Err "Si tu utilises une version récente de la CLI, essaie d'exécuter: gemini -m code-assist -p '@$tmp' -o text > $stdoutPath"
    exit 2
  } else {
    Write-Info "Sortie gemini écrite dans $stdoutPath"
  }

} else {
  Write-Info "Utilisation du fichier stdout existant : $stdoutPath"
}

Write-Info "Sortie sauvegardée dans $dest\stdout.txt. Tentative d'extraction automatique des sections..."

# Lecture du contenu
$stdout = Get-Content -Raw -Path $stdoutPath -ErrorAction Stop

function Save-Section([string]$text, [string]$begin, [string]$end, [string]$outfile){
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
  }
  return $false
}

$foundAny = $false
if(Save-Section -text $stdout -begin '--- BEGIN: purpose.md ---' -end '--- END: purpose.md ---' -outfile (Join-Path $dest 'purpose.md')){ $foundAny = $true }
if(Save-Section -text $stdout -begin '--- BEGIN: task.md ---' -end '--- END: task.md ---' -outfile (Join-Path $dest 'task.md')){ $foundAny = $true }
if(Save-Section -text $stdout -begin '--- BEGIN: spec.md ---' -end '--- END: spec.md ---' -outfile (Join-Path $dest 'spec.md')){ $foundAny = $true }

# metadata JSON optional
$metaPattern = '---metadata---\s*(\{.*?\})\s*$'
$mmeta = [Regex]::Match($stdout, $metaPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
if($mmeta.Success){
  $metaJson = $mmeta.Groups[1].Value.Trim()
  try{
    # validate JSON structure
    ConvertFrom-Json $metaJson -ErrorAction Stop | Out-Null
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
