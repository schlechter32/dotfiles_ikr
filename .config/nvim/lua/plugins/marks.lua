return {
	"chentoast/marks.nvim",
	config = function()
		require("marks").setup({
			builtin_marks = { "<", ">", "^" },
			refresh_interval = 250,
			sign_priority = { lower = 10, upper = 15, builtin = 8, bookmark = 20 },
			excluded_filetypes = {},
			excluded_buftypes = {},
			mappings = {},
		})
		vim.keymap.set("n", "<leader>ma", "<cmd>MarksListAll<CR>", { desc = "List all marks" })
	end,
}
