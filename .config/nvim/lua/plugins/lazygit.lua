return {
	dir = vim.fn.stdpath("config") .. "/lua",
	name = "lazygit-float",
	virtual = true,
	config = function()
		require("lazygit_float")
	end,
}
