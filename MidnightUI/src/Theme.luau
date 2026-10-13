--!strict
--[[
	MidnightUI · Theme
	------------------------------------------------------------------
	Single source of truth for the whole visual language:

		· Colors      – every color used by the library
		· Fonts       – Montserrat based type scale (FontFace, with
		                Gotham enum fallback for older clients)
		· Metrics     – paddings, radii, heights, gaps (luxury spacing)
		· Animation   – durations + easing used by the motion system

	A theme is a plain, immutable-in-practice table. Create a custom
	one through `Midnight:CreateTheme{ ... }` or pass a partial table
	to `Midnight:CreateWindow({ Theme = { Colors = { Accent = ... } } })`.
]]

local Theme = {}

--// Types ------------------------------------------------------------

export type FontSpec = {
	Family: string,
	Weight: Enum.FontWeight,
	Style: Enum.FontStyle,
	Fallback: Enum.Font,
}

export type Colors = {
	Window: Color3,
	WindowBorder: Color3,
	WindowShadow: Color3,
	Header: Color3,
	TabActive: Color3,
	TabInactive: Color3,
	TabHover: Color3,
	Sidebar: Color3,
	SidebarGroup: Color3,
	SidebarItem: Color3,
	SidebarItemHover: Color3,
	SidebarItemActive: Color3,
	SidebarItemActiveText: Color3,
	Panel: Color3,
	PanelBorder: Color3,
	PanelHeader: Color3,
	PanelDivider: Color3,
	Element: Color3,
	ElementBorder: Color3,
	ElementHover: Color3,
	ElementActive: Color3,
	Text: Color3,
	TextDim: Color3,
	TextMuted: Color3,
	TextDisabled: Color3,
	Accent: Color3,
	AccentHover: Color3,
	AccentText: Color3,
	AccentSoft: Color3,
	Track: Color3,
	TrackFill: Color3,
	Knob: Color3,
	ToggleOff: Color3,
	ToggleOffBorder: Color3,
	ToggleOn: Color3,
	ToggleOnBorder: Color3,
	ToggleCheck: Color3,
	Popup: Color3,
	PopupBorder: Color3,
	PopupHover: Color3,
	PopupShadow: Color3,
	Scrollbar: Color3,
	ScrollbarHover: Color3,
	Divider: Color3,
	Icon: Color3,
	IconActive: Color3,
	Success: Color3,
	Warning: Color3,
	Danger: Color3,
	Info: Color3,
	Tooltip: Color3,
	TooltipBorder: Color3,
}

export type Fonts = {
	Title: FontSpec,
	Tab: FontSpec,
	Panel: FontSpec,
	Text: FontSpec,
	Bold: FontSpec,
	Small: FontSpec,
	Mono: FontSpec,
}

export type Metrics = {
	Window: {
		Width: number,
		Height: number,
		MinWidth: number,
		MinHeight: number,
		Radius: number,
		HeaderHeight: number,
		SidebarWidth: number,
		Padding: number,
		Gap: number,
		ShadowSize: number,
		ShadowTransparency: number,
	},
	Tabs: {
		TextSize: number,
		Gap: number,
		UnderlineHeight: number,
		IconSize: number,
		IconGap: number,
	},
	Sidebar: {
		Padding: number,
		ItemHeight: number,
		ItemRadius: number,
		ItemGap: number,
		GroupHeight: number,
		GroupGap: number,
		IconSize: number,
		IconGap: number,
		IndicatorWidth: number,
		TextSize: number,
	},
	Panel: {
		Radius: number,
		HeaderHeight: number,
		HeaderTextSize: number,
		Padding: number,
		TopPadding: number,
		BottomPadding: number,
		Gap: number,
		ColumnGap: number,
		RowGap: number,
	},
	Element: {
		ToggleHeight: number,
		ToggleSize: number,
		ToggleRadius: number,
		SliderHeight: number,
		SliderTrackHeight: number,
		SliderKnobSize: number,
		FieldHeight: number,
		FieldBoxHeight: number,
		FieldRadius: number,
		FieldTextSize: number,
		FieldPadding: number,
		LabelHeight: number,
		DividerHeight: number,
		ButtonHeight: number,
		KeybindHeight: number,
		KeybindBadge: number,
		ColorSwatchHeight: number,
		ColorSwatchWidth: number,
		TextSize: number,
		TitleTextSize: number,
		Gap: number,
		BoxPadding: number,
	},
	Popup: {
		Radius: number,
		Padding: number,
		ItemHeight: number,
		ItemTextSize: number,
		MaxHeight: number,
		Offset: number,
		SearchHeight: number,
		ColorPickerSize: number,
		HueHeight: number,
	},
	Notification: {
		Width: number,
		MinHeight: number,
		Radius: number,
		Padding: number,
		Gap: number,
		Margin: number,
		AccentWidth: number,
		IconSize: number,
		TitleTextSize: number,
		TextSize: number,
		Duration: number,
		MaxVisible: number,
	},
	Scrollbar: {
		Thickness: number,
		Padding: number,
	},
	Hud: {
		Height: number,
		Radius: number,
		Padding: number,
		Margin: number,
		IconSize: number,
		IconGap: number,
		TitleTextSize: number,
		RowHeight: number,
		RowTextSize: number,
		BottomPadding: number,
		Gap: number,
	},
}

