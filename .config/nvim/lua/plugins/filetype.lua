-- Ansible playbooks use the same .yml/.yaml extension as every other YAML file,
-- so Neovim cannot tell them apart by name. ansible-language-server only attaches
-- to the `yaml.ansible` filetype, which nothing sets by default. Assign it here
-- using path conventions, project markers, and content. Vars files may also be
-- extensionless (e.g. group_vars/all), so those get their own patterns below.
local function is_ansible(path, bufnr)
	-- path conventions
	if
		path:match("/playbooks?/")
		or path:match("/roles/[^/]+/(tasks|handlers|vars|defaults|meta)/")
		or path:match("/group_vars/")
		or path:match("/host_vars/")
		or path:match("/[^/]*playbook[^/]*%.ya?ml$")
		or path:match("/site%.ya?ml$")
		or path:match("/ansible[^/]*%.ya?ml$")
	then
		return true
	end

	-- project markers (ansible.cfg / .ansible-lint in this or a parent dir)
	local dir = vim.fs.dirname(path)
	if dir and vim.fs.find({ "ansible.cfg", ".ansible-lint" }, { upward = true, path = dir })[1] then
		return true
	end

	-- content: a top-level play
	local ok, lines = pcall(vim.api.nvim_buf_get_lines, bufnr, 0, 60, false)
	if not ok then
		return false
	end
	local text = table.concat(lines, "\n")
	return text:match("^%s*%-%s+hosts:") ~= nil
		or text:match("\n%s*%-%s+hosts:") ~= nil
		or text:match("^%s*%-%s+import_playbook:") ~= nil
		or text:match("\n%s*%-%s+import_playbook:") ~= nil
end

-- Vars files may be extensionless (group_vars/webservers, group_vars/all/vault),
-- so they get their own patterns below. Dotted basenames (.gitkeep, README.md)
-- are not vars files.
local function is_vars_file(path)
	local base = path:match("[^/]+$")
	if base and not base:find(".", 1, true) then
		return "yaml.ansible"
	end
end

vim.filetype.add({
	pattern = {
		-- priority 10 so this runs before the builtin .yaml -> yaml mapping
		[".*%.ya?ml"] = {
			function(path, bufnr)
				if is_ansible(path, bufnr) then
					return "yaml.ansible"
				end
			end,
			{ priority = 10 },
		},
		[".*/group_vars/.*"] = is_vars_file,
		[".*/host_vars/.*"] = is_vars_file,
	},
})

-- Cloud-init user-data: `#cloud-config` means YAML, otherwise a script (handled
-- by Neovim's shebang detection).
local function is_cloud_config(_, bufnr)
	if not bufnr or bufnr <= 0 then
		return
	end
	local first = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] or ""
	if first:match("^#cloud%-config") then
		return "yaml"
	end
end

vim.filetype.add({
	filename = {
		["user-data"] = is_cloud_config,
	},
})
