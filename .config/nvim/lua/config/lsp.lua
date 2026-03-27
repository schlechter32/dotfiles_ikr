local util = require("lspconfig.util")

-- Copilot: force telemetry off via settings
vim.lsp.config("copilot", {
	settings = {
		telemetry = {
			telemetryLevel = "off",
		},
	},
})

-- JetLS using your working defaults (configure before enabling)
vim.lsp.config("jetls", {
	cmd = {
		"jetls",
	},
	filetypes = { "julia" },
	root_markers = { "Project.toml" },
})

-- Base server enabling (after configs are defined)
vim.lsp.enable({ "marksman", "lua_ls", "basedpyright", "texlab", "nil_ls", "jetls", "copilot" })

vim.lsp.config("texlab", {
	settings = {
		texlab = {
			auxDirectory = "auxfiles",
			outputDirectory = "build",
			pdfDirectory = "build",
			bibtexFormatter = "texlab",
			build = {
				args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" },
				executable = "latexmk",
				forwardSearchAfter = false,
				onSave = false,
				auxDirectory = "auxfiles",
				outputDirectory = "build",
				pdfDirectory = "build",
			},
			chktex = { onEdit = false, onOpenAndSave = false },
			diagnosticsDelay = 300,
			formatterLineLength = 80,
			forwardSearch = {
				executable = "okular",
				args = { "--unique", "file:%p#src:%l%f" },
			},
			latexFormatter = "latexindent",
			latexindent = { modifyLineBreaks = true },
		},
	},
})

vim.lsp.config("ltext_plus", {
	cmd = { "ltex-ls-plus" },
	autostart = false,
	filetypes = {
		"gitcommit",
		"markdown",
		"org",
		"rst",
		"rnoweb",
		"tex",
		"pandoc",
		"quarto",
		"context",
		"html",
		"xhtml",
		"mail",
		"text",
	},
})

vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			workspace = {
				library = vim.api.nvim_get_runtime_file("", true),
			},
		},
	},
})
