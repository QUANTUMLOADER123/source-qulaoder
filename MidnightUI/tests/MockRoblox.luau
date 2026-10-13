--!nocheck
--[[
	MockRoblox — a dependency-free simulation of the Roblox API surface
	MidnightUI uses. It exists so the library can be executed end to end
	(and regression tested) outside of Roblox:

		· Instances with validated properties (typos throw)
		· datatypes: Color3 / Vector2 / UDim / UDim2 / TweenInfo / Font /
		  NumberSequence / ColorSequence / Rect
		· Enums (value + typeof support through a `typeof` override)
		· a miniature layout engine for AbsolutePosition / AbsoluteSize,
		  AutomaticSize, UIPadding and UIListLayout
		· services: TweenService, UserInputService, Players, RunService,
		  GuiService, TextService, CoreGui
		· a deterministic task scheduler you can pump from tests

	Not shipped with the library — `src/` has no knowledge of it.
]]

local Mock = {}

--// Signal -------------------------------------------------------------------

local function newSignal()
	local handlers = {}
	local signal = {}

	function signal:Connect(callback)
		table.insert(handlers, callback)

		local connection = {
			Connected = true,
		}

		function connection:Disconnect()
			connection.Connected = false

			for index, stored in handlers do
				if stored == callback then
					table.remove(handlers, index)
					break
				end
			end
		end

		return connection
	end

	function signal:Once(callback)
		local connection

		connection = signal:Connect(function(...)
			connection:Disconnect()

			callback(...)
		end)

		return connection
	end

	function signal:Wait()
		error("MockRoblox signals cannot be awaited", 2)
	end

	function signal:Fire(...)
		for _, callback in table.clone(handlers) do
			callback(...)
		end
	end

	function signal:GetHandlerCount()
		return #handlers
	end

	return signal
end

Mock.newSignal = newSignal

--// Datatypes -----------------------------------------------------------------

local function tracebackSuffix(): string
	local debugLib = rawget(_G, "debug")

	if debugLib == nil or debugLib.traceback == nil then
		return ""
	end

	local ok, trace = pcall(debugLib.traceback, "", 3)

	if ok and type(trace) == "string" then
		return "\n" .. trace
	end

	return ""
end

local function mockify(value, kind)
	value.__mocktype = kind

	return value
end

local Color3 = {}
Color3.__index = Color3

function Color3.new(r, g, b)
	return mockify(setmetatable({
		R = math.clamp(r or 0, 0, 1),
		G = math.clamp(g or 0, 0, 1),
		B = math.clamp(b or 0, 0, 1),
	}, Color3), "Color3")
end

function Color3.fromRGB(r, g, b)
	return Color3.new((r or 0) / 255, (g or 0) / 255, (b or 0) / 255)
end

function Color3.fromHSV(h, s, v)
	local i = math.floor(h * 6)
	local f = h * 6 - i
	local p = v * (1 - s)
	local q = v * (1 - f * s)
	local t = v * (1 - (1 - f) * s)

	local r, g, b

	local sector = i % 6

	if sector == 0 then
		r, g, b = v, t, p
	elseif sector == 1 then
		r, g, b = q, v, p
	elseif sector == 2 then
		r, g, b = p, v, t
	elseif sector == 3 then
		r, g, b = p, q, v
	elseif sector == 4 then
		r, g, b = t, p, v
	else
		r, g, b = v, p, q
	end

	return Color3.new(r, g, b)
end

function Color3.toHSV(color)
	local r, g, b = color.R, color.G, color.B
	local maximum = math.max(r, g, b)
	local minimum = math.min(r, g, b)
	local delta = maximum - minimum
	local hue = 0

	if delta > 0 then
		if maximum == r then
			hue = ((g - b) / delta) % 6
		elseif maximum == g then
			hue = (b - r) / delta + 2
		else
			hue = (r - g) / delta + 4
		end

		hue /= 6
	end

	local saturation = maximum == 0 and 0 or delta / maximum

	return hue, saturation, maximum
end

function Color3:Lerp(other, alpha)
	return Color3.new(
		self.R + (other.R - self.R) * alpha,
		self.G + (other.G - self.G) * alpha,
		self.B + (other.B - self.B) * alpha
	)
end

function Color3.__tostring(self)
	return ("%d, %d, %d"):format(self.R * 255, self.G * 255, self.B * 255)
end

local Vector2 = {}
Vector2.__index = Vector2

function Vector2.new(x, y)
	return mockify(setmetatable({ X = x or 0, Y = y or 0 }, Vector2), "Vector2")
end

Vector2.zero = Vector2.new(0, 0)
Vector2.one = Vector2.new(1, 1)

function Vector2.__add(a, b)
	return Vector2.new(a.X + b.X, a.Y + b.Y)
end

function Vector2.__sub(a, b)
	return Vector2.new(a.X - b.X, a.Y - b.Y)
end

function Vector2.__mul(a, b)
	if type(a) == "number" then
		return Vector2.new(a * b.X, a * b.Y)
	end

	if type(b) == "number" then
		return Vector2.new(a.X * b, a.Y * b)
	end

	return Vector2.new(a.X * b.X, a.Y * b.Y)
end

function Vector2.__eq(a, b)
	return a.X == b.X and a.Y == b.Y
end

function Vector2.__tostring(self)
	return ("%s, %s"):format(tostring(self.X), tostring(self.Y))
end

function Vector2.__index(self, key)
	if key == "Magnitude" then
		return math.sqrt(self.X * self.X + self.Y * self.Y)
	end

	return rawget(Vector2, key)
end

local Vector3 = {}
Vector3.__index = Vector3

function Vector3.new(x, y, z)
	return mockify(setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, Vector3), "Vector3")
end

local UDim = {}
UDim.__index = UDim

function UDim.new(scale, offset)
	return mockify(setmetatable({ Scale = scale or 0, Offset = offset or 0 }, UDim), "UDim")
end

local UDim2 = {}
UDim2.__index = UDim2

function UDim2.new(xScale, xOffset, yScale, yOffset)
	return mockify(setmetatable({
		X = UDim.new(xScale, xOffset),
		Y = UDim.new(yScale, yOffset),
	}, UDim2), "UDim2")
end

function UDim2.fromScale(x, y)
	return UDim2.new(x, 0, y, 0)
end

function UDim2.fromOffset(x, y)
	return UDim2.new(0, x, 0, y)
end

function UDim2.__tostring(self)
	return ("{%s, %s}, {%s, %s}"):format(
		tostring(self.X.Scale),
		tostring(self.X.Offset),
		tostring(self.Y.Scale),
		tostring(self.Y.Offset)
	)
end

local Rect = {}
Rect.__index = Rect

function Rect.new(x, y, width, height)
	return mockify(setmetatable({ X = x, Y = y, Width = width, Height = height }, Rect), "Rect")
