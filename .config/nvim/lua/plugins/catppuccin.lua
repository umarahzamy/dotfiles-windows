-- catppuccin is native since nvim 0.12 (runtime/colors/catppuccin.vim):
-- Latte on light background, Mocha on dark. No setup options, so
-- transparency is reimplemented manually. nvim_set_hl() replaces the
-- whole group (missing attrs are wiped), so fg is passed explicitly;
-- re-applied on every ColorScheme since the scheme resets all groups.
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "catppuccin",
  callback = function()
    local fg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).fg
    vim.api.nvim_set_hl(0, "Normal", { fg = fg, bg = "NONE" })
    -- completion menu border in theme blue (matches FloatBorder)
    vim.api.nvim_set_hl(0, "PmenuBorder", { fg = "#89b4fa", bg = "NONE" })
  end,
})
vim.o.background = "dark" -- native catppuccin: dark => mocha (latté if light)
vim.cmd.colorscheme("catppuccin")
