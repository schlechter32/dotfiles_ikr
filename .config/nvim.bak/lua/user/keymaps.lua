local nnoremap = require("user.keymap_utils").nnoremap
local vnoremap = require("user.keymap_utils").vnoremap
local inoremap = require("user.keymap_utils").inoremap
local tnoremap = require("user.keymap_utils").tnoremap
local xnoremap = require("user.keymap_utils").xnoremap
local harpoon_ui = require "harpoon.ui"
local harpoon_mark = require "harpoon.mark"
local opens = require "user.open_functions"
local utils = require "user.utils"
--local neogit = require "neogit"
--local leap = require("leap")
-- local undotree = require("undotree")

local M = {}

--" Resize window with Ctrl-w + hjkl
-- nnoremap ("<C-w>j" ,":resize -5<CR>", {silent=true})
-- nnoremap ("<C-w>k", ":resize +5<CR>")
-- nnoremap( "<C-w>h", ":vertical resize 5<CR>" )
-- nnoremap ("<C-w>l", ":vertical resize -5<CR>")
-- Resize window with Ctrl-w + hjkl, repeatable
vim.api.nvim_set_keymap("n", "<C-w>j", ':<C-u>execute "resize -2" .. v:count1<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<C-w>k", ':<C-u>execute "resize +2" .. v:count1<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap(
  "n",
  "<C-w>h",
  ':<C-u>execute "vertical resize +2" .. v:count1<CR>',
  { noremap = true, silent = true }
)
vim.api.nvim_set_keymap(
  "n",
  "<C-w>l",
  ':<C-u>execute "vertical resize -2" .. v:count1<CR>',
  { noremap = true, silent = true }
)
nnoremap("<leader>i", ":Gen<CR>", { desc = "Ask local llm" })
vnoremap("<leader>i", ":Gen<CR>", { desc = "Ask local llm" })
--nnoremap("<leader>gs", function()
--    require("neogit").open()
-- kj(ij(kl()))-- i
--end, { desc = "Open Neogit" })
--nnoremap("<leader>gc", ":Neogit commit <CR>")
--nnoremap("<leader>gp", ":Neogit pull<CR>")
--nnoremap("<leader>gP", ":Neogit push<CR>")
--nnoremap("<leader>gb", ":Telescope git_branches<CR>")

nnoremap("<leader>a", function()
  -- print "test"
  require("Comment.api").toggle.linewise.current()
end, { desc = "Toggle comment" })
nnoremap("<leader>u", vim.cmd.UndotreeToggle, { desc = "Toggle Undootree" })
--nnoremap("f", leap.leap(),{desc= "Leap forwards"})
-- Maybe insert this if we are running out of shortcuts
-- vim.g.maplocalleader=","
local TERM = os.getenv "TERM"

-- Normal --
-- Disable Space bar since it'll be used as the leader key
nnoremap("<space>", "<nop>")
-- Review process
nnoremap("<leader>ok", ":w<cr>:!mv '%:p' $HOME/secondBrain/05Zettelkasten/<cr>:bd<cr>")
nnoremap("<leader>od", ":!rm '%:p'<cr>:bd<cr>", { desc = "Delete bufferfile" })
-- Obsidian
--
nnoremap("<leader>ot", ":ObsidianTemplate note<CR>")
nnoremap("<leader>on", ":ObsidianNew<CR>")
-- Window +  better kitty navigation
nnoremap("<C-j>", function()
  if vim.fn.exists ":KittyNavigateDown" ~= 0 and TERM == "xterm-kitty" then
    vim.cmd.KittyNavigateDown()
  elseif vim.fn.exists ":NvimTmuxNavigateDown" ~= 0 then
    vim.cmd.NvimTmuxNavigateDown()
  else
    vim.cmd.wincmd "j"
  end
end)
-- Pluto notebook bindings
nnoremap("<leader>pia", ":call pluto#insert_cell_above()<CR>", { desc = "Insert cell above" })
nnoremap("<leader>pib", ":call pluto#insert_cell_below()<CR>", { desc = "Insert cell below" })
nnoremap("<leader>pyc", ":call pluto#yank_cell()<CR>", { desc = "Yank cell" })
nnoremap("<leader>pdc", ":call pluto#delete_cell()<CR>", { desc = "Delete cell" })
nnoremap("<leader>ppa", ":call pluto#paste_cell_above()<CR>", { desc = "Paste cell above" })
nnoremap("<leader>ppb", ":call pluto#paste_cell_below()<CR>", { desc = "Paste cell below" })
nnoremap("<leader>psc", ":call pluto#show_code()<CR>", { desc = "Show code" })
nnoremap("<leader>phc", ":call pluto#hide_code()<CR>", { desc = "Hide code" })
nnoremap("<leader>ptc", ":call pluto#toggle_code()<CR>", { desc = "Toggle code" })

nnoremap("<C-k>", function()
  if vim.fn.exists ":KittyNavigateUp" ~= 0 and TERM == "xterm-kitty" then
    vim.cmd.KittyNavigateUp()
  elseif vim.fn.exists ":NvimTmuxNavigateUp" ~= 0 then
    vim.cmd.NvimTmuxNavigateUp()
  else
    vim.cmd.wincmd "k"
  end
end)

nnoremap("<C-l>", function()
  if vim.fn.exists ":KittyNavigateRight" ~= 0 and TERM == "xterm-kitty" then
    vim.cmd.KittyNavigateRight()
  elseif vim.fn.exists ":NvimTmuxNavigateRight" ~= 0 then
    vim.cmd.NvimTmuxNavigateRight()
  else
    vim.cmd.wincmd "l"
  end
end)

nnoremap("<C-h>", function()
  if vim.fn.exists ":KittyNavigateLeft" ~= 0 and TERM == "xterm-kitty" then
    vim.cmd.KittyNavigateLeft()
  elseif vim.fn.exists ":NvimTmuxNavigateLeft" ~= 0 then
    vim.cmd.NvimTmuxNavigateLeft()
  else
    vim.cmd.wincmd "h"
  end
end)
-- Swap between last two buffers
nnoremap("<leader>'", "<C-^>", { desc = "Switch to last buffer" })
nnoremap("<leader>'", "<tab>", { desc = "Switch to last buffer" })
-- Save with leader key
nnoremap("<leader>w", "<cmd>w<cr>", { silent = false }, { desc = "Save file" })

-- Quit with leader key
nnoremap("<leader>q", "<cmd>q<cr>", { silent = false }, { desc = "Close Buffer" })

-- Save and Quit with leader key
nnoremap("<leader>z", "<cmd>wq<cr>", { silent = false }, { desc = "Save and close Buffer" })

-- Map Oil to <leader>e
nnoremap("<leader>e", function()
  require("oil").toggle_float()
end, { desc = "Open oil floating" })

-- Center buffer while navigating
nnoremap("<C-u>", "<C-u>zz")
nnoremap("<C-f>", "<C-u>zz")
nnoremap("<C-d>", "<C-d>zz")
nnoremap("{", "{zz")
nnoremap("}", "}zz")
nnoremap("N", "Nzz")
nnoremap("n", "nzz")
nnoremap("G", "Gzz")
nnoremap("gg", "ggzz")
nnoremap("<C-i>", "<C-i>zz")
nnoremap("<C-o>", "<C-o>zz")
nnoremap("%", "%zz")
nnoremap("*", "*zz")
nnoremap("#", "#zz")

-- Press 'S' for quick find/replace for the word under the cursor
nnoremap("S", function()
  local cmd = ":%s/<C-r><C-w>/<C-r><C-w>/gI<Left><Left><Left>"
  local keys = vim.api.nvim_replace_termcodes(cmd, true, false, true)
  vim.api.nvim_feedkeys(keys, "n", false)
end)

-- Open Spectre for global find/replace
nnoremap("<leader>S", function()
  require("spectre").toggle()
end, { desc = "Open Spectre global" })

-- Open Spectre for global find/replace for the word under the cursor in normal mode
-- TODO Fix, currently being overriden by Telescope
nnoremap("<leader>sw", function()
  require("spectre").open_visual { select_word = true }
end, { desc = "Search current word" })

-- Press 'H', 'L' to jump to start/end of a line (first/last char)
nnoremap("L", "$")
nnoremap("H", "^")

-- Press 'U' for redo
nnoremap("U", "<C-r>")

-- Turn off highlighted results
nnoremap("<leader>no", "<cmd>noh<cr>")

-- Diagnostics

-- Goto next diagnostic of any severity
nnoremap("]d", function()
  vim.diagnostic.goto_next {}
  vim.api.nvim_feedkeys("zz", "n", false)
end)

-- Goto previous diagnostic of any severity
nnoremap("[d", function()
  vim.diagnostic.goto_prev {}
  vim.api.nvim_feedkeys("zz", "n", false)
end)

-- Goto next error diagnostic
nnoremap("]e", function()
  vim.diagnostic.goto_next { severity = vim.diagnostic.severity.ERROR }
  vim.api.nvim_feedkeys("zz", "n", false)
end)

-- Goto previous error diagnostic
nnoremap("[e", function()
  vim.diagnostic.goto_prev { severity = vim.diagnostic.severity.ERROR }
  vim.api.nvim_feedkeys("zz", "n", false)
end)

-- Goto next warning diagnostic
nnoremap("]w", function()
  vim.diagnostic.goto_next { severity = vim.diagnostic.severity.WARN }
  vim.api.nvim_feedkeys("zz", "n", false)
end)

-- Goto previous warning diagnostic
nnoremap("[w", function()
  vim.diagnostic.goto_prev { severity = vim.diagnostic.severity.WARN }
  vim.api.nvim_feedkeys("zz", "n", false)
end)

nnoremap("<leader>d", function()
  vim.diagnostic.open_float {
    border = "rounded",
  }
end, { desc = "Floating diagnostics" })

-- Place all dignostics into a qflist
nnoremap("<leader>ld", vim.diagnostic.setqflist, { desc = "Quickfix [L]ist [D]iagnostics" })

-- Navigate to next qflist item
nnoremap("<leader>cn", ":cnext<cr>zz")

-- Navigate to previos qflist item
nnoremap("<leader>cp", ":cprevious<cr>zz")

-- Open the qflist
nnoremap("<leader>co", ":copen<cr>zz")

-- Close the qflist
nnoremap("<leader>cc", ":cclose<cr>zz")

-- Map MaximizerToggle (szw/vim-maximizer) to leader-m
nnoremap("<leader>m", ":WindowsMaximize<cr>")
nnoremap("<F3>", ":WindowsMaximize<cr>")

-- Resize split windows to be equal size
nnoremap("<leader>=", "<C-w>=")

-- Press leader f to format
nnoremap("<leader>f", ":Format<cr>")
nnoremap("<leader>lf", ":LspFormat<cr>")

-- Press leader rw to rotate open windows
nnoremap("<leader>rw", ":RotateWindows<cr>", { desc = "[R]otate [W]indows" })

-- Press gx to open the link under the cursor
-- nnoremap("gx", OpenFileInxdg(), { silent = true })
nnoremap("gp", ":lua OpenFileInxdg()<CR>", { silent = true })
-- vim.keymap.set("n",  )

-- nnoremap("gx", function() vim.fn.jobstart(":sil !open <cWORD><cr>") end, { silent = true })
-- TSC autocommand keybind to run TypeScripts tsc
-- nnoremap("<leader>tc", ":TSC<cr>", { desc = "[T]ypeScript [C]ompile" })

-- Harpoon keybinds --
-- Open harpoon ui
nnoremap("<leader>ho", function()
  harpoon_ui.toggle_quick_menu()
end, { desc = "Open Harpoon" })

-- Add current file to harpoon
nnoremap("<leader>ha", function()
  harpoon_mark.add_file()
end, { desc = "Add Harpoon" })

-- Remove current file from harpoon
nnoremap("<leader>hr", function()
  harpoon_mark.rm_file()
end, { desc = "Remove Harpoon" })

-- Remove all files from harpoon
nnoremap("<leader>hc", function()
  harpoon_mark.clear_all()
end, { desc = "Clear all Harpoon" })

-- Quickly jump to harpooned files
nnoremap("<leader>1", function()
  harpoon_ui.nav_file(1)
end, { desc = "Jump to Spear 1" })

nnoremap("<leader>2", function()
  harpoon_ui.nav_file(2)
end, { desc = "Jump to Spear 2" })

nnoremap("<leader>3", function()
  harpoon_ui.nav_file(3)
end, { desc = "Jump to Spear 3" })

nnoremap("<leader>4", function()
  harpoon_ui.nav_file(4)
end, { desc = "Jump to Spear 4" })

nnoremap("<leader>5", function()
  harpoon_ui.nav_file(5)
end, { desc = "Jump to Spear 5" })

nnoremap("<leader>6", function()
  harpoon_ui.nav_file(6)
end, { desc = "Jump to Spear 6" })
-- Git keymaps --
-- nnoremap("<leader>gb", ":Gitsigns toggle_current_line_blame<cr>")
-- nnoremap("<leader>gf", function()
--     local cmd = {
--         "sort",
--         "-u",
--         "<(git diff --name-only --cached)",
--         "<(git diff --name-only)",
--         "<(git diff --name-only --diff-filter=U)",
--     }

--     if not utils.is_git_directory() then
--         vim.notify(
--             "Current project is not a git directory",
--             vim.log.levels.WARN,
--             { title = "Telescope Git Files", git_command = cmd }
--         )
--     else
--         require("telescope.builtin").git_files()
--     end
-- end, { desc = "Search [G]it [F]iles" })

-- Telescope keybinds --
-- nnoremap("<leader>?", require("telescope.builtin").oldfiles, { desc = "[?] Find recently opened files" })
-- nnoremap("<leader>sb", require("telescope.builtin").buffers, { desc = "[S]earch Open [B]uffers" })

-- nnoremap("<leader>sn", function()
--     require("telescope.builtin").find_files({ cwd = "~/secondBrain/05Zettelkasten/" })
-- end, { desc = "[S]earch [N]otes" })

-- nnoremap("<leader>sf", function()
--     require("telescope.builtin").find_files { hidden = true }
-- end, { desc = "[S]earch [F]iles" })

-- nnoremap("<leader>sh", require("telescope.builtin").help_tags, { desc = "[S]earch [H]elp" })
-- nnoremap("<leader>sg", require("telescope.builtin").live_grep, { desc = "[S]earch by [G]rep" })

-- nnoremap("<leader>gn", function()
--     require("telescope.builtin").live_grep({ type_filter="md" })
-- end, { desc = "[G]rep [N]otes" })
-- nnoremap("<leader>sc", function()
--     require("telescope.builtin").commands(require("telescope.themes").get_dropdown {
--         previewer = false,
--     })
-- end, { desc = "[S]earch [C]ommands" })
--
-- nnoremap("<leader>/", function()
--     require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown {
--         previewer = false,
--     })
-- end, { desc = "[/] Fuzzily search in current buffer]" })

