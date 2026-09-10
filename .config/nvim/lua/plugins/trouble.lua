pcall(function()
  require("trouble").setup({
    focus = true,
    win = {
      type = "split",
      position = "bottom",
      size = 0.4,
    },
    keys = {
      ["h"] = "fold_close",
      ["l"] = "fold_open",
    },
  })

  vim.keymap.set("n", "<C-S-m>", function()
    require("trouble").open("diagnostics")
  end, { desc = "trouble: open/focus diagnostics" })

  vim.keymap.set("n", "<C-j>", function()
    require("trouble").close()
  end, { desc = "trouble: close" })
end)