end

local NumberSequenceKeypoint = {}
NumberSequenceKeypoint.__index = NumberSequenceKeypoint

function NumberSequenceKeypoint.new(time, value)
	return mockify(setmetatable({ Time = time, Value = value }, NumberSequenceKeypoint), "NumberSequenceKeypoint")
end

local NumberSequence = {}
NumberSequence.__index = NumberSequence

function NumberSequence.new(a, b)
	if type(a) == "table" and a.Time == nil and a.Value == nil then
		return mockify(setmetatable({ Keypoints = a }, NumberSequence), "NumberSequence")
	end

	return mockify(setmetatable({
		Keypoints = {
			NumberSequenceKeypoint.new(0, a or 0),
			NumberSequenceKeypoint.new(1, b or a or 0),
		},
	}, NumberSequence), "NumberSequence")
end

local ColorSequenceKeypoint = {}
ColorSequenceKeypoint.__index = ColorSequenceKeypoint

function ColorSequenceKeypoint.new(time, color)
	return mockify(setmetatable({ Time = time, Value = color }, ColorSequenceKeypoint), "ColorSequenceKeypoint")
end

local ColorSequence = {}
ColorSequence.__index = ColorSequence

function ColorSequence.new(a, b)
	if type(a) == "table" and a.Value == nil then
		return mockify(setmetatable({ Keypoints = a }, ColorSequence), "ColorSequence")
	end

	return mockify(setmetatable({
		Keypoints = {
			ColorSequenceKeypoint.new(0, a),
			ColorSequenceKeypoint.new(1, b or a),
		},
	}, ColorSequence), "ColorSequence")
end

local TweenInfo = {}
TweenInfo.__index = TweenInfo

function TweenInfo.new(duration, style, direction, repeatCount, reverses, delayTime)
	return mockify(setmetatable({
		Time = duration or 1,
		EasingStyle = style,
		EasingDirection = direction,
		RepeatCount = repeatCount or 0,
		Reverses = reverses or false,
		DelayTime = delayTime or 0,
	}, TweenInfo), "TweenInfo")
end

local Font = {}
Font.__index = Font

function Font.fromName(family, weight, style)
	return mockify(setmetatable({
		Family = family,
		Weight = weight,
		Style = style,
	}, Font), "Font")
end

--// Enums ---------------------------------------------------------------------

local function newEnum(name, items)
	local enum = {
		Name = name,
		_items = {},
	}

	for index, itemName in items do
		local item = {
			Name = itemName,
			Value = index,
			EnumType = enum,
		}

		mockify(item, "EnumItem")
		item.__tostring = function()
			return ("Enum.%s.%s"):format(name, itemName)
		end

		setmetatable(item, {
			__index = function(_, key)
				if key == "__mocktype" then
					return "EnumItem"
				end

				return nil
			end,
			__tostring = item.__tostring,
		})

		enum._items[itemName] = item
	end

	setmetatable(enum, {
		__index = function(_, key)
			return enum._items[key]
		end,
	})

	return enum
end

local ENUM_ITEMS = {
	AutomaticSize = { "None", "X", "Y", "XY" },
	EasingStyle = {
		"Linear",
		"Sine",
		"Back",
		"Quad",
		"Quart",
		"Quint",
		"Bounce",
		"Elastic",
		"Exponential",
		"Circular",
		"Cubic",
	},
	EasingDirection = { "In", "Out", "InOut" },
	FillDirection = { "Horizontal", "Vertical" },
	HorizontalAlignment = { "Center", "Left", "Right" },
	VerticalAlignment = { "Center", "Top", "Bottom" },
	SortOrder = { "LayoutOrder", "Name", "Custom" },
	ScrollingDirection = { "X", "Y", "XY" },
	ScaleType = { "Stretch", "Slice", "Fit", "Crop", "Tile" },
	TextTruncate = { "None", "AtEnd", "AtStart" },
	TextXAlignment = { "Center", "Left", "Right" },
	TextYAlignment = { "Center", "Top", "Bottom" },
	ApplyStrokeMode = { "Contextual", "Border" },
	LineJoinMode = { "Round", "Miter", "Bevel" },
	ZIndexBehavior = { "Global", "Sibling" },
	FontStyle = { "Normal", "Italic" },
	FontWeight = { "Thin", "ExtraLight", "Light", "Regular", "Medium", "SemiBold", "Bold", "ExtraBold", "Heavy" },
	PlaybackState = { "Begin", "Delayed", "Playing", "Completed", "Cancelled" },
	Font = { "Legacy", "Gotham", "GothamMedium", "GothamBold", "GothamSemibold", "Code", "SourceSans", "Roboto" },
	UserInputType = {
		"Keyboard",
		"MouseButton1",
		"MouseButton2",
		"MouseButton3",
		"MouseWheel",
		"MouseMovement",
		"Touch",
	},
	KeyCode = {
		"Unknown",
		"Escape",
		"Backspace",
		"Return",
		"Tab",
		"CapsLock",
		"Delete",
		"Insert",
		"Home",
		"End",
		"PageUp",
		"PageDown",
		"Left",
		"Right",
		"Up",
		"Down",
		"Space",
		"LeftShift",
		"RightShift",
		"LeftControl",
		"RightControl",
		"LeftAlt",
		"RightAlt",
		"A",
		"B",
		"C",
		"D",
		"E",
		"F",
		"G",
		"H",
		"I",
		"J",
		"K",
		"L",
		"M",
		"N",
		"O",
		"P",
		"Q",
		"R",
		"S",
		"T",
		"U",
		"V",
		"W",
		"X",
		"Y",
		"Z",
	},
}

local Enum = {}

for enumName, items in ENUM_ITEMS do
	Enum[enumName] = newEnum(enumName, items)
end

--// Instances ------------------------------------------------------------------

local CLASS_HIERARCHY = {
	Instance = {},
	GuiBase2d = { "Instance" },
	GuiObject = {
		Rotation = "number",
		Selectable = "boolean",
		Active = "boolean",
		BackgroundTransparency = "number", "GuiBase2d" },
	LayerCollector = { "GuiBase2d" },
	GuiBase = { "Instance" },
	UIComponent = { "GuiBase" },
	Frame = { "GuiObject" },
	CanvasGroup = { "GuiObject" },
	ScrollingFrame = { "GuiObject" },
	ImageLabel = { "GuiObject" },
	TextLabel = { "GuiObject" },
	TextButton = { "GuiObject" },
	TextBox = { "GuiObject" },
	ScreenGui = { "LayerCollector" },
	UIListLayout = { "UIComponent" },
	UIPadding = { "UIComponent" },
	UICorner = { "UIComponent" },
	UIStroke = { "UIComponent" },
	UIGradient = { "UIComponent" },
	UIScale = { "UIComponent" },
	UITextSizeConstraint = { "UIComponent" },
	Folder = { "Instance" },
}

