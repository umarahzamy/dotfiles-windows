pcall(function()
  vim.keymap.set({ "n", "v" }, "<C-S-h>", function() require("grug-far").open() end, { desc = "grug-far: search and replace" })
end)
