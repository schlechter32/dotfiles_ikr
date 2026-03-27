local host = vim.loop.os_gethostname()
local hosts = {
	cobra0 = true,
	cobra1 = true,
	cobra2 = true,
	cobra3 = true,
	cobra4 = true,
	netserv1 = true,
	netserv0 = true,
}
if not hosts[host] then
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
