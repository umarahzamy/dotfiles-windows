# Source local env vars (outside git tree — survives dotfiles checkout)
$exportsFile = "$HOME\.exports.ps1"
if (Test-Path $exportsFile) {
  . $exportsFile
}

# Add Git for Windows bin to PATH (provides bash.exe, etc.)
$__gitBin = "$HOME\scoop\apps\git\current\bin"
if ((Test-Path $__gitBin) -and ($env:Path -notlike "*$__gitBin*")) {
  $env:Path = "$__gitBin;$env:Path"
}
Remove-Variable -Name '__gitBin' -ErrorAction SilentlyContinue

}

# Dotfiles management
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

# pi aliases (pi handles session detection natively)
function rpi { pi --resume @args }
function cpi { pi --continue @args }
function nspi { pi --no-session @args }


