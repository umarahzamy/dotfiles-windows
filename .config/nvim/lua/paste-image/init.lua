--- paste-image.nvim
--- Minimal local-only image paste. Intercepts p/P and vim.paste,
--- saves clipboard images and dropped files to assets/,
--- inserts markup. No URLs, no remote downloads, no link modes.

local config = require("paste-image.config")
local clipboard = require("paste-image.clipboard")

local M = {}
local _setup_done = false

-- ── Setup ──────────────────────────────────────────────────────────

---@param opts? paste_image.ConfigOpts
function M.setup(opts)
  if _setup_done then
    return
  end
  _setup_done = true

  config.setup(opts)

  -- Layer 1: vim.paste — terminal/GUI paste & drag-drop
  M._override_vim_paste()

  -- Layer 2: normal p/P — vim.paste doesn't reach here
  M._install_p_intercept()
end

-- ── Layer 1: vim.paste override ───────────────────────────────────

local paste_buffer = ""

local function streaming_paste(lines, phase)
  if phase == 1 then
    paste_buffer = ""
  end
  for i, line in ipairs(lines) do
    paste_buffer = paste_buffer .. line
    if i < #lines then
      paste_buffer = paste_buffer .. "\n"
    end
  end
  if phase == 3 then
    vim.paste(vim.split(paste_buffer, "\n"), -1)
  end
end

function M._override_vim_paste()
  local original = vim.paste

  -- intentional override of the runtime's vim.paste (image paste interception)
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.paste = function(lines, phase)
    if phase ~= -1 then
      return streaming_paste(lines, phase)
    end

    -- Step 1: clipboard image (screenshot via terminal/GUI paste)
    if clipboard.has_image() then
      M._paste_image()
      return
    end

    -- Step 2: drag-drop — single short path to image file
    if #lines <= 2 and #lines > 0 then
      local line = lines[1]
      if line and #line <= 512 and M._is_image_file(line) then
        M._paste_from_file(line)
        return
      end
    end

    -- Step 3: normal text paste
    return original(lines, phase)
  end
end

-- ── Layer 2: normal p/P intercept ─────────────────────────────────

function M._install_p_intercept()
  vim.keymap.set("n", "p", function()
    if clipboard.has_image() then
      M._paste_image()
      return
    end
    vim.cmd(vim.v.count >= 1 and ("normal! " .. vim.v.count .. "p") or "normal! p")
  end, { desc = "", silent = true })

  vim.keymap.set("n", "P", function()
    if clipboard.has_image() then
      M._paste_image()
      return
    end
    vim.cmd(vim.v.count >= 1 and ("normal! " .. vim.v.count .. "P") or "normal! P")
  end, { desc = "", silent = true })

  vim.keymap.set("x", "p", function()
    if clipboard.has_image() then
      vim.cmd('normal! "_d')
      M._paste_image()
      return
    end
    vim.cmd("normal! p")
  end, { desc = "", silent = true })

  vim.keymap.set("x", "P", function()
    if clipboard.has_image() then
      vim.cmd('normal! "_d')
      M._paste_image()
      return
    end
    vim.cmd("normal! P")
  end, { desc = "", silent = true })
end

-- ── Image file detection ──────────────────────────────────────────

local function is_image_ext(ext)
  ext = ext:lower()
  for _, f in ipairs({ "png", "jpg", "jpeg", "gif", "webp", "svg", "bmp", "tiff", "ico" }) do
    if ext == f then
      return true
    end
  end
  return false
end

function M._is_image_file(str)
  local ext = str:match("%.(%w+)$")
  if not ext or not is_image_ext(ext) then
    return false
  end
  -- absolute path, file:// URL, or Windows drive (C:\...) — rejects text like "see /tmp/x.png"
  return str:match("^[/~]") ~= nil or str:match("^file://") ~= nil or str:match("^%a:[/\\]") ~= nil
end

-- ── Paste from dropped file ───────────────────────────────────────

