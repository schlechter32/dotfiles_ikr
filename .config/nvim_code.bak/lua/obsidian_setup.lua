-- version = "*",
-- lazy = false,
-- ft = { "markdown", "quarto" },
-- config = function()
local ok, obsidian = pcall(require, "obsidian")
if not ok then
	return
end
require("obsidian").setup({
	-- vim.keymap.set("n", "<leader>on", ":ObsidianNew<CR>"),

	vim.keymap.set("n", "<leader>on", function()
		local title = vim.fn.input("Note title: ")
		vim.cmd("ObsidianNewFromTemplate " .. title .. " note")
	end, { desc = "New Obsidian note from 'note' template" }),
	workspaces = {
		{
			name = "secondBrain",
			path = "~/secondBrain",
			overrides = { notes_subdir = "00inbox" },
		},
	},
	log_level = vim.log.levels.WARN,
	daily_notes = {
		folder = "notes/dailies",
		date_format = "%Y-%m-%d",
		alias_format = "%B %-d, %Y",
	},
	completion = { nvim_cmp = false, min_chars = 2 },
	mappings = {
		["gf"] = {
			action = function()
				return require("obsidian").util.gf_passthrough()
			end,
			opts = { noremap = false, expr = true, buffer = true },
		},
		["<leader>ch"] = {
			action = function()
				return require("obsidian").util.toggle_checkbox()
			end,
			opts = { buffer = true },
		},
	},
	new_notes_location = "notes_subdir",
	note_id_func = function(title)
		local s = ""
		if title then
			s = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
		else
			for _ = 1, 4 do
				s = s .. string.char(math.random(65, 90))
			end
		end
		return os.date("%Y-%m-%d-%S") .. "-" .. s
	end,
	wiki_link_func = function(o)
		if not o.id then
			return string.format("[[%s]]", o.label)
		end
		if o.label ~= o.id then
			return string.format("[[%s|%s]]", o.id, o.label)
		end
		return string.format("[[%s]]", o.id)
	end,
	markdown_link_func = function(o)
		return string.format("[%s](%s)", o.label, o.path)
	end,
	preferred_link_style = "markdown",
	image_name_func = function()
		return string.format("%s-", os.time())
	end,
	disable_frontmatter = false,
	note_frontmatter_func = function(note)
		local out = { date = note.date, state = [[]], due = "", tag = "", topic = "[[]]", version = 1 }
		if note.metadata and not vim.tbl_isempty(note.metadata) then
			for k, v in pairs(note.metadata) do
				out[k] = v
				if k == "version" then
					out[k] = v + 1
				end
			end
		end
		return out
	end,
	templates = { subdir = "templates", date_format = "%Y-%m-%d", time_format = "%H:%M" },
	follow_url_func = function(url)
		vim.fn.jobstart({ "xdg-open", url })
	end,
	use_advanced_uri = false,
	open_app_foreground = false,
	picker = { name = "mini.pick" },
	sort_by = "modified",
	sort_reversed = true,
	open_notes_in = "current",
	ui = { enable = false },
	attachments = {
		img_folder = "03resources/pics",
		img_text_func = function(client, path)
			local p = client:vault_relative_path(path)
			local link = p and p or tostring(path)
			return string.format("![%s](%s)", vim.fs.basename(link), link)
		end,
	},
})
