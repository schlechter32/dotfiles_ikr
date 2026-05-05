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
			description = "Enter new tab name",
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
			description = "Enter new tab name",
			action = wezterm.action_callback(function(window, _, line)
				if line then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},

	-- Disable default ALT+Enter behavior
	{ key = "Enter", mods = "ALT", action = wezterm.action.DisableDefaultAssignment },

	-- SUPER+t / CTRL+SHIFT+t use wezterm's default new-tab.

	-- SUPER+s: prompt for `[user@]host`, open a new tab that SSH's there via
	-- the `ish` wrapper and attaches to whatever tmux session is running.
	-- Tab title is set to `<u>@<host>` so multiple tabs stay readable.
	{
		key = "s",
		mods = "SUPER",
		action = act.PromptInputLine({
			description = "ssh+tmux: enter [user@]host",
			action = wezterm.action_callback(function(window, _pane, line)
				if not line or line == "" then return end
				local user, host = line:match("^([^@]+)@(.+)$")
				if not host then host = line end
				local label = user and (user:sub(1, 1) .. "@" .. host) or host
				local ish = os.getenv("HOME") .. "/localapps/bin/ish"
				local tab, _, _ = window:mux_window():spawn_tab({
					args = { ish, "-t", line, "tmux attach" },
				})
				if tab then tab:set_title(label) end
			end),
		}),
	},

	-- SUPER+Shift+S: same prompt, but just ssh -- no tmux attach. Useful
	-- when the remote has no live tmux session yet, or you want a one-off
	-- shell.
	{
		key = "S",
		mods = "SUPER|SHIFT",
		action = act.PromptInputLine({
			description = "ssh: enter [user@]host",
			action = wezterm.action_callback(function(window, _pane, line)
				if not line or line == "" then return end
				local user, host = line:match("^([^@]+)@(.+)$")
				if not host then host = line end
				local label = user and (user:sub(1, 1) .. "@" .. host) or host
				local ish = os.getenv("HOME") .. "/localapps/bin/ish"
				local tab, _, _ = window:mux_window():spawn_tab({
					args = { ish, line },
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

wezterm.on("update-right-status", function(window)
	local leader = window:leader_is_active() and "󰘳  " or ""

	local batt = ""
	for _, b in ipairs(wezterm.battery_info() or {}) do
		batt = string.format(" %d%%  ", math.floor((b.state_of_charge or 0) * 100 + 0.5))
		break
	end

	local week = wezterm.strftime("W%V  ")
	local time = wezterm.strftime("%a %d.%m %H:%M")

	window:set_right_status(wezterm.format({
		{ Foreground = { Color = "#a6d189" } },
		{ Text = leader .. batt .. week .. time .. " " },
	}))
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
