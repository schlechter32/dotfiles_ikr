return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"nvim-neotest/nvim-nio",
			"mfussenegger/nvim-dap-python",
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")
			dapui.setup()
			require("dap-python").setup("uv")

			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close()
			end

			vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "DAP UI toggle" })
			vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "DAP toggle breakpoint" })
			vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "DAP continue" })
			vim.keymap.set("n", "<leader>dn", dap.step_over, { desc = "DAP step over" })
			vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "DAP step into" })
			vim.keymap.set("n", "<leader>dw", function()
				local expr = vim.fn.input("DAP watch: ")
				if expr ~= "" then
					dapui.elements.watches.add(expr)
				end
			end, { desc = "DAP add watch" })
		end,
	},
}
