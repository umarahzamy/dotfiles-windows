if not vim.g.vscode then
  return
end

local vscode = require("vscode")

vim.keymap.set("n", "[b", function()
  vscode.action("workbench.action.previousEditorInGroup")
end)
vim.keymap.set("n", "]b", function()
  vscode.action("workbench.action.nextEditorInGroup")
end)
vim.keymap.set("n", "[d", function()
  vscode.action("editor.action.marker.prev")
end)
vim.keymap.set("n", "]d", function()
  vscode.action("editor.action.marker.next")
end)
vim.keymap.set("n", "<C-w>q", function()
  vscode.action("workbench.action.closeEditorsInGroup")
end)
vim.keymap.set("n", "<leader>bd", function()
  vscode.action("workbench.action.closeActiveEditor")
end)
vim.keymap.set("n", "<leader>yp", function()
  vscode.action("copyFilePath")
end)
vim.keymap.set("n", "<C-w>h", function()
  vscode.action("workbench.action.navigateLeft")
end)
vim.keymap.set("n", "<C-w>j", function()
  vscode.action("workbench.action.navigateDown")
end)
vim.keymap.set("n", "<C-w>k", function()
  vscode.action("workbench.action.navigateUp")
end)
vim.keymap.set("n", "<C-w>l", function()
  vscode.action("workbench.action.navigateRight")
end)
vim.keymap.set("n", "<C-w>s", function()
  vscode.action("workbench.action.splitEditorDown")
end)
vim.keymap.set("n", "<C-w>v", function()
  vscode.action("workbench.action.splitEditorRight")
end)

-- Patterns that need unicode substitutions (mirrors typst.lua).
local sub_patterns = { "%.json$", "%.txt$", "%.md$", "%.typ$" }

vscode.on("document_buffer_init", function(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  for _, pat in ipairs(sub_patterns) do
    if name:match(pat) then
      -- BufWriteCmd replaces the normal write mechanism in VS Code.
      -- Substitutions and compile are handled by global autocmds in typst.lua.
      vim.api.nvim_create_autocmd("BufWriteCmd", {
        buffer = buf,
        callback = function(ev)
          local current_name = vim.api.nvim_buf_get_name(ev.buf)
          local data = {
            buf = ev.buf,
            bang = vim.v.cmdbang == 1,
            current_name = current_name,
            target_name = ev.match,
          }
          vscode.action("save_buffer", { args = { data } })
        end,
      })
      break
    end
  end
end)
