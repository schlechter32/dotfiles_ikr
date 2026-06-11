--=============================
-- WezTerm Configuration
--=============================
local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder and wezterm.config_builder() or {}

--=============================
-- Backend / Performance
--=============================
-- config.enable_wayland = true
-- config.enable_kitty_graphics = true
config.max_fps = 120
-- config.warn_about
config.warn_about_missing_glyphs = false

--=============================
-- Color Schemes
--=============================
local Light_scheme = require("cyberdream-light")
local Dark_scheme = require("cyberdream")
-- local Dark_scheme = require("tokyonight_moon")

config.color_schemes = {
	mydark = Dark_scheme,
	mylight = Light_scheme,
}
config.color_scheme = "mydark"

wezterm.on("toggle-dark-mode", function(window)
	local overrides = window:get_config_overrides() or {}
	overrides.color_scheme = (overrides.color_scheme == "mydark") and "mylight" or "mydark"
	window:set_config_overrides(overrides)
end)

--=============================
-- Fonts
--=============================
config.font = wezterm.font_with_fallback({
	{ family = "MonoLisa script", scale = 1.15 },
	{ family = "JetbrainsMono NerdFont", scale = 1.15 },
	{ family = "CaskaydiaCove Nerd Font", scale = 1.2 },
})

--=============================
-- Window
--=============================
config.window_background_opacity = 0.95
config.macos_window_background_blur = 40
config.window_padding = { left = 8, right = 3, top = 0, bottom = 1 }
config.window_decorations = "RESIZE"
config.window_close_confirmation = "AlwaysPrompt"
config.scrollback_lines = 30000
config.default_workspace = "home"
config.inactive_pane_hsb = { saturation = 0.8, brightness = 0.8 }

-- Tab bar re-enabled — wezterm is the only multiplexer now.
config.enable_tab_bar = true

--=============================
-- SSH host picker
--=============================
local ssh_favorites = {
	"agent@netserv1",
}

local function ssh_choices()
	local choices = {}
	local seen = {}

	for _, entry in ipairs(ssh_favorites) do
		seen[entry] = true
		table.insert(choices, { label = entry, id = entry })
	end

	local home = os.getenv("HOME") or ""
	local f = io.open(home .. "/.ssh/config", "r")
	if f then
		for line in f:lines() do
			local hosts = line:match("^Host%s+(.+)$")
			if hosts then
				for host in hosts:gmatch("%S+") do
					if not host:match("[*?]")
						and host ~= "github.com"
						and not host:match("%.devpod$")
						and not seen[host] then
						seen[host] = true
						table.insert(choices, { label = host, id = host })
					end
				end
			end
		end
		f:close()
	end

	return choices
end

--=============================
-- Keyboard
--=============================
config.send_composed_key_when_right_alt_is_pressed = true
config.leader = { key = "b", mods = "CTRL", timeout_milliseconds = 1000 }

