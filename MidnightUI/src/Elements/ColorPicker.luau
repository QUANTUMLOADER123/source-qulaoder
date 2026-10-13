--!strict
--[[
	MidnightUI · ColorPicker
	------------------------------------------------------------------
	`Label ................................ ( ████ )` with a saturated
	value square + hue strip + hex field inside the popup.

	The picker keeps its own HSV state so that dragging never loses
	hue information (a pure Color3 cannot represent greys properly).
]]

local UserInputService = game:GetService("UserInputService")

local Util = require(script.Parent.Parent.Util)

local Element = require(script.Parent.Parent.Element)

local ColorPicker = setmetatable({}, { __index = Element })
ColorPicker.__index = ColorPicker
ColorPicker.Name = "ColorPicker"

export type Props = {
	Title: string?,
	Default: Color3?,
	Flag: string?,
	Callback: ((value: Color3) -> ())?,
	Tooltip: string?,
	Visible: boolean?,
	Disabled: boolean?,
	Order: number?,
}

function ColorPicker.new(section: any, props: Props?): any
	local options = props or {}
	local theme = section.Theme
	local metrics = theme.Metrics.Element

	local self: any = Element.new({
		Class = ColorPicker,
		Title = options.Title,
		Tooltip = options.Tooltip,
		Flag = options.Flag,
		Default = options.Default or Color3.fromRGB(147, 168, 195),
		Callback = options.Callback,
		Visible = options.Visible,
		Disabled = options.Disabled,
		Order = options.Order,
	})

	self.Height = metrics.ColorSwatchHeight
	self.Instance.Size = UDim2.new(1, 0, 0, self.Height)
	self._hovering = false
	self._open = false
	self._popup = nil
	self._dragging = nil
	self._dragConnections = {}

	local swatchWidth = metrics.ColorSwatchWidth

	--// Label ---------------------------------------------------------
	local label = Instance.new("TextLabel")

	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(0, 0)
	label.Size = UDim2.new(1, -(swatchWidth + metrics.Gap), 1, 0)
	label.Text = options.Title or ""
	label.TextColor3 = theme.Colors.Text
	label.TextSize = metrics.TitleTextSize
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.ZIndex = 2
	label.Parent = self.Instance

	Util.setFont(label, theme.Fonts.Text)

	--// Swatch --------------------------------------------------------
	local swatch = Instance.new("Frame")

	swatch.Name = "Swatch"
	swatch.AnchorPoint = Vector2.new(1, 0.5)
	swatch.BackgroundColor3 = self.Value
	swatch.BorderSizePixel = 0
	swatch.Position = UDim2.new(1, 0, 0.5, 0)
	swatch.Size = UDim2.fromOffset(swatchWidth, self.Height)
	swatch.ZIndex = 2
	swatch.Parent = self.Instance

	Util.addCorner(swatch, metrics.FieldRadius)

	local swatchStroke = Util.addStroke(swatch, theme.Colors.ElementBorder, 1, 0.2)

	self.Swatch = swatch
	self.Label = label

	--// State helpers --------------------------------------------------
	local function toHsv(color: Color3): (number, number, number)
		return Color3.toHSV(color)
	end

	local function currentHsv(): (number, number, number)
		local hue, saturation, value = toHsv(self.Value)

		-- Grey colors carry no hue — reuse the last dragged hue.
		if saturation == 0 then
			hue = self._hue or hue
		end

		self._hue = hue

		return hue, saturation, value
	end

	function self.Refresh()
		local disabled = self:IsDisabled()

		swatch.BackgroundColor3 = self.Value
		swatchStroke.Color = if self._open or self._hovering then theme.Colors.Accent else theme.Colors.ElementBorder
		swatchStroke.Transparency = if disabled then 0.5 else 0.2
		swatch.BackgroundTransparency = if disabled then 0.5 else 0
		label.TextColor3 = if disabled then theme.Colors.TextDisabled else theme.Colors.Text
	end

	function self.ValueChanged()
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
		self:Refresh()
	end

	--// Popup ----------------------------------------------------------
	local function stopDragging()
		for _, connection in self._dragConnections do
			connection:Disconnect()
		end

		table.clear(self._dragConnections)

		self._dragging = nil
	end

	local function beginDrag(target: Frame, update: (relativeX: number, relativeY: number) -> ())
		self._dragging = target

		local function apply(input: InputObject)
			local position = Vector2.new(input.Position.X, input.Position.Y)
			local origin = target.AbsolutePosition
			local size = target.AbsoluteSize

			update(
				Util.clamp((position.X - origin.X) / math.max(size.X, 1), 0, 1),
				Util.clamp((position.Y - origin.Y) / math.max(size.Y, 1), 0, 1)
			)
		end

		table.insert(
			self._dragConnections,
			UserInputService.InputChanged:Connect(function(input: InputObject)
				if input.UserInputType == Enum.UserInputType.MouseMovement
					or input.UserInputType == Enum.UserInputType.Touch
				then
					apply(input)
				end
			end)
		)

		table.insert(
			self._dragConnections,
			UserInputService.InputEnded:Connect(function(input: InputObject)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				then
					stopDragging()
				end
			end)
		)
	end

	local function buildContent(parent: Frame): number
		local hue, saturation, value = currentHsv()

		local pickerSize = theme.Metrics.Popup.ColorPickerSize
		local areaHeight = 104
		local hueHeight = theme.Metrics.Popup.HueHeight
		local hexHeight = 26
		local gap = 8

		--// Saturation / value square ---------------------------------
		local area = Instance.new("Frame")

		area.Name = "SaturationValue"
		area.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
		area.BorderSizePixel = 0
		area.ClipsDescendants = true
		area.Size = UDim2.fromOffset(pickerSize, areaHeight)
		area.ZIndex = 22
		area.Parent = parent

		Util.addCorner(area, 6)

		local whiteGradient = Util.addGradient(area, Color3.new(1, 1, 1), Color3.new(1, 1, 1), 0)

		whiteGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		})

		local blackOverlay = Instance.new("Frame")

		blackOverlay.Name = "Value"
		blackOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
		blackOverlay.BorderSizePixel = 0
		blackOverlay.Size = UDim2.fromScale(1, 1)
		blackOverlay.ZIndex = 23
		blackOverlay.Parent = area

		local blackGradient = Util.addGradient(blackOverlay, Color3.new(0, 0, 0), Color3.new(0, 0, 0), 90)

		blackGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		})

		local marker = Instance.new("Frame")

		marker.Name = "Marker"
		marker.AnchorPoint = Vector2.new(0.5, 0.5)
		marker.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		marker.BackgroundTransparency = 1
		marker.BorderSizePixel = 0
		marker.Size = UDim2.fromOffset(12, 12)
		marker.Position = UDim2.new(saturation, 0, 1 - value, 0)
		marker.ZIndex = 25
		marker.Parent = area

		Util.addCorner(marker, 6)
		Util.addStroke(marker, Color3.fromRGB(255, 255, 255), 1.6)

		--// Hue strip ---------------------------------------------------
		local hueStrip = Instance.new("Frame")

		hueStrip.Name = "Hue"
		hueStrip.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		hueStrip.BorderSizePixel = 0
		hueStrip.Position = UDim2.fromOffset(0, areaHeight + gap)
		hueStrip.Size = UDim2.fromOffset(pickerSize, hueHeight)
		hueStrip.ZIndex = 22
		hueStrip.Parent = parent

		Util.addCorner(hueStrip, hueHeight / 2)

		local hueGradient = Util.addGradient(
			hueStrip,
			Color3.fromHSV(0, 1, 1),
			Color3.fromHSV(1, 1, 1),
			0
		)

		hueGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromHSV(0, 1, 1)),
			ColorSequenceKeypoint.new(1 / 6, Color3.fromHSV(1 / 6, 1, 1)),
			ColorSequenceKeypoint.new(2 / 6, Color3.fromHSV(2 / 6, 1, 1)),
			ColorSequenceKeypoint.new(3 / 6, Color3.fromHSV(3 / 6, 1, 1)),
			ColorSequenceKeypoint.new(4 / 6, Color3.fromHSV(4 / 6, 1, 1)),
			ColorSequenceKeypoint.new(5 / 6, Color3.fromHSV(5 / 6, 1, 1)),
			ColorSequenceKeypoint.new(1.0, Color3.fromHSV(1, 1, 1)),
		})

		local hueKnob = Instance.new("Frame")

		hueKnob.Name = "Knob"
		hueKnob.AnchorPoint = Vector2.new(0.5, 0.5)
		hueKnob.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
		hueKnob.BorderSizePixel = 0
		hueKnob.Position = UDim2.new(hue, 0, 0.5, 0)
		hueKnob.Size = UDim2.fromOffset(hueHeight + 6, hueHeight + 6)
		hueKnob.ZIndex = 25
		hueKnob.Parent = hueStrip

		Util.addCorner(hueKnob, (hueHeight + 6) / 2)
		Util.addStroke(hueKnob, Color3.fromRGB(255, 255, 255), 1.6)

		--// Hex field ----------------------------------------------------
		local hexBox = Instance.new("TextBox")

		hexBox.Name = "Hex"
		hexBox.BackgroundColor3 = theme.Colors.Element
		hexBox.BorderSizePixel = 0
		hexBox.ClearTextOnFocus = false
		hexBox.Position = UDim2.fromOffset(0, areaHeight + gap + hueHeight + gap)
		hexBox.Size = UDim2.fromOffset(pickerSize, hexHeight)
		hexBox.Text = Util.colorToHex(self.Value)
		hexBox.TextColor3 = theme.Colors.Text
		hexBox.TextSize = theme.Metrics.Element.FieldTextSize
		hexBox.TextXAlignment = Enum.TextXAlignment.Left
		hexBox.ZIndex = 22
		hexBox.Parent = parent

		Util.addCorner(hexBox, 4)
		Util.addPadding(hexBox, 8, 8, 0, 0)
		Util.addStroke(hexBox, theme.Colors.ElementBorder, 1)
		Util.setFont(hexBox, theme.Fonts.Mono)

		local function commit(color: Color3, fromHex: boolean?)
			if not fromHex then
				hexBox.Text = Util.colorToHex(color)
			end

			self:SetValue(color)
		end

		local function updateMarker()
			local newHue, newSaturation, newValue = currentHsv()

			marker.Position = UDim2.new(newSaturation, 0, 1 - newValue, 0)
			area.BackgroundColor3 = Color3.fromHSV(newHue, 1, 1)
			hueKnob.Position = UDim2.new(newHue, 0, 0.5, 0)
			hueKnob.BackgroundColor3 = Color3.fromHSV(newHue, 1, 1)
		end

		self._updatePopupMarker = updateMarker

		area.InputBegan:Connect(function(input: InputObject)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end

			local hueNow = currentHsv()

			beginDrag(area, function(relativeX, relativeY)
				commit(Color3.fromHSV(hueNow, relativeX, 1 - relativeY))
			end)

			commit(Color3.fromHSV(
				hueNow,
				Util.clamp((input.Position.X - area.AbsolutePosition.X) / math.max(area.AbsoluteSize.X, 1), 0, 1),
				Util.clamp(1 - (input.Position.Y - area.AbsolutePosition.Y) / math.max(area.AbsoluteSize.Y, 1), 0, 1)
			))
		end)

		hueStrip.InputBegan:Connect(function(input: InputObject)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end

			local _, saturationNow, valueNow = currentHsv()

			beginDrag(hueStrip, function(relativeX)
				commit(Color3.fromHSV(relativeX, saturationNow, valueNow))
			end)

			commit(Color3.fromHSV(
				Util.clamp((input.Position.X - hueStrip.AbsolutePosition.X) / math.max(hueStrip.AbsoluteSize.X, 1), 0, 1),
				saturationNow,
				valueNow
			))
		end)

		hexBox.FocusLost:Connect(function()
			local parsed = Util.hexToColor(hexBox.Text)

			if parsed == nil then
				hexBox.Text = Util.colorToHex(self.Value)

				return
			end

			commit(parsed)
		end)

		return areaHeight + gap + hueHeight + gap + hexHeight
	end

	function self.Open()
		if self._open or self:IsDisabled() then
			return
		end

		self._open = true
		self:Refresh()

		local contentWidth = theme.Metrics.Popup.ColorPickerSize

		self._popup = self.Window:_createPopup({
			Name = "ColorPicker",
			Anchor = swatch,
			Width = contentWidth + theme.Metrics.Popup.Padding * 2,
			Padding = theme.Metrics.Popup.Padding,
			Content = buildContent,
			OnClose = function()
				self._open = false
				self._popup = nil
				self._updatePopupMarker = nil
				stopDragging()
				self:Refresh()
			end,
		})
	end

	function self.Close()
		if self._popup ~= nil then
			self._popup:Close()
		end
	end

	--// Public API -------------------------------------------------------
	function self.SetValue(value: any, fireCallback: boolean?)
		local color = typeof(value) == "Color3" and value or Util.hexToColor(tostring(value)) or self.Value

		self._hue = select(1, Color3.toHSV(color))

		Element.SetValue(self, color, fireCallback)

		if self._updatePopupMarker ~= nil then
			self._updatePopupMarker()
		end

		if self._popup ~= nil then
			local hexBox = self._popup.Inner:FindFirstChild("Hex")

			if hexBox ~= nil then
				hexBox.Text = Util.colorToHex(color)
			end
		end
	end

	function self.GetHex(): string
		return Util.colorToHex(self.Value)
	end

	--// Interaction -------------------------------------------------------
	self:Connect(swatch.InputBegan, function(input: InputObject)
		if self:IsDisabled() then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		if self._open then
			self:Close()
		else
			self:Open()
		end
	end)

	self:AddHover(self.Instance)
	self:Refresh()

	return self
end

return ColorPicker
