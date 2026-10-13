--!strict
--[[
	MidnightUI · Util
	------------------------------------------------------------------
	Small, dependency-free helpers shared by every module:

		· instance factories (Util.new / setProps / addCorner / ...)
		· typography (Montserrat FontFace with a safe enum fallback)
		· color <-> hex conversions, number formatting
		· tweening with per-property conflict handling
		· ripple feedback for interactive elements
]]

local TweenService = game:GetService("TweenService")

local Maid = require(script.Parent.Maid)
local Theme = require(script.Parent.Theme)

type FontSpec = Theme.FontSpec

local Util = {}

export type Props = { [string]: any }

--// Instance helpers -------------------------------------------------

--- Creates an instance, applies properties and parents children.
--- Properties are applied *before* parenting (faster, no flicker).
function Util.new(className: string, props: Props?, children: { Instance }?): any
	local object = Instance.new(className)

	if props then
		for key, value in props do
			(object :: any)[key] = value
		end
	end

	if children then
		for _, child in children do
			child.Parent = object
		end
	end

	return object
end

--- Applies a property bag, swallowing no errors but skipping nil values.
function Util.setProps(object: any, props: Props): any
	for key, value in props do
		if value ~= nil then
			object[key] = value
		end
	end

	return object
end

--- Finds the first child of a given class name.
function Util.findClass(parent: Instance, className: string): any
	for _, child in parent:GetChildren() do
		if child.ClassName == className then
			return child
		end
	end

	return nil
end

--- Destroys every child of an instance.
function Util.clearChildren(parent: Instance)
	for _, child in parent:GetChildren() do
		if child.Parent == parent then
			child:Destroy()
		end
	end
end

--// Layout classes ---------------------------------------------------

function Util.addCorner(object: GuiObject, radius: number): UICorner
	local corner = Util.findClass(object, "UICorner")

	if corner == nil then
		corner = Instance.new("UICorner")
		corner.Parent = object
	end

	corner.CornerRadius = UDim.new(0, math.max(0, radius))

	return corner
end

function Util.addStroke(object: GuiObject, color: Color3, thickness: number, transparency: number?): UIStroke
	local stroke = Util.findClass(object, "UIStroke")

	if stroke == nil then
		stroke = Instance.new("UIStroke")
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.LineJoinMode = Enum.LineJoinMode.Round
		stroke.Parent = object
	end

	stroke.Color = color
	stroke.Thickness = math.max(0, thickness)
	stroke.Transparency = transparency or 0

	return stroke
end

function Util.addPadding(object: GuiObject, left: number, right: number, top: number, bottom: number): UIPadding
	local padding = Util.findClass(object, "UIPadding")

	if padding == nil then
		padding = Instance.new("UIPadding")
		padding.Parent = object
	end

	padding.PaddingLeft = UDim.new(0, left)
	padding.PaddingRight = UDim.new(0, right)
	padding.PaddingTop = UDim.new(0, top)
	padding.PaddingBottom = UDim.new(0, bottom)

	return padding
end

export type ListOptions = {
	Padding: number?,
	Direction: Enum.FillDirection?,
	HorizontalAlignment: Enum.HorizontalAlignment?,
	VerticalAlignment: Enum.VerticalAlignment?,
	SortOrder: Enum.SortOrder?,
	Wraps: boolean?,
	HorizontalFlex: Enum.UIFlexAlignment?,
	VerticalFlex: Enum.UIFlexAlignment?,
}

function Util.addList(object: GuiObject, options: ListOptions?): UIListLayout
	local list = Util.findClass(object, "UIListLayout")

	if list == nil then
		list = Instance.new("UIListLayout")
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Parent = object
	end

	if options then
		list.Padding = UDim.new(0, options.Padding or 0)

		if options.Direction then
			list.FillDirection = options.Direction
		end

		if options.HorizontalAlignment then
			list.HorizontalAlignment = options.HorizontalAlignment
		end

		if options.VerticalAlignment then
			list.VerticalAlignment = options.VerticalAlignment
		end

		if options.SortOrder then
			list.SortOrder = options.SortOrder
		end

		if options.Wraps ~= nil then
			list.Wraps = options.Wraps == true
		end

		if options.HorizontalFlex then
			list.HorizontalFlex = options.HorizontalFlex
		end

		if options.VerticalFlex then
			list.VerticalFlex = options.VerticalFlex
		end
	end

	return list
end

--- Convenience: a transparent, non-interactive container frame.
function Util.container(parent: Instance, name: string, size: UDim2?, position: UDim2?): Frame
	local frame = Instance.new("Frame")

	frame.Name = name
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Size = size or UDim2.fromScale(1, 1)
	frame.Position = position or UDim2.fromScale(0, 0)
	frame.Parent = parent

	return frame
end

--// Typography -------------------------------------------------------

local FONT_CACHE: { [string]: any } = {}
local FONT_FACE_SUPPORTED: boolean? = nil

