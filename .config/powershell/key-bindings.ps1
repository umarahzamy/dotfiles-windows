# fzf key bindings for PowerShell
# Compact, single file — like fzf's shell/key-bindings.bash
# Source from user_profile.ps1:  . $HOME\.config\powershell\key-bindings.ps1

if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
  Write-Warning "fzf: not found — install with: scoop install fzf" 
  return
}

# Ctrl+R — fuzzy history search
Set-PSReadLineKeyHandler -Key 'Ctrl+r' -BriefDescription 'FzfHistory' `
    -Description 'Fuzzy history search with fzf' `
    -ScriptBlock {
    param($key, $arg)
    $historyFile = (Get-PSReadLineOption).HistorySavePath
    if (-not (Test-Path $historyFile)) { return }

    $line = $null; $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    $selected = Get-Content $historyFile |
        Where-Object { $_ -match '\S' } |
        Select-Object -Unique |
        fzf --height 40% --min-height 20 --reverse `
            --scheme=history --bind=ctrl-r:toggle-sort `
            --bind=alt-j:down,alt-k:up `
            --highlight-line --query="$line" 2>$null

    if ($selected) {
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($selected)
    }
}

# Ctrl+T — fuzzy file path insert
Set-PSReadLineKeyHandler -Key 'Ctrl+t' -BriefDescription 'FzfFile' `
    -Description 'Search files with fzf and insert path' `
    -ScriptBlock {
    param($key, $arg)
    $cmd = if (Get-Command fd -ErrorAction SilentlyContinue) {
        'fd --type f --hidden --follow --exclude .git 2>$null'
    } else {
        'Get-ChildItem -Recurse -File -ErrorAction SilentlyContinue | % FullName'
    }
    $selected = Invoke-Expression $cmd | fzf --height 40% --min-height 20 --reverse --scheme=path 2>$null
    if ($selected) {
        if ($selected -match '\s') { $selected = "'$selected'" }
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($selected)
    }
}

# Alt+C — fuzzy cd into directory
Set-PSReadLineKeyHandler -Key 'Alt+c' -BriefDescription 'FzfCd' `
    -Description 'Search directories with fzf and cd' `
    -ScriptBlock {
    param($key, $arg)
    $cmd = if (Get-Command fd -ErrorAction SilentlyContinue) {
        'fd --type d --hidden --follow --exclude .git 2>$null'
    } else {
        'Get-ChildItem -Recurse -Directory -ErrorAction SilentlyContinue | % FullName'
    }
    $selected = Invoke-Expression $cmd | fzf --height 40% --min-height 20 --reverse --scheme=path 2>$null
    if ($selected) {
        Set-Location $selected
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    }
}
