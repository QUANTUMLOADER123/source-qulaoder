--!strict
--[[
	MidnightUI · Keybind
	------------------------------------------------------------------
	`Label ........................ ( E )` — a circular badge on the
	right that shows the bound key (see the "Type ●" row on the
	screenshots).

	Click the badge to start listening: the badge pulses until a key
	(or a mouse button) is pressed. Escape cancels the capture.
]]

local UserInputService = game:GetService("UserInputService")

local Util = require(script.Parent.Parent.Util)

local Element = require(script.Parent.Parent.Element)

local Keybind = setmetatable({}, { __index = Element })
Keybind.__index = Keybind
Keybind.Name = "Keybind"

export type Props = {
	Title: string?,
	Default: (string | EnumItem)?,
	Mode: ("Press" | "Hold")?,
	Flag: string?,
	Callback: ((key: string?) -> ())?,
	OnPress: ((pressed: boolean) -> ())?,
	Tooltip: string?,
	Visible: boolean?,
	Disabled: boolean?,
	Order: number?,
}

--- Compact labels so keys fit inside the 20px badge.
local SHORT_NAMES: { [string]: string } = {
	Space = "SPC",
	LeftControl = "LCT",
	RightControl = "RCT",
	LeftShift = "LSH",
	RightShift = "RSH",
	LeftAlt = "LAL",
	RightAlt = "RAL",
	Backspace = "BKS",
	Return = "ENT",
	Escape = "ESC",
	Tab = "TAB",
	CapsLock = "CAP",
	Delete = "DEL",
	Insert = "INS",
	PageUp = "PGU",
	PageDown = "PGD",
	Home = "HOM",
	["End"] = "END",
	MouseButton1 = "M1",
	MouseButton2 = "M2",
	MouseButton3 = "M3",
	MouseWheel = "M4",
	Up = "UP",
	Down = "DN",
	Left = "LF",
	Right = "RT",
}

local function toKeyName(value: any): string?
	if value == nil then
		return nil
	end

	if typeof(value) == "EnumItem" then
		return value.Name
	end

	if type(value) == "string" then
		if value == "" then
			return nil
		end

		return value
	end

	return nil
end

local function shortLabel(key: string?): string
	if key == nil then
		return ""
	end

	local mapped = SHORT_NAMES[key]

	if mapped ~= nil then
		return mapped
	end

	if #key <= 3 then
		return key:upper()
	end

	return key:sub(1, 3):upper()
end

local function inputToKeyName(input: InputObject): string?
	if input.KeyCode ~= Enum.KeyCode.Unknown then
		return input.KeyCode.Name
	end

	local inputType = input.UserInputType

	if inputType == Enum.UserInputType.MouseButton1 then
		return "MouseButton1"
	elseif inputType == Enum.UserInputType.MouseButton2 then
		return "MouseButton2"
	elseif inputType == Enum.UserInputType.MouseButton3 then
		return "MouseButton3"
	elseif inputType == Enum.UserInputType.MouseWheel then
		return "MouseWheel"
	end

	return nil
end

