vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.smartindent = true
vim.opt.updatetime = 250
vim.opt.timeoutlen = 4000
vim.opt.timeout = true
vim.opt.clipboard = "unnamedplus"
vim.opt.autoread = true
vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter", "FocusGained" }, {
	group = vim.api.nvim_create_augroup("auto_checktime", { clear = true }),
	callback = function()
		if vim.bo.buftype ~= "nofile" then
			vim.cmd.checktime()
		end
	end,
})
vim.opt.termguicolors = true
vim.opt.cursorline = true

vim.keymap.set({ "n", "v", "o" }, "q", "<Nop>")

if vim.g.vscode then
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
end

if vim.fn.executable("zathura") == 1 then
  local zathura_jobs = {}

  vim.api.nvim_create_autocmd("BufWipeout", {
    callback = function(ev)
      local job = zathura_jobs[ev.buf]
      if job then
        job:kill("sigterm")
        zathura_jobs[ev.buf] = nil
      end
    end,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      for _, job in pairs(zathura_jobs) do
        job:kill("sigterm")
      end
    end,
  })

  vim.keymap.set("n", "<C-k>v", function()
    local file = vim.fn.expand("%:p")
    if not file:match("%.typ$") then
      vim.notify("Not a .typ file", vim.log.levels.WARN)
      return
    end
    local dir = vim.fn.expand("%:p:h")
    local name = vim.fn.expand("%:t:r")
    local pdf = dir .. "/pdf/" .. name .. ".pdf"
    if vim.fn.filereadable(pdf) == 0 then
      vim.notify("Compile the file first (save it)", vim.log.levels.WARN)
      return
    end
    local job = vim.system({ "zathura", pdf }, { detach = true })
    zathura_jobs[vim.api.nvim_get_current_buf()] = job
  end, { desc = "zathura: open compiled PDF preview" })
end

if not vim.g.vscode then
  vim.keymap.set("n", "<leader>bd", ":bdelete!<CR>", { desc = "close buffer" })
  vim.keymap.set("n", "<leader>qq", ":qa!<CR>", { desc = "quit all" })

	vim.keymap.set("t", "[b", "<C-\\><C-n>:bprev!<CR>", { desc = "previous buffer" })
	vim.keymap.set("t", "]b", "<C-\\><C-n>:bnext!<CR>", { desc = "next buffer" })

	vim.keymap.set("t", "<C-space>", "<C-\\><C-n>", { desc = "exit terminal" })
	vim.keymap.set("t", "<C-w>h", "<C-\\><C-n><C-w>h", { desc = "exit terminal and move left" })
	vim.keymap.set("t", "<C-w>j", "<C-\\><C-n><C-w>j", { desc = "exit terminal and move down" })
	vim.keymap.set("t", "<C-w>k", "<C-\\><C-n><C-w>k", { desc = "exit terminal and move up" })
	vim.keymap.set("t", "<C-w>l", "<C-\\><C-n><C-w>l", { desc = "exit terminal and move right" })
end

vim.pack.add({
	{ src = "https://github.com/folke/flash.nvim", name = "flash" },
	{ src = "https://github.com/catppuccin/nvim", name = "catppuccin" },
	{ src = "https://github.com/nvim-lua/plenary.nvim", name = "plenary" },
	{ src = "https://github.com/mikavilpas/yazi.nvim", name = "yazi" },
	{ src = "https://github.com/dmtrKovalenko/fff.nvim", name = "fff" },
	{ src = "https://github.com/MagicDuck/grug-far.nvim", name = "grug-far" },
})

vim.api.nvim_create_autocmd("PackChanged", {
	callback = function(ev)
		local name, kind = ev.data.spec.name, ev.data.kind
		if name == "fff.nvim" and (kind == "install" or kind == "update") then
			if not ev.data.active then
				vim.cmd.packadd("fff.nvim")
			end
			require("fff.download").download_or_build_binary()
		end
	end,
})

vim.g.fff = {
	lazy_sync = true,
}

if not vim.g.vscode then
	local ok, yazi = pcall(require, "yazi")
	if ok then
		vim.keymap.set({ "n", "v" }, "<leader>e", function()
			yazi.yazi()
		end, { desc = "yazi: cwd" })
		vim.keymap.set({ "n", "v" }, "<leader>E", function()
			yazi.yazi(nil, vim.fn.expand("%:p:h"))
		end, { desc = "yazi: buffer dir" })
	end
end

if not vim.g.vscode then
	local ok, fff = pcall(require, "fff")
	if ok then
		fff.setup({
			layout = {
				height = 0.90,
				width = 0.90,
			},
			keymaps = {
				move_up = { "<M-k>" },
				move_down = { "<M-j>" },
			},
		})
		vim.keymap.set("n", "<C-p>", function()
			fff.find_files()
		end, { desc = "fff: find files" })
		vim.keymap.set("n", "<C-S-f>", function()
			fff.live_grep()
		end, { desc = "fff: live grep" })
	end
end

if not vim.g.vscode then
	local ok, grg = pcall(require, "grug-far")
	if ok then
		vim.keymap.set({ "n", "v" }, "<C-S-h>", function()
			grg.open()
		end, { desc = "grug-far: search and replace" })
	end
end

if not vim.g.vscode then
	local ok, catppuccin = pcall(require, "catppuccin")
	if ok then
		catppuccin.setup({
			flavour = "mocha",
			term_colors = false,
			transparent_background = true,
			float = {
				transparent = true,
			},
		})
		vim.cmd.colorscheme("catppuccin")
	end
end

local ok, flash = pcall(require, "flash")
if ok then
	flash.setup({})
	vim.keymap.set({ "n", "x", "o" }, "s", flash.jump, { desc = "flash" })
end



local function typst_compile()
	local file = vim.fn.expand("%:p")
	if not file:match("%.typ$") then
		return
	end
	local dir = vim.fn.expand("%:p:h")
	local name = vim.fn.expand("%:t:r")
	local pdf_dir = dir .. "/pdf"
	vim.fn.mkdir(pdf_dir, "p")
	local pdf = pdf_dir .. "/" .. name .. ".pdf"
	vim.system({ "typst", "compile", file, pdf }, { cwd = dir }, function(obj)
		if obj.code == 0 then
			vim.schedule(function()
				vim.notify("typst: compiled " .. vim.fn.fnamemodify(pdf, ":~"), vim.log.levels.INFO)
			end)
		else
			vim.schedule(function()
				vim.notify("typst: failed\n" .. obj.stderr, vim.log.levels.ERROR)
			end)
		end
	end)
end

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = {"*.typ", "*.txt", "*.md"},
	callback = function()
		vim.cmd([[%s/\%u2019/'/ge]])
	end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
	pattern = "*.typ",
	callback = typst_compile,
})

if vim.g.vscode then
	local ok, vscode = pcall(require, "vscode")
	if ok then
		vscode.on("document_buffer_init", function(buf)
			local name = vim.api.nvim_buf_get_name(buf)
			if name:match("%.typ$") then
				vim.api.nvim_create_autocmd("BufWriteCmd", {
					buffer = buf,
					callback = function(ev)
						vim.cmd([[%s/\%u2019/'/ge]])
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
				vim.api.nvim_create_autocmd("BufWriteCmd", {
					buffer = buf,
					callback = typst_compile,
				})
			end
		end)
	end
end