local PROPERTIES = {
	Instance = {
		Name = "string",
		Parent = "Instance?",
		Archivable = "boolean",
		ClassName = "readonly",
	},
	GuiBase2d = {
		AbsolutePosition = "readonly",
		AbsoluteSize = "readonly",
		AbsoluteRotation = "readonly",
	},
	GuiObject = {
		Active = "boolean",
		AnchorPoint = "Vector2",
		AutomaticSize = "AutomaticSize",
		BackgroundColor3 = "Color3",
		BackgroundTransparency = "number",
		BorderColor3 = "Color3",
		BorderMode = "number",
		BorderSizePixel = "number",
		ClipsDescendants = "boolean",
		Interactable = "boolean",
		LayoutOrder = "number",
		Position = "UDim2",
		Rotation = "number",
		Selectable = "boolean",
		Size = "UDim2",
		SizeConstraint = "number",
		Visible = "boolean",
		ZIndex = "number",
	},
	Frame = {
		Style = "number",
	},
	CanvasGroup = {
		GroupTransparency = "number",
	},
	ScrollingFrame = {
		AbsoluteCanvasSize = "readonly",
		AbsoluteWindowSize = "readonly",
		AutomaticCanvasSize = "AutomaticSize",
		CanvasPosition = "Vector2",
		CanvasSize = "UDim2",
		ElasticBehavior = "number",
		ScrollBarImageColor3 = "Color3",
		ScrollBarImageTransparency = "number",
		ScrollBarThickness = "number",
		ScrollingDirection = "ScrollingDirection",
		ScrollingEnabled = "boolean",
		VerticalScrollBarPosition = "number",
		HorizontalScrollBarInset = "number",
		VerticalScrollBarInset = "number",
	},
	TextLabel = {
		Font = "Font",
		FontFace = "Font",
		LineHeight = "number",
		MaxVisibleGraphemes = "number",
		RichText = "boolean",
		Text = "string",
		TextColor3 = "Color3",
		TextScaled = "boolean",
		TextSize = "number",
		TextStrokeColor3 = "Color3",
		TextStrokeTransparency = "number",
		TextTransparency = "number",
		TextTruncate = "TextTruncate",
		TextWrapped = "boolean",
		TextXAlignment = "TextXAlignment",
		TextYAlignment = "TextYAlignment",
	},
	TextBox = {
		ClearTextOnFocus = "boolean",
		CursorPosition = "number",
		MultiLine = "boolean",
		PlaceholderColor3 = "Color3",
		PlaceholderText = "string",
		ShowNativeInput = "boolean",
		TextEditable = "boolean",
		Font = "Font",
		FontFace = "Font",
		LineHeight = "number",
		MaxVisibleGraphemes = "number",
		RichText = "boolean",
		Text = "string",
		TextColor3 = "Color3",
		TextScaled = "boolean",
		TextSize = "number",
		TextStrokeColor3 = "Color3",
		TextStrokeTransparency = "number",
		TextTransparency = "number",
		TextTruncate = "TextTruncate",
		TextWrapped = "boolean",
		TextXAlignment = "TextXAlignment",
		TextYAlignment = "TextYAlignment",
	},
	TextButton = {
		AutoButtonColor = "boolean",
		Modal = "boolean",
		Selected = "boolean",
		Style = "number",
	},
	ImageLabel = {
		Image = "string",
		ImageColor3 = "Color3",
		ImageRectOffset = "Vector2",
		ImageRectSize = "Vector2",
		ImageTransparency = "number",
		ScaleType = "ScaleType",
		SliceCenter = "Rect",
		SliceScale = "number",
		TileSize = "UDim2",
	},
	ScreenGui = {
		DisplayOrder = "number",
		Enabled = "boolean",
		IgnoreGuiInset = "boolean",
		ResetOnSpawn = "boolean",
		ZIndexBehavior = "ZIndexBehavior",
	},
	UIListLayout = {
		AbsoluteContentSize = "readonly",
		FillDirection = "FillDirection",
		HorizontalAlignment = "HorizontalAlignment",
		HorizontalFlex = "number",
		ItemLineAlignment = "number",
		Padding = "UDim",
		SortOrder = "SortOrder",
		VerticalAlignment = "VerticalAlignment",
		VerticalFlex = "number",
		Wraps = "boolean",
	},
	UIPadding = {
		PaddingBottom = "UDim",
		PaddingLeft = "UDim",
		PaddingRight = "UDim",
		PaddingTop = "UDim",
	},
	UICorner = {
		CornerRadius = "UDim",
	},
	UIStroke = {
		ApplyStrokeMode = "ApplyStrokeMode",
		Color = "Color3",
		Enabled = "boolean",
		LineJoinMode = "LineJoinMode",
		Thickness = "number",
		Transparency = "number",
	},
	UIGradient = {
		Color = "ColorSequence",
		Enabled = "boolean",
		Offset = "Vector2",
		Rotation = "number",
		Transparency = "NumberSequence",
	},
	UIScale = {
		Scale = "number",
	},
	UITextSizeConstraint = {
		MaxTextSize = "number",
		MinTextSize = "number",
	},
}

local DEFAULTS = {
	Active = false,
	AnchorPoint = Vector2.zero,
	AutomaticSize = Enum.AutomaticSize.None,
	AutomaticCanvasSize = Enum.AutomaticSize.None,
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 0,
	BorderColor3 = Color3.new(0, 0, 0),
	BorderMode = 0,
	BorderSizePixel = 1,
	CanvasPosition = Vector2.zero,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	ClipsDescendants = false,
	CornerRadius = UDim.new(0, 0),
	DisplayOrder = 0,
	Enabled = true,
	FillDirection = Enum.FillDirection.Vertical,
	GroupTransparency = 0,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	HorizontalFlex = 0,
	IgnoreGuiInset = false,
	Image = "",
	ImageColor3 = Color3.new(1, 1, 1),
	ImageTransparency = 0,
	Interactable = true,
	ItemLineAlignment = 0,
	LayoutOrder = 0,
	LineJoinMode = Enum.LineJoinMode.Round,
	MaxTextSize = 100,
	MaxVisibleGraphemes = -1,
	MinTextSize = 1,
	Modal = false,
	MultiLine = false,
	Name = "",
	Padding = UDim.new(0, 0),
	PaddingBottom = UDim.new(0, 0),
	PaddingLeft = UDim.new(0, 0),
	PaddingRight = UDim.new(0, 0),
	PaddingTop = UDim.new(0, 0),
	Position = UDim2.new(0, 0, 0, 0),
	ResetOnSpawn = true,
	RichText = false,
	Rotation = 0,
	Scale = 1,
	ScaleType = Enum.ScaleType.Stretch,
	ScrollBarImageColor3 = Color3.new(1, 1, 1),
	ScrollBarImageTransparency = 0,
	ScrollBarThickness = 12,
	ScrollingDirection = Enum.ScrollingDirection.XY,
	ScrollingEnabled = true,
	Selectable = true,
	Size = UDim2.new(0, 0, 0, 0),
	SliceScale = 1,
	SortOrder = Enum.SortOrder.Name,
	Style = 0,
	Text = "",
	TextColor3 = Color3.new(0, 0, 0),
	TextEditable = true,
	TextScaled = false,
	TextSize = 14,
	TextStrokeColor3 = Color3.new(0, 0, 0),
	TextStrokeTransparency = 1,
	TextTransparency = 0,
	TextTruncate = Enum.TextTruncate.None,
	TextWrapped = false,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextYAlignment = Enum.TextYAlignment.Center,
	Thickness = 1,
	Transparency = 0,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	VerticalFlex = 0,
	Visible = true,
	Wraps = false,
	ZIndex = 1,
	ZIndexBehavior = Enum.ZIndexBehavior.Global,
	Archivable = true,
	CursorPosition = -1,
	ClearTextOnFocus = true,
	PlaceholderColor3 = Color3.new(0.5, 0.5, 0.5),
	PlaceholderText = "",
	ShowNativeInput = true,
	Selected = false,
	AutoButtonColor = true,
	ElasticBehavior = 0,
	HorizontalScrollBarInset = 0,
	VerticalScrollBarInset = 0,
	VerticalScrollBarPosition = 0,
	Font = Enum.Font.Gotham,
	FontFace = nil,
	LineHeight = 1,
}

