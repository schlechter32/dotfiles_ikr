local pack = require("pack-manager")
local cobra = require("install_on_cobra")

-- Plugin list
pack.add(vim.list_extend({
	{ src = "https://github.com/vague-theme/vague.nvim.git" },
	{ src = "https://github.com/stevearc/oil.nvim" },
	{ src = "https://github.com/chentoast/marks.nvim" },
	{ src = "https://github.com/echasnovski/mini.pick" },
	{ src = "https://github.com/nvim-mini/mini.comment" },
	{ src = "https://github.com/nvim-tree/nvim-web-devicons" },
	{ src = "https://github.com/neovim/nvim-lspconfig" },
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter" },
	{ src = "nvim-treesitter/nvim-treesitter-context" },
	{ src = "https://github.com/alexghergh/nvim-tmux-navigation" },
	{ src = "https://github.com/saghen/blink.cmp", version = "v1.7.0" },
	{ src = "https://github.com/nvim-mini/mini.ai" },
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
	{ src = "https://github.com/williamboman/mason.nvim" },
	{ src = "https://github.com/stevearc/conform.nvim" },
	{ src = "https://github.com/declancm/maximize.nvim" },
	{ src = "https://github.com/mfussenegger/nvim-dap" },
	{ src = "https://github.com/rcarriga/nvim-dap-ui" },
	{ src = "https://github.com/nvim-neotest/nvim-nio.git" },
	{ src = "https://github.com/mfussenegger/nvim-dap-python" },
	{ src = "folke/todo-comments.nvim" },
	{ src = "https://github.com/MagicDuck/grug-far.nvim" },
	{ src = "https://github.com/nvim-lua/plenary.nvim" },
	{ src = "https://github.com/epwalsh/obsidian.nvim" },
	{ src = "https://github.com/folke/flash.nvim" },
	{ src = "https://github.com/j-hui/fidget.nvim.git" },
	{ src = "iamcco/markdown-preview.nvim" },
	{ src = "https://github.com/kevinhwang91/nvim-bqf.git" },
	{ src = "https://github.com/MeanderingProgrammer/render-markdown.nvim.git" },
}, cobra))

require("todo-comments").setup({})
require("fidget").setup({})

-- nvim-dap UI + python adapter
require("dapui").setup()
require("dap-python").setup("uv")
local dap_ok, dap = pcall(require, "dap")
local dapui_ok, dapui = pcall(require, "dapui")
if dap_ok and dapui_ok then
	dapui.setup()
	dap.listeners.after.event_initialized["dapui_config"] = function()
		dapui.open()
	end
	dap.listeners.before.event_terminated["dapui_config"] = function()
		dapui.close()
	end
	dap.listeners.before.event_exited["dapui_config"] = function()
		dapui.close()
	end
	-- python adapter (falls back to system python)
	require("dap-python").setup("uv")
	local dap_py_ok, dap_python = pcall(require, "dap-python")
	if dap_py_ok then
		print("dap_py_ok")
		-- use python that has debugpy; swap to your venv path if needed
		dap_python.setup("uv")
		-- ensure configurations table exists
		-- dap.configurations.python = dap.configurations.python or {}
		-- local pycfg = dap.configurations.python
		-- local function add(cfg)
		-- 	table.insert(pycfg, cfg)
		-- end
		-- add({
		-- 	type = "python",
		-- 	request = "launch",
		-- 	name = "Python: current file",
		-- 	program = "${file}",
		-- 	console = "integratedTerminal",
		-- })
		-- add({
		-- 	type = "python",
		-- 	request = "launch",
		-- 	name = "Python: module",
		-- 	module = "${fileBasenameNoExtension}",
		-- 	cwd = "${workspaceFolder}",
		-- })
		-- add({
		-- 	type = "python",
		-- 	request = "attach",
		-- 	name = "Python: attach 5678",
		-- 	connect = { host = "127.0.0.1", port = 5678 },
		-- 	justMyCode = false,
		-- })
	end
end

require("marks").setup({
	builtin_marks = { "<", ">", "^" },
	refresh_interval = 250,
	sign_priority = { lower = 10, upper = 15, builtin = 8, bookmark = 20 },
	excluded_filetypes = {},
	excluded_buftypes = {},
	mappings = {},
})

