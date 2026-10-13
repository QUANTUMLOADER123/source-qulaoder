--!strict
--[[
	MidnightUI
	==============================================================
	A modern, animation-first interface library for Roblox.

		· dark "Midnight" palette by default, 5 presets + full theming
		· masonry grid of groupboxes, top tabs, grouped sidebar pages
		· Toggle · Slider · Dropdown · Textbox · Button · Keybind ·
		  ColorPicker · Label · Divider
		· popups rendered in an overlay (never clipped), live re-theming,
		  search palette, settings panel, notifications, flags & configs
		· zero external assets: every icon is drawn from primitives

	Quick start
	--------------------------------------------------------------
		local Midnight = require(path.to.MidnightUI)

		local Window = Midnight:CreateWindow({
			Title = "Midnight",
			Keybind = "RightControl",
		})

		local Features = Window:Tab("Features")
		local Combat = Features:Page("Combat", { Group = "Main", Icon = "crosshair" })
		local Aimbot = Combat:Groupbox("Aimbot")

		Aimbot:Toggle({ Title = "Enable", Flag = "aim_enabled" })
		Aimbot:Slider({ Title = "FOV", Min = 0, Max = 180, Default = 90, Flag = "aim_fov" })
]]

local Icon = require(script.Icon)
local Maid = require(script.Maid)
local Notification = require(script.Notification)
local Page = require(script.Page)
local Popup = require(script.Popup)
local Section = require(script.Section)
local Signal = require(script.Signal)
local Tab = require(script.Tab)
local Theme = require(script.Theme)
local Util = require(script.Util)
local Window = require(script.Window)

local Midnight = {}

Midnight.Version = "1.0.0"

--// Modules (handy for advanced usage / custom elements) --------------
Midnight.Signal = Signal
Midnight.Maid = Maid
Midnight.Theme = Theme
Midnight.Util = Util
Midnight.Icon = Icon
Midnight.Notification = Notification

--// Element classes ----------------------------------------------------
Midnight.Elements = {
	Button = require(script.Elements.Button),
	ColorPicker = require(script.Elements.ColorPicker),
	Divider = require(script.Elements.Divider),
	Dropdown = require(script.Elements.Dropdown),
	Keybind = require(script.Elements.Keybind),
	Label = require(script.Elements.Label),
	Slider = require(script.Elements.Slider),
	Textbox = require(script.Elements.Textbox),
	Toggle = require(script.Elements.Toggle),
}

Midnight.Window = Window
Midnight.Tab = Tab
Midnight.Page = Page
Midnight.Section = Section
Midnight.Popup = Popup

Midnight.DefaultTheme = Theme.Default
Midnight._windows = {}

--// Window management ----------------------------------------------------

--- Creates a new window.
function Midnight.CreateWindow(self: any, config: any): any
	local window = Window.new(config or {})

	table.insert(self._windows, window)

	local originalDestroy = window.Destroy

	window.Destroy = function(instance: any)
		originalDestroy(instance)

		for index, stored in self._windows do
			if stored == window then
				table.remove(self._windows, index)

				break
			end
		end
	end

	return window
end

--- Alias so both `Midnight:CreateWindow{…}` and `Midnight.new{…}` work.
Midnight.new = Midnight.CreateWindow

--- Every window that is still alive.
function Midnight.GetWindows(self: any): { any }
	local alive = {}

	for _, window in self._windows do
		if not window:IsDestroyed() then
			table.insert(alive, window)
		end
	end

	return alive
end

--- The most recently created window (used by `Midnight:Notify`).
function Midnight.GetWindow(self: any): any
	local windows = self:GetWindows()

	return windows[#windows]
end

--- Destroys every window created through this module.
function Midnight.DestroyAll(self: any)
	local windows = self:GetWindows()

	for index = #windows, 1, -1 do
		windows[index]:Destroy()
	end
end

--// Helpers ----------------------------------------------------------------

--- Shows a notification on the newest window without touching it.
function Midnight.Notify(self: any, props: any): any
	local window = self:GetWindow()

	if window == nil then
		warn("[MidnightUI] Midnight:Notify called before any window was created")

		return nil
	end

	return window:Notify(props)
end

--- Changes the theme of every open window.
function Midnight.SetTheme(self: any, theme: any)
	for _, window in self:GetWindows() do
		window:SetTheme(theme)
	end
end

--- Creates a theme table from a single accent colour.
function Midnight.CreateTheme(self: any, accent: Color3, name: string?): any
	return Theme.fromAccent(accent, name)
end

--- Every available preset name.
function Midnight.GetThemes(self: any): { string }
	return Theme.getPresets()
end

--- Every vector icon name (useful for autocomplete/documentation).
function Midnight.GetIcons(self: any): { string }
	return Icon.list()
end

return Midnight
