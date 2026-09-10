pcall(function()
  require("flash").setup({})
  vim.keymap.set({ "n", "x", "o" }, "s", function() require("flash").jump() end, { desc = "flash" })
end)
