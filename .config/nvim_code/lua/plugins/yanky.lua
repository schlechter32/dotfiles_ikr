return {
	"gbprod/yanky.nvim",
  lazy=false,
	opts = {
		highlight = { timer = 150 },
		textobj = {
			enabled = false,
		},
	},

	keys = {
		{ "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" }, desc = "Put after" },
		{ "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" }, desc = "Put before" },
		{ "gp", "<Plug>(YankyGPutAfter)", mode = { "n", "x" }, desc = "Put after (cursor after)" },
		{ "gP", "<Plug>(YankyGPutBefore)", mode = { "n", "x" }, desc = "Put before (cursor after)" },
		{ "(p", "<Plug>(YankyPreviousEntry)", desc = "Previous yank history entry" },
		{ ")p", "<Plug>(YankyNextEntry)", desc = "Next yank history entry" },
	},
}