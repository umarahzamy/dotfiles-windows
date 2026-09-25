pcall(function()
  require("conform").setup({
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "ruff_format" },
      rust = { "rustfmt" },
      go = { "gofmt" },
      c = { "clang-format" },
      cpp = { "clang-format" },
      javascript = { "biome" },
      typescript = { "biome" },
      javascriptreact = { "biome" },
      typescriptreact = { "biome" },
      json = { "biome" },
      toml = { "tombi" },
      yaml = { "yamlfmt" },
      sh = { "shfmt" },
      bash = { "shfmt" },
      css = { "biome" },
      html = { "biome" },
      sql = { "sql_formatter" },
      typst = { "typstyle" },
      -- no CLI formatter for systemd/quadlet; use systemd_lsp's formatting
      systemd = { lsp_format = "fallback" },
    },
    format_on_save = { timeout_ms = 500 },
  })
end)
