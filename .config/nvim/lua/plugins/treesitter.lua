-- Quadlet/systemd use the systemd filetype; Butane and Ignition use YAML/JSON.
vim.filetype.add({
	extension = {
		container = "systemd",
		volume = "systemd",
		network = "systemd",
		kube = "systemd",
		image = "systemd",
		build = "systemd",
		pod = "systemd",
		artifact = "systemd",
		bu = "yaml",
		ign = "json",
	},
})

local parsers = {
	"astro",
	"bash",
	"c",
	"cpp",
	"css",
	"diff",
	"dockerfile",
	"go",
	"groovy",
	"hcl",
	"helm",
	"html",
	"ini",
	"java",
	"javascript",
	"tsx",
	"typescript",
	"json",
	"kotlin",
	"lua",
	"luau",
	"markdown",
	"markdown_inline",
	"php",
	"python",
	"rust",
	"sql",
	"svelte",
	"terraform",
	"toml",
	"typst",
	"vim",
	"vimdoc",
	"vue",
	"yaml",
}

-- Install missing parsers; this is a no-op for existing ones.
pcall(function()
	require("nvim-treesitter").install(parsers)
end)

-- Use the INI parser for systemd and Quadlet files.
pcall(vim.treesitter.language.register, "ini", "systemd")

-- Keep parsers aligned with nvim-treesitter revisions.
vim.api.nvim_create_autocmd("PackChanged", {
	callback = function(pack_event)
		if pack_event.data.spec.name == "nvim-treesitter"
			and (pack_event.data.kind == "install" or pack_event.data.kind == "update") then
			pcall(vim.cmd, "TSUpdate")
		end
	end,
	desc = "treesitter: :TSUpdate on plugin install/update",
})

-- Use treesitter when available; keep legacy syntax as fallback.
vim.api.nvim_create_autocmd("FileType", {
	callback = function()
		pcall(vim.treesitter.start)
	end,
	desc = "treesitter: highlight (systemd uses ini parser via register above)",
})