function Keybind.new(section: any, props: Props?): any
	local options = props or {}
	local theme = section.Theme
	local metrics = theme.Metrics.Element

	local self: any = Element.new({
		Class = Keybind,
		Title = options.Title,
		Tooltip = options.Tooltip,
		Flag = options.Flag,
		Default = toKeyName(options.Default),
		Callback = options.Callback,
		Visible = options.Visible,
		Disabled = options.Disabled,
		Order = options.Order,
	})

	self.Mode = options.Mode or "Press"
	self.Height = math.max(metrics.KeybindHeight, metrics.KeybindBadge)
	self.Instance.Size = UDim2.new(1, 0, 0, self.Height)

	self._capturing = false
	self._pressed = false
	self._hovering = false

	local badgeSize = metrics.KeybindBadge

	--// Label ---------------------------------------------------------
	local label = Instance.new("TextLabel")

	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(0, 0)
	label.Size = UDim2.new(1, -(badgeSize + metrics.Gap), 1, 0)
	label.Text = options.Title or ""
	label.TextColor3 = theme.Colors.Text
	label.TextSize = metrics.TitleTextSize
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.ZIndex = 2
	label.Parent = self.Instance

	Util.setFont(label, theme.Fonts.Text)

	--// Badge ---------------------------------------------------------
	local badge = Instance.new("Frame")

	badge.Name = "Badge"
	badge.AnchorPoint = Vector2.new(1, 0.5)
	badge.BackgroundColor3 = theme.Colors.Element
	badge.BorderSizePixel = 0
	badge.Position = UDim2.new(1, 0, 0.5, 0)
	badge.Size = UDim2.fromOffset(badgeSize, badgeSize)
	badge.ZIndex = 2
	badge.Parent = self.Instance

	Util.addCorner(badge, badgeSize / 2)

	local badgeStroke = Util.addStroke(badge, theme.Colors.ElementBorder, 1)

	local badgeText = Instance.new("TextLabel")

	badgeText.Name = "Key"
	badgeText.BackgroundTransparency = 1
	badgeText.Size = UDim2.new(1, -4, 1, 0)
	badgeText.Position = UDim2.fromOffset(2, 0)
	badgeText.Text = ""
	badgeText.TextColor3 = theme.Colors.Text
	badgeText.TextScaled = true
	badgeText.TextXAlignment = Enum.TextXAlignment.Center
	badgeText.TextYAlignment = Enum.TextYAlignment.Center
	badgeText.ZIndex = 3
	badgeText.Parent = badge

	Util.setFont(badgeText, theme.Fonts.Mono)

	local badgeScale = Instance.new("UIScale")

	badgeScale.Parent = badge

	self.Badge = badge
	self.BadgeText = badgeText
	self.Label = label
	self._badgeScale = badgeScale

	--// Visual state ----------------------------------------------------
	function self.Refresh()
		local key = self.Value
		local disabled = self:IsDisabled()

		badgeText.Text = if self._capturing then "…" else shortLabel(key)

		if disabled then
			badge.BackgroundColor3 = theme.Colors.Element
			badgeStroke.Color = theme.Colors.ElementBorder
			badgeStroke.Transparency = 0.5
			badgeText.TextColor3 = theme.Colors.TextDisabled
			label.TextColor3 = theme.Colors.TextDisabled

			return
		end

		local active = self._capturing or self._pressed or self._hovering

		badge.BackgroundColor3 = if active then theme.Colors.ElementActive else theme.Colors.Element
		badgeStroke.Color = if active then theme.Colors.Accent else theme.Colors.ElementBorder
		badgeStroke.Transparency = if self._pressed then 0 else 0.15
		badgeText.TextColor3 = if active and key ~= nil or self._capturing
			then theme.Colors.Accent
			else theme.Colors.TextDim
		label.TextColor3 = theme.Colors.Text
	end

	function self.ValueChanged()
		self:Refresh()
	end

	function self.OnHoverEnter()
		self._hovering = true

		Util.tween(badgeScale, { Scale = 1.1 }, theme, { Duration = theme.Animation.Fast })
		self:Refresh()
	end

	function self.OnHoverLeave()
		self._hovering = false

		Util.tween(badgeScale, { Scale = 1 }, theme, { Duration = theme.Animation.Fast })
		self:Refresh()
	end

	function self.DisabledChanged()
		if self:IsDisabled() then
			self:CancelCapture()
		end

		self:Refresh()
	end

	function self.OnThemeChanged()
		Util.setFont(label, theme.Fonts.Text)
		Util.setFont(badgeText, theme.Fonts.Mono)
		self:Refresh()
	end

	--// Capture --------------------------------------------------------
	local captureConnection = nil

	local function stopCaptureTween()
		Util.tween(badgeStroke, { Transparency = 0.15 }, theme, { Duration = theme.Animation.Instant })
	end

	function self.CancelCapture()
		if not self._capturing then
			return
		end

		self._capturing = false

		if captureConnection ~= nil then
			captureConnection:Disconnect()
			captureConnection = nil
		end

		stopCaptureTween()
		self:Refresh()
	end

	function self.StartCapture()
		if self._capturing or self:IsDisabled() then
			return
		end

		self._capturing = true

		Util.tween(badgeStroke, { Transparency = 0.7 }, theme, {
			Duration = 0.45,
			Reverses = true,
			RepeatCount = -1,
		})

		self:Refresh()

		captureConnection = UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
			if gameProcessed then
				return
			end

			if input.UserInputType == Enum.UserInputType.MouseMovement then
				return
			end

			if input.KeyCode == Enum.KeyCode.Escape then
				self:CancelCapture()

				return
			end

			local key = inputToKeyName(input)

			if key == nil then
				return
			end

			self:CancelCapture()
			self:SetValue(key)
		end)
	end

	--// Press handling ---------------------------------------------------
	self:Connect(UserInputService.InputBegan, function(input: InputObject, gameProcessed: boolean)
		if gameProcessed or self:IsDisabled() or self._capturing or self.Value == nil then
			return
		end

		if inputToKeyName(input) ~= self.Value then
			return
		end

		self._pressed = true
		self:Refresh()

		Util.tween(badgeScale, { Scale = 0.9 }, theme, {
			Duration = theme.Animation.Instant,
			Reverses = true,
		})

		if options.OnPress ~= nil then
			local ok, err = pcall(options.OnPress, true)

			if not ok then
				warn(("[MidnightUI] Keybind OnPress errored: %s"):format(tostring(err)))
			end
		end
	end)

	self:Connect(UserInputService.InputEnded, function(input: InputObject)
		if not self._pressed or self:IsDisabled() then
			return
		end

		if inputToKeyName(input) ~= self.Value then
			return
		end

		self._pressed = false
		self:Refresh()

		if self.Mode == "Hold" and options.OnPress ~= nil then
			local ok, err = pcall(options.OnPress, false)

			if not ok then
				warn(("[MidnightUI] Keybind OnPress errored: %s"):format(tostring(err)))
			end
		end
	end)

	--// Interaction -------------------------------------------------------
	self:Connect(badge.InputBegan, function(input: InputObject)
		if self:IsDisabled() or self._capturing then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		self:StartCapture()
	end)

	self:Connect(self.Instance.InputBegan, function(input: InputObject)
		if self:IsDisabled() or self._capturing then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			self:SetValue(nil)
		end
	end)

	--// Public API ---------------------------------------------------------
	function self.IsPressed(): boolean
		return self._pressed
	end

	function self.IsCapturing(): boolean
		return self._capturing
	end

	self:AddHover(self.Instance)
	self:Refresh()

	return self
end

return Keybind
