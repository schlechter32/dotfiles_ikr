if vim.g.vscode then
  local vscode = require("vscode")

  vim.keymap.set("n", "<leader>d", function()
    vscode.action("editor.action.showHover")
  end, { desc = "VSCode hover" })

vim.keymap.set("n", "<leader>rn",function()
    vscode.action("editor.action.rename")
  end, { desc = "VSCode rename" })
 
vim.keymap.set("n", "<leader>rr",function()
    vscode.action("editor.action.goToReferences")
  end, { desc = "VSCode rename" })
 
vim.keymap.set("n", "<leader>gd",function()
    vscode.action("editor.action.revealDefinition")
  end, { desc = "VSCode definitions" })

vim.keymap.set("n", "<leader>sg",function()
    vscode.action("workbench.action.quickTextSearch")
  end, { desc = "VSCode search grep" })

vim.keymap.set("n", "<leader>ps",function()
    vscode.action("workbench.action.showAllSymbols")
  end, { desc = "VSCode all symbols" })

vim.keymap.set("n", "<leader>fs",function()
    vscode.action("workbench.action.gotoSymbol")
  end, { desc = "VSCode file symbols" })

vim.keymap.set("n", "<leader>lg",function()
    vscode.action("workbench.view.scm")
  end, { desc = "VSCode source control" })

vim.keymap.set("n", "<leader> ",function()
    vscode.action("workbench.action.quickOpen")
  end, { desc = "VSCode pick files" })

vim.keymap.set("v", "<C-j> ",function()
    vscode.action("editor.action.moveLinesdownAction")
  end, { desc = "VSCode pick files" })

vim.keymap.set("n", "<leader>lv ",function()
    vscode.action("latex-workshop.synctex")
  end, { desc = "VSCode pick files" })

vim.keymap.set("n", "<leader>q",function()
    vscode.action("workbench.action.closeActiveEditor")
  end, { desc = "VSCode close" })

vim.keymap.set("n", "<leader>z",function()
    vim.cmd("write")
    vscode.call("workbench.action.closeActiveEditor")
  end, { desc = "VSCode save close" })
else
vim.keymap.set("n", "<leader>q", ":quit<CR>")
vim.keymap.set("n", "<leader>z", "<cmd>wq<cr>",  { desc = "Save and close Buffer" })
vim.keymap.set("n", "<leader>lv", "<cmd>LspTexlabForward<cr>")
vim.keymap.set("v", "<C-j>", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "<C-k>", ":m '<-2<CR>gv=gv")
vim.keymap.set("n", "<leader> ", ":Pick files<CR>")
vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "LSP: [G]oto [D]efinition" })
vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "LSP: [G]oto [R]eferences" })
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename)
  vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, { desc = "LSP hover/diagnostic float" })
end

