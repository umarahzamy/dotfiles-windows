-- Autosave, VS Code `files.autoSave: afterDelay`: each change re-arms a
-- trailing timer that saves after `delay_ms` of silence. This is the only
-- trigger (no saves on focus, window, insert, or buffer leave).
--
-- save() re-checks the buffer, so a stale timer firing after a manual save,
-- or on a readonly/unnamed buffer, is a no-op.

---@type table<integer, integer>
local timers = {}
local delay_ms = vim.g.autosave_delay_ms or 1000

local function skip(bufnr)
	return vim.bo[bufnr].buftype ~= ""
		or not vim.bo[bufnr].modifiable
		or vim.bo[bufnr].readonly
		or vim.fn.bufname(bufnr) == ""
end

local function cancel(bufnr)
	local handle = timers[bufnr]
	if handle then
		vim.fn.timer_stop(handle)
		timers[bufnr] = nil
	end
end

local function save(bufnr)
	cancel(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) or not vim.bo[bufnr].modified or skip(bufnr) then
		return
	end
	-- the buffer may not be current when the timer fires
	vim.api.nvim_buf_call(bufnr, function()
		pcall(function() vim.cmd("silent! update") end)
	end)
end

local function schedule(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) or skip(bufnr) then
		cancel(bufnr)
		return
	end
	cancel(bufnr)
	timers[bufnr] = vim.fn.timer_start(delay_ms, function()
		timers[bufnr] = nil
		save(bufnr)
	end)
end

local group = vim.api.nvim_create_augroup("autosave", { clear = true })
vim.api.nvim_create_autocmd({ "TextChangedI", "TextChanged" }, {
	group = group,
	callback = function(args)
		schedule(args.buf)
	end,
	desc = "autosave: re-arm debounce",
})