local EVENTS = {
	"AncestryChanged",
	"Changed",
	"ChildAdded",
	"ChildRemoved",
	"Destroying",
	"DescendantAdded",
	"DescendantRemoving",
	"InputBegan",
	"InputChanged",
	"InputEnded",
	"MouseButton1Click",
	"MouseButton1Down",
	"MouseButton1Up",
	"MouseEnter",
	"MouseLeave",
	"MouseMoved",
	"SelectionGained",
	"SelectionLost",
	"TouchLongPress",
	"TouchPan",
	"TouchPinch",
	"TouchRotate",
	"TouchSwipe",
	"TouchTap",
	"Focused",
	"FocusLost",
	"ReturnPressedFromOnScreenKeyboard",
}

local VALIDATORS = {}

local function validateValue(kind, value): boolean
	if kind == "readonly" or kind == "any" then
		return true
	end

	local typeName = typeof(value)

	if kind == "number" then
		return typeName == "number"
	elseif kind == "string" then
		return typeName == "string"
	elseif kind == "boolean" then
		return typeName == "boolean"
	end

	if kind:sub(-1) == "?" then
		if value == nil then
			return true
		end

		return validateValue(kind:sub(1, -2), value)
	end

	if kind == "Instance?" then
		return typeName == "Instance"
	end

	if typeName == "EnumItem" then
		local enumType = rawget(value, "EnumType")

		return enumType ~= nil and enumType.Name == kind
	end

	return typeName == kind
end

-- Fallback value for a declared property kind, so reading a property that was
-- never assigned behaves like the engine instead of returning nil.
-- Enum-typed properties need the enum to exist; each entry is a closure so a
-- missing enum degrades to nil instead of breaking module load.
local FUNCTION_KINDS = { "UDim2", "UDim", "Vector2", "Color3", "Rect" }

local KIND_DEFAULTS = {
	number = function()
		return 0
	end,
	string = function()
		return ""
	end,
	boolean = function()
		return false
	end,
	UDim2 = function()
		return UDim2.new()
	end,
	UDim = function()
		return UDim.new()
	end,
	Vector2 = function()
		return Vector2.new()
	end,
	Color3 = function()
		return Color3.new()
	end,
	Rect = function()
		return Rect.new()
	end,
	AutomaticSize = function()
		return Enum.AutomaticSize.None
	end,
	SortOrder = function()
		return Enum.SortOrder.LayoutOrder
	end,
	FillDirection = function()
		return Enum.FillDirection.Vertical
	end,
	HorizontalAlignment = function()
		return Enum.HorizontalAlignment.Left
	end,
	VerticalAlignment = function()
		return Enum.VerticalAlignment.Top
	end,
	TextXAlignment = function()
		return Enum.TextXAlignment.Center
	end,
	TextYAlignment = function()
		return Enum.TextYAlignment.Center
	end,
	ScaleType = function()
		return Enum.ScaleType.Stretch
	end,
	ScrollBarVisibility = function()
		return Enum.ScrollBarVisibility.Auto
	end,
	Font = function()
		return Enum.Font.Gotham
	end,
	ZIndexBehavior = function()
		return Enum.ZIndexBehavior.Sibling
	end,
}

local KIND_DEFAULT_CACHE = {}

local function defaultForKind(kind): any
	if kind == nil or kind == "readonly" or kind == "any" then
		return nil
	end

	local cached = KIND_DEFAULT_CACHE[kind]

	if cached ~= nil then
		return cached
	end

	local baseKind = kind:sub(-1) == "?" and kind:sub(1, -2) or kind
	local factory = KIND_DEFAULTS[baseKind]
	local value = nil

	if factory ~= nil then
		local ok, result = pcall(factory)

		if ok then
			value = result
		end
	end

	if value == nil and FUNCTION_KINDS[baseKind] == nil and kind:sub(-1) ~= "?" then
		value = nil
	end

	KIND_DEFAULT_CACHE[kind] = value

	return value
end

