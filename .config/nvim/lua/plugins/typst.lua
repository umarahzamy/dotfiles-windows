local M = {}

local substitution_patterns = { "%.json$", "%.txt$", "%.md$", "%.typ$" }
M.substitution_patterns = substitution_patterns

local is_touying_deck = function(file)
  for _, line in ipairs(vim.fn.readfile(file)) do
    if line:find("@preview/touying:") then
      return true
    end
  end
  return false
end

M.compile = function()
  local file = vim.fn.expand("%:p")
  if not file:match("%.typ$") then
    return
  end
  local dir = vim.fn.expand("%:p:h")
  local name = vim.fn.expand("%:t:r")
  local pdf_dir = dir .. "/pdf"
  vim.fn.mkdir(pdf_dir, "p")
  local pdf = pdf_dir .. "/" .. name .. ".pdf"
  vim.system({ "typst", "compile", file, pdf }, { cwd = dir }, function(obj)
    if obj.code == 0 then
      vim.schedule(function()
        vim.notify("typst: compiled " .. vim.fn.fnamemodify(pdf, ":t"), vim.log.levels.INFO)
      end)
    else
      vim.schedule(function()
        vim.notify("typst: failed\n" .. obj.stderr, vim.log.levels.ERROR, { timeout = 10000 })
      end)
    end
  end)
end

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = {"*.typ", "*.txt", "*.md", "*.json"},
  callback = function()
    vim.cmd([[%s/\%u2019/'/ge]])
    vim.cmd([[%s/\%u2013/-/ge]])
    vim.cmd([[%s/\%u2014/-/ge]])
  end,
})

M.compile_pptx = function()
  local file = vim.fn.expand("%:p")
  if not file:match("%.typ$") then
    return
  end
  if not vim.fn.executable("typ2pptx") then
    vim.schedule(function()
      vim.notify("typ2pptx: not found, skipping (uv tool install typ2pptx)", vim.log.levels.WARN, { timeout = 8000 })
    end)
    return
  end
  if not is_touying_deck(file) then
    return
  end
  local dir = vim.fn.expand("%:p:h")
  local name = vim.fn.expand("%:t:r")
  local pptx_dir = dir .. "/pptx"
  vim.fn.mkdir(pptx_dir, "p")
  local pptx = pptx_dir .. "/" .. name .. ".pptx"
  vim.system({ "typ2pptx", file, "-o", pptx }, { cwd = dir }, function(obj)
    vim.schedule(function()
      if obj.code == 0 then
        vim.notify("typ2pptx: converted " .. vim.fn.fnamemodify(pptx, ":t"), vim.log.levels.INFO)
      else
        vim.notify("typ2pptx: failed\n" .. obj.stderr, vim.log.levels.ERROR, { timeout = 10000 })
      end
    end)
  end)
end

-- Manual invocation only.
-- BufWritePost was dropped: on-save firing on nvim-tree's rename-write was
-- un-avoidable (both are rename + write) and a suppression guard added edge
-- cases. compile_pptx self-skips when the file has no touying declaration.
vim.api.nvim_create_user_command("TypstCompile", function()
  M.compile()
  M.compile_pptx()
end, { desc = "typst: compile pdf (+pptx if touying)" })

return M