export type Animation = {
	Instant: number,
	Fast: number,
	Normal: number,
	Slow: number,
	VerySlow: number,
	Easing: Enum.EasingStyle,
	EasingIn: Enum.EasingStyle,
	EasingBounce: Enum.EasingStyle,
	Enabled: boolean,
}

export type Theme = {
	Name: string,
	Colors: Colors,
	Fonts: Fonts,
	Metrics: Metrics,
	Animation: Animation,
}

--// Base theme -------------------------------------------------------

local Base = {
	Name = "Midnight",
	Colors = {
		Window = Color3.fromRGB(23, 23, 26),
		WindowBorder = Color3.fromRGB(38, 38, 42),
		WindowShadow = Color3.fromRGB(0, 0, 0),

		Header = Color3.fromRGB(23, 23, 26),
		TabActive = Color3.fromRGB(238, 240, 243),
		TabInactive = Color3.fromRGB(128, 132, 139),
		TabHover = Color3.fromRGB(198, 202, 210),

		Sidebar = Color3.fromRGB(23, 23, 26),
		SidebarGroup = Color3.fromRGB(110, 110, 118),
		SidebarItem = Color3.fromRGB(186, 186, 193),
		SidebarItemHover = Color3.fromRGB(34, 34, 38),
		SidebarItemActive = Color3.fromRGB(42, 42, 46),
		SidebarItemActiveText = Color3.fromRGB(240, 240, 244),

		Panel = Color3.fromRGB(28, 28, 31),
		PanelBorder = Color3.fromRGB(34, 34, 38),
		PanelHeader = Color3.fromRGB(140, 140, 147),
		PanelDivider = Color3.fromRGB(36, 36, 40),

		Element = Color3.fromRGB(38, 38, 42),
		ElementBorder = Color3.fromRGB(54, 54, 60),
		ElementHover = Color3.fromRGB(46, 46, 51),
		ElementActive = Color3.fromRGB(52, 52, 58),
		ElementDim = Color3.fromRGB(26, 26, 29),
		ElementDimBorder = Color3.fromRGB(42, 42, 47),

		Text = Color3.fromRGB(233, 233, 238),
		TextDim = Color3.fromRGB(168, 168, 176),
		TextMuted = Color3.fromRGB(118, 118, 126),
		TextDisabled = Color3.fromRGB(92, 92, 99),

		Accent = Color3.fromRGB(47, 128, 237),
		AccentHover = Color3.fromRGB(72, 148, 245),
		AccentText = Color3.fromRGB(255, 255, 255),
		AccentSoft = Color3.fromRGB(30, 72, 140),

		Track = Color3.fromRGB(52, 52, 58),
		TrackFill = Color3.fromRGB(47, 128, 237),
		Knob = Color3.fromRGB(240, 241, 245),

		ToggleOff = Color3.fromRGB(30, 30, 34),
		ToggleOffBorder = Color3.fromRGB(62, 62, 68),
		ToggleOn = Color3.fromRGB(47, 128, 237),
		ToggleOnBorder = Color3.fromRGB(47, 128, 237),
		ToggleCheck = Color3.fromRGB(255, 255, 255),

		Popup = Color3.fromRGB(26, 26, 29),
		PopupBorder = Color3.fromRGB(42, 42, 47),
		PopupHover = Color3.fromRGB(38, 38, 42),
		PopupShadow = Color3.fromRGB(0, 0, 0),

		Scrollbar = Color3.fromRGB(62, 62, 68),
		ScrollbarHover = Color3.fromRGB(88, 88, 94),

		Divider = Color3.fromRGB(36, 36, 40),
		Icon = Color3.fromRGB(150, 150, 158),
		IconActive = Color3.fromRGB(47, 128, 237),

		Success = Color3.fromRGB(122, 199, 147),
		Warning = Color3.fromRGB(226, 181, 100),
		Danger = Color3.fromRGB(226, 108, 108),
		Info = Color3.fromRGB(47, 128, 237),

		Tooltip = Color3.fromRGB(30, 30, 34),
		TooltipBorder = Color3.fromRGB(48, 48, 54),
	} :: Colors,

	Fonts = {
		Title = {
			Family = "Montserrat",
			Weight = Enum.FontWeight.Bold,
			Style = Enum.FontStyle.Normal,
			Fallback = Enum.Font.GothamBold,
		},
		Tab = {
			Family = "Montserrat",
			Weight = Enum.FontWeight.SemiBold,
			Style = Enum.FontStyle.Normal,
			Fallback = Enum.Font.GothamSemibold,
		},
		Panel = {
			Family = "Montserrat",
			Weight = Enum.FontWeight.SemiBold,
			Style = Enum.FontStyle.Normal,
			Fallback = Enum.Font.GothamSemibold,
		},
		Text = {
			Family = "Montserrat",
			Weight = Enum.FontWeight.Medium,
			Style = Enum.FontStyle.Normal,
			Fallback = Enum.Font.GothamMedium,
		},
		Bold = {
			Family = "Montserrat",
			Weight = Enum.FontWeight.Bold,
			Style = Enum.FontStyle.Normal,
			Fallback = Enum.Font.GothamBold,
		},
		Small = {
			Family = "Montserrat",
			Weight = Enum.FontWeight.Medium,
			Style = Enum.FontStyle.Normal,
			Fallback = Enum.Font.Gotham,
		},
		Mono = {
			Family = "Roboto Mono",
			Weight = Enum.FontWeight.Medium,
			Style = Enum.FontStyle.Normal,
			Fallback = Enum.Font.Code,
		},
	} :: Fonts,

	Metrics = {
		Window = {
			Width = 800,
			Height = 570,
			MinWidth = 560,
			MinHeight = 400,
			Radius = 12,
			HeaderHeight = 58,
			SidebarWidth = 176,
			Padding = 16,
			Gap = 14,
			ShadowSize = 26,
			ShadowTransparency = 0.55,
		},
		Tabs = {
			TextSize = 13,
			Gap = 28,
			UnderlineHeight = 2,
			IconSize = 17,
			IconGap = 2,
		},
		Sidebar = {
			Padding = 10,
			ItemHeight = 32,
			ItemRadius = 6,
			ItemGap = 0,
			GroupHeight = 28,
			GroupGap = 4,
			IconSize = 16,
			IconGap = 10,
			IndicatorWidth = 2,
			TextSize = 15,
		},
		Panel = {
			Radius = 8,
			HeaderHeight = 26,
			HeaderTextSize = 15,
			Padding = 18,
			TopPadding = 6,
			BottomPadding = 12,
			Gap = 4,
			ColumnGap = 14,
			RowGap = 14,
		},
		Element = {
			ToggleHeight = 24,
			ToggleSize = 16,
			ToggleRadius = 4,
			SliderHeight = 38,
			SliderTrackHeight = 4,
			SliderKnobSize = 14,
			FieldHeight = 46,
			FieldBoxHeight = 28,
			FieldRadius = 4,
			FieldTextSize = 13,
			FieldPadding = 10,
			LabelHeight = 24,
			DividerHeight = 10,
			ButtonHeight = 30,
			KeybindHeight = 22,
			KeybindBadge = 20,
			ColorSwatchHeight = 20,
			ColorSwatchWidth = 15,
			TextSize = 15,
			TitleTextSize = 15,
			Gap = 10,
			BoxPadding = 8,
		},
		Popup = {
			Radius = 6,
			Padding = 4,
			ItemHeight = 26,
			ItemTextSize = 13,
			MaxHeight = 190,
			Offset = 6,
			SearchHeight = 28,
			ColorPickerSize = 168,
			HueHeight = 10,
		},
		Notification = {
			Width = 300,
			MinHeight = 54,
			Radius = 8,
			Padding = 12,
			Gap = 8,
			Margin = 16,
			AccentWidth = 2,
			IconSize = 16,
			TitleTextSize = 13,
			TextSize = 12,
			Duration = 5,
			MaxVisible = 4,
		},
		Scrollbar = {
			Thickness = 4,
			Padding = 2,
		},
		Hud = {
			Height = 38,
			Radius = 9,
			Padding = 12,
			Margin = 12,
			IconSize = 16,
			IconGap = 10,
			TitleTextSize = 14,
			RowHeight = 20,
			RowTextSize = 13,
			BottomPadding = 8,
			Gap = 4,
		},
	} :: Metrics,

	Animation = {
		Instant = 0.08,
		Fast = 0.14,
		Normal = 0.22,
		Slow = 0.34,
		VerySlow = 0.55,
		Easing = Enum.EasingStyle.Quint,
		EasingIn = Enum.EasingStyle.Quart,
		EasingBounce = Enum.EasingStyle.Back,
		Enabled = true,
	} :: Animation,
}

