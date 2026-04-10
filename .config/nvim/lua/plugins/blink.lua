return {
	"saghen/blink.cmp",
	version = "v1.7.0",
	config = function()
		require("blink.cmp").setup({
			signature = { enabled = true },
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
				per_filetype = {
					markdown = { "obsidian", "obsidian_new", "obsidian_tags", "lsp", "path", "snippets", "buffer" },
				},
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