local function buildInstance(className: string)
	local hierarchy: { string } = {}
	local cursor = className

	while cursor ~= nil do
		table.insert(hierarchy, cursor)
		cursor = CLASS_HIERARCHY[cursor] and CLASS_HIERARCHY[cursor][1] or nil
	end

	local properties = {}
	local defaults = {}

	for index = #hierarchy, 1, -1 do
		local classProps = PROPERTIES[hierarchy[index]]

		if classProps ~= nil then
			for key, value in classProps do
				properties[key] = value
			end
		end
	end

	-- type-appropriate fallbacks for properties that were never assigned
	local typeDefaults = {
		number = 0,
		string = "",
		boolean = false,
		Color3 = Color3 and Color3.new() or nil,
		UDim2 = UDim2 and UDim2.new() or nil,
		UDim = UDim and UDim.new() or nil,
		Vector2 = Vector2 and Vector2.new() or nil,
		Rect = Rect and Rect.new() or nil,
	}

	local fallbacks = {}

	for key, value in properties do
		fallbacks[key] = typeDefaults[value]
	end

	for key, value in DEFAULTS do
		fallbacks[key] = value
	end

	for key, value in DEFAULTS do
		defaults[key] = value
	end

	defaults.Name = className

	local instance = {}

	local store = {
		__className = className,
		__hierarchy = hierarchy,
		__properties = properties,
		__data = defaults,
		__defaults = fallbacks,
		__children = {},
		__signals = {},
		__attributes = {},
	}

	for _, event in EVENTS do
		if event:sub(-1) ~= "?" then
			store.__signals[event] = newSignal()
		end
	end

	local methods = {}

	local function signalFor(name: string)
		if store.__signals[name] == nil then
			store.__signals[name] = newSignal()
		end

		return store.__signals[name]
	end

	function methods:GetPropertyChangedSignal(property: string)
		if store.__signals["$" .. property] == nil then
			store.__signals["$" .. property] = newSignal()
		end

		return store.__signals["$" .. property]
	end

	function methods:GetChildren()
		return table.clone(store.__children)
	end

	function methods:GetDescendants()
		local descendants = {}

		for _, child in store.__children do
			table.insert(descendants, child)

			for _, grandchild in (child :: any):GetDescendants() do
				table.insert(descendants, grandchild)
			end
		end

		return descendants
	end

	function methods:FindFirstChild(name: string, recursive: boolean?)
		for _, child in store.__children do
			if child.Name == name then
				return child
			end
		end

		if recursive then
			for _, child in store.__children do
				local found = child:FindFirstChild(name, true)

				if found ~= nil then
					return found
				end
			end
		end

		return nil
	end

	function methods:FindFirstChildOfClass(wanted: string)
		for _, child in store.__children do
			if child.ClassName == wanted then
				return child
			end
		end

		return nil
	end

	function methods:FindFirstChildWhichIsA(wanted: string)
		for _, child in store.__children do
			if child:IsA(wanted) then
				return child
			end
		end

		return nil
	end

	function methods:WaitForChild(name: string)
		local found = methods:FindFirstChild(name)

		if found ~= nil then
			return found
		end

		error(("MockRoblox: WaitForChild(%q) timed out"):format(name))
	end

	function methods:IsA(wanted: string): boolean
		if wanted == className then
			return true
		end

		for _, entry in hierarchy do
			if entry == wanted then
				return true
			end
		end

		return false
	end

	function methods:IsDescendantOf(ancestor: any): boolean
		local parent = store.__data.Parent

		while parent ~= nil do
			if parent == ancestor then
				return true
			end

			parent = parent.Parent
		end

		return false
	end

	function methods:SetAttribute(name: string, value: any)
		store.__attributes[name] = value
	end

	function methods:GetAttribute(name: string)
		return store.__attributes[name]
	end

	function methods:Destroy()
		for _, child in table.clone(store.__children) do
			local target = child :: any

			target:Destroy()
		end

		signalFor("Destroying"):Fire()

		local parent = store.__data.Parent

		if parent ~= nil then
			parent:__removeChild(instance)
		end

		store.__data.Parent = nil
		store.__destroyed = true
	end

	function methods:__addChild(child: any)
		if table.find(store.__children, child) == nil then
			table.insert(store.__children, child)
		end

		signalFor("ChildAdded"):Fire(child)
	end

	function methods:__removeChild(child: any)
		local index = table.find(store.__children, child)

		if index ~= nil then
			table.remove(store.__children, index)
		end

		signalFor("ChildRemoved"):Fire(child)
	end

	function methods:CaptureFocus()
		local signal = store.__signals["$IsFocused"]

		if signal ~= nil then
			signal:Fire(true)
		end

		signalFor("Focused"):Fire()
		store.__data.__focused = true
	end

	function methods:ReleaseFocus()
		signalFor("FocusLost"):Fire(false, nil)
		store.__data.__focused = false
	end

	function methods:IsFocused(): boolean
		return store.__data.__focused == true
	end

	function methods:__signal(name: string)
		return signalFor(name)
	end

	local metatable = {
		__mocktype = "Instance",
		__index = function(_, key)
			local propertyKind = store.__properties[key]

			-- read-only computed properties
			if key == "AbsolutePosition" or key == "AbsoluteSize" or key == "AbsoluteCanvasSize"
				or key == "AbsoluteWindowSize" or key == "AbsoluteContentSize" or key == "AbsoluteRotation"
			then
				local computed = Mock.computeLayout(instance)

				return computed[key]
			end

			if propertyKind ~= nil then
				local value = store.__data[key]

				if value == nil then
					value = store.__defaults[key] or defaultForKind(propertyKind)
				end

				return value
			end

			local method = methods[key]

			if method ~= nil then
				return method
			end

			if store.__signals[key] ~= nil then
				return store.__signals[key]
			end

			-- Unknown members read as nil and are recorded, so a missing
			-- property never aborts a long scenario mid-way.
			store.__properties[key] = "any"
			table.insert(Mock.AutoProperties, ("%s.%s (read)"):format(className, tostring(key)))

			return nil
		end,
		__newindex = function(_, key, value)
			if key == "Parent" then
				local previous = store.__data.Parent

				if previous == instance then
					return
				end

				if previous ~= nil then
					previous:__removeChild(instance)
				end

				store.__data.Parent = value

				if value ~= nil then
					value:__addChild(instance)
				end

				return
			end

			local propertyKind = store.__properties[key]

			if propertyKind == nil then
				-- Unknown members are tolerated (the real engine has far more
				-- properties than this mock models) but every first write is
				-- recorded so gaps stay visible.
				propertyKind = value == nil and "any" or typeof(value)
				store.__properties[key] = propertyKind
				table.insert(Mock.AutoProperties, ("%s.%s (%s)"):format(className, tostring(key), propertyKind))
			end

			if not validateValue(propertyKind, value) then
				error((
					"MockRoblox: %s.%s expected %s, got %s"
				):format(className, tostring(key), propertyKind, typeof(value)) .. tracebackSuffix(), 2)
			end

			store.__data[key] = value

			local propertySignal = store.__signals["$" .. key]

			if propertySignal ~= nil then
				propertySignal:Fire()
			end
		end,
		__tostring = function()
			return className .. ": " .. tostring(store.__data.Name)
		end,
	}

	setmetatable(instance, metatable)
	store.__data.ClassName = className
	store.__data.Parent = nil

	return instance
end

--// Mini layout engine ----------------------------------------------------------

local VIEWPORT = Vector2.new(1920, 1080)
Mock.ViewportSize = VIEWPORT

local LAYOUT_CACHE = setmetatable({}, { __mode = "k" })

local function getProperty(instance, key)
	return (instance :: any)[key]
end

local function getChildren(instance)
	return (instance :: any):GetChildren()
end

local function findComponent(instance, className)
	return (instance :: any):FindFirstChildOfClass(className)
end

