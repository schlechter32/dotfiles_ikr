-- Bootstrap pack-manager if missing
local pack_path = vim.fn.stdpath("data") .. "/site/pack/core/start/pack-manager.nvim"
if not vim.uv.fs_stat(pack_path) then
	vim.notify("Installing pack-manager.nvim...")
	vim.fn.system({ "git", "clone", "--depth=1", "https://github.com/GlennMm/pack-manager.nvim.git", pack_path })
	vim.cmd("packloadall!")
	vim.notify("Pack-manager installed! Please restart Neovim.")
end

-- Load pack-manager and set it up early
require("pack-manager").setup({
	auto_install = true,
	show_progress = true,
})

-- Load modular config
require("config.options")
require("config.keymaps")
require("config.plugins")
require("config.autocmds")
require("config.lsp")