--// Presets ----------------------------------------------------------

--- Alternative dark palette – neutral greys, "Carbon".
local Carbon = {
	Name = "Carbon",
	Colors = {
		Accent = Color3.fromRGB(178, 180, 186),
		AccentHover = Color3.fromRGB(206, 208, 214),
		AccentSoft = Color3.fromRGB(44, 44, 48),
		TrackFill = Color3.fromRGB(178, 180, 186),
		ToggleOn = Color3.fromRGB(186, 188, 194),
		ToggleOnBorder = Color3.fromRGB(206, 208, 214),
		IconActive = Color3.fromRGB(186, 188, 194),
		SidebarItemActiveText = Color3.fromRGB(236, 237, 240),
		Info = Color3.fromRGB(178, 180, 186),
	},
}

--- Violet palette.
local Amethyst = {
	Name = "Amethyst",
	Colors = {
		Accent = Color3.fromRGB(163, 140, 235),
		AccentHover = Color3.fromRGB(185, 166, 245),
		AccentSoft = Color3.fromRGB(46, 40, 66),
		TrackFill = Color3.fromRGB(163, 140, 235),
		ToggleOn = Color3.fromRGB(163, 140, 235),
		ToggleOnBorder = Color3.fromRGB(185, 166, 245),
		IconActive = Color3.fromRGB(163, 140, 235),
		Info = Color3.fromRGB(163, 140, 235),
	},
}

