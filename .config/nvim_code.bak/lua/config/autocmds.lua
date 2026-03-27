-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
	pattern = "*",
	desc = "Highlight selection on yank",
	callback = function()
		vim.highlight.on_yank({ timeout = 200, visual = true })
	end,
})

-- Enable Quarto (and its Otter-backed LSPs) for markdown and quarto files
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "markdown", "quarto" },
	callback = function()
		local ok, quarto = pcall(require, "quarto")
		if ok and quarto.activate then
			quarto.activate()
		end
	end,
})

vim.api.nvim_create_autocmd("VimResized", {
	group = vim.api.nvim_create_augroup("WinResize", { clear = true }),
	pattern = "*",
	command = "wincmd =",
	desc = "Auto-resize windows on terminal buffer resize.",
})
