--!strict
--[[
	MidnightUI · Notification
	------------------------------------------------------------------
	Toast cards that slide in from the right with an accent strip, a
	title, a body and a progress bar. Up to `MaxVisible` cards are
	stacked; older ones are dismissed automatically.
]]

local TweenService = game:GetService("TweenService")

local Icon = require(script.Parent.Icon)
local Maid = require(script.Parent.Maid)
local Util = require(script.Parent.Util)

local Notification = {}
Notification.__index = Notification

export type Kind = "Info" | "Success" | "Warning" | "Error"

export type Props = {
	Title: string?,
	Text: string?,
	Duration: number?,
	Kind: Kind?,
	Icon: string?,
}

export type Notification = typeof(setmetatable(
	{} :: {
		Window: any,
		Theme: any,
		Root: Frame,
		Height: number,
		Duration: number,
		Closing: boolean,
		_maid: any,
		_layout: (() -> ())?,
		_onClosed: (() -> ())?,
	},
	Notification
))

local KIND_COLORS: { [string]: string } = {
	Info = "Info",
	Success = "Success",
	Warning = "Warning",
	Error = "Danger",
}

local KIND_ICONS: { [string]: string } = {
	Info = "info",
	Success = "check",
	Warning = "warning",
	Error = "warning",
}

--// Construction -----------------------------------------------------

