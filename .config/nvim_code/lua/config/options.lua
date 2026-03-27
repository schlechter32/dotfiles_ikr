-- General UI and editing options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.conceallevel = 2
vim.opt.mouse = "a"
vim.opt.guicursor = {
	"n-v:blck",
	"i-c-ve:ver25",
	"r-cr:hor20",
	"o:hor50",
	"a:blinkwait700-blinkoff400-blinkon250",
	"sm:block-blinkwait175-blinkoff150-blinkon175",
}
vim.opt.termguicolors = true
vim.opt.updatetime = 200
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.shortmess:append("sS") -- suppress search count [x/y] and wrap messages (avoids VSCode output panel)
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.wrap = true
vim.o.signcolumn = "yes"
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true
vim.opt.swapfile = false
vim.o.winborder = "rounded"
vim.opt.clipboard = "unnamed,unnamedplus"
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.undofile = true
vim.opt.smartindent = true
vim.cmd([[set completeopt+=menuone,noselect,popup]])

-- GitHub Copilot: disable telemetry
vim.g.copilot_disable_telemetry = 1
vim.env.COPILOT_TELEMETRY_OPTOUT = "1"
vim.g.mapleader = " "
vim.g.maplocalleader = " "
