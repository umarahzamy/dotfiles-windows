-- nvim-lint: standalone linters complementing LSP diagnostics.
-- Tools installed via mise (see ~/.config/mise/config.toml).
local lint = require("lint")

lint.linters_by_ft = {
	bash = { "shellcheck" },
	c = { "clangtidy" },
	cpp = { "clangtidy" },
	css = { "biomejs" },
	dockerfile = { "hadolint" },
	html = { "biomejs" },
	javascript = { "biomejs" },
	javascriptreact = { "biomejs" },
	json = { "biomejs" },
	jsonc = { "biomejs" },
	lua = { "selene" },
	python = { "ruff" },
	sh = { "shellcheck" },
	sql = { "sqlfluff" },
	terraform = { "tflint" },
	toml = { "tombi" },
	typescript = { "biomejs" },
	typescriptreact = { "biomejs" },
	yaml = { "yamllint" },
	-- ansiblels runs ansible-lint, whose yamllint rule covers these files.
	["yaml.ansible"] = {},
}

-- selene reads selene.toml from the process cwd, which nvim-lint does not set.
-- Point it at this config's selene.toml for files inside this config.
local selene = require("lint.linters.selene")
lint.linters.selene = function()
	if not vim.startswith(vim.api.nvim_buf_get_name(0), vim.fn.stdpath("config")) then
		return selene
	end
	return vim.tbl_deep_extend("force", selene, {
		args = { "--config", vim.fn.stdpath("config") .. "/selene.toml", "--display-style", "json", "-" },
	})
end

-- Trigger: on write. The autosave plugin writes on debounce while you keep
-- typing, so linting follows your thinking pause automatically.
vim.api.nvim_create_autocmd("BufWritePost", {
	callback = function()
		lint.try_lint()
	end,
	desc = "nvim-lint: lint on save",
})
