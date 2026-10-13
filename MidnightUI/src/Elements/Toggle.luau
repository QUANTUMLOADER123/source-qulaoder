--!strict
--[[
	MidnightUI · Toggle
	------------------------------------------------------------------
	The square checkbox used for every "Enable" row on the screenshots.

	Visual anatomy
		· 16x16 rounded square (radius 3) with a hairline border
		· check glyph that pops in with a Back ease when turned on
		· label vertically centred on the right of the box
]]

local Icon = require(script.Parent.Parent.Icon)
local Util = require(script.Parent.Parent.Util)

local Element = require(script.Parent.Parent.Element)

local Toggle = setmetatable({}, { __index = Element })
Toggle.__index = Toggle
Toggle.Name = "Toggle"

export type Props = {
	Title: string?,
	Default: boolean?,
	Flag: string?,
	Callback: ((value: boolean) -> ())?,
	Tooltip: string?,
	Visible: boolean?,
	Disabled: boolean?,
	BoxSize: number?,
	Ripple: boolean?,
	Order: number?,
}

function Toggle.new(section: any, props: Props?): any
	local options = props or {}
	local theme = section.Theme
	local metrics = theme.Metrics.Element

	local self: any = Element.new({
		Class = Toggle,
		Title = options.Title,
		Tooltip = options.Tooltip,
		Flag = options.Flag,
		Default = options.Default == true,
		Callback = options.Callback,
		Visible = options.Visible,
		Disabled = options.Disabled,
		Order = options.Order,
	})

	local boxSize = options.BoxSize or metrics.ToggleSize

	self.Height = math.max(metrics.ToggleHeight, boxSize)
	self.Instance.Size = UDim2.new(1, 0, 0, self.Height)

	--// Checkbox ------------------------------------------------------
	local box = Instance.new("Frame")

	box.Name = "Box"
	box.AnchorPoint = Vector2.new(0, 0.5)
	box.BackgroundColor3 = theme.Colors.ToggleOff
	box.BorderSizePixel = 0
	box.Position = UDim2.new(0, 0, 0.5, 0)
	box.Size = UDim2.fromOffset(boxSize, boxSize)
	box.ZIndex = 2
	box.Parent = self.Instance

	Util.addCorner(box, metrics.ToggleRadius)

	local boxStroke = Util.addStroke(box, theme.Colors.ToggleOffBorder, 1)

	local boxScale = Instance.new("UIScale")

	boxScale.Parent = box

	--// Check glyph ---------------------------------------------------
	local check = Icon.create("check", {
		Size = math.floor(boxSize * 0.66),
		Color = theme.Colors.ToggleCheck,
		Parent = box,
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Name = "Check",
		ZIndex = 3,
	})

	local checkScale = Instance.new("UIScale")

	checkScale.Scale = self.Value and 1 or 0
	checkScale.Parent = check

	--// Label ---------------------------------------------------------
	local labelOffset = boxSize + metrics.Gap

	local label = Instance.new("TextLabel")

	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(labelOffset, 0)
	label.Size = UDim2.new(1, -labelOffset, 1, 0)
	label.Text = options.Title or ""
	label.TextColor3 = theme.Colors.Text
	label.TextSize = metrics.TitleTextSize
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.ZIndex = 2
	label.Parent = self.Instance

	Util.setFont(label, theme.Fonts.Text)

	self.Box = box
	self.Check = check
	self.Label = label
	self._boxScale = boxScale
	self._checkScale = checkScale
	self._hovering = false

	--// State painting ------------------------------------------------
	function self.Refresh()
		local value = self.Value == true
		local disabled = self:IsDisabled()

		if disabled then
			box.BackgroundColor3 = theme.Colors.Element
			boxStroke.Color = theme.Colors.ElementBorder
			boxStroke.Transparency = 0.4
			label.TextColor3 = theme.Colors.TextDisabled
			Icon.setColor(check, theme.Colors.TextDisabled)

			return
		end

		if value then
			box.BackgroundColor3 = theme.Colors.ToggleOn
			boxStroke.Color = theme.Colors.ToggleOnBorder
			boxStroke.Transparency = 0
			Icon.setColor(check, theme.Colors.ToggleCheck)
		else
			box.BackgroundColor3 = self._hovering and theme.Colors.ElementActive or theme.Colors.ToggleOff
			boxStroke.Color = self._hovering and theme.Colors.Accent or theme.Colors.ToggleOffBorder
			boxStroke.Transparency = 0
			Icon.setColor(check, theme.Colors.ToggleCheck)
		end

		label.TextColor3 = theme.Colors.Text
	end

	function self.ValueChanged(value: any, animated: boolean?)
		local on = value == true

		if animated == false then
			checkScale.Scale = on and 1 or 0
		else
			Util.tween(checkScale, { Scale = on and 1 or 0 }, theme, {
				Duration = theme.Animation.Normal,
				Style = on and theme.Animation.EasingBounce or theme.Animation.EasingIn,
			})
		end

		self:Refresh()
	end

	function self.OnHoverEnter()
		self._hovering = true

		if not self:IsDisabled() then
			Util.tween(boxScale, { Scale = 1.08 }, theme, {
				Duration = theme.Animation.Fast,
			})
		end

		self:Refresh()
	end

	function self.OnHoverLeave()
		self._hovering = false

		Util.tween(boxScale, { Scale = 1 }, theme, {
			Duration = theme.Animation.Fast,
		})

		self:Refresh()
	end

	function self.DisabledChanged(disabled: boolean)
		if disabled then
			self._hovering = false
		end

		self:Refresh()
	end

	function self.OnThemeChanged()
		Util.setFont(label, theme.Fonts.Text)
		label.TextSize = metrics.TitleTextSize
		self:Refresh()
	end

	--// Interaction ---------------------------------------------------
	self:Connect(self.Instance.InputBegan, function(input: InputObject)
		if self:IsDisabled() then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		Util.tween(boxScale, { Scale = 0.92 }, theme, {
			Duration = theme.Animation.Instant,
			Reverses = true,
		})

		self:SetValue(not self.Value)
	end)

	self:AddHover(self.Instance)
	self:Refresh()

	return self
end

return Toggle
