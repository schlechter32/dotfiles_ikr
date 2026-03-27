-- Make this config self-contained even when loaded from a non-standard appname.
local init_file = debug.getinfo(1, "S").source:sub(2)
local config_root = vim.fn.fnamemodify(init_file, ":p:h")
local lua_root = config_root .. "/lua"

if not string.find(vim.o.runtimepath, config_root, 1, true) then
	vim.opt.rtp:prepend(config_root)
end


package.path = table.concat({
	lua_root .. "/?.lua",
	lua_root .. "/?/init.lua",
	package.path,
}, ";")

-- -- Load pack-manager and set it up early
-- require("pack-manager").setup({
-- 	auto_install = true,
-- 	show_progress = true,
-- })
--
-- -- Load modular config
--
require("config.options")
require("config.lazy")
require("config.autocmds")
require("config.keymaps")
require("config.codium")

-- require("config.plugins")
-- -- require("config.lsp")
--
