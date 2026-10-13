--!strict
--[[
	MidnightUI · Popup
	------------------------------------------------------------------
	Floating surface used by Dropdown, ColorPicker, the search bar, the
	settings panel and tooltips.

	Popups live in the window's overlay layer (never inside a
	ScrollingFrame), so they are never clipped. While a popup is open
	its position is refreshed every frame, which keeps it glued to its
	anchor even when the page underneath is being scrolled.

	Behaviour included out of the box:
		· auto flip when there is not enough space below the anchor
		· click-outside / Escape to close
		· scale + fade opening animation
		· one popup at a time per window
]]

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Maid = require(script.Parent.Maid)
local Util = require(script.Parent.Util)

local Popup = {}
Popup.__index = Popup

export type ContentCallback = (parent: Frame) -> number

export type Config = {
	Anchor: GuiObject,
	Width: number?,
	Content: ContentCallback,
	Direction: ("Down" | "Up" | "Auto")?,
	Offset: number?,
	Padding: number?,
	Radius: number?,
	OnClose: (() -> ())?,
	Name: string?,
	--- `false` lets the caller manage its own children (used by the
	--- dropdown so that its search box keeps focus while filtering).
	Rebuild: boolean?,
}

export type Popup = typeof(setmetatable(
	{} :: {
		Window: any,
		Theme: any,
		Anchor: GuiObject,
		Root: Frame,
		Inner: Frame,
		Scale: UIScale,
		Width: number,
		Height: number,
		Direction: string,
		Offset: number,
		Padding: number,
		Open: boolean,
		Closing: boolean,
		_content: ContentCallback,
		_rebuild: boolean,
		_onClose: (() -> ())?,
		_maid: any,
	},
	Popup
))

--// Positioning ------------------------------------------------------

function Popup._computePosition(self: Popup)
	local window = self.Window
	local overlay = window.Overlay
	local anchor = self.Anchor

	if anchor == nil or anchor.Parent == nil or overlay == nil or overlay.Parent == nil then
		Popup.Close(self)

		return
	end

	local scale = math.max(window:GetScale(), 0.01)
	local anchorPosition = anchor.AbsolutePosition - overlay.AbsolutePosition
	local anchorSize = anchor.AbsoluteSize
	local overlaySize = overlay.AbsoluteSize

	local width = self.Width * scale
	local height = self.Height * scale

	local direction = self.Direction

	if direction == "Auto" then
		local spaceBelow = overlaySize.Y - (anchorPosition.Y + anchorSize.Y)
		local spaceAbove = anchorPosition.Y

		direction = (spaceBelow >= height + self.Offset * scale or spaceBelow >= spaceAbove) and "Down" or "Up"
	end

	local y: number

	if direction == "Down" then
		y = anchorPosition.Y + anchorSize.Y + self.Offset * scale
	else
		y = anchorPosition.Y - height - self.Offset * scale
	end

	local x = anchorPosition.X

	if x + width > overlaySize.X then
		x = overlaySize.X - width
	end

	x = math.max(0, math.min(x, math.max(0, overlaySize.X - width)))
	y = math.max(0, math.min(y, math.max(0, overlaySize.Y - height)))

	self.Root.Position = UDim2.fromOffset(math.floor(x / scale), math.floor(y / scale))
end

--// Input ------------------------------------------------------------

local function isInside(position: Vector2, objectPosition: Vector2, objectSize: Vector2): boolean
	return position.X >= objectPosition.X
		and position.X <= objectPosition.X + objectSize.X
		and position.Y >= objectPosition.Y
		and position.Y <= objectPosition.Y + objectSize.Y
end

function Popup._bindInput(self: Popup)
	self._maid:Add(UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed or not self:IsOpen() then
			return
		end

		if input.KeyCode == Enum.KeyCode.Escape then
			Popup.Close(self)

			return
		end

		local inputType = input.UserInputType

		if inputType ~= Enum.UserInputType.MouseButton1
			and inputType ~= Enum.UserInputType.MouseButton2
			and inputType ~= Enum.UserInputType.Touch
		then
			return
		end

		local position = Vector2.new(input.Position.X, input.Position.Y)

		if isInside(position, self.Root.AbsolutePosition, self.Root.AbsoluteSize) then
			return
		end

		if isInside(position, self.Anchor.AbsolutePosition, self.Anchor.AbsoluteSize) then
			return
		end

		Popup.Close(self)
	end))

	self._maid:Add(RunService.RenderStepped:Connect(function()
		if self:IsOpen() then
			Popup._computePosition(self)
		end
	end))

	self._maid:Add(self.Window.VisibilityChanged:Connect(function(visible: boolean)
		if not visible then
			Popup.Close(self)
		end
	end))

	self._maid:Add(self.Window.ThemeChanged:Connect(function()
		Popup.Close(self)
	end))
