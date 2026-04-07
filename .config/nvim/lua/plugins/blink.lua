return {
	"saghen/blink.cmp",
	version = "v1.7.0",
	config = function()
		require("blink.cmp").setup({
			signature = { enabled = true },
			sources = {
				default = { "lsp", "path", "snippets", "buffer", "obsidian", "obsidian_new", "obsidian_tags" },
			},
			keymap = {
				preset = "enter",
				["<C-K>"] = { "show_signature", "hide_signature", "fallback" },
				["<S-Tab>"] = { "select_prev", "fallback_to_mappings" },
				["<Tab>"] = { "select_next", "fallback_to_mappings" },
			},
		})
	end,
}
