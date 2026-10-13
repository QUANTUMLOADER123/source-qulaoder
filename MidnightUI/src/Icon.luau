--!strict
--[[
	MidnightUI · Icon
	------------------------------------------------------------------
	Asset-free vector icon set.

	Every icon is described as a list of primitive shapes on a 20x20
	grid, which lets the renderer scale them to any size while staying
	crisp. No image ids are required (so nothing can be moderated or
	fail to load), but `rbxassetid://…` strings are still accepted and
	rendered as ImageLabels.

	Shape grammar (all coordinates on the 20x20 grid):

		{ "rect",    x, y, w, h, radius? }
		{ "circle",  x, y, w, h }
		{ "outline", x, y, w, h, thickness?, radius? }
		{ "ring",    x, y, w, h, thickness? }
		{ "line",    x1, y1, x2, y2, thickness? }
]]

local Util = require(script.Parent.Util)

local Icon = {}

local GRID = 20

--// Vector definitions ----------------------------------------------

type Shape = { [number]: any }

local ICONS: { [string]: { Shape } } = {
	logo = {
		{ "outline", 2.6, 2.6, 14.8, 14.8, 1.5, 2.6 },
		{ "rect", 7.2, 7.2, 5.6, 5.6, 1.4 },
	},
	triangle = {
		{ "line", 10, 3, 17.4, 16.6, 1.5 },
		{ "line", 17.4, 16.6, 2.6, 16.6, 1.5 },
		{ "line", 2.6, 16.6, 10, 3, 1.5 },
	},
	search = {
		{ "ring", 3, 3, 12, 12, 1.6 },
		{ "line", 13.6, 13.6, 17.4, 17.4, 1.7 },
	},
	settings = {
		{ "ring", 7, 7, 6, 6, 1.5 },
		{ "rect", 9.2, 1.6, 1.6, 3.6, 0.8 },
		{ "rect", 9.2, 14.8, 1.6, 3.6, 0.8 },
		{ "rect", 1.6, 9.2, 3.6, 1.6, 0.8 },
		{ "rect", 14.8, 9.2, 3.6, 1.6, 0.8 },
		{ "circle", 3.4, 3.4, 2, 2 },
		{ "circle", 14.6, 3.4, 2, 2 },
		{ "circle", 3.4, 14.6, 2, 2 },
		{ "circle", 14.6, 14.6, 2, 2 },
	},
	user = {
		{ "circle", 7, 2.6, 6, 6 },
		{ "rect", 4.2, 11, 11.6, 6.2, 3.1 },
	},
	users = {
		{ "circle", 2.6, 4.4, 4.4, 4.4 },
		{ "rect", 1.2, 11, 7.6, 5, 2.5 },
		{ "circle", 12.2, 3.4, 5, 5 },
		{ "rect", 10.8, 10.4, 8.6, 5.6, 2.8 },
	},
	car = {
		{ "rect", 2, 8.6, 16, 4, 1.6 },
		{ "rect", 5.2, 5.2, 9.6, 4, 1.6 },
		{ "circle", 4.4, 12.4, 3, 3 },
		{ "circle", 12.6, 12.4, 3, 3 },
	},
	crosshair = {
		{ "ring", 2.6, 2.6, 14.8, 14.8, 1.4 },
		{ "line", 10, 0.4, 10, 4.4, 1.4 },
		{ "line", 10, 15.6, 10, 19.6, 1.4 },
		{ "line", 0.4, 10, 4.4, 10, 1.4 },
		{ "line", 15.6, 10, 19.6, 10, 1.4 },
		{ "circle", 9, 9, 2, 2 },
	},
	globe = {
		{ "ring", 2.6, 2.6, 14.8, 14.8, 1.4 },
		{ "line", 2.6, 10, 17.4, 10, 1.2 },
		{ "ring", 6.6, 2.8, 6.8, 14.4, 1.2 },
	},
	network = {
		{ "rect", 3.4, 13, 3.2, 4, 1 },
		{ "rect", 8.4, 10, 3.2, 7, 1 },
		{ "rect", 13.4, 7, 3.2, 10, 1 },
	},
	shield = {
		{ "outline", 5, 2.8, 10, 8.6, 1.4, 2.4 },
		{ "line", 5.6, 10.4, 10, 17.2, 1.4 },
		{ "line", 14.4, 10.4, 10, 17.2, 1.4 },
	},
	eye = {
		{ "ring", 2.2, 6.2, 15.6, 7.6, 1.4 },
		{ "circle", 8.6, 8.6, 2.8, 2.8 },
	},
	layout = {
		{ "outline", 2.4, 3.4, 15.2, 13.2, 1.4, 1.8 },
		{ "line", 7.6, 3.6, 7.6, 16.4, 1.2 },
	},
	code = {
		{ "line", 7.4, 6, 3, 10, 1.6 },
		{ "line", 3, 10, 7.4, 14, 1.6 },
		{ "line", 12.6, 6, 17, 10, 1.6 },
		{ "line", 17, 10, 12.6, 14, 1.6 },
		{ "line", 11.2, 4.4, 8.8, 15.6, 1.4 },
	},
	cube = {
		{ "outline", 5, 6.2, 10, 10, 1.4, 1.6 },
		{ "line", 5, 6.4, 10, 2.6, 1.4 },
		{ "line", 10, 2.6, 15, 6.4, 1.4 },
	},
	refresh = {
		{ "ring", 3.4, 3.4, 13.2, 13.2, 1.5 },
		{ "line", 13.2, 3, 17.2, 5.4, 1.6 },
		{ "line", 17.2, 5.4, 14.8, 9.2, 1.6 },
	},
	star = {
		{ "line", 10, 2.2, 10, 17.8, 1.5 },
		{ "line", 2.2, 10, 17.8, 10, 1.5 },
		{ "line", 10, 5.4, 14.6, 10, 1.2 },
		{ "line", 14.6, 10, 10, 14.6, 1.2 },
		{ "line", 10, 14.6, 5.4, 10, 1.2 },
		{ "line", 5.4, 10, 10, 5.4, 1.2 },
	},
	bolt = {
		{ "line", 11.6, 2.2, 5.6, 11, 1.5 },
		{ "line", 5.6, 11, 9.6, 11, 1.5 },
		{ "line", 9.6, 11, 8.4, 17.8, 1.5 },
		{ "line", 8.4, 17.8, 14.4, 9, 1.5 },
		{ "line", 14.4, 9, 10.4, 9, 1.5 },
		{ "line", 10.4, 9, 11.6, 2.2, 1.5 },
	},
	bell = {
		{ "ring", 6.4, 3.4, 7.2, 8, 1.4 },
		{ "rect", 4.8, 11, 10.4, 1.9, 1 },
		{ "circle", 8.9, 14.6, 2.2, 2.2 },
	},
	clock = {
		{ "ring", 2.6, 2.6, 14.8, 14.8, 1.4 },
		{ "line", 10, 5.6, 10, 10.4, 1.4 },
		{ "line", 10, 10.4, 13.4, 12.2, 1.4 },
	},
	folder = {
		{ "outline", 2.4, 6.4, 15.2, 10.4, 1.4, 1.8 },
		{ "rect", 2.4, 4.2, 6.4, 3, 0.9 },
	},
	camera = {
		{ "outline", 2.4, 6, 15.2, 10.4, 1.4, 1.8 },
		{ "circle", 8.6, 9.2, 2.8, 2.8 },
		{ "rect", 12.4, 3.8, 4, 2.4, 0.8 },
	},
	mouse = {
		{ "outline", 6, 2.8, 8, 14.4, 1.4, 4 },
		{ "line", 10, 6, 10, 9.4, 1.4 },
	},
	key = {
		{ "ring", 2.6, 6.6, 6.4, 6.4, 1.5 },
		{ "line", 9, 10.4, 17.4, 10.4, 1.5 },
		{ "line", 14.2, 10.4, 14.2, 13.6, 1.4 },
		{ "line", 17, 10.4, 17, 12.8, 1.4 },
	},
	palette = {
		{ "outline", 2.4, 2.4, 15.2, 15.2, 1.4, 5 },
		{ "circle", 6.4, 6.4, 2, 2 },
		{ "circle", 11.6, 6.4, 2, 2 },
		{ "circle", 6.4, 11.6, 2, 2 },
		{ "circle", 11.6, 11.6, 2, 2 },
	},
	sun = {
		{ "circle", 6.6, 6.6, 6.8, 6.8 },
		{ "line", 10, 0.8, 10, 3.2, 1.3 },
		{ "line", 10, 16.8, 10, 19.2, 1.3 },
		{ "line", 0.8, 10, 3.2, 10, 1.3 },
		{ "line", 16.8, 10, 19.2, 10, 1.3 },
		{ "line", 3.2, 3.2, 4.9, 4.9, 1.3 },
		{ "line", 15.1, 15.1, 16.8, 16.8, 1.3 },
		{ "line", 3.2, 16.8, 4.9, 15.1, 1.3 },
		{ "line", 15.1, 4.9, 16.8, 3.2, 1.3 },
	},
	cloud = {
		{ "circle", 4.4, 7.4, 4.8, 4.8 },
		{ "circle", 9.6, 5.2, 6, 6 },
		{ "rect", 4.4, 10.4, 11.2, 4.2, 2.1 },
	},
	sliders = {
		{ "line", 2.2, 6, 17.8, 6, 1.4 },
		{ "line", 2.2, 10, 17.8, 10, 1.4 },
		{ "line", 2.2, 14, 17.8, 14, 1.4 },
		{ "circle", 5, 4.6, 2.8, 2.8 },
		{ "circle", 12, 8.6, 2.8, 2.8 },
		{ "circle", 8, 12.6, 2.8, 2.8 },
	},
	gun = {
		{ "rect", 2.2, 8, 11.6, 4, 1.2 },
		{ "rect", 13, 9.4, 4.8, 1.6, 0.8 },
		{ "rect", 4.6, 12, 3, 3.4, 0.8 },
	},
	plane = {
		{ "line", 2.4, 9.4, 17.6, 2.6, 1.5 },
		{ "line", 17.6, 2.6, 12, 17.4, 1.5 },
		{ "line", 12, 17.4, 9.4, 11.6, 1.5 },
		{ "line", 9.4, 11.6, 2.4, 9.4, 1.5 },
	},
	plus = {
		{ "line", 10, 4, 10, 16, 1.8 },
		{ "line", 4, 10, 16, 10, 1.8 },
	},
	minus = {
		{ "line", 4, 10, 16, 10, 1.8 },
	},
	close = {
		{ "line", 5.2, 5.2, 14.8, 14.8, 1.8 },
		{ "line", 14.8, 5.2, 5.2, 14.8, 1.8 },
	},
	check = {
		{ "line", 4.4, 10.6, 8.4, 14.6, 2 },
		{ "line", 8.4, 14.6, 15.8, 5.4, 2 },
	},
	chevronDown = {
		{ "line", 5.6, 8.2, 10, 12.6, 1.8 },
		{ "line", 10, 12.6, 14.4, 8.2, 1.8 },
	},
	chevronUp = {
		{ "line", 5.6, 11.8, 10, 7.4, 1.8 },
		{ "line", 10, 7.4, 14.4, 11.8, 1.8 },
	},
	chevronRight = {
		{ "line", 8.2, 5.6, 12.6, 10, 1.8 },
		{ "line", 12.6, 10, 8.2, 14.4, 1.8 },
	},
	chevronLeft = {
		{ "line", 11.8, 5.6, 7.4, 10, 1.8 },
		{ "line", 7.4, 10, 11.8, 14.4, 1.8 },
	},
	dot = {
		{ "circle", 7.6, 7.6, 4.8, 4.8 },
	},
	trash = {
		{ "outline", 5, 5.6, 10, 11.4, 1.4, 1.4 },
		{ "line", 3.4, 5.6, 16.6, 5.6, 1.4 },
		{ "rect", 7.2, 2.6, 5.6, 2, 0.8 },
	},
	copy = {
		{ "outline", 3.2, 3.2, 10.4, 10.4, 1.4, 1.6 },
		{ "outline", 6.4, 6.4, 10.4, 10.4, 1.4, 1.6 },
	},
	download = {
		{ "line", 10, 2.6, 10, 12.4, 1.6 },
		{ "line", 6.2, 9, 10, 12.8, 1.6 },
		{ "line", 13.8, 9, 10, 12.8, 1.6 },
		{ "line", 3.6, 16.6, 16.4, 16.6, 1.6 },
	},
	info = {
		{ "ring", 2.6, 2.6, 14.8, 14.8, 1.4 },
		{ "line", 10, 9, 10, 14.2, 1.6 },
		{ "circle", 9.2, 5.6, 1.6, 1.6 },
	},
	warning = {
		{ "line", 10, 2.6, 18.4, 17.4, 1.5 },
		{ "line", 18.4, 17.4, 1.6, 17.4, 1.5 },
		{ "line", 1.6, 17.4, 10, 2.6, 1.5 },
		{ "line", 10, 7.6, 10, 13, 1.5 },
		{ "circle", 9.2, 14.8, 1.6, 1.6 },
	},
	paragraph = {
		{ "line", 3, 6, 17, 6, 1.6 },
		{ "line", 3, 10, 17, 10, 1.6 },
		{ "line", 3, 14, 11, 14, 1.6 },
	},
}

