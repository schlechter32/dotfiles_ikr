local host = vim.loop.os_gethostname()

if not host:find("cobra1") then
	return {} -- never nil
end

return {
	{
		src = "https://github.com/folke/sidekick.nvim",
		config = function()
			require("local_sidekick").setup()
		end,
	},
}
