local plugins = {
	{ "talha-akram/noctis.nvim" },
	{ "stevearc/oil.nvim" },
	{ "chentoast/marks.nvim" },
	{ "nvim-tree/nvim-web-devicons" },
	{ "neovim/nvim-lspconfig" },
	{ "nvim-treesitter/nvim-treesitter", branch = "master", build = ":TSUpdate" },
	{ "nvim-treesitter/nvim-treesitter-context" },
	{ "alexghergh/nvim-tmux-navigation" },
	{ "saghen/blink.cmp", version = "v1.7.0" },
	{ "nvim-mini/mini.ai" },
	{ "nvim-mini/mini.comment" },
	{ "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" },
	{ "williamboman/mason.nvim" },
	{ "stevearc/conform.nvim" },
	{ "declancm/maximize.nvim" },
	{ "mfussenegger/nvim-dap" },
	{ "rcarriga/nvim-dap-ui" },
	{ "nvim-neotest/nvim-nio" },
	{ "mfussenegger/nvim-dap-python" },
	{ "folke/todo-comments.nvim" },
	{ "MagicDuck/grug-far.nvim" },
	{ "nvim-lua/plenary.nvim" },
	{ "epwalsh/obsidian.nvim" },
	{ "folke/flash.nvim" },
	{ "j-hui/fidget.nvim" },
	{ "iamcco/markdown-preview.nvim", build = "cd app && npm install", ft = { "markdown" } },
	{ "kevinhwang91/nvim-bqf" },
	{ "MeanderingProgrammer/render-markdown.nvim" },
	{
		"nvim-telescope/telescope.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
	},
	{ "MunifTanjim/nui.nvim" },
	{ "stevearc/dressing.nvim" },
	{
		"yetone/avante.nvim",
		build = vim.fn.has("win32") ~= 0
				and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
			or "make",
		version = false,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-telescope/telescope.nvim",
			"MeanderingProgrammer/render-markdown.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		opts = {
			provider = "opencode",
			input = {
				provider = "dressing",
				provider_opts = {},
			},
			selector = {
				provider = "telescope",
			},
			acp_providers = {
				opencode = {
					command = vim.fn.exepath("opencode"),
					args = { "acp" },
				},
			},
			behaviour = {
				auto_suggestions = false,
				auto_set_keymaps = true,
				auto_apply_diff_after_generation = false,
				minimize_diff = true,
				auto_add_current_file = true,
			},
			providers = {
				claude = {
					-- endpoint = "https://api.anthropic.com",
					auth_type = "max",
					-- model = "claude-sonnet-4-20250514",
					timeout = 30000,
					extra_request_body = {
						temperature = 0,
						max_tokens = 4096,
					},
				},
				openai = {
					endpoint = "https://api.openai.com/v1",
					model = "gpt-4o",
					timeout = 30000,
					extra_request_body = {
						temperature = 0,
						max_tokens = 4096,
					},
				},
			},
			mappings = {
				ask = "<leader>aa",
				edit = "<leader>ae",
				refresh = "<leader>ar",
				toggle = {
					default = "<leader>at",
					debug = "<leader>ad",
					hint = "<leader>ah",
					suggestion = "<leader>as",
				},
			},
		},
	},
}

require("lazy").setup(plugins, {
	defaults = {
		lazy = false,
	},
	install = {
		colorscheme = { "noctis_uva" },
	},
	lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",
	change_detection = {
		notify = false,
	},
})

require("todo-comments").setup({})
require("fidget").setup({})
require("dressing").setup({})

require("telescope").setup({
	defaults = {
		layout_strategy = "vertical",
		layout_config = {
			prompt_position = "top",
			width = 0.95,
			height = 0.95,
			preview_height = 0.55,
		},
		sorting_strategy = "ascending",
	},
	pickers = {
		find_files = {
			layout_strategy = "vertical",
		},
		live_grep = {
			layout_strategy = "vertical",
		},
		grep_string = {
			layout_strategy = "vertical",
		},
		buffers = {
			layout_strategy = "vertical",
			previewer = true,
		},
		help_tags = {
			layout_strategy = "vertical",
		},
	},
})

require("dapui").setup()
require("dap-python").setup("uv")
local dap_ok, dap = pcall(require, "dap")
local dapui_ok, dapui = pcall(require, "dapui")
if dap_ok and dapui_ok then
	dap.listeners.after.event_initialized["dapui_config"] = function()
		dapui.open()
	end
	dap.listeners.before.event_terminated["dapui_config"] = function()
		dapui.close()
	end
	dap.listeners.before.event_exited["dapui_config"] = function()
		dapui.close()
	end
	local dap_py_ok, dap_python = pcall(require, "dap-python")
	if dap_py_ok then
		print("dap_py_ok")
		dap_python.setup("uv")
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
require("local_avante").setup()
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

vim.cmd.colorscheme("noctis_uva")
vim.api.nvim_set_hl(0, "StatusLine", { bg = "NONE" })
vim.api.nvim_set_hl(0, "FlashBackdrop", { fg = "#6c6f93" })
vim.api.nvim_set_hl(0, "FlashLabel", { fg = "#82aaff", bold = true })
vim.api.nvim_set_hl(0, "FlashMatch", { fg = "#ecc48d", underline = true })

require("mini.ai").setup()
require("nvim-tmux-navigation").setup({})

local ok_ts, ts_configs = pcall(require, "nvim-treesitter.configs")
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