config.keys = {
	-- Pane management
	{ key = "b", mods = "LEADER", action = act.ActivateCopyMode },
	{ key = "s", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "v", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
	{ key = "q", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
	{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
	{ key = "x", mods = "LEADER", action = act.RotatePanes("Clockwise") },

	-- Resize & move mode
	{ key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },
	{ key = "m", mods = "LEADER", action = act.ActivateKeyTable({ name = "move_tab", one_shot = false }) },

	-- Tabs
	{ key = "n", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "[", mods = "LEADER", action = act.ActivateTabRelative(-1) },
	{ key = "]", mods = "LEADER", action = act.ActivateTabRelative(1) },
	{ key = "t", mods = "LEADER", action = act.ShowTabNavigator },

	-- Rename tab
	{
		key = "e",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = wezterm.format({
				{ Attribute = { Intensity = "Bold" } },
				{ Foreground = { Color = "#a6e3a1" } },
				{ Text = " Rename tab: " },
			}),
			action = wezterm.action_callback(function(window, _, line)
				if line then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},
	-- Rename tab
	{
		key = "E",
		mods = "CTRL|SHIFT",
		action = act.PromptInputLine({
			description = wezterm.format({
				{ Attribute = { Intensity = "Bold" } },
				{ Foreground = { Color = "#a6e3a1" } },
				{ Text = " Rename tab: " },
			}),
			action = wezterm.action_callback(function(window, _, line)
				if line then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},

	-- Disable default ALT+Enter behavior
	{ key = "Enter", mods = "ALT", action = wezterm.action.DisableDefaultAssignment },

	-- Alt+h/l (and Alt+j/k as a synonym) cycle tabs without the leader.
	{ key = "h", mods = "ALT", action = act.ActivateTabRelative(-1) },
	{ key = "l", mods = "ALT", action = act.ActivateTabRelative(1) },
	{ key = "k", mods = "ALT", action = act.ActivateTabRelative(-1) },
	{ key = "j", mods = "ALT", action = act.ActivateTabRelative(1) },

	-- SUPER+t / CTRL+SHIFT+t use wezterm's default new-tab.

	-- SUPER+s: fuzzy-pick a host from ~/.ssh/config, SSH + tmux attach.
	{
		key = "s",
		mods = "SUPER",
		action = act.InputSelector({
			title = " SSH + tmux attach",
			choices = ssh_choices(),
			fuzzy = true,
			fuzzy_description = "Pick host: ",
			action = wezterm.action_callback(function(window, _pane, id)
				if not id then return end
				local user, host = id:match("^([^@]+)@(.+)$")
				if not host then host = id end
				local label = user and (user:sub(1, 1) .. "@" .. host) or host
				local home = os.getenv("HOME")
				local ish = home .. "/localapps/bin/ish"
				local path = home .. "/.local/bin:" .. home .. "/localapps/bin:"
					.. (os.getenv("PATH") or "/usr/local/bin:/usr/bin:/bin")
				local tab, _, _ = window:mux_window():spawn_tab({
					args = { ish, "-t", id, "tmux new-session -A" },
					set_environment_variables = { PATH = path },
				})
				if tab then tab:set_title(label) end
			end),
		}),
	},

	-- SUPER+Shift+S: free-text ssh, no tmux. For arbitrary hosts not in the config.
	{
		key = "S",
		mods = "SUPER|SHIFT",
		action = act.PromptInputLine({
			description = wezterm.format({
				{ Attribute = { Intensity = "Bold" } },
				{ Foreground = { Color = "#a6e3a1" } },
				{ Text = " SSH: [user@]host " },
			}),
			action = wezterm.action_callback(function(window, _pane, line)
				if not line or line == "" then return end
				local user, host = line:match("^([^@]+)@(.+)$")
				if not host then host = line end
				local label = user and (user:sub(1, 1) .. "@" .. host) or host
				local home = os.getenv("HOME")
				local ish = home .. "/localapps/bin/ish"
				local path = home .. "/.local/bin:" .. home .. "/localapps/bin:"
					.. (os.getenv("PATH") or "/usr/local/bin:/usr/bin:/bin")
				local tab, _, _ = window:mux_window():spawn_tab({
					args = { ish, line },
					set_environment_variables = { PATH = path },
				})
				if tab then tab:set_title(label) end
			end),
		}),
	},

	-- Toggle dark/light
	{ key = "Q", mods = "CTRL", action = act.EmitEvent("toggle-dark-mode") },
}

-- Leader+[1–9] → activate tab
for i = 1, 9 do
	table.insert(config.keys, {
		key = tostring(i),
		mods = "LEADER",
		action = act.ActivateTab(i - 1),
	})
	-- Alt+[1–9] → activate tab (no leader needed)
	table.insert(config.keys, {
		key = tostring(i),
		mods = "ALT",
		action = act.ActivateTab(i - 1),
	})
end

--=============================
-- Key Tables
--=============================
config.key_tables = {
	resize_pane = {
		{ key = "h", action = act.AdjustPaneSize({ "Left", 1 }) },
		{ key = "j", action = act.AdjustPaneSize({ "Down", 1 }) },
		{ key = "k", action = act.AdjustPaneSize({ "Up", 1 }) },
		{ key = "l", action = act.AdjustPaneSize({ "Right", 1 }) },
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "Enter", action = "PopKeyTable" },
	},
	move_tab = {
		{ key = "h", action = act.MoveTabRelative(-1) },
		{ key = "j", action = act.MoveTabRelative(-1) },
		{ key = "k", action = act.MoveTabRelative(1) },
		{ key = "l", action = act.MoveTabRelative(1) },
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "Enter", action = "PopKeyTable" },
	},
}

--=============================
-- Tabs / UI
--=============================
config.use_fancy_tab_bar = false
config.status_update_interval = 1000
config.colors = {
	tab_bar = {
		-- Tab bar uses Catppuccin Mocha for consistency with the right-status.
		background         = "#181825", -- mantle
		active_tab         = { bg_color = "#a6e3a1", fg_color = "#1e1e2e", intensity = "Bold" },                 -- green on base
		inactive_tab       = { bg_color = "#181825", fg_color = "#6c7086" },                                      -- overlay0 on mantle
		inactive_tab_hover = { bg_color = "#313244", fg_color = "#cdd6f4", italic = true },                       -- surface0 + text
		new_tab            = { bg_color = "#181825", fg_color = "#6c7086" },
		new_tab_hover      = { bg_color = "#313244", fg_color = "#cdd6f4", italic = true },
	},
}

-- Format tabs as "<index>: <title>" (1-based) so tab labels are scannable.
wezterm.on("format-tab-title", function(tab, _tabs, _panes, _config, _hover, _max_width)
	local title = tab.tab_title
	if title == nil or title == "" then
		title = tab.active_pane.title or ""
	end
	return string.format(" %d: %s ", tab.tab_index + 1, title)
end)

-- Claude session limits. Two caches feed this, both stamped with `ts` (unix s):
--   ~/.claude/rate-cache.json  — written by the Claude Code statusLine from API
--       response headers; exact, but only fresh during active Claude sessions.
--   ~/.claude/usage-poll.json  — written by nbin/claude-usage-poll.py from the
--       OAuth usage endpoint (~hourly, self-throttled); covers idle periods.
-- Whichever was written most recently wins.
local function read_usage_cache(path)
	local f = io.open(path, "r")
	if not f then return nil end
	local raw = f:read("*a")
	f:close()
	local ok, d = pcall(wezterm.json_parse, raw)
	if not ok or type(d) ~= "table" then return nil end
	-- Usable only if it carries real percentages (a poll cache that has only
	-- ever seen 429s has none).
	if d.r5 == nil or d.r7 == nil then return nil end
	return d
end

local function claude_usage()
	local home = os.getenv("HOME") or ""
	local a = read_usage_cache(home .. "/.claude/rate-cache.json")
	local b = read_usage_cache(home .. "/.claude/usage-poll.json")
	local d
	if a and b then
		d = (tonumber(b.ts) or 0) > (tonumber(a.ts) or 0) and b or a
	else
		d = a or b
	end
	if not d then return nil end

	local now = os.time()
	-- If the window's reset time has already passed since the cache was
	-- written, the limit has rolled over → report 0 instead of a stale value.
	-- resets_at is unix-epoch seconds (string or number); non-numeric → skip.
	local function pct(value, resets_at)
		local v = tonumber(value) or 0
		local r = tonumber(resets_at)
		if r and now >= r then return 0 end
		return v
	end

	return pct(d.r5, d.r5_resets_at), pct(d.r7, d.r7_resets_at)
end

-- Opportunistically refresh the poll cache while WezTerm is open. The poller
-- self-throttles (~1 call/hour, honours server retry-after); we additionally
-- gate here so we never spawn a process more than once a minute, and only when
-- the poller would actually do something.
local last_poll_spawn = 0
local function maybe_spawn_poller()
	local t = os.time()
	if t - last_poll_spawn < 60 then return end
	local home = os.getenv("HOME") or ""
	local f = io.open(home .. "/.claude/usage-poll.json", "r")
	if f then
		local ok, d = pcall(wezterm.json_parse, f:read("*a"))
		f:close()
		if ok and type(d) == "table" then
			local na = tonumber(d.next_allowed_at)
			if na and t < na then return end -- not due yet
		end
	end
	last_poll_spawn = t
	-- background_child_process requires {args={...}} but is finicky in older builds;
	-- io.popen with & is simpler and guaranteed to work.
	io.popen("python3 " .. home .. "/nbin/claude-usage-poll.py &")
end

-- Threshold colors (Catppuccin Mocha), matching the statusline script.
local function usage_color(p)
	if p >= 80 then return "#f38ba8" end -- red
	if p >= 50 then return "#f9e2af" end -- yellow
	return "#a6e3a1" -- green
end

wezterm.on("update-right-status", function(window)
	maybe_spawn_poller()

	local leader = window:leader_is_active() and "󰘳  " or ""

	local batt = ""
	for _, b in ipairs(wezterm.battery_info() or {}) do
		batt = string.format(" %d%%  ", math.floor((b.state_of_charge or 0) * 100 + 0.5))
		break
	end

	local week = wezterm.strftime("W%V  ")
	local time = wezterm.strftime("%a %d.%m %H:%M")

	local segments = {}
	local r5, r7 = claude_usage()
	if r5 then
		table.insert(segments, { Foreground = { Color = "#a6d189" } })
		table.insert(segments, { Text = "󰚩 " })
		table.insert(segments, { Foreground = { Color = usage_color(r5) } })
		table.insert(segments, { Text = string.format("5h %d%%", r5) })
		table.insert(segments, { Foreground = { Color = "#6c7086" } })
		table.insert(segments, { Text = " · " })
		table.insert(segments, { Foreground = { Color = usage_color(r7) } })
		table.insert(segments, { Text = string.format("7d %d%%", r7) })
		table.insert(segments, { Foreground = { Color = "#6c7086" } })
		table.insert(segments, { Text = "  │  " })
	end

	table.insert(segments, { Foreground = { Color = "#a6d189" } })
	table.insert(segments, { Text = leader .. batt .. week .. time .. " " })

	window:set_right_status(wezterm.format(segments))
end)
-- wezterm.on("update-right-status", function(window)
-- 	local text = window:leader_is_active() and "󰘳  " or ""
-- 	window:set_right_status(wezterm.format({
-- 		{ Foreground = { Color = "#a6d189" } },
-- 		{ Text = text },
-- 	}))
-- end)
--=============================
-- Default shell
--=============================
config.default_prog = { "zsh" }

return config
