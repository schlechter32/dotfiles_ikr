return {
	{
		"nvim-mini/mini.ai",
		config = function()
			require("mini.ai").setup()
		end,
	},
	{
		"nvim-mini/mini.comment",
		config = function()
			require("mini.comment").setup({
				mappings = {
					comment = "<leader>a",
					comment_line = "<leader>a",
					textobject = "<leader>a",
					comment_visual = "<leader>a",
				},
			})
		end,
	},
}
