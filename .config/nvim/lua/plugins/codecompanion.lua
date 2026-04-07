return {
	"olimorris/codecompanion.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
	},
	config = function()
		require("codecompanion").setup({
			interactions = {
				chat = { adapter = "opencode" },
				inline = { adapter = "opencode" },
			},
		})
		vim.keymap.set({ "n", "v" }, "<leader>aa", "<cmd>CodeCompanionActions<cr>", { silent = true, desc = "CodeCompanion Actions" })
		vim.keymap.set({ "n", "v" }, "<leader>at", "<cmd>CodeCompanionChat Toggle<cr>", { silent = true, desc = "CodeCompanion Toggle Chat" })
		vim.keymap.set("v", "<leader>ae", "<cmd>CodeCompanionChat Add<cr>", { silent = true, desc = "CodeCompanion Add Selection" })
		vim.keymap.set("n", "<leader>ai", "<cmd>CodeCompanion<cr>", { silent = true, desc = "CodeCompanion Inline" })
		vim.cmd([[cab cc CodeCompanion]])
	end,
}
