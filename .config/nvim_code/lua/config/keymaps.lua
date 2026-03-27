-- Keymaps
vim.keymap.set("t", "<C-q>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })
vim.keymap.set("n", "<leader>o", ":update<CR> :source<CR>")
vim.keymap.set("n", "<leader>w", ":write<CR>")
vim.keymap.set("n", "U", "<C-r>")

-- Centering while moving
local center_keys = { "<C-u>", "<C-f>", "<C-d>", "{", "}", "G", "gg", "<C-i>", "<C-o>", "%" }
for _, k in ipairs(center_keys) do
	vim.keymap.set("n", k, k .. "zz")
end

-- Silent search navigation to suppress vscode-neovim output panel
local function silent_search(motion)
	return function()
		vim.cmd("silent! normal! " .. motion .. "zz")
	end
end
vim.keymap.set("n", "n", silent_search("n"))
vim.keymap.set("n", "N", silent_search("N"))

-- Pure neovim * and # search (avoids VSCode output panel)
vim.keymap.set("n", "*", function()
	vim.fn.setreg("/", "\\<" .. vim.fn.expand("<cword>") .. "\\>")
	vim.opt.hlsearch = true
	vim.cmd("silent! normal! nzz")
end)
vim.keymap.set("n", "#", function()
	vim.fn.setreg("/", "\\<" .. vim.fn.expand("<cword>") .. "\\>")
	vim.opt.hlsearch = true
	vim.cmd("silent! normal! Nzz")
end)

vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "L", "$")
vim.keymap.set("n", "H", "^")
vim.keymap.set("n", "<leader>no", "<cmd>noh<cr>")

vim.keymap.set("x", "<leader>p", '"_dP')

vim.keymap.set("n", "<leader>f", function()
	require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Format buffer" })
vim.keymap.set("n", "<leader>y", ":YankyRingHistory<CR>")
 -- {"<leader>y", mode={ "n"},  vim.cmd("YankyRingHistory")}, 