end

--// Construction -----------------------------------------------------

function Popup.new(window: any, config: Config): Popup
	local theme = window.Theme
	local metrics = theme.Metrics

	local self: any = setmetatable({}, Popup)

	self.Window = window
	self.Theme = theme
	self.Anchor = config.Anchor
	self.Direction = config.Direction or "Auto"
	self.Offset = config.Offset or metrics.Popup.Offset
	self.Padding = config.Padding or metrics.Popup.Padding
	self.Open = true
	self.Closing = false
	self._content = config.Content
	self._onClose = config.OnClose
	self._rebuild = config.Rebuild ~= false
	self._maid = Maid.new()

	local radius = config.Radius or metrics.Popup.Radius
	local width = config.Width or config.Anchor.AbsoluteSize.X

	if width == nil or width <= 0 then
		width = 160
	end

	self.Width = width

	local root = Instance.new("Frame")

	root.Name = config.Name or "Popup"
	root.BackgroundColor3 = theme.Colors.Popup
	root.BackgroundTransparency = 1
	root.BorderSizePixel = 0
	root.ClipsDescendants = false
	root.Size = UDim2.fromOffset(width, 0)
	root.ZIndex = 20
	root.Parent = window.Overlay

	Util.addCorner(root, radius)

	local stroke = Util.addStroke(root, theme.Colors.PopupBorder, 1, 1)

	local scale = Instance.new("UIScale")

	scale.Scale = 0.97
	scale.Parent = root

	local inner = Instance.new("Frame")

	inner.Name = "Content"
	inner.BackgroundTransparency = 1
	inner.BorderSizePixel = 0
	inner.Position = UDim2.fromOffset(self.Padding, self.Padding)
	inner.Size = UDim2.new(1, -self.Padding * 2, 1, -self.Padding * 2)
	inner.ClipsDescendants = false
	inner.ZIndex = 21
	inner.Parent = root

	self.Root = root
	self.Inner = inner
	self.Scale = scale

	local contentHeight = self._content(inner) or 0

	self.Height = math.max(0, contentHeight) + self.Padding * 2
	root.Size = UDim2.fromOffset(width, self.Height)

	Popup._computePosition(self)
	Popup._bindInput(self)

	Util.tween(root, { BackgroundTransparency = 0 }, theme, {
		Duration = theme.Animation.Fast,
	})
	Util.tween(stroke, { Transparency = 0 }, theme, {
		Duration = theme.Animation.Fast,
	})
	Util.tween(scale, { Scale = 1 }, theme, {
		Duration = theme.Animation.Normal,
		Style = theme.Animation.EasingBounce,
	})

	return self :: Popup
end

--// Public API -------------------------------------------------------

--- Rebuilds the popup content and resizes it (dropdowns use this while
--- filtering, colour pickers when switching to the advanced view, …).
function Popup.Refresh(self: Popup)
	if not self:IsOpen() then
		return
	end

	if self._rebuild then
		Util.clearChildren(self.Inner)
	end

	local contentHeight = self._content(self.Inner) or 0

	self.Height = math.max(0, contentHeight) + self.Padding * 2
	self.Root.Size = UDim2.fromOffset(self.Width, self.Height)

	Popup._computePosition(self)
end

--- Changes the popup width (e.g. when the anchor resized).
function Popup.SetWidth(self: Popup, width: number)
	if width <= 0 or width == self.Width then
		return
	end

	self.Width = width
	self.Root.Size = UDim2.fromOffset(width, self.Height)

	Popup._computePosition(self)
end

function Popup.Close(self: Popup)
	if self.Closing or not self.Open then
		return
	end

	self.Closing = true

	local theme = self.Theme
	local root = self.Root
	local stroke = Util.findClass(root, "UIStroke")
	local duration = theme.Animation.Enabled and theme.Animation.Fast or 0

	Util.tween(root, { BackgroundTransparency = 1 }, theme, { Duration = duration })
	Util.tween(self.Scale, { Scale = 0.97 }, theme, { Duration = duration })

	if stroke ~= nil then
		Util.tween(stroke, { Transparency = 1 }, theme, { Duration = duration })
	end

	task.delay(duration, function()
		self.Open = false
		self._maid:Destroy()

		if root.Parent ~= nil then
			root:Destroy()
		end

		if self._onClose ~= nil then
			local ok, err = pcall(self._onClose)

			if not ok then
				warn(("[MidnightUI] Popup close handler errored: %s"):format(tostring(err)))
			end
		end
	end)
end

function Popup.IsOpen(self: Popup): boolean
	return self.Open and not self.Closing
end

return Popup
