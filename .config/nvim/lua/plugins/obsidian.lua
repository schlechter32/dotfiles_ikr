local vault = vim.fn.expand("~/secondBrain")
if vim.fn.isdirectory(vault) == 0 then
	return {}
end

return {
	"obsidian-nvim/obsidian.nvim",
	version = "*",
	ft = "markdown",
	config = function()
		require("obsidian_setup")
	end,
}
