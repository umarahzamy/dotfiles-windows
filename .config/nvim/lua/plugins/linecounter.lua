-- Per-line word/char counter for .typ files.
-- Shows a small "Nw Mc" label at end-of-line for every non-empty line in
-- the viewport plus a pre-rendered band of `margin` lines above/below, so
-- scrolling never flashes unmarked lines. Rendered via extmark virtual
-- text; extmarks outside the viewport don't draw, so cost stays O(viewport
-- + margin) regardless of buffer size.

local M = {}

local ns = vim.api.nvim_create_namespace("linecounter")
local timers = {}
local enabled = {} -- buf -> true
local ranges = {} -- buf -> { top, bot } last rendered band (1-based)

-- File types the counter is enabled for. Append to extend:
--   require("plugins.linecounter").supported_filetypes[#it + 1] = "org"
M.supported_filetypes = { "typst", "markdown", "text" }

M.defaults = {
  debounce_ms = 80, -- insert-mode re-render debounce
  margin = 100, -- pre-render this many lines above/below the viewport
}

M.opts = vim.deepcopy(M.defaults)

local function setup_hl()
  vim.api.nvim_set_hl(0, "LineCounter", { link = "Comment", default = true })
end

local function count_line(line)
  local words = vim.split(line, "%s+")
  return #words, vim.fn.strchars(line)
end

local function is_blank(line)
  return vim.fn.strchars(line) == 0
end

local function visible_range(win, buf)
  local info = vim.fn.getwininfo(win)[1]
  local top, bot = info.topline, info.botline
  if not top or top <= 0 then
    top = 1
  end
  if not bot or bot <= 0 then
    bot = vim.api.nvim_buf_line_count(buf)
  end
  return top, bot
end

local function find_win(buf)
  local cur = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_get_buf(cur) == buf then
    return cur
  end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == buf then
      return win
    end
  end
end

local function render(buf)
  if not enabled[buf] or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local top, bot, lines
  local win = find_win(buf)
  if win then
    top, bot = visible_range(win, buf)
    local nlines = vim.api.nvim_buf_line_count(buf)
    top = math.max(1, top - M.opts.margin)
    bot = math.min(nlines, bot + M.opts.margin)
    lines = vim.api.nvim_buf_get_lines(buf, top - 1, bot, false)
  else
    top, bot = 1, vim.api.nvim_buf_line_count(buf)
    lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  end
  -- Clear union of previously-rendered and newly-rendered ranges so
  -- marks that scrolled out of view don't linger.
  local old = ranges[buf]
  local cstart = (old and math.min(old.top, top) or top) - 1
  local cend = old and math.max(old.bot, bot) or bot
  vim.api.nvim_buf_clear_namespace(buf, ns, cstart, cend)
  for offset, line in ipairs(lines) do
    local n, c = count_line(line)
    if not is_blank(line) then
      vim.api.nvim_buf_set_extmark(buf, ns, top - 1 + (offset - 1), 0, {
        virt_text = { { ("%dw %dc"):format(n, c), "LineCounter" } },
        virt_text_pos = "eol",
        hl_mode = "combine",
      })
    end
  end
  ranges[buf] = { top = top, bot = bot }
end

-- True when the current viewport is fully inside the already-rendered
-- band; then scroll/cursor events can skip re-rendering entirely.
local function covered(buf, vtop, vbot)
  local r = ranges[buf]
  return r ~= nil and r.top <= vtop and vbot <= r.bot
end

local function debounced_render(buf)
  local t = timers[buf]
  if t then
    t:stop()
  end
  timers[buf] = vim.defer_fn(function()
    timers[buf] = nil
    render(buf)
  end, M.opts.debounce_ms)
end

function M.enable(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  enabled[buf] = true
  render(buf)
end

function M.disable(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  enabled[buf] = nil
  ranges[buf] = nil
  if timers[buf] then
    timers[buf]:stop()
    timers[buf] = nil
  end
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  end
end

function M.toggle(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if enabled[buf] then
    M.disable(buf)
  else
    M.enable(buf)
  end
end

function M.setup(opts)
  M.opts = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

local function setup()
  setup_hl()
  local group = vim.api.nvim_create_augroup("linecounter", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = M.supported_filetypes,
    callback = function(ev)
      M.enable(ev.buf)
    end,
  })

  vim.api.nvim_create_autocmd(
    { "TextChanged", "InsertLeave", "BufWritePost", "FileChangedShellPost" },
    {
      group = group,
      callback = function(ev)
        if enabled[ev.buf] then
          render(ev.buf)
        end
      end,
    }
  )

  vim.api.nvim_create_autocmd("TextChangedI", {
    group = group,
    callback = function(ev)
      if enabled[ev.buf] then
        debounced_render(ev.buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "WinScrolled", "CursorMoved" }, {
    group = group,
    callback = function(ev)
      if enabled[ev.buf] then
        local win = find_win(ev.buf)
        if win then
          local vtop, vbot = visible_range(win, ev.buf)
          if not covered(ev.buf, vtop, vbot) then
            debounced_render(ev.buf)
          end
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
    group = group,
    callback = function(ev)
      enabled[ev.buf] = nil
      ranges[ev.buf] = nil
      if timers[ev.buf] then
        timers[ev.buf]:stop()
        timers[ev.buf] = nil
      end
    end,
  })
end

vim.api.nvim_create_user_command("LineCounterToggle", M.toggle, {
  desc = "toggle per-line word/char counter",
})

setup()

return M
