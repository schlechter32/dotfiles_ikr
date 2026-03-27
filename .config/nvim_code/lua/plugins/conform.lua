return {
	"stevearc/conform.nvim",
	opts = {

		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		notify_on_error = true,
		format_after_save = {
			async = true,
			timeout_ms = 500,
			lsp_fallback = true,
		},
		formatters_by_ft = {
			lua = { "stylua" },
			julia = { "runic" },
			python = { "black" },
			latex = { "tex-fmt" },
			tex = { "tex-fmt" },
			markdown = { "pymarkdownlnt" },
			bash = { "beautysh" },
			sh = { "beautysh" },
			nix = { "nixfmt", "alejandra", stop_after_first = true },
			go = { "gofmt" },
		},
	},
}