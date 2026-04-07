return {
	"stevearc/oil.nvim",
	config = function()
		require("oil").setup({
			lsp_file_methods = {
				enabled = true,
				timeout_ms = 1000,
				autosave_changes = true,
			},
			columns = { "permissions", "icon" },
			float = { max_width = 0.7, max_height = 0.6, border = "rounded" },
		})
		vim.keymap.set("n", "<leader>e", function()
			require("oil").toggle_float()
		end, { desc = "Oil file explorer" })
	end,
}
