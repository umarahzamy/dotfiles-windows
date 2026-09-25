-- LSP servers. Skips if binary not in $PATH.

-- native autocompletion (nvim 0.12): LSP via omnifunc (o) + buffer words (., w, b) ──
vim.opt.autocomplete = true
vim.opt.autocompletedelay = 250
vim.opt.complete = ".,w,b,o"
vim.opt.completeopt = "menuone,noselect,fuzzy"
vim.opt.pumborder = "rounded"
vim.opt.pumheight = 7
vim.opt.winborder = "rounded"

-- alt-j/k: navigate completion menu; fall back to cursor movement when closed
vim.keymap.set("i", "<A-j>", function()
	return vim.fn.pumvisible() == 1 and "<C-n>" or "<Down>"
end, { expr = true, desc = "complete: next" })
vim.keymap.set("i", "<A-k>", function()
	return vim.fn.pumvisible() == 1 and "<C-p>" or "<Up>"
end, { expr = true, desc = "complete: prev" })
vim.keymap.set("i", "<Tab>", function()
	return vim.fn.pumvisible() == 1 and "<C-y>" or "<Tab>"
end, { expr = true, desc = "complete: accept" })

-- typst: formatting owned by conform (typstyle); disable tinymist's embedded formatter
vim.lsp.config["tinymist"] = vim.lsp.config["tinymist"] or {}
vim.lsp.config["tinymist"].settings = { tinymist = { formatterMode = "disable" } }

vim.lsp.config("clangd", {
	cmd = { "clangd", "--background-index" },
})
vim.lsp.config("helm_ls", {
	cmd = { "helm-ls", "serve" },
})

-- attach handler: buffer-local keymaps (must be registered before servers attach) ──
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(ev)
		local map = function(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = "lsp: " .. desc })
		end
		map("n", "gd", vim.lsp.buf.definition, "go to definition")
		map("n", "K", vim.lsp.buf.hover, "hover")
		map({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, "code action")
		map("n", "gr", vim.lsp.buf.references, "references")
		map("n", "[d", function()
			vim.diagnostic.jump({ count = -1 })
		end, "prev diagnostic")
		map("n", "]d", function()
			vim.diagnostic.jump({ count = 1 })
		end, "next diagnostic")
	end,
})

vim.lsp.enable({
	"ansiblels",
	"astro",
	"basedpyright",
	"bashls",
	"clangd",
	"cssls",
	"dockerls",
	"emmet_language_server",
	"gopls",
	"groovyls",
	"helm_ls",
	"html",
	"jdtls",
	"jsonls",
	"kotlin_language_server",
	"lua_ls",
	"luau_lsp",
	"phpactor",
	"rust_analyzer",
	"systemd_lsp",
	"svelte",
	"tailwindcss",
	"terraformls",
	"tinymist",
	"vtsls",
	"vue_ls",
	"yamlls",
})
