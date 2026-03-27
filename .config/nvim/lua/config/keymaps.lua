-- Keymaps
vim.keymap.set("t", "<C-q>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })
vim.keymap.set("n", "<leader>o", ":update<CR> :source<CR>")
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action)
vim.keymap.set("n", "<leader>w", ":write<CR>")
vim.keymap.set("n", "<leader>z", "<cmd>wq<cr>", { silent = false }, { desc = "Save and close Buffer" })
vim.keymap.set("n", "<leader>q", ":quit<CR>")
vim.keymap.set("n", "<leader>lf", vim.lsp.buf.format)
vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float)
vim.keymap.set("v", "<C-j>", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "<C-k>", ":m '<-2<CR>gv=gv")
vim.keymap.set("v", "<C-n>", "<cmd>tabprevious<cr>")
vim.keymap.set("v", "<C-p>", "<cmd>tabnext<cr>")
vim.keymap.set("i", "jj", "<esc>")
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename)
vim.keymap.set("n", "<leader>rr", vim.lsp.buf.references)
vim.keymap.set("n", "U", "<C-r>")
vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "LSP: [G]oto [D]efinition" })
vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "LSP: [G]oto [R]eferences" })

-- Window resize + move around tmux
vim.api.nvim_create_autocmd("VimResized", {
	group = vim.api.nvim_create_augroup("WinResize", { clear = true }),
	pattern = "*",
	command = "wincmd =",
	desc = "Auto-resize windows on terminal buffer resize.",
})

-- Convenience file ops
vim.keymap.set("n", "<leader>ok", ":w<cr>:!mv '%:p' $HOME/secondBrain/05Zettelkasten/<cr>:bd<cr>")
vim.keymap.set("n", "<leader>od", ":!rm '%:p'<cr>:bd<cr>", { desc = "Delete bufferfile" })

-- Centering while moving
local center_keys = { "<C-u>", "<C-f>", "<C-d>", "{", "}", "N", "n", "G", "gg", "<C-i>", "<C-o>", "%", "*", "#" }
for _, k in ipairs(center_keys) do
	vim.keymap.set("n", k, k .. "zz")
end
vim.keymap.set("n", "L", "$")
vim.keymap.set("n", "H", "^")
vim.keymap.set("n", "<leader>no", "<cmd>noh<cr>")

-- Quickfix navigation
vim.keymap.set("n", "<leader>cn", ":cnext<cr>zz")
vim.keymap.set("n", "<leader>cp", ":cprevious<cr>zz")
vim.keymap.set("n", "<leader>co", ":copen<cr>zz")
vim.keymap.set("n", "<leader>cc", ":cclose<cr>zz")

-- Marks
vim.keymap.set("x", "<leader>p", '"_dP')
vim.keymap.set("n", "M", "`")

-- Plugin-related mappings
vim.keymap.set("n", "<leader>mp", "<cmd>MarkdownPreviewToggle<CR>", { desc = "Markdown preview" })
vim.keymap.set("n", "<leader>ma", "<cmd>MarksListAll<CR>", { desc = "List all marks" })
vim.keymap.set("n", "<leader>lg", function()
	require("lazygit_float").open()
end, { desc = "Open LazyGit in float" })
-- DAP basic controls
vim.keymap.set("n", "<leader>du", function()
	local ok, dapui = pcall(require, "dapui")
	if ok then
		dapui.toggle()
	end
end, { desc = "DAP UI toggle" })
vim.keymap.set("n", "<leader>db", function()
	local ok, dap = pcall(require, "dap")
	if ok then
		dap.toggle_breakpoint()
	end
end, { desc = "DAP toggle breakpoint" })
vim.keymap.set("n", "<leader>dc", function()
	local ok, dap = pcall(require, "dap")
	if ok then
		dap.continue()
	end
end, { desc = "DAP continue" })
vim.keymap.set("n", "<leader>dn", function()
	local ok, dap = pcall(require, "dap")
	if ok then
		dap.step_over()
	end
end, { desc = "DAP step over" })
vim.keymap.set("n", "<leader>di", function()
	local ok, dap = pcall(require, "dap")
	if ok then
		dap.step_into()
	end
end, { desc = "DAP step into" })
vim.keymap.set("n", "<leader>dw", function()
	local ok, dapui = pcall(require, "dapui")
	if not ok then
		return
	end
	local expr = vim.fn.input("DAP watch: ")
	if expr ~= "" then
		dapui.elements.watches.add(expr)
	end
end, { desc = "DAP add watch" })
vim.keymap.set("n", "<F3>", function()
	local ok, maximize = pcall(require, "maximize")
	if ok then
		maximize.toggle()
	else
		vim.notify("maximize.nvim not available", vim.log.levels.WARN)
	end
end, { desc = "Toggle maximize" })
vim.keymap.set("n", "<leader>sg", function()
	local q = vim.fn.input("Grep > ")
	if q ~= "" then
		require("mini.pick").builtin.grep({ pattern = q, preview = { kind = "vertical" } })
	end
end, { desc = "Search (grep) with MiniPick" })
vim.keymap.set("n", "<leader>f", function()
	require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Format buffer" })
vim.keymap.set("n", "<leader> ", ":Pick files<CR>")
vim.keymap.set("n", "<leader>sb", ":Pick buffers<CR>")
vim.keymap.set("n", "<leader>h", ":Pick help<CR>")
vim.keymap.set("n", "<leader>e", function()
	local ok, oil = pcall(require, "oil")
	if ok then
		return oil.toggle_float()
	end
	vim.notify("oil.nvim is not available", vim.log.levels.WARN)
end, { desc = "Oil file explorer" })

-- Tmux navigation
vim.keymap.set({ "n", "i", "v", "t" }, "<C-j>", ":NvimTmuxNavigateDown<CR>")
vim.keymap.set({ "n", "i", "v", "t" }, "<C-h>", ":NvimTmuxNavigateLeft<CR>")
vim.keymap.set({ "n", "i", "v", "t" }, "<C-k>", ":NvimTmuxNavigateUp<CR>")
vim.keymap.set({ "n", "i", "v", "t" }, "<C-l>", ":NvimTmuxNavigateRight<CR>")
vim.keymap.set("t", "<C-j>", [[<C-\><C-n><Cmd>NvimTmuxNavigateDown<CR>]], {
	silent = true,
	desc = "Tmux down (terminal)",
})
vim.keymap.set("t", "<C-l>", [[<C-\><C-n><Cmd>NvimTmuxNavigateRight<CR>]], {
	silent = true,
	desc = "Tmux right (terminal)",
})

vim.keymap.set("n", "<leader>lv", "<cmd>LspTexlabForward<cr>")
