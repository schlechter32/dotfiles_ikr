return {
	"nvim-telescope/telescope.nvim",
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		require("telescope").setup({
			defaults = {
				layout_strategy = "vertical",
				layout_config = {
					prompt_position = "top",
					width = 0.95,
					height = 0.95,
					vertical = { preview_height = 0.55 },
				},
				sorting_strategy = "ascending",
				file_ignore_patterns = { "%.git/" },
			},
			pickers = {
				find_files = { hidden = true },
				live_grep = {
					additional_args = { "--hidden", "--glob", "!.git/" },
				},
				grep_string = {
					additional_args = { "--hidden", "--glob", "!.git/" },
				},
				buffers = { previewer = true },
			},
		})

		vim.keymap.set("n", "<leader>sg", function()
			require("telescope.builtin").live_grep()
		end, { desc = "Search (grep) with Telescope" })
		vim.keymap.set("n", "<leader> ", function()
			require("telescope.builtin").find_files()
		end, { desc = "Find files" })
		vim.keymap.set("n", "<leader>sb", function()
			require("telescope.builtin").buffers()
		end, { desc = "Search buffers" })
		vim.keymap.set("n", "<leader>h", function()
			require("telescope.builtin").help_tags()
		end, { desc = "Help tags" })
	end,
}
