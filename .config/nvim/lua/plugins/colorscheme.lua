return {
	"talha-akram/noctis.nvim",
	priority = 1000,
	config = function()
		vim.cmd.colorscheme("noctis_uva")
		vim.api.nvim_set_hl(0, "StatusLine", { bg = "NONE" })
		vim.api.nvim_set_hl(0, "FlashBackdrop", { fg = "#6c6f93" })
		vim.api.nvim_set_hl(0, "FlashLabel", { fg = "#82aaff", bold = true })
		vim.api.nvim_set_hl(0, "FlashMatch", { fg = "#ecc48d", underline = true })
	end,
}
