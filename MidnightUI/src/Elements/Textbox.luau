--!strict
--[[
	MidnightUI · Textbox
	------------------------------------------------------------------
	Label above + flat input box, identical to the dropdown's closed
	state. Focus is highlighted with an accent border.

	`Numeric = true` turns the value into a number clamped to
	[Min, Max] and formatted with `Decimals`.
]]

local Util = require(script.Parent.Parent.Util)

local Element = require(script.Parent.Parent.Element)

local Textbox = setmetatable({}, { __index = Element })
Textbox.__index = Textbox
Textbox.Name = "Textbox"

export type Props = {
	Title: string?,
	Default: (string | number)?,
	Placeholder: string?,
	Numeric: boolean?,
	Min: number?,
	Max: number?,
	Decimals: number?,
	MaxLength: number?,
	Live: boolean?,
	Flag: string?,
	Callback: ((value: any) -> ())?,
	Tooltip: string?,
	Visible: boolean?,
	Disabled: boolean?,
	Order: number?,
}

function Textbox.new(section: any, props: Props?): any
	local options = props or {}
	local theme = section.Theme
	local metrics = theme.Metrics.Element

	local self: any = Element.new({
		Class = Textbox,
		Title = options.Title,
		Tooltip = options.Tooltip,
		Flag = options.Flag,
		Default = options.Default,
		Callback = options.Callback,
		Visible = options.Visible,
		Disabled = options.Disabled,
		Order = options.Order,
	})

	self.Numeric = options.Numeric == true
	self.Min = options.Min or 0
	self.Max = options.Max or 100
	self.Decimals = options.Decimals or 0
	self.Height = metrics.FieldHeight
	self.Instance.Size = UDim2.new(1, 0, 0, self.Height)

	local labelHeight = 15
	local boxHeight = metrics.FieldBoxHeight

	--// Label ---------------------------------------------------------
	local label = Instance.new("TextLabel")

	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(0, 0)
	label.Size = UDim2.new(1, 0, 0, labelHeight)
	label.Text = options.Title or ""
	label.TextColor3 = theme.Colors.Text
	label.TextSize = metrics.TitleTextSize
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Visible = options.Title ~= nil
	label.ZIndex = 2
	label.Parent = self.Instance

	Util.setFont(label, theme.Fonts.Text)

	--// Box -----------------------------------------------------------
	local box = Instance.new("Frame")

	box.Name = "Box"
	box.AnchorPoint = Vector2.new(0, 1)
	box.BackgroundColor3 = theme.Colors.Element
	box.BorderSizePixel = 0
	box.Position = UDim2.new(0, 0, 1, 0)
	box.Size = UDim2.new(1, 0, 0, boxHeight)
	box.ZIndex = 2
	box.Parent = self.Instance

	Util.addCorner(box, metrics.FieldRadius)

	local boxStroke = Util.addStroke(box, theme.Colors.ElementBorder, 1)

	local input = Instance.new("TextBox")

	input.Name = "Input"
	input.BackgroundTransparency = 1
	input.ClearTextOnFocus = options.ClearOnFocus == true
	input.MultiLine = false
	input.PlaceholderText = options.Placeholder or ""
	input.PlaceholderColor3 = theme.Colors.TextMuted
	input.Position = UDim2.fromOffset(metrics.FieldPadding, 0)
	input.Size = UDim2.new(1, -metrics.FieldPadding * 2, 1, 0)
	input.Text = options.Default ~= nil and tostring(options.Default) or ""
	input.TextColor3 = theme.Colors.Text
	input.TextSize = metrics.FieldTextSize
	input.TextXAlignment = Enum.TextXAlignment.Left
	input.TextYAlignment = Enum.TextYAlignment.Center
	input.TextEditable = true
	input.ZIndex = 3
	input.Parent = box

	if options.MaxLength ~= nil then
		input.MaxVisibleGraphemes = options.MaxLength
	else
		input.MaxVisibleGraphemes = -1
	end

	Util.setFont(input, theme.Fonts.Text)

	self.Box = box
	self.Input = input
	self.Label = label
	self._focused = false
	self._hovering = false

	--// Helpers --------------------------------------------------------
	local function sanitize(text: string): any
		if not self.Numeric then
			return text
		end

		if text == "" or text == "-" then
			return nil
		end

		local filtered = text:gsub("[^%d%.%-]", "")

		if options.Decimals == 0 or options.Decimals == nil then
			filtered = filtered:gsub("%.", "")
		end

		local number = tonumber(filtered)

		if number == nil then
			return nil
		end

		number = Util.clamp(number, self.Min, self.Max)

		return Util.round(number, self.Decimals)
	end

	local function displayValue(): string
		if self.Value == nil then
			return ""
		end

		if self.Numeric then
			return Util.formatValue(self.Value, self.Decimals, "", "")
		end

		return tostring(self.Value)
	end

	local function commit(fireCallback: boolean?)
		local parsed = sanitize(input.Text)

		if self.Numeric and parsed == nil then
			input.Text = displayValue()

			return
		end

		self:SetValue(self.Numeric and parsed or input.Text, fireCallback)
	end

	-- Make sure numeric defaults are shown with the right precision.
	input.Text = displayValue()

	--// Visual refresh -------------------------------------------------
	function self.Refresh()
		local disabled = self:IsDisabled()

		box.BackgroundColor3 = if disabled
			then theme.Colors.Element
			elseif self._focused then theme.Colors.ElementActive
			elseif self._hovering then theme.Colors.ElementHover
			else theme.Colors.Element

		boxStroke.Color = if self._focused or self._hovering then theme.Colors.Accent else theme.Colors.ElementBorder
		boxStroke.Transparency = if disabled then 0.5 else 0

		input.TextColor3 = if disabled then theme.Colors.TextDisabled else theme.Colors.Text
		input.TextEditable = not disabled
		label.TextColor3 = if disabled then theme.Colors.TextDisabled else theme.Colors.Text
	end

	function self.ValueChanged()
		if not self._focused then
			input.Text = displayValue()
		end

		self:Refresh()
	end

	function self.OnHoverEnter()
		self._hovering = true
		self:Refresh()
	end

	function self.OnHoverLeave()
		self._hovering = false
		self:Refresh()
	end

	function self.DisabledChanged()
		self:Refresh()
	end

	function self.OnThemeChanged()
		Util.setFont(label, theme.Fonts.Text)
		Util.setFont(input, theme.Fonts.Text)
		self:Refresh()
	end

	--// Interaction ----------------------------------------------------
	self:Connect(input.Focused, function()
		self._focused = true
		self:Refresh()
	end)

	self:Connect(input.FocusLost, function()
		self._focused = false

		commit(true)
		self:Refresh()
	end)

	if options.Live == true then
		self:Connect(input:GetPropertyChangedSignal("Text"), function()
			if not self._focused then
				return
			end

			local parsed = sanitize(input.Text)

			if parsed == nil then
				return
			end

			self.Value = parsed
			self:SetValue(parsed, false)
		end)
	end

	self:Connect(box.InputBegan, function(input2: InputObject)
		if self:IsDisabled() then
			return
		end

		if input2.UserInputType ~= Enum.UserInputType.MouseButton1
			and input2.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		if not self._focused then
			input:CaptureFocus()
		end
	end)

	self:AddHover(self.Instance)

	--// Public API ------------------------------------------------------
	function self.GetValue(): any
		return self.Value
	end

	function self.SetValue(value: any, fireCallback: boolean?)
		if self.Numeric then
			local number = tonumber(value)

			if number == nil then
				number = self.Min
			end

			number = Util.clamp(Util.round(number, self.Decimals), self.Min, self.Max)

			Element.SetValue(self, number, fireCallback)
		else
			Element.SetValue(self, value ~= nil and tostring(value) or "", fireCallback)
		end

		if not self._focused then
			input.Text = displayValue()
		end
	end

	function self.Reset()
		self:SetValue(self._defaultValue)
	end

	self:Refresh()

	return self
end

return Textbox