local flash = require("flash")
flash.setup({
	label = { rainbow = { enabled = true, shade = 5 } },
	modes = {
		search = { enabled = true },
		char = { jump_labels = true },
	},
})
vim.keymap.set({ "n", "x", "o" }, "s", flash.jump, { desc = "Flash" })
vim.keymap.set({ "n", "x", "o" }, "S", flash.treesitter, { desc = "Flash Treesitter" })
vim.keymap.set("o", "r", flash.remote, { desc = "Remote Flash" })
vim.keymap.set({ "o", "x" }, "R", flash.treesitter_search, { desc = "Treesitter Search" })
vim.keymap.set("c", "<C-s>", flash.toggle, { desc = "Toggle Flash Search" })
vim.api.nvim_set_hl(0, "FlashBackdrop", { fg = "#555555" })
vim.api.nvim_set_hl(0, "FlashLabel", { fg = "#64eb34", bold = true })
vim.api.nvim_set_hl(0, "FlashMatch", { fg = "#df8e1d", underline = true })

require("maximize").setup()
require("conform").setup({
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	notify_on_error = true,
	format_after_save = {
		async = true,
		timeout_ms = 500,
		lsp_fallback = true,
	},
	formatters_by_ft = {
		lua = { "stylua" },
		julia = { "runic" },
		python = { "black" },
		latex = { "tex-fmt" },
		tex = { "tex-fmt" },
		markdown = { "pymarkdownlnt" },
		bash = { "beautysh" },
		sh = { "beautysh" },
		nix = { "nixfmt", "alejandra", stop_after_first = true },
		go = { "gofmt" },
	},
})
vim.cmd([[ command! Format lua require("conform").format() ]])

require("lazygit_float")
require("obsidian_setup")
require("local_sidekick")
require("mason").setup()

local cmp = require("blink.cmp")
cmp.setup({
	signature = { enabled = true },
	keymap = {
		preset = "enter",
		["<C-K>"] = { "show_signature", "hide_signature", "fallback" },
		["<S-Tab>"] = { "select_prev", "fallback_to_mappings" },
		["<Tab>"] = { "select_next", "fallback_to_mappings" },
	},
})

vim.cmd("hi statusline guibg=NONE")
require("vague").setup({
	on_highlights = function(hl)
		hl.Comment = { fg = "#ebaeae", bg = "NONE", italic = true }
		hl.LineNr = { fg = "#ebaeae", bg = "NONE" }
		hl.CurSearch = { fg = "#d20f39", bg = "NONE" }
		hl.IncSearch = { fg = "#64eb34", bg = "NONE" }
		hl.Search = { fg = "#df8e1d", bg = "NONE" }
		hl.Visual = { bg = "#666666" }
		hl.FlashBackdrop = { fg = "#9f9f9f" }
		hl.FlashLabel = { fg = "#64eb34", bold = true }
		hl.FlashMatch = { fg = "#df8e1d", underline = true }
	end,
})
vim.cmd.colorscheme("vague")

require("mini.ai").setup()
require("mini.pick").setup()
require("nvim-tmux-navigation").setup({})

-- Treesitter for highlighting (markdown fenced code blocks included)
local ok_ts, ts_configs = pcall(require, "nvim-treesitter")
if ok_ts then
	ts_configs.setup({
		ensure_installed = { "lua", "julia", "markdown", "markdown_inline", "python", "latex", "bash", "vim" },
		highlight = {
			enable = true,
			additional_vim_regex_highlighting = { "markdown" },
		},
		incremental_selection = { enable = true },
		textobjects = { enable = true },
	})
else
	vim.notify("nvim-treesitter not available; syntax highlighting may be reduced", vim.log.levels.WARN)
end

local ok_oil, oil = pcall(require, "oil")
if ok_oil then
	oil.setup({
		lsp_file_methods = {
			enabled = true,
			timeout_ms = 1000,
			autosave_changes = true,
		},
		columns = { "permissions", "icon" },
		float = { max_width = 0.7, max_height = 0.6, border = "rounded" },
	})
else
	vim.notify("oil.nvim not available (yet); skip setup", vim.log.levels.WARN)
end

require("mini.comment").setup({
	mappings = {
		comment = "<leader>a",
		comment_line = "<leader>a",
		textobject = "<leader>a",
		comment_visual = "<leader>a",
	},
})
