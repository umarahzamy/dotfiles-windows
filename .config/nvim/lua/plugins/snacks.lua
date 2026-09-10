local Snacks = require("snacks")

Snacks.setup({
  notifier = {
    enabled = true,
    style = "minimal", -- or "fancy"; floating window, no hit-enter prompt
    height = { min = 1, max = 0.95 }, -- grow vertically to fit the whole message (~full height)
    -- NOTE: max must be < 1 (fraction of screen). 1.0 == 1 numerically, so
    -- snacks' dim() clamps to 1 row. width left default: { min = 40, max = 0.4 }
  },
})

-- notification style defaults to wo.wrap = false -> long single-line messages
-- stay height 1 and get truncated horizontally. Wrap them so the wrapped
-- height is computed and the window expands to fit (up to height.max).
Snacks.config.style("notification", { wo = { wrap = true } })

vim.keymap.set("n", "<leader>bd", function() Snacks.bufdelete() end, { desc = "close buffer" })

-- helper export: init.lua must only require config modules, not plugin
-- internals (avoids LuaLS different-requires false positive)
local M = { bufdelete = Snacks.bufdelete }
return M
