local ok, _ = pcall(require, "obsidian")
if not ok then
	return
end

vim.keymap.set("n", "<leader>on", function()
	local title = vim.fn.input("Note title: ")
	vim.cmd("Obsidian new_from_template " .. title .. " note")
end, { desc = "New Obsidian note from 'note' template" })

require("obsidian").setup({
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
	link = { style = "markdown" },
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
	image_name_func = function()
		return string.format("%s-", os.time())
	end,
	frontmatter = {
		enabled = true,
		func = function(note)
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
	},
	templates = { subdir = "templates", date_format = "%Y-%m-%d", time_format = "%H:%M" },
	picker = { name = "telescope.nvim" },
	search = {
		sort_by = "modified",
		sort_reversed = true,
	},
	open_notes_in = "current",
	ui = { enable = false },
	attachments = {
		folder = "03resources/pics",
		img_text_func = function(client, path)
			local p = client:vault_relative_path(path)
			local link = p and p or tostring(path)
			return string.format("![%s](%s)", vim.fs.basename(link), link)
		end,
	},
	legacy_commands = false,
})
