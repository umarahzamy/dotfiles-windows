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

# fzf global options (alt+j/k to navigate results, like bash)
if (Get-Command fzf -ErrorAction SilentlyContinue) {
  $env:FZF_DEFAULT_OPTS = "--bind=alt-j:down,alt-k:up"
}

# Dotfiles management
function dotfiles { 
    git --git-dir=$HOME\dotfiles-windows --work-tree=$HOME @args
}

# Autossh like function
function autossh {
    param(
        [Parameter(Mandatory)]
        [string]$SshServer,

        [int]$GraceRetries = 3,
        [int]$MaxDelay = 60,
        [int]$ResetAfterMin = 5
    )

    $tries = 0

    while ($true) {
        $start = Get-Date
        Write-Host ("[{0}] Connecting to {1} ..." -f $start.ToString("yyyy-MM-dd HH:mm:ss"), $SshServer) -ForegroundColor Cyan

        ssh $SshServer

        $stop = Get-Date
        $uptime = $stop - $start
        Write-Host ("[{0}] SSH to {1} ended after {2}s." -f $stop.ToString("yyyy-MM-dd HH:mm:ss"), $SshServer, [int]$uptime.TotalSeconds) -ForegroundColor Yellow

        if ($uptime.TotalMinutes -ge $ResetAfterMin) {
            $tries = 0
            Write-Host ("Connection was stable ({0}m). Resetting counter." -f [int]$uptime.TotalMinutes) -ForegroundColor Green
        }

        Write-Host "Press q to quit, or wait to reconnect..." -ForegroundColor Cyan

        if ($tries -lt $GraceRetries) {
            $delay = 1
        } else {
            $delay = [math]::Pow(2, $tries - $GraceRetries)
            if ($delay -gt $MaxDelay) { $delay = $MaxDelay }
        }

        $left = $delay
        while ($left -gt 0) {
            if ($Host.UI.RawUI.KeyAvailable) {
                $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                if ($key.Character -eq 'q' -or $key.Character -eq 'Q') {
                    Write-Host "Exiting autossh..." -ForegroundColor Red
                    return
                }
            }
            if ($delay -gt 1) {
                Write-Host ("Reconnecting in {0}s..." -f $left) -ForegroundColor DarkGray
            }
            Start-Sleep -Seconds 1
            $left--
        }

        $tries++
    }
}

# PSReadLine + fzf key bindings
Import-Module PSReadLine -ErrorAction SilentlyContinue

# fzf integration (Ctrl+R, Ctrl+T, Alt+C)
$__fzfBindings = Join-Path $PSScriptRoot "key-bindings.ps1"
if (Test-Path $__fzfBindings) {
  . $__fzfBindings
}
Remove-Variable -Name '__fzfBindings' -ErrorAction SilentlyContinue

# pi -- smart session launcher for the pi coding agent
function pi {
  # Cache the real pi path (Get-Command runs once per session)
  if (-not $script:piPath) {
    $__cmd = @(Get-Command pi -CommandType Application -ErrorAction SilentlyContinue)
    if (-not $__cmd) { Write-Error "pi: command not found"; return }
    $script:piPath = $__cmd[0].Source
  }

  # Fast pass-through for simple queries (skip session scan)
  foreach ($arg in $args) {
    if ($arg -match '^--(help|version)$' -or $arg -eq '-h') {
      & $script:piPath @args
      return
    }
  }

  # Encode $PWD into the same hash pi uses for its session folder
  $dir = $PWD.Path -replace '\\', '/'
  $dir = $dir.TrimStart('/')
  $encoded = "--$($dir -replace '/', '-')--"
  $base = if ($env:PI_CODING_AGENT_SESSION_DIR) { $env:PI_CODING_AGENT_SESSION_DIR } else { "$HOME\.pi\agent\sessions" }
  $sessionDir = Join-Path $base $encoded

  $sessions = @()
  if (Test-Path $sessionDir) {
    $sessions = @(Get-ChildItem "$sessionDir\*.jsonl" -ErrorAction SilentlyContinue)
  }

  $n = $sessions.Count
  switch ($n) {
    0 { & $script:piPath @args }
    1 { & $script:piPath --continue @args }
    default { & $script:piPath --resume @args }
  }
}

