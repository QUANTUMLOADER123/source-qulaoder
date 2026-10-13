--!strict
--[[
	MidnightUI · Slider
	------------------------------------------------------------------
	`Label .................... value` on one row with a 4px track below
	and a 12px knob — exactly the layout used on the screenshots.

	Interaction
		· click anywhere on the track to jump to that value
		· drag the knob (delta based, so it stays smooth while the page
		  is scrolling)
		· mouse wheel over the element to nudge the value
		· hold Left Shift while dragging for fine control (0.1x)
]]

local UserInputService = game:GetService("UserInputService")

local Util = require(script.Parent.Parent.Util)

local Element = require(script.Parent.Parent.Element)

local Slider = setmetatable({}, { __index = Element })
Slider.__index = Slider
Slider.Name = "Slider"

export type Props = {
	Title: string?,
	Min: number?,
	Max: number?,
	Default: number?,
	Decimals: number?,
	Step: number?,
	Prefix: string?,
	Suffix: string?,
	ShowValue: boolean?,
	Flag: string?,
	Callback: ((value: number) -> ())?,
	Tooltip: string?,
	Visible: boolean?,
	Disabled: boolean?,
	Order: number?,
}

function Slider.new(section: any, props: Props?): any
	local options = props or {}
	local theme = section.Theme
	local metrics = theme.Metrics.Element

	local minimum = options.Min or 0
	local maximum = options.Max or 100

	if maximum < minimum then
		maximum = minimum
	end

	local decimals = options.Decimals

	if decimals == nil then
		if options.Step ~= nil and options.Step > 0 and options.Step < 1 then
			decimals = #tostring(options.Step):match("%.(%d+)") or 0
		else
			decimals = 0
		end
	end

	local defaultValue = Util.clamp(options.Default or minimum, minimum, maximum)

	local self: any = Element.new({
		Class = Slider,
		Title = options.Title,
		Tooltip = options.Tooltip,
		Flag = options.Flag,
		Default = defaultValue,
		Callback = options.Callback,
		Visible = options.Visible,
		Disabled = options.Disabled,
		Order = options.Order,
	})

	self.Min = minimum
	self.Max = maximum
	self.Decimals = decimals
	self.Step = options.Step
	self.Prefix = options.Prefix or ""
	self.Suffix = options.Suffix or ""
	self.ShowValue = options.ShowValue ~= false
	self.Height = metrics.SliderHeight
	self.Instance.Size = UDim2.new(1, 0, 0, self.Height)

	local labelHeight = 15
	local trackHeight = metrics.SliderTrackHeight
	local knobSize = metrics.SliderKnobSize

	--// Row: label + value --------------------------------------------
	local label = Instance.new("TextLabel")

	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(0, 0)
	label.Size = UDim2.new(1, -70, 0, labelHeight)
	label.Text = options.Title or ""
	label.TextColor3 = theme.Colors.Text
	label.TextSize = metrics.TitleTextSize
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.ZIndex = 2
	label.Parent = self.Instance

	Util.setFont(label, theme.Fonts.Text)

	local valueLabel = Instance.new("TextLabel")

	valueLabel.Name = "Value"
	valueLabel.BackgroundTransparency = 1
	valueLabel.AnchorPoint = Vector2.new(1, 0)
	valueLabel.Position = UDim2.new(1, 0, 0, 0)
	valueLabel.Size = UDim2.new(1, -70, 0, labelHeight)
	valueLabel.Text = ""
	valueLabel.TextColor3 = theme.Colors.Text
	valueLabel.TextSize = metrics.TextSize
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.TextYAlignment = Enum.TextYAlignment.Center
	valueLabel.ZIndex = 2
	valueLabel.Parent = self.Instance

	Util.setFont(valueLabel, theme.Fonts.Text)

	--// Track ---------------------------------------------------------
	local trackArea = Instance.new("Frame")

	trackArea.Name = "TrackArea"
	trackArea.BackgroundTransparency = 1
	trackArea.BorderSizePixel = 0
	trackArea.Position = UDim2.fromOffset(0, self.Height - knobSize)
	trackArea.Size = UDim2.new(1, 0, 0, knobSize)
	trackArea.ZIndex = 2
	trackArea.Parent = self.Instance

	local track = Instance.new("Frame")

	track.Name = "Track"
	track.AnchorPoint = Vector2.new(0, 0.5)
	track.BackgroundColor3 = theme.Colors.Track
	track.BorderSizePixel = 0
	track.Position = UDim2.new(0, 0, 0.5, 0)
	track.Size = UDim2.new(1, 0, 0, trackHeight)
	track.ZIndex = 2
	track.Parent = trackArea

	Util.addCorner(track, trackHeight / 2)

	local fill = Instance.new("Frame")

	fill.Name = "Fill"
	fill.AnchorPoint = Vector2.new(0, 0.5)
	fill.BackgroundColor3 = theme.Colors.TrackFill
	fill.BorderSizePixel = 0
	fill.Position = UDim2.new(0, 0, 0.5, 0)
	fill.Size = UDim2.new(0, 0, 0, trackHeight)
	fill.ZIndex = 3
	fill.Parent = trackArea

	Util.addCorner(fill, trackHeight / 2)

	local knob = Instance.new("Frame")

	knob.Name = "Knob"
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.BackgroundColor3 = theme.Colors.Knob
	knob.BorderSizePixel = 0
	knob.Position = UDim2.new(0, 0, 0.5, 0)
	knob.Size = UDim2.fromOffset(knobSize, knobSize)
	knob.ZIndex = 4
	knob.Parent = trackArea

	Util.addCorner(knob, knobSize / 2)

	local knobStroke = Util.addStroke(knob, theme.Colors.ElementBorder, 1)

	local knobScale = Instance.new("UIScale")

	knobScale.Parent = knob

	self.Track = track
	self.Fill = fill
	self.Knob = knob
	self.ValueLabel = valueLabel
	self.Label = label
	self._trackArea = trackArea
	self._knobScale = knobScale
	self._hovering = false
	self._dragging = false
	self._dragConnections = {}

	--// Helpers -------------------------------------------------------
	local function getAlpha(): number
		if maximum == minimum then
			return 0
		end

		return Util.clamp((self.Value - minimum) / (maximum - minimum), 0, 1)
	end

	local function commit(rawValue: number, fireCallback: boolean?)
		local value = Util.clamp(rawValue, minimum, maximum)
		value = Util.snap(value, options.Step, minimum)
		value = Util.clamp(Util.round(value, decimals), minimum, maximum)

		if value == self.Value and fireCallback ~= false then
			return
		end

		self:SetValue(value, fireCallback)
	end

	function self.Refresh()
		local alpha = getAlpha()
		local disabled = self:IsDisabled()

		fill.Size = UDim2.new(alpha, 0, 0, trackHeight)
		knob.Position = UDim2.new(alpha, knobSize / 2 - alpha * knobSize, 0.5, 0)

		valueLabel.Text = self.ShowValue
			and Util.formatValue(self.Value, decimals, self.Prefix, self.Suffix)
			or ""

		fill.BackgroundColor3 = disabled and theme.Colors.TextDisabled or theme.Colors.TrackFill
		knob.BackgroundColor3 = disabled and theme.Colors.TextDisabled or theme.Colors.Knob
		knobStroke.Color = self._dragging and theme.Colors.Accent or theme.Colors.ElementBorder
		knobStroke.Transparency = self._dragging and 0 or 0.35

		label.TextColor3 = disabled and theme.Colors.TextDisabled or theme.Colors.Text
		valueLabel.TextColor3 = disabled and theme.Colors.TextDisabled or theme.Colors.Text
	end

	function self.ValueChanged()
		self:Refresh()
	end

	function self.OnHoverEnter()
		self._hovering = true

		if not self:IsDisabled() then
			Util.tween(knobScale, { Scale = 1.15 }, theme, {
				Duration = theme.Animation.Fast,
			})
		end
	end

	function self.OnHoverLeave()
		self._hovering = false

		if not self._dragging then
			Util.tween(knobScale, { Scale = 1 }, theme, {
				Duration = theme.Animation.Fast,
			})
		end
	end

	function self.DisabledChanged()
		self:Refresh()
	end

	function self.OnThemeChanged()
		Util.setFont(label, theme.Fonts.Text)
		Util.setFont(valueLabel, theme.Fonts.Text)
		track.BackgroundColor3 = theme.Colors.Track

		self:Refresh()
	end

	--// Interaction ---------------------------------------------------
	local function valueFromInputX(inputX: number): number
		local trackWidth = math.max(self._trackArea.AbsoluteSize.X, 1)
		local relative = (inputX - self.Track.AbsolutePosition.X) / trackWidth

		relative = Util.clamp(relative, 0, 1)

		return minimum + relative * (maximum - minimum)
	end

	local function modifierMultiplier(): number
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
			return 0.1
		elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			return 0.01
		end

		return 1
	end

	local function stopDragging()
		for _, connection in self._dragConnections do
			connection:Disconnect()
		end

		table.clear(self._dragConnections)

		self._dragging = false

		Util.tween(knobScale, { Scale = self._hovering and 1.15 or 1 }, theme, {
			Duration = theme.Animation.Fast,
		})

		self:Refresh()
	end

	local function startDragging(input: InputObject)
		self._dragging = true

		Util.tween(knobScale, { Scale = 1.28 }, theme, {
			Duration = theme.Animation.Fast,
			Style = theme.Animation.Easing,
		})

		commit(valueFromInputX(input.Position.X))

		table.insert(
			self._dragConnections,
			UserInputService.InputChanged:Connect(function(changed: InputObject)
				if changed.UserInputType ~= Enum.UserInputType.MouseMovement
					and changed.UserInputType ~= Enum.UserInputType.Touch
				then
					return
				end

				local width = math.max(self._trackArea.AbsoluteSize.X, 1)
				local delta = (maximum - minimum) * (changed.Delta.X / width)

				commit(self.Value + delta * modifierMultiplier())
			end)
		)

		table.insert(
			self._dragConnections,
			UserInputService.InputEnded:Connect(function(ended: InputObject)
				if ended.UserInputType == Enum.UserInputType.MouseButton1
					or ended.UserInputType == Enum.UserInputType.Touch
				then
					stopDragging()
				end
			end)
		)
	end

	self:Connect(trackArea.InputBegan, function(input: InputObject)
		if self:IsDisabled() then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			startDragging(input)
		end
	end)

	--// Mouse wheel ---------------------------------------------------
	self:Connect(trackArea.InputChanged, function(input: InputObject)
		if self:IsDisabled() or input.UserInputType ~= Enum.UserInputType.MouseWheel then
			return
		end

		local increment = options.Step

		if increment == nil or increment <= 0 then
			increment = (maximum - minimum) / 100
		end

		commit(self.Value + increment * input.Position.Z)
	end)

	self:AddHover(self.Instance)
	self:Refresh()

	return self
end

return Slider
