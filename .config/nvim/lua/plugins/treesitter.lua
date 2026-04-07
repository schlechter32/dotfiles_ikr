return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			vim.treesitter.language.register("latex", "tex")
			local parsers = { "lua", "julia", "markdown", "markdown_inline", "python", "latex", "bash", "vim" }
			for _, lang in ipairs(parsers) do
				pcall(vim.treesitter.language.add, lang)
			end
		end,
	},
	{ "nvim-treesitter/nvim-treesitter-context" },
	{ "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" },
}
