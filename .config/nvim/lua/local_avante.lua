local M = {}

function M.setup()
	local ok, avante = pcall(require, "avante")
	if not ok then
		return
	end

	local api = require("avante.api")
	local map = vim.keymap.set

	map({ "n", "i", "v", "t" }, "<C-.>", function()
		avante.toggle()
	end, { desc = "Avante Toggle" })
	map("n", "<leader>cc", function()
		avante.toggle()
	end, { desc = "Avante Toggle" })

	map("n", "<leader>af", function()
		api.focus()
	end, { desc = "Avante Focus" })

	map("n", "<leader>aq", function()
		avante.close_sidebar()
	end, { desc = "Avante Close" })
	map("n", "<leader>cd", function()
		avante.close_sidebar()
	end, { desc = "Avante Close" })

	map("n", "<leader>an", function()
		api.ask({ new_chat = true })
	end, { desc = "Avante New Chat" })
	map("n", "<leader>cp", function()
		api.ask({ floating = true })
	end, { desc = "Avante Prompt" })
	map({ "n", "x" }, "<leader>ct", function()
		api.ask({ floating = true })
	end, { desc = "Avante Ask This" })
	map("n", "<leader>cf", function()
		api.ask({ floating = true, without_selection = true })
	end, { desc = "Avante Ask File" })
	map("x", "<leader>cv", function()
		api.ask({ floating = true })
	end, { desc = "Avante Ask Selection" })

	vim.api.nvim_create_user_command("AvanteResume", function()
		api.ask({ new_chat = false })
	end, {})
	vim.api.nvim_create_user_command("AvanteOpenCode", function()
		api.switch_provider("opencode")
	end, {})
end

return M