function M._paste_from_file(source_path)
  local source_path_clean = source_path:match("^[^\n\r]+")
  if not source_path_clean then
    return
  end
  source_path_clean = source_path_clean:gsub("[\r\n]", ""):match("^%s*(.-)%s*$")
  if not source_path_clean or source_path_clean == "" then
    return
  end
  -- strip file:// prefix
  source_path_clean = source_path_clean:gsub("^file://", "")

  local assets_dir = M._assets_dir()
  M._ensure_dir(assets_dir)

  -- keep the dropped file's own extension; clipboard saves honor config.format
  local ext = source_path_clean:match("%.(%w+)$")
  if not ext then
    return
  end
  ext = ext:lower()
  local dest_name = M._next_name(ext)
  local dest_path = assets_dir .. "/" .. dest_name

  vim.fn.system({ "cp", source_path_clean, dest_path })
  if vim.v.shell_error ~= 0 then
    vim.notify("[paste-image] copy failed: " .. source_path_clean, vim.log.levels.ERROR)
    return
  end

  M._insert_markup("assets/" .. dest_name)
end

-- ── Clipboard image paste ─────────────────────────────────────────

function M._paste_image()
  local assets_dir = M._assets_dir()
  M._ensure_dir(assets_dir)

  local ext = config.get().format
  local fname = M._next_name(ext)

  local abs_path = assets_dir .. "/" .. fname
  local ok, err = clipboard.save_image(abs_path)
  if not ok then
    local msg = "[paste-image] save failed: " .. tostring(err)
    if err == "no clipboard tool" then
      msg = msg .. " (" .. clipboard.missing_hint() .. ")"
    end
    vim.notify(msg, vim.log.levels.ERROR, { timeout = 8000 })
    return
  end

  M._insert_markup("assets/" .. fname)
end

-- ── Insert markup at cursor ───────────────────────────────────────

function M._insert_markup(path)
  local cfg = config.get()
  local fname = vim.fn.fnamemodify(path, ":t")
  local stem = vim.fn.fnamemodify(fname, ":r")
  local resolved = path
  if cfg.url_encode_path then
    resolved = M._url_encode(resolved)
  end
  if cfg.use_absolute_path then
    -- assets live next to the current file, not the cwd
    resolved = vim.fn.fnamemodify(vim.fn.expand("%:p:h") .. "/" .. resolved, ":p")
  end

  local tmpl = M._template()
  local text = tmpl:gsub("$FILE_PATH", resolved):gsub("$FILE_NAME", fname):gsub("$FILE_NAME_NO_EXT", stem)

  -- resolve $CURSOR after the other substitutions, before nvim_put
  local cursor_col = text:find("$CURSOR")
  if cursor_col then
    text = text:gsub("$CURSOR", "")
  end

  vim.api.nvim_put(vim.split(text, "\n"), "c", true, true)
  if cursor_col then
    vim.api.nvim_win_set_cursor(0, { vim.fn.line("."), cursor_col - 1 })
  end
  if cfg.insert_mode_after_paste and vim.api.nvim_get_mode().mode ~= "i" then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("a", true, false, true), "n", false)
  end
end

-- ── Template ──────────────────────────────────────────────────────

function M._template()
  local ft = vim.bo.filetype
  local t = config.get().templates
  return t[ft] or t[ft:match("^([^.]+)")] or t["markdown"] or "$FILE_PATH"
end

-- ── Helpers ───────────────────────────────────────────────────────

function M._next_name(ext)
  if ext:sub(1, 1) ~= "." then
    ext = "." .. ext
  end
  local dir = M._assets_dir()
  local max_n = 0
  local handle = vim.uv.fs_scandir(dir)
  if handle then
    while true do
      local name = vim.uv.fs_scandir_next(handle)
      if not name then
        break
      end
      local n = name:match("^image%-(%d+)" .. vim.pesc(ext) .. "$")
      if n then
        n = tonumber(n)
        if n and n > max_n then
          max_n = n
        end
      end
    end
  end
  return "image-" .. (max_n + 1) .. ext
end

function M._assets_dir()
  local cfg = config.get()
  local base = vim.fn.expand("%:p:h")
  if base == "" then
    base = vim.fn.getcwd()
  end

  if cfg.relative_to_root then
    local root = vim.fn.systemlist("git rev-parse --show-toplevel 2>/dev/null")[1]
      or vim.fn.systemlist("hg root 2>/dev/null")[1]
      or base
    return root .. "/" .. cfg.assets_dir
  end
  return base .. "/" .. cfg.assets_dir
end

function M._ensure_dir(d)
  if vim.fn.isdirectory(d) == 0 then
    vim.fn.mkdir(d, "p")
  end
end

function M._url_encode(str)
  return str:gsub("\\", "/"):gsub(" ", function(c)
    return string.format("%%%02X", string.byte(c))
  end)
end

-- Auto-setup on require with defaults
M.setup()

return M
