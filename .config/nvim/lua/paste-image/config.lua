--- Configuration for paste-image.nvim
--- Only storage-location options. No URLs, no remote, no link modes.

---@class paste_image.ConfigOpts
---@field assets_dir? string              # dir name (default: 'assets')
---@field relative_to_current_file? boolean  # assets/ next to current file
---@field relative_to_root? boolean       # use git/hg root instead
---@field use_absolute_path? boolean      # absolute paths in markup
---@field format? string                  # output format (png, jpg)
---@field filename_fn? fun():string       # custom name generator
---@field insert_mode_after_paste? boolean
---@field url_encode_path? boolean
---@field templates? table<string,string> # ft → template

local M = {}

local defaults = {
  assets_dir = "assets",
  relative_to_current_file = true,
  relative_to_root = false,
  use_absolute_path = false,
  format = "png",
  filename_fn = nil,
  insert_mode_after_paste = true,
  url_encode_path = false,
  templates = {
    markdown = "![$FILE_NAME_NO_EXT]($FILE_PATH)",
    mdx = "![$FILE_NAME_NO_EXT]($FILE_PATH)",
    rmd = "![$FILE_NAME_NO_EXT]($FILE_PATH)",
    quarto = "![$FILE_NAME_NO_EXT]($FILE_PATH)",
    typst = '#image("$FILE_PATH")',
    tex = "\\includegraphics[width=\\linewidth]{$FILE_PATH}",
    latex = "\\includegraphics[width=\\linewidth]{$FILE_PATH}",
    plaintex = "\\includegraphics[width=\\linewidth]{$FILE_PATH}",
    context = "\\externalfigure[$FILE_PATH]",
    html = '<img src="$FILE_PATH" alt="$FILE_NAME_NO_EXT">',
    htm = '<img src="$FILE_PATH" alt="$FILE_NAME_NO_EXT">',
    rst = ".. image:: $FILE_PATH",
    asciidoc = "image::$FILE_PATH[]",
    adoc = "image::$FILE_PATH[]",
    org = "[[file:$FILE_PATH]]",
    wiki = "{{$FILE_PATH}}",
    vimwiki = "![$FILE_NAME_NO_EXT]($FILE_PATH)",
  },
}

function M.setup(opts)
  if not opts then
    return
  end
  for k, v in pairs(opts) do
    if k == "templates" then
      for ft, tmpl in pairs(v) do
        defaults.templates[ft] = tmpl
      end
    elseif v ~= nil then
      defaults[k] = v
    end
  end
end

function M.get()
  return defaults
end

return M