local function fontFaceSupported(): boolean
	if FONT_FACE_SUPPORTED == nil then
		local ok = pcall(function()
			return Font.fromName("Montserrat", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
		end)

		FONT_FACE_SUPPORTED = ok
	end

	return FONT_FACE_SUPPORTED :: boolean
end

local function resolveFont(spec: FontSpec): any
	local key = spec.Family .. "|" .. tostring(spec.Weight) .. "|" .. tostring(spec.Style)
	local cached = FONT_CACHE[key]

	if cached ~= nil then
		return cached
	end

	local ok, font = pcall(function()
		return Font.fromName(spec.Family, spec.Weight, spec.Style)
	end)

	if ok and font ~= nil then
		FONT_CACHE[key] = font

		return font
	end

	return nil
end

--- Applies a theme font spec to any text-bearing GuiObject.
function Util.setFont(object: GuiObject, spec: FontSpec)
	local target = object :: any

	if fontFaceSupported() then
		local font = resolveFont(spec)

		if font ~= nil then
			local ok = pcall(function()
				target.FontFace = font
			end)

			if ok then
				return
			end
		end
	end

	target.Font = spec.Fallback
end

--// Math & formatting ------------------------------------------------

function Util.clamp(value: number, minimum: number, maximum: number): number
	if value < minimum then
		return minimum
	elseif value > maximum then
		return maximum
	end

	return value
end

function Util.lerp(a: number, b: number, alpha: number): number
	return a + (b - a) * alpha
end

function Util.inverseLerp(a: number, b: number, value: number): number
	if b == a then
		return 0
	end

	return Util.clamp((value - a) / (b - a), 0, 1)
end

function Util.round(value: number, decimals: number?): number
	local places = decimals or 0
	local multiplier = 10 ^ places

	return math.floor(value * multiplier + 0.5) / multiplier
end

--- Snaps a value to the closest step (step <= 0 disables snapping).
function Util.snap(value: number, step: number?, minimum: number?): number
	if step == nil or step <= 0 then
		return value
	end

	local origin = minimum or 0

	return origin + math.floor((value - origin) / step + 0.5) * step
end

--- 1234567 -> "1,234,567"
function Util.comma(value: number): string
	local formatted = tostring(value)
	local separatorCount = 0

	repeat
		formatted, separatorCount = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
	until separatorCount == 0

	return formatted
end

--- Formats a numeric value the way sliders display it.
function Util.formatValue(value: number, decimals: number, prefix: string?, suffix: string?): string
	local text = tostring(Util.round(value, decimals))

	if decimals > 0 and not text:find("%.") then
		text ..= "." .. string.rep("0", decimals)
	elseif decimals > 0 then
		local _, dotIndex = text:find("%.")
		local fraction = #text - (dotIndex :: number)

		if fraction < decimals then
			text ..= string.rep("0", decimals - fraction)
		end
	end

	return (prefix or "") .. text .. (suffix or "")
end

--// Colors -----------------------------------------------------------

function Util.colorToHex(color: Color3): string
	return string.format(
		"%02X%02X%02X",
		math.floor(color.R * 255 + 0.5),
		math.floor(color.G * 255 + 0.5),
		math.floor(color.B * 255 + 0.5)
	)
end

--- Accepts "#RRGGBB", "RRGGBB", "#RGB", "RGB" — returns nil when invalid.
function Util.hexToColor(hex: string): Color3?
	local value = hex:gsub("#", ""):gsub("%s+", "")

	if #value == 3 then
		value = value:sub(1, 1):rep(2) .. value:sub(2, 2):rep(2) .. value:sub(3, 3):rep(2)
	end

	if #value ~= 6 or value:match("^%x%x%x%x%x%x$") == nil then
		return nil
	end

	local red = tonumber(value:sub(1, 2), 16)
	local green = tonumber(value:sub(3, 4), 16)
	local blue = tonumber(value:sub(5, 6), 16)

	if red == nil or green == nil or blue == nil then
		return nil
	end

	return Color3.fromRGB(red, green, blue)
end

--- Builds a UIGradient if needed and returns it.
function Util.addGradient(object: GuiObject, from: Color3, to: Color3, rotation: number?): UIGradient
	local gradient = Util.findClass(object, "UIGradient")

	if gradient == nil then
		gradient = Instance.new("UIGradient")
		gradient.Parent = object
	end

	gradient.Color = ColorSequence.new(from, to)
	gradient.Rotation = rotation or 0

	return gradient
end

--// Tweening ---------------------------------------------------------

local ACTIVE_TWEENS: { [any]: { [string]: Tween } } = setmetatable({}, { __mode = "k" }) :: any

local function cancelPropertyTweens(object: any, props: Props)
	local tracked = ACTIVE_TWEENS[object]

	if tracked == nil then
		return
	end

	for property in props do
		local tween = tracked[property]

		if tween ~= nil then
			tween:Cancel()
			tracked[property] = nil
		end
	end
end

export type TweenOptions = {
	Duration: number?,
	Style: Enum.EasingStyle?,
	Direction: Enum.EasingDirection?,
	RepeatCount: number?,
	Reverses: boolean?,
	DelayTime: number?,
	NoOverride: boolean?,
}

--- Tweens `props` on `object`, cancelling earlier tweens of the same
--- properties so animations never fight each other.
function Util.tween(object: any, props: Props, theme: Theme.Theme?, options: TweenOptions?): Tween
	local resolvedTheme = theme
	local duration = (options and options.Duration) or (resolvedTheme and resolvedTheme.Animation.Normal) or 0.22

	if resolvedTheme ~= nil and not resolvedTheme.Animation.Enabled then
		duration = 0
	end

	if options and options.NoOverride == true then
		-- keep previously tracked tweens alive
	else
		cancelPropertyTweens(object, props)
	end

	local info = TweenInfo.new(
		duration,
		(options and options.Style) or (resolvedTheme and resolvedTheme.Animation.Easing) or Enum.EasingStyle.Quint,
		(options and options.Direction) or Enum.EasingDirection.Out,
		(options and options.RepeatCount) or 0,
		(options and options.Reverses) or false,
		(options and options.DelayTime) or 0
	)

	local tween = TweenService:Create(object, info, props)

	local tracked = ACTIVE_TWEENS[object]

	if tracked == nil then
		tracked = {}
		ACTIVE_TWEENS[object] = tracked
	end

	if options == nil or options.NoOverride ~= true then
		for property in props do
			tracked[property] = tween
		end
	end

	tween:Play()

	return tween
end

--- Sets properties immediately (used when animations are disabled).
function Util.setInstant(object: any, props: Props)
	cancelPropertyTweens(object, props)
	Util.setProps(object, props)
end

--- Awaits a tween without yielding the whole script when it finishes
--- instantly (duration == 0).
function Util.awaitTween(tween: Tween)
	if tween.PlaybackState == Enum.PlaybackState.Completed then
		return
	end

	tween.Completed:Wait()
end

--// Interaction feedback --------------------------------------------

local RIPPLE_LIMIT = 4

--- Spawns a material-style ripple inside `frame` at the input position.
function Util.ripple(frame: GuiObject, inputPosition: Vector2, color: Color3, maid: Maid.Maid?)
	local existing = 0

	for _, child in frame:GetChildren() do
		if child:GetAttribute("MidnightRipple") then
			existing += 1
		end
	end

	if existing >= RIPPLE_LIMIT then
		return
	end

	local position = Vector2.new(
		Util.clamp(inputPosition.X - frame.AbsolutePosition.X, 0, math.max(frame.AbsoluteSize.X, 1)),
		Util.clamp(inputPosition.Y - frame.AbsolutePosition.Y, 0, math.max(frame.AbsoluteSize.Y, 1))
	)

		local diameter = math.max(math.max(frame.AbsoluteSize.X, frame.AbsoluteSize.Y) * 1.6, 8)

	local ripple = Instance.new("Frame")
	ripple.Name = "Ripple"
	ripple:SetAttribute("MidnightRipple", true)
	ripple.AnchorPoint = Vector2.new(0.5, 0.5)
	ripple.BackgroundColor3 = color
	ripple.BackgroundTransparency = 0.78
	ripple.BorderSizePixel = 0
	ripple.Position = UDim2.fromOffset(math.floor(position.X), math.floor(position.Y))
	ripple.Size = UDim2.fromOffset(0, 0)
	ripple.ZIndex = frame.ZIndex + 1
	ripple.Parent = frame

	Util.addCorner(ripple, diameter / 2)

	local tween = TweenService:Create(
		ripple,
		TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{
			Size = UDim2.fromOffset(math.floor(diameter), math.floor(diameter)),
			BackgroundTransparency = 1,
		}
	)

	tween:Play()

	local cleanup = function()
		ripple:Destroy()
	end

	if maid ~= nil then
		maid:Add(cleanup)
		maid:Add(tween)
	else
		tween.Completed:Once(cleanup)
	end
end

--- Debounces a function so it only runs once per `delay` window.
function Util.debounce(callback: (...any) -> (), delay: number): (...any) -> ()
	local lastCall = 0

	return function(...)
		local now = os.clock()

		if now - lastCall < delay then
			return
		end

		lastCall = now

		callback(...)
	end
end

--- Smoothly scrolls a ScrollingFrame to an absolute Y canvas offset.
function Util.scrollTo(frame: ScrollingFrame, y: number, theme: Theme.Theme?): Tween
	local maximum = math.max(0, frame.AbsoluteCanvasSize.Y - frame.AbsoluteSize.Y)
	local target = Util.clamp(y, 0, maximum)

	return Util.tween(frame, { CanvasPosition = Vector2.new(frame.CanvasPosition.X, target) }, theme, {
		Duration = 0.3,
	})
end

return Util
