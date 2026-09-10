if vim.fn.executable("zathura") ~= 1 then
  return
end

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