--- Friendly aliases so user code can be forgiving.
local ALIASES: { [string]: string } = {
	["gear"] = "settings",
	cog = "settings",
	target = "crosshair",
	aim = "crosshair",
	weapon = "gun",
	teleport = "plane",
	wifi = "network",
	internet = "network",
	web = "globe",
	world = "globe",
	account = "user",
	profile = "user",
	people = "users",
	players = "users",
	vehicle = "car",
	domain = "globe",
	sdk = "code",
	lua = "code",
	script = "code",
	misc = "cube",
	box = "cube",
	recovery = "refresh",
	reload = "refresh",
	visuals = "eye",
	view = "eye",
	ui = "layout",
	interface = "layout",
	skin = "palette",
	theme = "palette",
	color = "palette",
	colour = "palette",
	light = "sun",
	menu = "layout",
	["dashboard"] = "layout",
	["x"] = "close",
	cross = "close",
	tick = "check",
	space = "dot",
	["bullet"] = "dot",
	speed = "bolt",
	power = "bolt",
	energy = "bolt",
	alert = "warning",
	question = "info",
	help = "info",
	save = "download",
	export = "download",
	clean = "trash",
	delete = "trash",
	remove = "trash",
	duplicate = "copy",
	time = "clock",
	timer = "clock",
	spinner = "refresh",
	audio = "bell",
	notification = "bell",
	notify = "bell",
	webhook = "network",
	home = "layout",
	apps = "cube",
	debug = "code",
	console = "paragraph",
	text = "paragraph",
	hotkey = "key",
	keybind = "key",
	cursor = "mouse",
	screenshot = "camera",
	screen = "camera",
	host = "cloud",
	miscellaneous = "cube",
}