--- Emerald palette.
local Emerald = {
	Name = "Emerald",
	Colors = {
		Accent = Color3.fromRGB(126, 205, 160),
		AccentHover = Color3.fromRGB(154, 224, 184),
		AccentSoft = Color3.fromRGB(32, 56, 44),
		TrackFill = Color3.fromRGB(126, 205, 160),
		ToggleOn = Color3.fromRGB(126, 205, 160),
		ToggleOnBorder = Color3.fromRGB(154, 224, 184),
		IconActive = Color3.fromRGB(126, 205, 160),
		Info = Color3.fromRGB(126, 205, 160),
	},
}

--- Light palette built on the same layout system.
local Daybreak = {
	Name = "Daybreak",
	Colors = {
		Window = Color3.fromRGB(246, 247, 249),
		WindowBorder = Color3.fromRGB(216, 219, 226),
		WindowShadow = Color3.fromRGB(120, 126, 140),
		Header = Color3.fromRGB(240, 241, 245),
		TabActive = Color3.fromRGB(30, 32, 38),
		TabInactive = Color3.fromRGB(120, 124, 134),
		TabHover = Color3.fromRGB(70, 74, 84),
		Sidebar = Color3.fromRGB(240, 241, 245),
		SidebarGroup = Color3.fromRGB(140, 144, 154),
		SidebarItem = Color3.fromRGB(92, 96, 106),
		SidebarItemHover = Color3.fromRGB(228, 230, 236),
		SidebarItemActive = Color3.fromRGB(222, 226, 235),
		SidebarItemActiveText = Color3.fromRGB(26, 28, 34),
		Panel = Color3.fromRGB(252, 252, 253),
		PanelBorder = Color3.fromRGB(220, 223, 230),
		PanelHeader = Color3.fromRGB(48, 51, 58),
		PanelDivider = Color3.fromRGB(228, 231, 238),
		Element = Color3.fromRGB(238, 240, 244),
		ElementBorder = Color3.fromRGB(214, 218, 226),
		ElementHover = Color3.fromRGB(232, 234, 240),
		ElementActive = Color3.fromRGB(226, 229, 236),
		Text = Color3.fromRGB(32, 34, 40),
		TextDim = Color3.fromRGB(104, 108, 118),
		TextMuted = Color3.fromRGB(140, 144, 154),
		TextDisabled = Color3.fromRGB(176, 180, 190),
		Accent = Color3.fromRGB(72, 106, 158),
		AccentHover = Color3.fromRGB(56, 88, 138),
		AccentText = Color3.fromRGB(250, 250, 252),
		AccentSoft = Color3.fromRGB(216, 226, 242),
		Track = Color3.fromRGB(216, 219, 228),
		TrackFill = Color3.fromRGB(72, 106, 158),
		Knob = Color3.fromRGB(252, 252, 253),
		ToggleOff = Color3.fromRGB(238, 240, 244),
		ToggleOffBorder = Color3.fromRGB(206, 210, 220),
		ToggleOn = Color3.fromRGB(72, 106, 158),
		ToggleOnBorder = Color3.fromRGB(60, 92, 140),
		ToggleCheck = Color3.fromRGB(250, 250, 252),
		Popup = Color3.fromRGB(252, 252, 253),
		PopupBorder = Color3.fromRGB(214, 218, 226),
		PopupHover = Color3.fromRGB(232, 235, 242),
		PopupShadow = Color3.fromRGB(120, 126, 140),
		Scrollbar = Color3.fromRGB(202, 206, 216),
		ScrollbarHover = Color3.fromRGB(178, 182, 194),
		Divider = Color3.fromRGB(226, 229, 236),
		Icon = Color3.fromRGB(120, 124, 134),
		IconActive = Color3.fromRGB(72, 106, 158),
		Success = Color3.fromRGB(56, 152, 96),
		Warning = Color3.fromRGB(196, 140, 40),
		Danger = Color3.fromRGB(200, 74, 74),
		Info = Color3.fromRGB(72, 106, 158),
		Tooltip = Color3.fromRGB(38, 40, 46),
		TooltipBorder = Color3.fromRGB(58, 60, 68),
	},
}