-- nnoremap("<leader>ss", function()
--     require("telescope.builtin").spell_suggest(require("telescope.themes").get_dropdown {
--         previewer = false,
--     })
-- end, { desc = "[S]earch [S]pelling suggestions" })

-- LSP Keybinds (exports a function to be used in ../../after/plugin/lsp.lua b/c we need a reference to the current buffer) --
M.map_lsp_keybinds = function(buffer_number)
  nnoremap("<leader>rn", vim.lsp.buf.rename, { desc = "LSP: [R]e[n]ame", buffer = buffer_number })
  nnoremap("<leader>ca", vim.lsp.buf.code_action, { desc = "LSP: [C]ode [A]ction", buffer = buffer_number })

  -- nnoremap("gd", vim.lsp.buf.definition, { desc = "LSP: [G]oto [D]efinition", buffer = buffer_number })

  -- Telescope LSP keybinds --
  -- nnoremap(
  --     "gr",
  --     require("telescope.builtin").lsp_references,
  --     { desc = "LSP: [G]oto [R]eferences", buffer = buffer_number }
  -- )
  --
  -- nnoremap(
  --     "gi",
  --     require("telescope.builtin").lsp_implementations,
  --     { desc = "LSP: [G]oto [I]mplementation", buffer = buffer_number }
  -- )
  --
  -- nnoremap(
  --     "<leader>bs",
  --     require("telescope.builtin").lsp_document_symbols,
  --     { desc = "LSP: [B]uffer [S]ymbols", buffer = buffer_number }
  -- )
  --
  -- nnoremap(
  --     "<leader>ps",
  --     require("telescope.builtin").lsp_workspace_symbols,
  --     { desc = "LSP: [P]roject [S]ymbols", buffer = buffer_number }
  -- )

  -- See `:help K` for why this keymap
  nnoremap("K", vim.lsp.buf.hover, { desc = "LSP: Hover Documentation", buffer = buffer_number })
  nnoremap("<leader>k", vim.lsp.buf.signature_help, { desc = "LSP: Signature Documentation", buffer = buffer_number })
  inoremap("<C-k>", vim.lsp.buf.signature_help, { desc = "LSP: Signature Documentation", buffer = buffer_number })

  -- Lesser used LSP functionality
  -- nnoremap("gD", vim.lsp.buf.declaration, { desc = "LSP: [G]oto [D]eclaration", buffer = buffer_number })
  -- nnoremap("td", vim.lsp.buf.type_definition, { desc = "LSP: [T]ype [D]efinition", buffer = buffer_number })
