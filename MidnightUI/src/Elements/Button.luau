--!strict
--[[
	MidnightUI · Button
	------------------------------------------------------------------
	Full width action button ("Set", "Apply", … on the screenshots).

	Styles
		· Default – flat dark box with a hairline border
		· Accent  – accent fill, dark label
		· Danger  – red fill
		· Ghost   – transparent with a border only

	Feedback: hover lift, press squash, material ripple, optional icon.
]]

local Icon = require(script.Parent.Parent.Icon)
local Util = require(script.Parent.Parent.Util)

local Element = require(script.Parent.Parent.Element)

local Button = setmetatable({}, { __index = Element })
Button.__index = Button
Button.Name = "Button"

export type Props = {
	Title: string?,
	Icon: string?,
	Style: ("Default" | "Accent" | "Danger" | "Ghost")?,
	Width: number?,
	Callback: ((value: boolean) -> ())?,
	Flag: string?,
	Tooltip: string?,
	Visible: boolean?,
	Disabled: boolean?,
	Ripple: boolean?,
	Order: number?,
}

function Button.new(section: any, props: Props?): any
	local options = props or {}
	local theme = section.Theme
	local metrics = theme.Metrics.Element

	local self: any = Element.new({
		Class = Button,
		Title = options.Title,
		Tooltip = options.Tooltip,
		Flag = options.Flag,
		Default = false,
		Callback = options.Callback,
		Visible = options.Visible,
		Disabled = options.Disabled,
		Order = options.Order,
	})

	self.Style = options.Style or "Default"
	self.Height = metrics.ButtonHeight
	self.Instance.Size = if options.Width ~= nil
		then UDim2.fromOffset(options.Width, self.Height)
		else UDim2.new(1, 0, 0, self.Height)

	local box = Instance.new("Frame")

	box.Name = "Box"
	box.BackgroundColor3 = theme.Colors.Element
	box.BorderSizePixel = 0
	box.ClipsDescendants = true
	box.Size = UDim2.new(1, 0, 1, 0)
	box.ZIndex = 2
	box.Parent = self.Instance

	Util.addCorner(box, metrics.FieldRadius)

	local stroke = Util.addStroke(box, theme.Colors.ElementBorder, 1)

	local boxScale = Instance.new("UIScale")

	boxScale.Parent = box

	local iconSize = 14
	local labelOffset = 0
	local icon = nil

	if options.Icon ~= nil then
		icon = Icon.create(options.Icon, {
			Size = iconSize,
			Color = theme.Colors.Text,
			Parent = box,
			Position = UDim2.new(0.5, -(iconSize / 2), 0.5, -(iconSize / 2)),
			Name = "Icon",
			ZIndex = 3,
		})

		labelOffset = iconSize + 8
	end

	local label = Instance.new("TextLabel")

	label.Name = "Label"
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.Size = UDim2.new(1, -labelOffset, 1, 0)
	label.Text = options.Title or ""
	label.TextColor3 = theme.Colors.Text
	label.TextSize = metrics.TextSize
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.ZIndex = 3
	label.Parent = box

	Util.setFont(label, theme.Fonts.Text)

	if icon ~= nil then
		-- shift both icon and label so the pair stays centred
		icon.Position = UDim2.new(0.5, -(labelOffset / 2), 0.5, -(iconSize / 2))
		label.Position = UDim2.new(0.5, iconSize / 2 + 4, 0.5, 0)
		label.Size = UDim2.new(1, -(iconSize + 16), 1, 0)
		label.TextXAlignment = Enum.TextXAlignment.Left
	end

	self.Box = box
	self.Label = label
	self.Icon = icon
	self._labelOffset = labelOffset
	self._hovering = false
	self._pressed = false

	local function palette(): (Color3, Color3, Color3)
		-- (background, border, text)
		local style = self.Style

		if style == "Accent" then
			return theme.Colors.Accent, theme.Colors.AccentHover, theme.Colors.AccentText
		elseif style == "Danger" then
			return theme.Colors.Danger, theme.Colors.Danger, Color3.fromRGB(255, 255, 255)
		elseif style == "Ghost" then
			return theme.Colors.Panel, theme.Colors.ElementBorder, theme.Colors.Text
		end

		return theme.Colors.Element, theme.Colors.ElementBorder, theme.Colors.Text
	end

	function self.Refresh()
		local background, border, text = palette()
		local disabled = self:IsDisabled()

		if disabled then
			box.BackgroundColor3 = background
			box.BackgroundTransparency = 0.5
			stroke.Color = border
			stroke.Transparency = 0.5
			label.TextColor3 = theme.Colors.TextDisabled

			if icon ~= nil then
				Icon.setColor(icon, theme.Colors.TextDisabled)
			end

			return
		end

		box.BackgroundTransparency = self.Style == "Ghost" and 0.55 or 0
		box.BackgroundColor3 = if self._hovering and self.Style == "Default"
			then theme.Colors.ElementHover
			else background

		stroke.Color = if self._hovering then theme.Colors.Accent else border
		stroke.Transparency = if self._hovering then 0.25 else 0.4
		label.TextColor3 = text

		if icon ~= nil then
			Icon.setColor(icon, text)
		end
	end

	function self.OnHoverEnter()
		self._hovering = true

		if not self:IsDisabled() then
			Util.tween(boxScale, { Scale = 1.02 }, theme, {
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

	function self.DisabledChanged()
		self:Refresh()
	end

	function self.OnThemeChanged()
		Util.setFont(label, theme.Fonts.Text)
		self:Refresh()
	end

	self:AddHover(self.Instance)

	self:Connect(box.InputBegan, function(input: InputObject)
		if self:IsDisabled() then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		self._pressed = true

		Util.tween(boxScale, { Scale = 0.97 }, theme, {
			Duration = theme.Animation.Instant,
		})

		if options.Ripple ~= false then
			local rippleColor = if self.Style == "Accent" or self.Style == "Danger"
				then Color3.fromRGB(255, 255, 255)
				else theme.Colors.Accent

			Util.ripple(box, Vector2.new(input.Position.X, input.Position.Y), rippleColor, self._maid)
		end
	end)

	self:Connect(box.InputEnded, function(input: InputObject)
		if not self._pressed then
			return
		end

		self._pressed = false

		Util.tween(boxScale, { Scale = self._hovering and 1.02 or 1 }, theme, {
			Duration = theme.Animation.Fast,
		})
	end)

	self:Connect(box.MouseButton1Click, function()
		if self:IsDisabled() then
			return
		end

		self:SetValue(true)
	end)

	function self.SetTitle(title: string, iconName: string?)
		self.Title = title
		label.Text = title

		if iconName ~= nil and icon ~= nil then
			icon:Destroy()

			icon = Icon.create(iconName, {
				Size = iconSize,
				Color = theme.Colors.Text,
				Parent = box,
				Position = UDim2.new(0.5, -(self._labelOffset / 2), 0.5, -(iconSize / 2)),
				Name = "Icon",
				ZIndex = 3,
			})

			self.Icon = icon
		end
	end

	self:Refresh()

	return self
end

return Button