local function measureText(instance, text: string?, textSize: number?): Vector2
	text = text or ""
	textSize = textSize or 14

	local longest = 0

	for line in text:gmatch("[^\n]+") do
		longest = math.max(longest, #line)
	end

	if longest == 0 then
		longest = 1
	end

	local upper = text:upper()
	local wide = 0

	for index = 1, #text do
		local char = text:sub(index, index)

		if char:match("%u") then
			wide += 1
		end
	end

	local average = 0.5 + (wide / math.max(#text, 1)) * 0.12

	return Vector2.new(longest * textSize * average, textSize * 1.22)
end

local function resolveSize(instance, parentSize: Vector2, forced: any?): Vector2
	if forced ~= nil and forced[instance] ~= nil then
		return forced[instance]
	end

	local size = getProperty(instance, "Size") or UDim2.new()
	local width = parentSize.X * size.X.Scale + size.X.Offset
	local height = parentSize.Y * size.Y.Scale + size.Y.Offset

	local automatic = getProperty(instance, "AutomaticSize") or Enum.AutomaticSize.None
	local className = getProperty(instance, "ClassName")

	if automatic ~= Enum.AutomaticSize.None then
		local contentWidth = 0
		local contentHeight = 0

		if className == "TextLabel" or className == "TextButton" or className == "TextBox" then
			local measured = measureText(instance, getProperty(instance, "Text"), getProperty(instance, "TextSize"))

			contentWidth = measured.X
			contentHeight = measured.Y
		end

		local padding = findComponent(instance, "UIPadding")

		if padding ~= nil then
			contentWidth += padding.PaddingLeft.Offset + padding.PaddingRight.Offset
			contentHeight += padding.PaddingTop.Offset + padding.PaddingBottom.Offset
		end

		local layout = findComponent(instance, "UIListLayout")

		if layout ~= nil then
			local children = getChildren(instance)
			local cursor = 0

			for _, child in children do
				if child.Visible then
					local childSize = resolveSize(child, Vector2.new(width, height), forced)

					if layout.FillDirection == Enum.FillDirection.Horizontal then
						cursor += childSize.X

						contentHeight = math.max(contentHeight, childSize.Y)
					else
						cursor += childSize.Y

						contentWidth = math.max(contentWidth, childSize.X)
					end
				end
			end

			if layout.FillDirection == Enum.FillDirection.Horizontal then
				contentWidth = math.max(contentWidth, cursor + math.max(0, #children - 1) * layout.Padding.Offset)
			else
				contentHeight = math.max(contentHeight, cursor + math.max(0, #children - 1) * layout.Padding.Offset)
			end
		end

		if automatic == Enum.AutomaticSize.X or automatic == Enum.AutomaticSize.XY then
			width = math.max(width, contentWidth)
		end

		if automatic == Enum.AutomaticSize.Y or automatic == Enum.AutomaticSize.XY then
			height = math.max(height, contentHeight)
		end
	end

	return Vector2.new(width, height)
end

local function findParentLayout(instance)
	for _, child in getChildren(instance) do
		if child.ClassName == "UIListLayout" then
			return child
		end
	end

	return nil
end

local function sortChildren(instance, layout)
	local children = {}

	for _, child in getChildren(instance) do
		table.insert(children, child)
	end

	if layout.SortOrder == Enum.SortOrder.LayoutOrder then
		table.sort(children, function(a, b)
			return (a.LayoutOrder or 0) < (b.LayoutOrder or 0)
		end)
	else
		table.sort(children, function(a, b)
			return tostring(a.Name) < tostring(b.Name)
		end)
	end

	return children
end

local function scaleOf(instance): number
	local scale = 1

	for _, child in getChildren(instance) do
		if child.ClassName == "UIScale" then
			scale *= child.Scale
		end
	end

	return scale
end

local function layoutSubtree(instance, position: Vector2, size: Vector2, inheritedScale: number, forced: any)
	local scale = inheritedScale * scaleOf(instance)

	LAYOUT_CACHE[instance] = {
		AbsolutePosition = position,
		AbsoluteSize = size,
		AbsoluteRotation = getProperty(instance, "Rotation") or 0,
		AbsoluteCanvasSize = size,
		AbsoluteWindowSize = size,
		AbsoluteContentSize = Vector2.new(0, 0),
		__scale = scale,
	}

	local padding = findComponent(instance, "UIPadding")
	local left, right, top, bottom = 0, 0, 0, 0

	if padding ~= nil then
		left = (padding.PaddingLeft or UDim.new()).Offset
		right = (padding.PaddingRight or UDim.new()).Offset
		top = (padding.PaddingTop or UDim.new()).Offset
		bottom = (padding.PaddingBottom or UDim.new()).Offset
	end

	local contentPosition = position + Vector2.new(left, top) * scale
	local contentSize = Vector2.new(
		math.max(0, size.X - (left + right) * scale),
		math.max(0, size.Y - (top + bottom) * scale)
	)

	local layout = findParentLayout(instance)

	if layout ~= nil then
		local children = sortChildren(instance, layout)
		local paddingOffset = (layout.Padding or UDim.new()).Offset * scale
		local count = 0
		local contentExtent = 0

		for _, child in children do
			if child.Visible then
				count += 1
			end
		end

		local cursor = 0

		for index, child in children do
			if child.Visible then
				local childSize = resolveSize(child, contentSize, forced)
				childSize = childSize * scale

				local childPosition

				if layout.FillDirection == Enum.FillDirection.Horizontal then
					local alignY = 0

					if layout.VerticalAlignment == Enum.VerticalAlignment.Center then
						alignY = (contentSize.Y - childSize.Y) / 2
					elseif layout.VerticalAlignment == Enum.VerticalAlignment.Bottom then
						alignY = contentSize.Y - childSize.Y
					end

					local alignX = 0

					if layout.HorizontalAlignment == Enum.HorizontalAlignment.Center then
						alignX = 0
					elseif layout.HorizontalAlignment == Enum.HorizontalAlignment.Right then
						alignX = 0
					end

					childPosition = contentPosition + Vector2.new(cursor + alignX, alignY)
					cursor += childSize.X + paddingOffset
					contentExtent = math.max(contentExtent, childSize.Y)
				else
					local alignX = 0

					if layout.HorizontalAlignment == Enum.HorizontalAlignment.Center then
						alignX = (contentSize.X - childSize.X) / 2
					elseif layout.HorizontalAlignment == Enum.HorizontalAlignment.Right then
						alignX = contentSize.X - childSize.X
					end

					local alignY = 0

					if layout.VerticalAlignment == Enum.VerticalAlignment.Center then
						alignY = 0
					end

					childPosition = contentPosition + Vector2.new(alignX, cursor + alignY)
					cursor += childSize.Y + paddingOffset
					contentExtent = math.max(contentExtent, childSize.X)
				end

				if count > 1 and index == #children then
					cursor -= paddingOffset
				end

				layoutSubtree(child, childPosition, childSize, scale, forced)
			end
		end

		local content = LAYOUT_CACHE[instance]

		if content ~= nil then
			content.AbsoluteContentSize = if layout.FillDirection == Enum.FillDirection.Horizontal
				then Vector2.new(math.max(0, cursor), contentExtent)
				else Vector2.new(contentExtent, math.max(0, cursor))
		end
	else
		for _, child in getChildren(instance) do
			local childSize = resolveSize(child, contentSize, forced) * scale
			local childPosition = getProperty(child, "Position") or UDim2.new()
			local anchor = getProperty(child, "AnchorPoint") or Vector2.new()

			local offsetX = childPosition.X.Scale * contentSize.X + childPosition.X.Offset * scale
			local offsetY = childPosition.Y.Scale * contentSize.Y + childPosition.Y.Offset * scale

			local position = contentPosition
				+ Vector2.new(
					offsetX - anchor.X * childSize.X,
					offsetY - anchor.Y * childSize.Y
				)

			layoutSubtree(child, position, childSize, scale, forced)
		end
	end

	-- scrolling frames shift their children
	if instance.ClassName == "ScrollingFrame" then
		local canvas = getProperty(instance, "CanvasPosition") or Vector2.new()

		if canvas.X ~= 0 or canvas.Y ~= 0 then
			for _, child in getChildren(instance) do
				local entry = LAYOUT_CACHE[child]

				if entry ~= nil then
					entry.AbsolutePosition = entry.AbsolutePosition - canvas
				end
			end
		end
	end
end

--- Recomputes AbsolutePosition / AbsoluteSize for the given root
--- (or every ScreenGui found in the DataModel).
function Mock.layout(root: any?)
	local roots = {}

	if root ~= nil then
		table.insert(roots, root)
	else
		for _, screen in Mock.ScreenGuis do
			table.insert(roots, screen)
		end
	end

	for _, screen in roots do
		layoutSubtree(screen, Vector2.zero, VIEWPORT, 1, {})
	end

	return LAYOUT_CACHE
end

function Mock.computeLayout(instance)
	local entry = LAYOUT_CACHE[instance]

	if entry ~= nil then
		return entry
	end

	Mock.layout()

	entry = LAYOUT_CACHE[instance]

	if entry == nil then
		return {
			AbsolutePosition = Vector2.zero,
			AbsoluteSize = Vector2.new(0, 0),
			AbsoluteCanvasSize = Vector2.new(0, 0),
			AbsoluteWindowSize = Vector2.zero,
			AbsoluteContentSize = Vector2.zero,
			AbsoluteRotation = 0,
		}
	end

	local readOnly = {}

	for key, value in entry do
		readOnly[key] = value
	end

	if instance.ClassName == "UIListLayout" then
		readOnly.AbsoluteContentSize = LAYOUT_CACHE[instance.Parent] and LAYOUT_CACHE[instance.Parent].AbsoluteContentSize
			or readOnly.AbsoluteContentSize
	end

	return readOnly
end

--// Services ---------------------------------------------------------------------

Mock.ScreenGuis = {}
Mock.Deferred = {}
Mock.Clock = 0

local services = {}

local function newServiceInstance(className: string, name: string)
	local instance = buildInstance("Folder")

	instance.Name = name
	services[name] = instance

	return instance
end

local InputObjects = {}

local function newInputObject(props: any)
	local input = {
		UserInputType = props.UserInputType or Enum.UserInputType.MouseMovement,
		KeyCode = props.KeyCode or Enum.KeyCode.Unknown,
		Position = props.Position or Vector3.new(0, 0, 0),
		Delta = props.Delta or Vector3.new(0, 0, 0),
	}

	mockify(input, "InputObject")

	return input
end

Mock.newInputObject = newInputObject

local function installGlobals()
	local task = {}

	local function resumeNow(callback, ...)
		local ok, err = pcall(callback, ...)

		if not ok then
			error("[MockRoblox] scheduled task errored: " .. tostring(err), 0)
		end
	end

	function task.spawn(callback, ...)
		resumeNow(callback, ...)
	end

	function task.defer(callback, ...)
		table.insert(Mock.Deferred, { Time = Mock.Clock, Callback = callback, Args = { ... } })
	end

	function task.delay(delay: number, callback, ...)
		table.insert(Mock.Deferred, { Time = Mock.Clock + (delay or 0), Callback = callback, Args = { ... } })
	end

	function task.wait(delay: number?)
		local target = Mock.Clock + (delay or 0)

		Mock.Clock = target
		Mock.pump()
	end

	function task.cancel() end

	_G.task = task

	_G.print = function(...)
		local parts = {}

		for index = 1, select("#", ...) do
			table.insert(parts, tostring((select(index, ...))))
		end

		table.insert(Mock.Output, table.concat(parts, " "))

		return nil
	end

	_G.warn = function(...)
		local parts = {}

		for index = 1, select("#", ...) do
			table.insert(parts, tostring((select(index, ...))))
		end

		local text = table.concat(parts, " ")

		table.insert(Mock.Warnings, text)

		local hook = rawget(_G, "__warnHook")

		if hook ~= nil then
			hook(text)
		end

		return nil
	end

	_G.Instance = {
		new = function(className: string)
			if CLASS_HIERARCHY[className] == nil then
				error(("MockRoblox: unknown class %q"):format(className), 2)
			end

			local instance = buildInstance(className)

			if className == "ScreenGui" then
				table.insert(Mock.ScreenGuis, instance)
			end

			return instance
		end,
	}

	_G.Color3 = Color3
	_G.Vector2 = Vector2
	_G.Vector3 = Vector3
	_G.UDim = UDim
	_G.UDim2 = UDim2
	_G.Rect = Rect
	_G.NumberSequence = NumberSequence
	_G.NumberSequenceKeypoint = NumberSequenceKeypoint
	_G.ColorSequence = ColorSequence
	_G.ColorSequenceKeypoint = ColorSequenceKeypoint
	_G.TweenInfo = TweenInfo
	_G.Font = Font
	_G.Enum = Enum

	local rawTypeof = typeof

	_G.typeof = function(value)
		if type(value) == "table" then
			local direct = rawget(value, "__mocktype")

			if direct ~= nil then
				return direct
			end

			local meta = getmetatable(value)

			if meta ~= nil then
				local inherited = rawget(meta, "__mocktype")

				if inherited ~= nil then
					return inherited
				end
			end
		end

		return rawTypeof(value)
	end

	local tweenServiceClass = {}

	function tweenServiceClass:Create(instance: any, info: any, props: any)
		local tween = {
			PlaybackState = Enum.PlaybackState.Begin,
			Instance = instance,
			Info = info,
			Props = props,
			Completed = newSignal(),
		}

		mockify(tween, "Tween")

		local finish = function()
			for key, value in props do
				instance[key] = value
			end

			tween.PlaybackState = Enum.PlaybackState.Completed

			tween.Completed:Fire(Enum.PlaybackState.Completed)
		end

		function tween:Play()
			tween.PlaybackState = Enum.PlaybackState.Playing

			resumeNow(finish)
		end

		function tween:Cancel()
			tween.PlaybackState = Enum.PlaybackState.Cancelled
		end

		function tween:Pause()
			tween.PlaybackState = Enum.PlaybackState.Begin
		end

		return tween
	end

	local userInputServiceClass = {
		InputBegan = newSignal(),
		InputChanged = newSignal(),
		InputEnded = newSignal(),
		MouseIcon = "",
		MouseIconEnabled = true,
		MouseLocation = Vector2.zero,
		__keysDown = {},
	}

	function userInputServiceClass:GetMouseLocation()
		return userInputServiceClass.MouseLocation
	end

	function userInputServiceClass:IsKeyDown(keyCode)
		return userInputServiceClass.__keysDown[keyCode.Name] == true
	end

	function userInputServiceClass:GetFocusedTextBox()
		return nil
	end

	local runServiceClass = {
		RenderStepped = newSignal(),
		Heartbeat = newSignal(),
		Stepped = newSignal(),
		PreRender = newSignal(),
	}

	function runServiceClass:IsClient(): boolean
		return true
	end

	function runServiceClass:IsServer(): boolean
		return false
	end

	function runServiceClass:IsStudio(): boolean
		return false
	end

	local guiServiceClass = {
		SelectedCoreObject = nil,
	}

	function guiServiceClass:GetGuiInset()
		return Vector2.new(0, 36)
	end

	local textServiceClass = {}

	function textServiceClass:GetTextSize(text: string, size: number)
		return measureText(nil, text, size)
	end

	local playersClass = {
		PlayerAdded = newSignal(),
		PlayerRemoving = newSignal(),
	}

	local player = buildInstance("Folder")

	player.Name = "MockPlayer"

	local playerGui = buildInstance("Folder")

	playerGui.Name = "PlayerGui"
	playerGui.Parent = player

	playersClass.LocalPlayer = player

	services.TweenService = tweenServiceClass
	services.UserInputService = userInputServiceClass
	services.RunService = runServiceClass
	services.GuiService = guiServiceClass
	services.TextService = textServiceClass
	services.Players = playersClass
	services.CoreGui = newServiceInstance("Folder", "CoreGui")
	services.StarterGui = newServiceInstance("Folder", "StarterGui")
	services.ReplicatedStorage = newServiceInstance("Folder", "ReplicatedStorage")
	services.SoundService = newServiceInstance("Folder", "SoundService")
	services.HttpService = newServiceInstance("Folder", "HttpService")
	services.ContextActionService = newServiceInstance("Folder", "ContextActionService")

	local dataModel = {}

	function dataModel:GetService(name: string)
		local service = services[name]

		if service == nil then
			error(("MockRoblox: service %q is not mocked"):format(name), 2)
		end

		return service
	end

	function dataModel:GetChildren()
		local list = {}

		for _, service in services do
			table.insert(list, service)
		end

		return list
	end

	_G.game = dataModel
	_G.workspace = { CurrentCamera = { ViewportSize = VIEWPORT } }
	_G.script = nil

	Mock.services = services
	Mock.playerGui = playerGui
	Mock.dataModel = dataModel
end

--// Pumping / input helpers ----------------------------------------------------------

Mock.Output = {}
Mock.Warnings = {}

Mock.AutoProperties = {}

--- Runs every deferred/delayed callback that is due.
function Mock.pump()
	local pending = Mock.Deferred
	Mock.Deferred = {}

	for _, entry in pending do
		if entry.Time <= Mock.Clock then
			local ok, err = pcall(entry.Callback, table.unpack(entry.Args))

			if not ok then
				error("[MockRoblox] deferred task errored: " .. tostring(err), 0)
			end
		else
			table.insert(Mock.Deferred, entry)
		end
	end

	return #Mock.Deferred
end

--- Advances the virtual clock and runs a few render frames.
function Mock.flush(iterations: number?)
	local count = iterations or 6

	for _ = 1, count do
		Mock.Clock += 0.05
		Mock.pump()

		local runService = Mock.services.RunService

		runService.RenderStepped:Fire(0.016)
		runService.Heartbeat:Fire(0.016)
	end

	Mock.layout()
end

function Mock.inputBegan(props)
	local input = newInputObject(props)

	Mock.services.UserInputService.InputBegan:Fire(input, false)

	if input.KeyCode ~= Enum.KeyCode.Unknown then
		Mock.services.UserInputService.__keysDown[input.KeyCode.Name] = true
	end

	return input
end

function Mock.inputChanged(props)
	local input = newInputObject(props)

	Mock.services.UserInputService.InputChanged:Fire(input, false)

	return input
end

function Mock.inputEnded(props)
	local input = newInputObject(props)

	Mock.services.UserInputService.InputEnded:Fire(input, false)

	if input.KeyCode ~= Enum.KeyCode.Unknown then
		Mock.services.UserInputService.__keysDown[input.KeyCode.Name] = nil
	end

	return input
end

function Mock.mouseMoveTo(x: number, y: number)
	Mock.services.UserInputService.MouseLocation = Vector2.new(x, y)

	Mock.inputChanged({
		UserInputType = Enum.UserInputType.MouseMovement,
		Position = Vector3.new(x, y, 0),
	})
end

--- Fires an instance event (MouseEnter, MouseButton1Click, …).
function Mock.fire(instance, event: string, ...)
	local target = instance :: any

	target:__signal(event):Fire(...)
end

function Mock.click(instance, x: number?, y: number?)
	local position = Mock.services.UserInputService.MouseLocation

	if x ~= nil then
		position = Vector2.new(x, y or 0)
	end

	local input = newInputObject({
		UserInputType = Enum.UserInputType.MouseButton1,
		Position = Vector3.new(position.X, position.Y, 0),
	})

	local target = instance :: any

	target:__signal("InputBegan"):Fire(input, false)
	target:__signal("InputEnded"):Fire(input, false)
	target:__signal("MouseButton1Click"):Fire()
end

--- Simulates clicking an element at its centre.
function Mock.clickObject(object)
	local layout = Mock.computeLayout(object)
	local centre = layout.AbsolutePosition + layout.AbsoluteSize * 0.5

	Mock.services.UserInputService.MouseLocation = centre

	Mock.click(object, centre.X, centre.Y)
end

function Mock.reset()
	table.clear(Mock.ScreenGuis)
	table.clear(Mock.Deferred)
	table.clear(Mock.Output)
	table.clear(Mock.Warnings)
	Mock.Clock = 0
end

function Mock.install()
	if Mock._installed then
		return Mock
	end

	Mock._installed = true
	Mock.reset()

	installGlobals()

	return Mock
end

return Mock