function Notification.new(window: any, props: Props, layout: (() -> ())?, onClosed: (() -> ())?): Notification
	local theme = window.Theme
	local metrics = theme.Metrics.Notification

	local self: any = setmetatable({}, Notification)

	self.Window = window
	self.Theme = theme
	self.Closing = false
	self.Duration = props.Duration or metrics.Duration
	self._maid = window._maid:AddProxy(Maid.new())
	self._layout = layout
	self._onClosed = onClosed

	local kind = props.Kind or "Info"
	local accentKey = KIND_COLORS[kind] or "Info"
	local accent = theme.Colors[accentKey] or theme.Colors.Info
	local iconName = props.Icon or KIND_ICONS[kind] or "info"

	local root = Instance.new("Frame")

	root.Name = "Notification"
	root.AnchorPoint = Vector2.new(1, 1)
	root.BackgroundColor3 = theme.Colors.Popup
	root.BackgroundTransparency = 1
	root.BorderSizePixel = 0
	root.ClipsDescendants = true
	root.Position = UDim2.new(1, metrics.Margin + metrics.Width, 1, -metrics.Margin)
	root.Size = UDim2.fromOffset(metrics.Width, metrics.MinHeight)
	root.ZIndex = 60
	root.Parent = window.Root

	Util.addCorner(root, metrics.Radius)

	local stroke = Util.addStroke(root, theme.Colors.PopupBorder, 1, 1)

	--// Accent strip ----------------------------------------------------
	local strip = Instance.new("Frame")

	strip.Name = "Accent"
	strip.AnchorPoint = Vector2.new(0, 0.5)
	strip.BackgroundColor3 = accent
	strip.BorderSizePixel = 0
	strip.Position = UDim2.new(0, 0, 0.5, 0)
	strip.Size = UDim2.new(0, metrics.AccentWidth, 1, 0)
	strip.ZIndex = 61
	strip.Parent = root

	--// Icon --------------------------------------------------------------
	local icon = Icon.create(iconName, {
		Size = metrics.IconSize,
		Color = accent,
		Parent = root,
		Position = UDim2.fromOffset(metrics.Padding + 2, metrics.Padding + 1),
		Name = "Icon",
		ZIndex = 62,
	})

	--// Text ------------------------------------------------------------------
	local textLeft = metrics.Padding + metrics.IconSize + 10
	local hasTitle = props.Title ~= nil and props.Title ~= ""

	local title = Instance.new("TextLabel")

	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(textLeft, metrics.Padding - 2)
	title.Size = UDim2.new(1, -(textLeft + metrics.Padding), 0, 16)
	title.Text = props.Title or ""
	title.TextColor3 = theme.Colors.Text
	title.TextSize = metrics.TitleTextSize
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextYAlignment = Enum.TextYAlignment.Center
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Visible = hasTitle
	title.ZIndex = 62
	title.Parent = root

	Util.setFont(title, theme.Fonts.Bold)

	local body = Instance.new("TextLabel")

	body.Name = "Text"
	body.BackgroundTransparency = 1
	body.Position = UDim2.fromOffset(textLeft, hasTitle and (metrics.Padding + 14) or (metrics.Padding - 2))
	body.Size = UDim2.new(1, -(textLeft + metrics.Padding), 0, 16)
	body.Text = props.Text or ""
	body.TextColor3 = theme.Colors.TextDim
	body.TextSize = metrics.TextSize
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Center
	body.TextTruncate = Enum.TextTruncate.AtEnd
	body.ZIndex = 62
	body.Parent = root

	Util.setFont(body, theme.Fonts.Small)

	--// Progress ------------------------------------------------------------
	local progress = Instance.new("Frame")

	progress.Name = "Progress"
	progress.AnchorPoint = Vector2.new(0, 1)
	progress.BackgroundColor3 = accent
	progress.BackgroundTransparency = 0.45
	progress.BorderSizePixel = 0
	progress.Position = UDim2.new(0, 0, 1, 0)
	progress.Size = UDim2.new(1, 0, 0, 2)
	progress.ZIndex = 62
	progress.Parent = root

	local height = math.max(metrics.MinHeight, (hasTitle and 34 or 24) + metrics.Padding * 2)

	root.Size = UDim2.fromOffset(metrics.Width, height)
	self.Height = height

	self.Root = root
	self._closed = false
	self.Accent = accent
	self.Title = title
	self.Text = body

	--// Animation ------------------------------------------------------------
	local targetPosition = UDim2.new(1, -metrics.Margin, 1, -metrics.Margin)

	Util.tween(root, { BackgroundTransparency = 0 }, theme, { Duration = theme.Animation.Normal })
	Util.tween(stroke, { Transparency = 0 }, theme, { Duration = theme.Animation.Normal })
	Util.tween(root, { Position = targetPosition }, theme, {
		Duration = theme.Animation.Slow,
		Style = theme.Animation.Easing,
	})

	local progressTween = TweenService:Create(
		progress,
		TweenInfo.new(self.Duration, Enum.EasingStyle.Linear),
		{ Size = UDim2.new(0, 0, 0, 2) }
	)

	progressTween:Play()
	self._maid:Add(progressTween)

	if self.Duration > 0 then
		task.delay(self.Duration, function()
			if not self._closed then
				self:Close()
			end
		end)
	end

	--// Click to dismiss -------------------------------------------------------
	root.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			self:Close()
		end
	end)

	return self :: Notification
end

--// Public API -------------------------------------------------------

function Notification.Close(self: Notification)
	if self.Closing then
		return
	end

	self.Closing = true
	self._closed = true

	local theme = self.Theme
	local metrics = theme.Metrics.Notification
	local root = self.Root

	Util.tween(root, { Position = UDim2.new(1, metrics.Margin + metrics.Width, 1, -metrics.Margin) }, theme, {
		Duration = theme.Animation.Normal,
		Style = theme.Animation.EasingIn,
	})
	Util.tween(root, { BackgroundTransparency = 1 }, theme, { Duration = theme.Animation.Normal })

	local stroke = Util.findClass(root, "UIStroke")

	if stroke ~= nil then
		Util.tween(stroke, { Transparency = 1 }, theme, { Duration = theme.Animation.Normal })
	end

	task.delay(theme.Animation.Normal + 0.02, function()
		self._maid:Destroy()

		if root.Parent ~= nil then
			root:Destroy()
		end

		if self._onClosed ~= nil then
			self._onClosed()
		end

		if self._layout ~= nil then
			self._layout()
		end
	end)
end

function Notification.IsClosed(self: Notification): boolean
	return self.Closing
end

return Notification
