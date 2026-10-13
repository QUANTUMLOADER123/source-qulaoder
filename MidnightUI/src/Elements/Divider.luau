--!strict
--[[
	MidnightUI · Divider
	------------------------------------------------------------------
	Hairline separator between groups of elements. With
	`Invisible = true` it becomes pure vertical spacing (used by
	`Section:Gap`).
]]

local Util = require(script.Parent.Parent.Util)

local Element = require(script.Parent.Parent.Element)

local Divider = setmetatable({}, { __index = Element })
Divider.__index = Divider
Divider.Name = "Divider"

export type Props = {
	Height: number?,
	Invisible: boolean?,
	Color: string?,
	Visible: boolean?,
	Order: number?,
	Transparency: number?,
}

function Divider.new(section: any, props: Props?): any
	local options = props or {}
	local theme = section.Theme
	local metrics = theme.Metrics.Element
	local invisible = options.Invisible == true

	local self: any = Element.new({
		Class = Divider,
		Default = false,
		Visible = options.Visible,
		Order = options.Order,
	})

	self.Height = options.Height or metrics.DividerHeight
	self.Instance.Size = UDim2.new(1, 0, 0, self.Height)
	self.Invisible = invisible
	self.ColorKey = options.Color or "Divider"
	self.Transparency = options.Transparency or 0

	local line = nil

	if not invisible then
		line = Instance.new("Frame")

		line.Name = "Line"
		line.AnchorPoint = Vector2.new(0, 0.5)
		line.BackgroundColor3 = theme.Colors[self.ColorKey]
		line.BackgroundTransparency = self.Transparency
		line.BorderSizePixel = 0
		line.Position = UDim2.new(0, 0, 0.5, 0)
		line.Size = UDim2.new(1, 0, 0, 1)

		if self.Height <= 1 then
			line.Size = UDim2.new(1, 0, 1, 0)
			line.Position = UDim2.fromScale(0, 0)
			line.AnchorPoint = Vector2.new(0, 0)
		end

		line.ZIndex = 2
		line.Parent = self.Instance

		self.Line = line
	end

	function self.Refresh()
		if line == nil then
			return
		end

		line.BackgroundColor3 = theme.Colors[self.ColorKey] or theme.Colors.Divider
		line.BackgroundTransparency = if self:IsDisabled() then 1 else self.Transparency
	end

	function self.OnThemeChanged()
		self:Refresh()
	end

	function self.DisabledChanged()
		self:Refresh()
	end

	self:Refresh()

	return self
end

return Divider