--- Named presets. Every preset is a *partial* theme that gets merged
--- on top of `Base`, so a preset only needs to describe what changes.
Theme.Presets = {
	Midnight = Base,
	Carbon = Carbon,
	Amethyst = Amethyst,
	Emerald = Emerald,
	Daybreak = Daybreak,
}

Theme.Default = "Midnight"

--// Helpers ----------------------------------------------------------

-- Only plain tables are merged recursively — Roblox datatypes and EnumItems
-- (which carry a metatable) are copied by reference as opaque values.
local function isPlainTable(value: any): boolean
	return type(value) == "table" and getmetatable(value) == nil
end

--- Recursively merges `overrides` into a copy of `base`.
function Theme.merge(base: any, overrides: any): any
	if not isPlainTable(base) or not isPlainTable(overrides) then
		return overrides
	end

	local result: any = {}

	for key, value in base do
		result[key] = value
	end

	for key, value in overrides do
		local existing = result[key]

		if isPlainTable(existing) and isPlainTable(value) then
			result[key] = Theme.merge(existing, value)
		else
			result[key] = value
		end
	end

	return result
end

--- Resolves a preset name (or a partial theme table) into a full theme.
function Theme.resolve(input: (string | { [string]: any })?): Theme
	local override: any = Base

	if type(input) == "string" then
		override = Theme.Presets[input]

		if override == nil then
			warn(("[MidnightUI] Unknown theme preset %q — falling back to %q"):format(input, Theme.Default))
			override = Base
		end
	elseif isPlainTable(input) then
		override = input
	end

	local resolved: any = Theme.merge(Base, override)

	resolved.Animation.Enabled = true

	return resolved :: Theme
end

--- Returns a list of available preset names.
function Theme.getPresets(): { string }
	local names: { string } = {}

	for name in Theme.Presets do
		table.insert(names, name)
	end

	table.sort(names)

	return names
end

--- Creates a new palette from a single accent color, keeping the rest
--- of the Midnight identity intact. Handy for white-label menus.
function Theme.fromAccent(accent: Color3, name: string?): Theme
	local resolved = Theme.resolve(Base)

	resolved.Name = name or "Custom"
	resolved.Colors.Accent = accent
	resolved.Colors.AccentHover = accent:Lerp(Color3.new(1, 1, 1), 0.18)
	resolved.Colors.AccentSoft = accent:Lerp(Color3.fromRGB(12, 12, 14), 0.72)
	resolved.Colors.AccentText = accent:Lerp(Color3.new(0, 0, 0), 0.82)
	resolved.Colors.TrackFill = accent
	resolved.Colors.ToggleOn = accent
	resolved.Colors.ToggleOnBorder = accent:Lerp(Color3.new(1, 1, 1), 0.16)
	resolved.Colors.IconActive = accent
	resolved.Colors.Info = accent

	return resolved
end

return Theme
