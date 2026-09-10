--- Clipboard image detection and saving.
--- Explicit support: Fedora GNOME (Wayland, wl-paste) and Windows 10/11 (pwsh 7).
--- No xclip/xsel/pngpaste/powershell 5.1.
---
--- WARNING: vibecoded. Wayland path tested; pwsh path untested from this machine.

local M = {}

local is_wayland = vim.fn.has("linux") == 1 and os.getenv("WAYLAND_DISPLAY") ~= nil
local is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1

local have_cache = {}

local function have(name)
  if have_cache[name] ~= nil then
    return have_cache[name]
  end
  local ok = vim.fn.executable(name) == 1
  have_cache[name] = ok
  return ok
end

M.cmd = nil

function M.get_clip_cmd()
  if M.cmd then
    return M.cmd
  end
  if is_wayland and have("wl-paste") then
    M.cmd = "wl-paste"
  elseif is_windows and have("pwsh") then
    M.cmd = "pwsh"
  end
  return M.cmd
end

function M.missing_hint()
  if M.cmd == "wl-paste" then
    return "install wl-clipboard (Fedora: sudo dnf install wl-clipboard)"
  elseif M.cmd == "pwsh" then
    return "install PowerShell 7 (winget install Microsoft.PowerShell)"
  end
  return "unsupported: expected Wayland wl-paste or Windows pwsh 7"
end

--- Check if clipboard holds an image.
function M.has_image()
  local cmd = M.get_clip_cmd()
  if not cmd then
    return false, "no clipboard tool"
  end
  if cmd == "wl-paste" then
    local out = vim.fn.system({ "wl-paste", "--list-types" })
    if vim.v.shell_error ~= 0 then
      return false, "no_image"
    end
    return out:find("image/") ~= nil, "no_image"
  elseif cmd == "pwsh" then
    -- pwsh 7 defaults to MTA: Windows Forms clipboard needs -STA
    local out = vim.fn.system({
      "pwsh",
      "-NoProfile",
      "-STA",
      "-Command",
      [[Add-Type -AssemblyName System.Windows.Forms; if ([System.Windows.Forms.Clipboard]::ContainsImage()) { Write-Output "image" }]],
    })
    return out:match("image") ~= nil, "no_image"
  end
  return false, "no clipboard tool"
end

--- Save clipboard image to file. Uses shell redirect for binary safety.
function M.save_image(abs_path)
  local cmd = M.get_clip_cmd()
  if not cmd then
    return false, "no clipboard tool"
  end
  if cmd == "wl-paste" then
    local c = string.format('wl-paste --type image/png > "%s" 2>/dev/null', abs_path)
    vim.fn.system(c)
    if vim.v.shell_error ~= 0 or vim.fn.getfsize(abs_path) <= 0 then
      c = string.format('wl-paste --type image/jpeg > "%s" 2>/dev/null', abs_path)
      vim.fn.system(c)
    end
    if vim.v.shell_error ~= 0 or vim.fn.getfsize(abs_path) <= 0 then
      return false, "wl-paste failed"
    end
    return true
  elseif cmd == "pwsh" then
    local ps_path = abs_path:gsub("/", "\\"):gsub('"', '`"')
    local script = string.format(
      [[
      Add-Type -AssemblyName System.Windows.Forms
      Add-Type -AssemblyName System.Drawing
      $img = [System.Windows.Forms.Clipboard]::GetImage()
      if ($img) { $img.Save("%s", [System.Drawing.Imaging.ImageFormat]::Png) }
    ]],
      ps_path
    )
    vim.fn.system({ "pwsh", "-NoProfile", "-STA", "-Command", script })
    if vim.v.shell_error ~= 0 or vim.fn.getfsize(abs_path) <= 0 then
      return false, "pwsh save failed"
    end
    return true
  end
  return false, "no clipboard tool"
end

return M
