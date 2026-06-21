local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("config.options")
require("config.keymaps")
require("config.autocmds")

-- Collect plugin specs from lua/plugins/*.lua
local plugin_specs = {}
local plugins_dir = vim.fn.stdpath("config") .. "/lua/plugins"
for _, file in ipairs(vim.fn.readdir(plugins_dir)) do
	if file:match("%.lua$") then
		local mod = "plugins." .. file:gsub("%.lua$", "")
		local ok, spec = pcall(require, mod)
		if ok then
			if spec[1] or spec.dir then
				table.insert(plugin_specs, spec)
			else
				for _, s in ipairs(spec) do
					table.insert(plugin_specs, s)
				end
			end
		end
	end
end

require("lazy").setup(plugin_specs, {
	defaults = { lazy = false },
	install = { colorscheme = { "noctis_uva" } },
	lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",
	change_detection = { notify = false },
})

require("config.lsp")
