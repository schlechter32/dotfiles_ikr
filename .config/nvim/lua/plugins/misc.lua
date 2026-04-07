return {
	{ "nvim-tree/nvim-web-devicons" },
	{ "neovim/nvim-lspconfig" },
	{ "nvim-lua/plenary.nvim" },
	{ "kevinhwang91/nvim-bqf" },
	{ "MeanderingProgrammer/render-markdown.nvim" },
	{ "iamcco/markdown-preview.nvim", build = "cd app && npm install", ft = { "markdown" } },
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},
	{
		"j-hui/fidget.nvim",
		config = function()
			require("fidget").setup({})
		end,
	},
	{
		"folke/todo-comments.nvim",
		config = function()
			require("todo-comments").setup({})
		end,
	},
	{
		"stevearc/dressing.nvim",
		config = function()
			require("dressing").setup({
				select = { backend = { "telescope", "builtin" } },
			})
		end,
	},
	{
		"declancm/maximize.nvim",
		config = function()
			require("maximize").setup()
			vim.keymap.set("n", "<F3>", function()
				require("maximize").toggle()
			end, { desc = "Toggle maximize" })
		end,
	},
	{ "MagicDuck/grug-far.nvim" },
	{
		"alexghergh/nvim-tmux-navigation",
		config = function()
			require("nvim-tmux-navigation").setup({})
		end,
	},
}
