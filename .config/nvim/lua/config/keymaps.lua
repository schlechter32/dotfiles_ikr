vim.keymap.set("t", "<C-q>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })
vim.keymap.set("n", "<leader>o", ":update<CR> :source<CR>")
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action)
vim.keymap.set("n", "<leader>w", ":write<CR>")
vim.keymap.set("n", "<leader>z", "<cmd>wq<cr>", { silent = false, desc = "Save and close Buffer" })
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

vim.keymap.set("n", "<leader>ok", ":w<cr>:!mv '%:p' $HOME/secondBrain/05Zettelkasten/<cr>:bd<cr>")
vim.keymap.set("n", "<leader>od", ":!rm '%:p'<cr>:bd<cr>", { desc = "Delete bufferfile" })

local center_keys = { "<C-u>", "<C-f>", "<C-d>", "{", "}", "N", "n", "G", "gg", "<C-i>", "<C-o>", "%", "*", "#" }
for _, k in ipairs(center_keys) do
	vim.keymap.set("n", k, k .. "zz")
end
vim.keymap.set("n", "L", "$")
vim.keymap.set("n", "H", "^")
vim.keymap.set("n", "<leader>no", "<cmd>noh<cr>")

vim.keymap.set("n", "<leader>cn", ":cnext<cr>zz")
vim.keymap.set("n", "<leader>cp", ":cprevious<cr>zz")
vim.keymap.set("n", "<leader>co", ":copen<cr>zz")
vim.keymap.set("n", "<leader>cc", ":cclose<cr>zz")

vim.keymap.set("x", "<leader>p", '"_dP')
vim.keymap.set("n", "M", "`")

vim.keymap.set("n", "<leader>mp", "<cmd>MarkdownPreviewToggle<CR>", { desc = "Markdown preview" })
vim.keymap.set("n", "<leader>lv", "<cmd>LspTexlabForward<cr>")

vim.keymap.set({ "n", "i", "v", "t" }, "<C-j>", ":NvimTmuxNavigateDown<CR>")
vim.keymap.set({ "n", "i", "v", "t" }, "<C-h>", ":NvimTmuxNavigateLeft<CR>")
vim.keymap.set({ "n", "i", "v", "t" }, "<C-k>", ":NvimTmuxNavigateUp<CR>")
vim.keymap.set({ "n", "i", "v", "t" }, "<C-l>", ":NvimTmuxNavigateRight<CR>")
vim.keymap.set("t", "<C-j>", [[<C-\><C-n><Cmd>NvimTmuxNavigateDown<CR>]], { silent = true, desc = "Tmux down (terminal)" })
vim.keymap.set("t", "<C-l>", [[<C-\><C-n><Cmd>NvimTmuxNavigateRight<CR>]], { silent = true, desc = "Tmux right (terminal)" })
