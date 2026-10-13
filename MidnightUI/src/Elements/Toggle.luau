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
local Signal = require(script.Parent.Parent.Signal)
local Util = require(script.Parent.Parent.Util)

local Element = require(script.Parent.Parent.Element)

local Toggle = setmetatable({}, { __index = Element })
Toggle.__index = Toggle
Toggle.Name = "Toggle"

export type Props = {
	Circle: boolean?,
	Color: Color3?,
	ColorFlag: string?,
	OnColorChanged: ((value: Color3) -> ())?,
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

	local circle = options.Circle == true
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

	Util.addCorner(box, circle and boxSize / 2 or metrics.ToggleRadius)

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

	-- Circle style: a solid dot instead of the tick glyph.
	local dot = nil

	if circle then
		check.Visible = false

		dot = Instance.new("Frame")

		dot.Name = "Dot"
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		dot.BackgroundColor3 = theme.Colors.ToggleCheck
		dot.BorderSizePixel = 0
		dot.Position = UDim2.fromScale(0.5, 0.5)
		dot.Size = UDim2.fromOffset(math.max(4, math.floor(boxSize * 0.42)), math.max(4, math.floor(boxSize * 0.42)))
		dot.ZIndex = 3
		dot.Parent = box

		Util.addCorner(dot, math.huge)

		local dotScale = Instance.new("UIScale")

		dotScale.Scale = self.Value and 1 or 0
		dotScale.Parent = dot

		self._dotScale = dotScale
		self.Dot = dot
	end

	--// Label ---------------------------------------------------------
	local labelOffset = boxSize + metrics.Gap

	--// Optional colour swatch (checkbox + colour rows from the reference) --
	local swatch = nil
	local swatchSize = 15

	if options.Color ~= nil then
		swatch = Instance.new("Frame")

		swatch.Name = "Swatch"
		swatch.AnchorPoint = Vector2.new(1, 0.5)
		swatch.BackgroundColor3 = options.Color
		swatch.BorderSizePixel = 0
		swatch.Position = UDim2.new(1, 0, 0.5, 0)
		swatch.Size = UDim2.fromOffset(swatchSize, swatchSize)
		swatch.ZIndex = 3
		swatch.Parent = self.Instance

		Util.addCorner(swatch, 4)
		Util.addStroke(swatch, theme.Colors.ElementBorder, 1, 0.25)
	end

	local label = Instance.new("TextLabel")

	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(labelOffset, 0)
	label.Size = UDim2.new(1, -labelOffset - (swatch ~= nil and (swatchSize + 8) or 0), 1, 0)
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
	self.Swatch = swatch
	self.Color = options.Color
	self._open = false
	self._popup = nil

	if swatch ~= nil then
		self.ColorChanged = Signal.new()
	end
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
		local dotScale = self._dotScale

		if animated == false then
			checkScale.Scale = on and 1 or 0

			if dotScale ~= nil then
				dotScale.Scale = on and 1 or 0
			end
		else
			Util.tween(checkScale, { Scale = on and 1 or 0 }, theme, {
				Duration = theme.Animation.Normal,
				Style = on and theme.Animation.EasingBounce or theme.Animation.EasingIn,
			})

			if dotScale ~= nil then
				Util.tween(dotScale, { Scale = on and 1 or 0 }, theme, {
					Duration = theme.Animation.Fast,
				})
			end
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

	--// Colour popup --------------------------------------------------
	local function commitColor(color: Color3)
		self.Color = color
		swatch.BackgroundColor3 = color

		if self.ColorChanged ~= nil then
			self.ColorChanged:Fire(color)
		end

		if options.OnColorChanged ~= nil then
			local ok, err = pcall(options.OnColorChanged, color)

			if not ok then
				warn(("[MidnightUI] OnColorChanged errored: %s"):format(tostring(err)))
			end
		end

		if self.Window ~= nil and options.ColorFlag ~= nil then
			self.Window:_setFlag(options.ColorFlag, color)
		end
	end

	local PALETTE = {
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(233, 70, 70),
		Color3.fromRGB(255, 176, 32),
		Color3.fromRGB(255, 235, 59),
		Color3.fromRGB(76, 217, 100),
		Color3.fromRGB(0, 199, 190),
		Color3.fromRGB(47, 128, 237),
		Color3.fromRGB(155, 89, 240),
		Color3.fromRGB(255, 80, 190),
		Color3.fromRGB(120, 128, 140),
		Color3.fromRGB(60, 62, 68),
		Color3.fromRGB(16, 16, 18),
	}

	if swatch ~= nil then
		self._maid:Add(swatch.InputBegan:Connect(function(input: InputObject)
			if self:IsDisabled() then
				return
			end

			if input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end

			if self._open then
				if self._popup ~= nil then
					self._popup:Close()
				end

				return
			end

			self._open = true

			local columns = 6
			local cell = 22
			local gap = 6
			local width = columns * cell + (columns - 1) * gap

			self._popup = self.Window:_createPopup({
				Name = "ColorSwatch",
				Anchor = swatch,
				Width = width,
				Padding = 10,
				OnClose = function()
					self._open = false
					self._popup = nil
				end,
				Content = function(parent: Frame): number
					local grid = Instance.new("Frame")

					grid.Name = "Palette"
					grid.BackgroundTransparency = 1
					grid.BorderSizePixel = 0
					grid.Size = UDim2.new(1, 0, 0, 0)
					grid.ZIndex = 21
					grid.Parent = parent

					Util.addList(grid, {
						Padding = gap,
						Direction = Enum.FillDirection.Horizontal,
						SortOrder = Enum.SortOrder.LayoutOrder,
						Wraps = true,
					})

					local rows = math.ceil(#PALETTE / columns)
					local height = rows * cell + (rows - 1) * gap

					grid.Size = UDim2.new(1, 0, 0, height)

					for index, color in PALETTE do
						local cellButton = Instance.new("TextButton")

						cellButton.Name = "Color" .. tostring(index)
						cellButton.AutoButtonColor = false
						cellButton.BackgroundColor3 = color
						cellButton.BorderSizePixel = 0
						cellButton.LayoutOrder = index
						cellButton.Size = UDim2.fromOffset(cell, cell)
						cellButton.Text = ""
						cellButton.ZIndex = 22
						cellButton.Parent = grid

						Util.addCorner(cellButton, 5)

						cellButton.MouseEnter:Connect(function()
							cellButton.Size = UDim2.fromOffset(cell + 2, cell + 2)
						end)

						cellButton.MouseLeave:Connect(function()
							cellButton.Size = UDim2.fromOffset(cell, cell)
						end)

						cellButton.MouseButton1Click:Connect(function()
							commitColor(color)
						end)
					end

					local hex = Instance.new("TextBox")

					hex.Name = "Hex"
					hex.BackgroundColor3 = self.Theme.Colors.Element
					hex.BorderSizePixel = 0
					hex.ClearTextOnFocus = false
					hex.Position = UDim2.fromOffset(0, height + 10)
					hex.Size = UDim2.new(1, 0, 0, 26)
					hex.Text = Util.colorToHex(self.Color)
					hex.TextColor3 = self.Theme.Colors.Text
					hex.TextSize = self.Theme.Metrics.Element.TextSize
					hex.TextXAlignment = Enum.TextXAlignment.Center
					hex.ZIndex = 22
					hex.Parent = parent

					Util.addCorner(hex, 5)

					hex.FocusLost:Connect(function()
						local parsed = Util.hexToColor(hex.Text)

						if parsed == nil then
							hex.Text = Util.colorToHex(self.Color)

							return
						end

						commitColor(parsed)
					end)

					return height + 10 + 26
				end,
			})
		end))
	end

	self:AddHover(self.Instance)
	self:Refresh()

	return self
end

--- Sets the swatch colour (no-op when the toggle has no swatch).
function Toggle.SetColor(self: any, color: Color3)
	if self.Swatch == nil then
		return
	end

	self.Color = color
	self.Swatch.BackgroundColor3 = color

	if self.ColorChanged ~= nil then
		self.ColorChanged:Fire(color)
	end
end

function Toggle.GetColor(self: any): Color3?
	return self.Color
end

return Toggle