--// Renderer ---------------------------------------------------------

export type IconOptions = {
	Size: number?,
	Color: Color3?,
	Transparency: number?,
	Parent: Instance?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	Name: string?,
	ZIndex: number?,
}

local function isImage(value: string): boolean
	return value:match("^rbxassetid://") ~= nil
		or value:match("^rbxasset://") ~= nil
		or value:match("^http") ~= nil
		or value:match("^rbxthumb://") ~= nil
end

local function resolveName(name: string): string
	local alias = ALIASES[name]

	return alias or name
end

--- Applies a color to an icon built by `Icon.create`.
function Icon.setColor(icon: GuiObject, color: Color3, transparency: number?)
	local alpha = transparency or 0
	local target = icon :: any

	if target:IsA("ImageLabel") then
		target.ImageColor3 = color
		target.ImageTransparency = alpha

		return
	end

	for _, child in icon:GetChildren() do
		local shape = child :: any

		if shape:IsA("Frame") or shape:IsA("ImageLabel") then
			local stroke = Util.findClass(shape, "UIStroke")

			if stroke ~= nil then
				stroke.Color = color
				stroke.Transparency = alpha
			end

			if shape:IsA("Frame") and shape.BackgroundTransparency < 1 then
				shape.BackgroundColor3 = color
				shape.BackgroundTransparency = alpha
			end
		end
	end
