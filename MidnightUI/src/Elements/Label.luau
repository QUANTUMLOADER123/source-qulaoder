--!strict
--[[
	MidnightUI · Label
	------------------------------------------------------------------
	Non-interactive text row. Use it for hints, section captions and
	paragraphs (`Wrapped = true`).

	Wrapped labels need an explicit `Height` because the library uses
	deterministic height accounting instead of reading back layout.
]]

local Util = require(script.Parent.Parent.Util)

local Element = require(script.Parent.Parent.Element)

local Label = setmetatable({}, { __index = Element })
Label.__index = Label
Label.Name = "Label"

export type Props = {
	Text: string?,
	Title: string?,
	Height: number?,
	TextSize: number?,
	Color: string?,
	Align: ("Left" | "Center" | "Right")?,
	Wrapped: boolean?,
	Bold: boolean?,
	Indent: number?,
	Dim: boolean?,
	Visible: boolean?,
	Order: number?,
}

function Label.new(section: any, props: Props?): any
	local options = props or {}
	local theme = section.Theme
	local metrics = theme.Metrics.Element
	local text = options.Text or options.Title or ""
	local wrapped = options.Wrapped == true

	local self: any = Element.new({
		Class = Label,
		Title = options.Title,
		Default = text,
		Visible = options.Visible,
		Order = options.Order,
	})

	self.Height = options.Height or (wrapped and 36 or metrics.LabelHeight)
	self.Instance.Size = UDim2.new(1, 0, 0, self.Height)

	local label = Instance.new("TextLabel")

	label.Name = "Text"
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(options.Indent or 0, 0)
	label.Size = UDim2.new(1, -(options.Indent or 0), 1, 0)
	label.Text = text
	label.TextColor3 = theme.Colors.TextDim
	label.TextSize = options.TextSize or metrics.TextSize
	label.TextWrapped = wrapped
	label.TextYAlignment = if wrapped then Enum.TextYAlignment.Top else Enum.TextYAlignment.Center
	label.TextXAlignment = if options.Align == "Center"
		then Enum.TextXAlignment.Center
		elseif options.Align == "Right" then Enum.TextXAlignment.Right
		else Enum.TextXAlignment.Left

	label.ZIndex = 2
	label.Parent = self.Instance

	Util.setFont(label, if options.Bold == true then theme.Fonts.Bold else theme.Fonts.Small)

	self.Label = label
	self.ColorKey = options.Color or (if options.Dim == true then "TextMuted" else "TextDim")

	function self.Refresh()
		local color = theme.Colors[self.ColorKey] or theme.Colors.TextDim
		local disabled = self:IsDisabled()

		label.TextColor3 = if disabled then theme.Colors.TextDisabled else color
	end

	function self.OnThemeChanged()
		Util.setFont(label, if options.Bold == true then theme.Fonts.Bold else theme.Fonts.Small)
		label.TextSize = options.TextSize or metrics.TextSize

		self:Refresh()
	end

	function self.DisabledChanged()
		self:Refresh()
	end

	--// Public API -------------------------------------------------------
	function self.SetText(value: string)
		self.Value = value
		label.Text = value
	end

	function self.GetText(): string
		return label.Text
	end

	function self.SetColor(colorKey: string)
		self.ColorKey = colorKey

		self:Refresh()
	end

	self:Refresh()

	return self
end

return Label
