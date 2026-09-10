vim.g.fff = { lazy_sync = true }
pcall(function()
  require("fff").setup({
    layout = { height = 0.90, width = 0.90 },
    keymaps = { move_up = { "<M-k>" }, move_down = { "<M-j>" } },
  })
  vim.keymap.set("n", "<C-p>", function() require("fff").find_files() end, { desc = "fff: find files" })
  vim.keymap.set("n", "<C-S-f>", function() require("fff").live_grep() end, { desc = "fff: live grep" })

  -- Disable autocomplete popup in fff buffers
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "fff_input" },
    callback = function()
      vim.opt_local.autocomplete = false
    end,
  })
end)
