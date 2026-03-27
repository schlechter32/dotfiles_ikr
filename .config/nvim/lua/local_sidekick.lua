local M = {}

function M.setup()
	require("sidekick").setup({
		cli = {
			mux = {
				backend = "tmux",
				enabled = true,
			},
		},
	})

	local map = vim.keymap.set

	map({ "n", "x", "o" }, "<tab>", function()
		if not require("sidekick").nes_jump_or_apply() then
			return "<Tab>"
		end
	end, { expr = true, desc = "Goto/Apply Next Edit Suggestion" })

	map({ "n", "t", "i", "x" }, "<c-.>", function()
		require("sidekick.cli").toggle()
	end, { desc = "Sidekick Toggle" })

	map("n", "<leader>cc", function()
		require("sidekick.cli").toggle()
	end, { desc = "Sidekick Toggle CLI" })

	map("n", "<leader>cs", function()
		require("sidekick.cli").select()
	end, { desc = "Select CLI" })

	map("n", "<leader>cd", function()
		require("sidekick.cli").close()
	end, { desc = "Detach CLI Session" })

	map({ "n", "x" }, "<leader>ct", function()
		require("sidekick.cli").send({ msg = "{this}" })
	end, { desc = "Send This" })

	map("n", "<leader>cf", function()
		require("sidekick.cli").send({ msg = "{file}" })
	end, { desc = "Send File" })

	map("x", "<leader>cv", function()
		require("sidekick.cli").send({ msg = "{selection}" })
	end, { desc = "Send Visual Selection" })

	map({ "n", "x" }, "<leader>cp", function()
		require("sidekick.cli").prompt()
	end, { desc = "Sidekick Prompt" })

	-- 	map("n", "<leader>cc", function()
	-- 		require("sidekick.cli").toggle({ name = "claude", focus = true })
	-- 	end, { desc = "Toggle Claude" })
	vim.api.nvim_create_user_command("CodexResume", function()
		vim.fn.jobstart({ "tmux", "new-session", "-A", "-s", "codex", "codex", "resume", "--last" }, {
			detach = true,
		})
	end, {})
end

return M
