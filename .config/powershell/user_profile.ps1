# untracked local env vars
$exportsFile = "$HOME\.exports.ps1"
if (Test-Path $exportsFile) {
  . $exportsFile
}

$__gitBin = "$HOME\scoop\apps\git\current\bin"
if ((Test-Path $__gitBin) -and ($env:Path -notlike "*$__gitBin*")) {
  $env:Path = "$__gitBin;$env:Path"
}
Remove-Variable -Name '__gitBin' -ErrorAction SilentlyContinue

if (Get-Command mise -ErrorAction SilentlyContinue) {
  # persist shims for -NoProfile / cmd / batch
  $__shims = "$env:LOCALAPPDATA\mise\shims"
  if ($env:LOCALAPPDATA -and (Test-Path 'HKCU:\Environment')) {
    $__key = Get-Item 'HKCU:\Environment'
    try { $__kind = $__key.GetValueKind('Path') }
    catch { $__kind = [Microsoft.Win32.RegistryValueKind]::ExpandString }
    $__raw = $__key.GetValue('Path', '', 'DoNotExpandEnvironmentNames')
    if ($__raw -notlike "*$__shims*") {
      $__new = if ([string]::IsNullOrWhiteSpace($__raw)) { $__shims } else { "$__raw;$__shims" }
      $__key.SetValue('Path', $__new, $__kind)
    }
    Remove-Variable -Name '__key','__kind','__raw','__new' -ErrorAction SilentlyContinue
  }
  Remove-Variable -Name '__shims' -ErrorAction SilentlyContinue

  (&mise activate pwsh) | Out-String | Invoke-Expression
}

function dotfiles {
    git --git-dir=$HOME\dotfiles-windows --work-tree=$HOME @args
}

function gitdot {
    if (-not (Get-Command gitui -ErrorAction SilentlyContinue)) {
        Write-Error "gitui not found"
        return 1
    }
    $env:GIT_DIR = "$HOME/dotfiles-windows"
    $env:GIT_WORK_TREE = "$HOME"
    try {
        gitui
    } finally {
        Remove-Item Env:GIT_DIR -ErrorAction SilentlyContinue
        Remove-Item Env:GIT_WORK_TREE -ErrorAction SilentlyContinue
    }
}

Import-Module PSReadLine -ErrorAction SilentlyContinue

# --- sshd-on-windows: drop PSReadLine in SSH sessions (ConPTY input quirks) ---
if ($env:SSH_CLIENT -or $env:SSH_TTY -or $env:SSH_CONNECTION) {
    Remove-Module PSReadLine -ErrorAction SilentlyContinue
}

function rpi { pi --resume @args }
function cpi { pi --continue @args }
function nspi { pi --no-session @args }
