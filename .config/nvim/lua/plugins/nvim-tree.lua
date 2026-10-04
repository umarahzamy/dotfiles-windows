pcall(function()
  local keymaps = require("nvim-tree.keymap")
  local nt_api = require("nvim-tree.api")

  local external_exts = vim.tbl_map(string.lower, {
    "7z",
    "avi",
    "bmp",
    "bz2",
    "cbr",
    "cbz",
    "epub",
    "flac",
    "gif",
    "gz",
    "jpeg",
    "jpg",
    "mkv",
    "mov",
    "mp3",
    "mp4",
    "ogg",
    "pdf",
    "png",
    "pptx",
    "rar",
    "svg",
    "tar",
    "wav",
    "webm",
    "webp",
    "xz",
    "zip",
  })

  local function is_root(node)
    return node and node.name == ".."
  end

  local function open_keep_focus()
    local node = nt_api.tree.get_node_under_cursor()
    if not node then
      return
    end
    if is_root(node) then
      return
    end
    local ext = vim.fn.fnamemodify(node.name, ":e"):lower()
    if vim.tbl_contains(external_exts, ext) then
      nt_api.node.run.system()
      vim.notify(string.format("Opening %s", node.name))
      return
    end
    nt_api.node.open.edit(node, { focus = true })
  end

  local function single_chain_expand()
    local node = nt_api.tree.get_node_under_cursor()
    if not node then
      return
    end
    if is_root(node) then
      return
    end
    if node.type ~= "directory" then
      local ext = vim.fn.fnamemodify(node.name, ":e"):lower()
      if vim.tbl_contains(external_exts, ext) then
        nt_api.node.run.system()
        vim.notify(string.format("Opening %s", node.name))
        return
      end
      nt_api.node.open.edit()
      return
    end
    local was_open = node.open
    nt_api.node.open.edit()
    if not was_open and node.open then
      local function rec(n)
        if not n.open or not n.nodes or #n.nodes ~= 1 then
          return
        end
        local child = n.nodes[1]
        if child.type ~= "directory" then
          return
        end
        if not child.open then
          child:expand_or_collapse()
        end
        rec(child)
      end
      rec(node)
    end
  end

  -- yazi-like copy helpers
  local function copy_set(text)
    vim.fn.setreg("+", text, "v")
    vim.notify(string.format("Copied: %s", text))
  end

  local function node_path(node)
    if not node then
      return nil
    end
    if node.name == ".." then
      return node.explorer and node.explorer.absolute_path or nil
    end
    return node.absolute_path
  end

  -- cc: absolute path, no trailing slash
  local function copy_abs_path()
    local path = node_path(nt_api.tree.get_node_under_cursor())
    if not path then
      return
    end
    path = path:gsub("/+$", "")
    if path == "" then
      path = "/"
    end
    copy_set(path)
  end

  -- cd: absolute parent directory
  local function copy_dir_path()
    local path = node_path(nt_api.tree.get_node_under_cursor())
    if not path then
      return
    end
    copy_set(vim.fn.fnamemodify(path, ":h"))
  end

  -- cf: filename
  local function copy_filename()
    local node = nt_api.tree.get_node_under_cursor()
    if not node then
      return
    end
    if node.name == ".." then
      copy_set(vim.fn.fnamemodify(node.explorer.absolute_path, ":t"))
    else
      copy_set(node.name)
    end
  end

  -- cn: filename without extension
  local function copy_basename()
    local node = nt_api.tree.get_node_under_cursor()
    if not node then
      return
    end
    local name = node.name
    if name == ".." then
      name = vim.fn.fnamemodify(node.explorer.absolute_path, ":t")
    end
    copy_set(vim.fn.fnamemodify(name, ":r"))
  end

  -- buffer ui: hide cursor + ~ lines + number/sign gap
  local cursor_hl = vim.api.nvim_get_hl(0, { name = "Cursor", link = false })
  vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
    callback = function(data)
      if nt_api.tree.is_tree_buf(data.buf) then
        vim.wo.fillchars = "eob: "
        vim.api.nvim_set_hl(0, "Cursor", { blend = 100, fg = cursor_hl.fg, bg = cursor_hl.bg })
        vim.opt_local.guicursor:append("a:Cursor/lCursor")
      else
        vim.api.nvim_set_hl(0, "Cursor", { blend = 0, fg = cursor_hl.fg, bg = cursor_hl.bg })
        vim.opt_local.guicursor:remove("a:Cursor/lCursor")
      end
    end,
  })

  require("nvim-tree").setup({
    disable_netrw = true,
    hijack_netrw = true,
    respect_buf_cwd = true,
    view = { width = 40, side = "left", signcolumn = "no" },
    actions = { open_file = { resize_window = false } },
    renderer = { group_empty = false },
    filters = { dotfiles = false },
    git = { enable = true },
    on_attach = function(bufnr)
      keymaps.on_attach_default(bufnr)
      local function m(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = "nvim-tree: " .. desc })
      end
      m("c", function()
        local key = vim.fn.getcharstr()
        if key == "c" then
          copy_abs_path()
        elseif key == "d" then
          copy_dir_path()
        elseif key == "f" then
          copy_filename()
        elseif key == "n" then
          copy_basename()
        end
      end, "copy: path|dir|filename|name")
      m("y", nt_api.fs.copy.node, "yank (copy) file/dir")
      m("d", nt_api.fs.trash, "trash file/dir")
      m("D", "<Nop>", "(disabled)")
      m("<CR>", open_keep_focus, "open file & stay in tree")
      m("l", single_chain_expand, "open (auto-chain)")
      m("h", nt_api.node.navigate.parent_close, "close directory")
      m("z", nt_api.tree.collapse_all, "collapse all")
    end,
  })

  vim.keymap.set("n", "<C-b>", function()
    nt_api.tree.toggle()
  end, { desc = "nvim-tree: toggle" })
  vim.keymap.set("i", "<C-b>", function()
    nt_api.tree.close()
  end, { desc = "nvim-tree: close (insert)" })
  vim.keymap.set("n", "<C-S-e>", function()
    nt_api.tree.open({ find_file = true })
  end, { desc = "nvim-tree: reveal file" })
end)
