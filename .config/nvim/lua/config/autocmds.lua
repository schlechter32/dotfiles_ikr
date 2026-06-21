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

-- After Lazy installs/updates/syncs/cleans plugins, the byte-compile cache that
-- lazy.nvim auto-enables (vim.loader) keeps an in-memory index pointing at .luac
-- files that the operation just moved/removed. The next require() then throws
-- E5108 ENOENT (e.g. on flash.nvim via telescope) until a restart. Resetting the
-- loader index forces a clean recompile and avoids the stale-cache crash.
vim.api.nvim_create_autocmd("User", {
	group = vim.api.nvim_create_augroup("ResetLoaderCacheOnLazyOps", { clear = true }),
	pattern = { "LazyInstall", "LazyUpdate", "LazySync", "LazyClean", "LazyCheck" },
	desc = "Reset vim.loader byte-compile cache after Lazy plugin ops.",
	callback = function()
		if vim.loader and vim.loader.reset then
			vim.loader.reset()
		end
	end,
})