end

-- Symbol Outline keybind
nnoremap("<leader>so", ":SymbolsOutline<cr>")

-- Open Copilot panel
-- nnoremap("<leader>oc", function()
--   require("copilot.panel").open({})
-- end, { desc = "[O]pen [C]opilot panel" })

-- nvim-ufo keybinds
-- nnoremap("zR", require("ufo").openAllFolds)
-- nnoremap("zM", require("ufo").closeAllFolds)

-- Insert --
-- Map jj to <esc>
inoremap("jj", "<esc>")

-- Visual --
-- Disable Space bar since it'll be used as the leader key
vnoremap("<space>", "<nop>")

-- Press 'H', 'L' to jump to start/end of a line (first/last char)
vnoremap("L", "$<left>")
vnoremap("H", "^")
vnoremap(
  "<leader>a",
  "<ESC><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>",
  { desc = "Togle comment" }
)

-- Paste without losing the contents of the register
xnoremap("<leader>p", '"_dP')
-- Yank to system clipbord
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])
-- Delete to void register
vim.keymap.set({ "v" }, "<leader>d", [["_d]])
-- Move selected text up/down in visual mode
vnoremap("<C-j>", ":m '>+1<CR>gv=gv")
vnoremap("<C-k>", ":m '<-2<CR>gv=gv")
-- vim.keymap.set("v", "<D-j>", ":m '>+1<CR>gv=gv")
-- vim.keymap.set("v", "<D-k>", ":m '<-2<CR>gv=gv")
-- vim.keymap.set("v", "˚", ":m '<-2<CR>gv=gv") -- Alt-k
-- vim.keymap.set("v", "∆", ":m '>+1<CR>gv=gv") -- Alt-j

-- Reselect the last visual selection
xnoremap("<<", function()
  vim.cmd "normal! <<"
  vim.cmd "normal! gv"
end)

xnoremap(">>", function()
  vim.cmd "normal! >>"
  vim.cmd "normal! gv"
end)

-- Terminal --
-- Enter normal mode while in a terminal
-- tnoremap("<esc>", [[<C-\><C-n>]])
-- tnoremap("jj", [[<C-\><C-n>]])

-- Window navigation from terminal
tnoremap("<C-h>", [[<Cmd>wincmd h<CR>]])
tnoremap("<C-j>", [[<Cmd>wincmd j<CR>]])
tnoremap("<C-k>", [[<Cmd>wincmd k<CR>]])
tnoremap("<C-l>", [[<Cmd>wincmd l<CR>]])

-- Reenable default <space> functionality to prevent input delay
tnoremap("<space>", "<space>")

inoremap("<C-l>", "<c-g>u<Esc>[s1z=`]a<c-g>u")
-- DAP remaps
nnoremap("<leader>tb", "<cmd>DapToggleBreakpoint <CR>")

-- nnoremap("<leader>rt", "<cmd>DapToggleBreakpoint <CR>")

-- nnoremap("<C-n>", "tabnext<cr>")
-- nnoremap("<C-p>", "tabprevious<cr>")
nnoremap("<C-n>", "<cmd>tabprevious<cr>")
nnoremap("<C-p>", "<cmd>tabnext<cr>")
return M