end

--- Creates an icon. Returns the container (Frame or ImageLabel).
function Icon.create(name: string, options: IconOptions?): any
	local opts = options or {}
	local size = opts.Size or 16
	local color = opts.Color or Color3.fromRGB(255, 255, 255)
	local transparency = opts.Transparency or 0
	local scale = size / GRID

	if isImage(name) then
		local image = Instance.new("ImageLabel")

		image.Name = opts.Name or "Icon"
		image:SetAttribute("MidnightIcon", name)
		image.BackgroundTransparency = 1
		image.BorderSizePixel = 0
		image.Image = name
		image.ImageColor3 = color
		image.ImageTransparency = transparency
		image.ScaleType = Enum.ScaleType.Fit
		image.Size = UDim2.fromOffset(size, size)
		image.Position = opts.Position or UDim2.fromOffset(0, 0)
		image.AnchorPoint = opts.AnchorPoint or Vector2.new(0, 0)
		image.ZIndex = opts.ZIndex or 1

		if opts.Parent then
			image.Parent = opts.Parent
		end

		return image
	end

	local container = Instance.new("Frame")

	container.Name = opts.Name or "Icon"
	container:SetAttribute("MidnightIcon", resolveName(name))
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.Size = UDim2.fromOffset(size, size)
	container.Position = opts.Position or UDim2.fromOffset(0, 0)
	container.AnchorPoint = opts.AnchorPoint or Vector2.new(0, 0)
	container.ZIndex = opts.ZIndex or 1

	local shapes = ICONS[resolveName(name)]

	if shapes == nil then
		warn(("[MidnightUI] Unknown icon %q — rendering a placeholder"):format(name))

		shapes = {
			{ "circle", 5, 5, 10, 10 },
		}
	end

	for _, shape in shapes do
		local kind = shape[1]

		if kind == "line" then
			local x1, y1, x2, y2 = shape[2], shape[3], shape[4], shape[5]
			local thickness = math.max(1, Util.round((shape[6] or 1.4) * scale))
			local dx, dy = x2 - x1, y2 - y1
			local length = math.sqrt(dx * dx + dy * dy) * scale

			local line = Instance.new("Frame")
			line.Name = "Line"
			line.AnchorPoint = Vector2.new(0.5, 0.5)
			line.BackgroundColor3 = color
			line.BackgroundTransparency = transparency
			line.BorderSizePixel = 0
			line.Position = UDim2.fromOffset(Util.round((x1 + x2) / 2 * scale), Util.round((y1 + y2) / 2 * scale))
			line.Rotation = math.deg(math.atan2(dy, dx))
			line.Size = UDim2.fromOffset(math.max(1, Util.round(length)), thickness)
			line.ZIndex = container.ZIndex + 1
			line.Parent = container

			Util.addCorner(line, math.floor(thickness / 2))
		else
			local x, y, width, height = shape[2], shape[3], shape[4], shape[5]
			local thickness = shape[6]
			local radius = shape[7]

			local shapeFrame = Instance.new("Frame")
			shapeFrame.Name = kind
			shapeFrame.BorderSizePixel = 0
			shapeFrame.Position = UDim2.fromOffset(Util.round(x * scale), Util.round(y * scale))
			shapeFrame.Size = UDim2.fromOffset(math.max(1, Util.round(width * scale)), math.max(1, Util.round(height * scale)))
			shapeFrame.ZIndex = container.ZIndex + 1
			shapeFrame.Parent = container

			local cornerRadius = 0

			if radius ~= nil then
				cornerRadius = radius * scale
			elseif kind == "ring" then
				cornerRadius = math.min(shapeFrame.Size.X.Offset, shapeFrame.Size.Y.Offset) / 2
			end

			if kind == "outline" or kind == "ring" then
				shapeFrame.BackgroundTransparency = 1
				Util.addStroke(
					shapeFrame,
					color,
					math.max(1, Util.round((thickness or 1.4) * scale)),
					transparency
				)
				Util.addCorner(shapeFrame, cornerRadius)
			else
				shapeFrame.BackgroundColor3 = color
				shapeFrame.BackgroundTransparency = transparency
				Util.addCorner(shapeFrame, cornerRadius)
			end
		end
	end

	if opts.Parent then
		container.Parent = opts.Parent
	end

	return container
end

--- Returns true when the icon name exists (images always count).
function Icon.exists(name: string): boolean
	return isImage(name) or ICONS[resolveName(name)] ~= nil
end

--- List of every vector icon name (aliases excluded).
function Icon.list(): { string }
	local names: { string } = {}

	for name in ICONS do
		table.insert(names, name)
	end

	table.sort(names)

	return names
end

return Icon
