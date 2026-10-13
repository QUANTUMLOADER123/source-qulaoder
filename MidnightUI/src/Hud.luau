--!strict
--[[
	MidnightUI · Hud
	------------------------------------------------------------------
	The small floating panel from the reference: a rounded dark card with
	an icon and an uppercase title, sitting in a corner of the screen
	("SPECTATORS", "BINDS", …). Rows appear under the header as soon as
	you feed it text, so an empty panel is just the header bar.

		local spectators = window:Hud({ Title = "Spectators", Icon = "eye", Position = "TopLeft" })

		spectators:SetRows({ "Player1", "Player2" })
		spectators:AddRow("Player3")
		spectators:Clear()
]]

local TextService = game:GetService("TextService")
local UserInputService = game:GetService("UserInputService")

local Icon = require(script.Parent.Icon)
local Maid = require(script.Parent.Maid)
local Util = require(script.Parent.Util)

local Hud = {}
Hud.__index = Hud

export type Props = {
	Title: string?,
	Icon: string?,
	Position: ("TopLeft" | "TopRight" | "BottomLeft" | "BottomRight")?,
	Rows: { string }?,
	Visible: boolean?,
	Offset: Vector2?,
	Order: number?,
}

export type Hud = typeof(setmetatable(
	{} :: {
		Window: any,
		Theme: any,
		Root: Frame,
		Header: Frame,
		List: Frame,
		RowsFrame: Frame,
		Title: TextLabel,
		Rows: { string },
		Visible: boolean,
		Expanded: boolean,
		Position: string,
		_x: number,
		_y: number,
		_maid: any,
		_destroyed: boolean,
	},
	Hud
))

local CORNERS = {
	TopLeft = Vector2.new(0, 0),
	TopRight = Vector2.new(1, 0),
	BottomLeft = Vector2.new(0, 1),
	BottomRight = Vector2.new(1, 1),
}

function Hud.new(window: any, props: Props?): Hud
	local options: Props = props or {}
	local theme = window.Theme
	local metrics = theme.Metrics.Hud

	local self: any = setmetatable({}, Hud)

	self.Window = window
	self.Theme = theme
	self.Rows = {}
	self.Visible = options.Visible ~= false
	self.Expanded = true
	self.Position = options.Position or "TopLeft"
	self._destroyed = false
	self._maid = Maid.new()

	local corner = CORNERS[self.Position] or CORNERS.TopLeft
	local margin = metrics.Margin

	self._x = margin * (1 - corner.X * 2)
	self._y = margin * (1 - corner.Y * 2)

	--// Panel ----------------------------------------------------------
	local root = Instance.new("Frame")

	root.Name = "Hud_" .. (options.Title or "Panel")
	root.AnchorPoint = corner
	root.BackgroundColor3 = theme.Colors.Window
	root.BorderSizePixel = 0
	root.ClipsDescendants = true
	root.Size = UDim2.fromOffset(0, metrics.Height)
	root.ZIndex = 20
	root.Visible = self.Visible
	root.Parent = window.Gui

	Util.addCorner(root, metrics.Radius)
	Util.addStroke(root, theme.Colors.WindowBorder, 1, 0.35)

	self.Root = root

	--// Header ---------------------------------------------------------
	local header = Instance.new("Frame")

	header.Name = "Header"
	header.BackgroundTransparency = 1
	header.BorderSizePixel = 0
	header.Size = UDim2.new(1, 0, 0, metrics.Height)
	header.ZIndex = 21
	header.Parent = root

	self.Header = header

	local iconSize = metrics.IconSize

	local icon = Icon.create(options.Icon or "dot", {
		Size = iconSize,
		Color = theme.Colors.Accent,
		Parent = header,
		Position = UDim2.fromOffset(metrics.Padding, (metrics.Height - iconSize) / 2),
		Name = "Icon",
		ZIndex = 22,
	})

	local title = Instance.new("TextLabel")

	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(metrics.Padding + iconSize + metrics.IconGap, 0)
	title.Size = UDim2.new(1, -(metrics.Padding * 2 + iconSize + metrics.IconGap), 1, 0)
	title.Text = (options.Title or ""):upper()
	title.TextColor3 = theme.Colors.Text
	title.TextSize = metrics.TitleTextSize
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextYAlignment = Enum.TextYAlignment.Center
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.ZIndex = 22
	title.Parent = header

	Util.setFont(title, theme.Fonts.Panel)

	self.Title = title
	self.Icon = icon

	--// Rows -----------------------------------------------------------
	local list = Instance.new("Frame")

	list.Name = "List"
	list.AnchorPoint = Vector2.new(0, 1)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Position = UDim2.new(0, 0, 1, -metrics.BottomPadding)
	list.Size = UDim2.new(1, 0, 0, 0)
	list.ZIndex = 21
	list.Parent = root

	Util.addList(list, {
		Padding = metrics.Gap,
		Direction = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	self.List = list

	--// Dragging -------------------------------------------------------
	local function startDrag(input: InputObject)
		local startMouse = Vector2.new(input.Position.X, input.Position.Y)
		local startX, startY = self._x, self._y
		local connections = {}

		local function stop()
			for _, connection in connections do
				connection:Disconnect()
			end

			table.clear(connections)
		end

		table.insert(
			connections,
			UserInputService.InputChanged:Connect(function(move: InputObject)
				if move.UserInputType ~= Enum.UserInputType.MouseMovement
					and move.UserInputType ~= Enum.UserInputType.Touch
				then
					return
				end

				local dx = move.Position.X - startMouse.X
				local dy = move.Position.Y - startMouse.Y

				self._x = startX + dx
				self._y = startY + dy

				self:UpdatePosition()
			end)
		)

		table.insert(
			connections,
			UserInputService.InputEnded:Connect(function(release: InputObject)
				if release.UserInputType == Enum.UserInputType.MouseButton1
					or release.UserInputType == Enum.UserInputType.Touch
				then
					stop()
				end
			end)
		)

		self._maid:Add(function()
			stop()
		end)
	end

	self._maid:Add(header.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			startDrag(input)
		end
	end))

	self:UpdatePosition()

	if options.Rows ~= nil then
		self:SetRows(options.Rows)
	else
		self:_resize()
	end

	return self :: Hud
end

--// Geometry ----------------------------------------------------------

--- Places the panel for its anchor corner.
function Hud.UpdatePosition(self: Hud)
	local corner = CORNERS[self.Position] or CORNERS.TopLeft

	self.Root.Position = UDim2.fromOffset(self._x, self._y)
	self.Root.AnchorPoint = corner
end

--- Measures a single line of text (falls back to an estimate outside Roblox).
local function measure(text: string, size: number, font: any): number
	local ok, result = pcall(function()
		return TextService:GetTextSize(text, size, font, Vector2.new(math.huge, size * 2))
	end)

	if ok and typeof(result) == "Vector2" then
		return result.X
	end

	return #text * size * 0.58
end

--- Recomputes the panel size from the title and the visible rows.
function Hud._resize(self: Hud)
	local metrics = self.Theme.Metrics.Hud
	local count = self.Expanded and #self.Rows or 0
	local height = metrics.Height

	if count > 0 then
		height += metrics.RowHeight * count + metrics.Gap * (count - 1) + metrics.BottomPadding
	end

	local titleWidth = measure(self.Title.Text, metrics.TitleTextSize, self.Theme.Fonts.Panel)
	local contentWidth = metrics.Padding * 2 + metrics.IconSize + metrics.IconGap + titleWidth
	local rowWidth = 0

	for _, row in self.Rows do
		rowWidth = math.max(rowWidth, measure(row, metrics.RowTextSize, self.Theme.Fonts.Text))
	end

	contentWidth = math.max(contentWidth, rowWidth + metrics.Padding * 2)

	self.Root.Size = UDim2.fromOffset(math.ceil(contentWidth), height)
end

--// Content -----------------------------------------------------------

function Hud.SetTitle(self: Hud, title: string, iconName: string?)
	self.Title.Text = title:upper()

	if iconName ~= nil then
		Icon.setColor(self.Icon, self.Theme.Colors.Accent)
	end
end

--- Replaces every row.
function Hud.SetRows(self: Hud, rows: { string })
	Util.clearChildren(self.List)

	table.clear(self.Rows)

	for _, row in rows do
		table.insert(self.Rows, tostring(row))
	end

	self:_render()

	return self
end

function Hud.AddRow(self: Hud, text: string)
	table.insert(self.Rows, tostring(text))

	self:_render()

	return self
end

--- Removes a row by index; also accepts the row's text.
function Hud.RemoveRow(self: Hud, target: (number | string))
	local index = nil

	if type(target) == "number" then
		index = target
	else
		index = table.find(self.Rows, target)
	end

	if index == nil or self.Rows[index] == nil then
		return false
	end

	table.remove(self.Rows, index)

	self:_render()

	return true
end

function Hud.Clear(self: Hud)
	return self:SetRows({})
end

function Hud._render(self: Hud)
	local theme = self.Theme
	local metrics = theme.Metrics.Hud

	Util.clearChildren(self.List)

	if not self.Expanded then
		self.List.Visible = false
		self:_resize()

		return
	end

	self.List.Visible = true

	for index, text in self.Rows do
		local row = Instance.new("TextLabel")

		row.Name = "Row" .. tostring(index)
		row.BackgroundTransparency = 1
		row.LayoutOrder = index
		row.Size = UDim2.new(1, 0, 0, metrics.RowHeight)
		row.Text = text
		row.TextColor3 = theme.Colors.TextDim
		row.TextSize = metrics.RowTextSize
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.TextYAlignment = Enum.TextYAlignment.Center
		row.TextTruncate = Enum.TextTruncate.AtEnd
		row.ZIndex = 22
		row.Parent = self.List

		Util.setFont(row, theme.Fonts.Text)
	end

	if #self.Rows > 0 then
		self.List.Size = UDim2.new(1, -metrics.Padding * 2, 0, 0)
		self.List.Position = UDim2.new(0, metrics.Padding, 1, -metrics.BottomPadding)
		self.List.AutomaticSize = Enum.AutomaticSize.Y
	end

	self:_resize()
end

--// Visibility & lifetime ----------------------------------------------

function Hud.SetVisible(self: Hud, visible: boolean)
	self.Visible = visible
	self.Root.Visible = visible
end

function Hud.IsVisible(self: Hud): boolean
	return self.Visible
end

function Hud.SetExpanded(self: Hud, expanded: boolean)
	self.Expanded = expanded
	self:_render()
end

function Hud.IsDestroyed(self: Hud): boolean
	return self._destroyed
end

function Hud.SetTheme(self: Hud, theme: any)
	self.Theme = theme

	self.Root.BackgroundColor3 = theme.Colors.Window

	local stroke = Util.findClass(self.Root, "UIStroke")

	if stroke ~= nil then
		stroke.Color = theme.Colors.WindowBorder
	end

	Icon.setColor(self.Icon, theme.Colors.Accent)
	self.Title.TextColor3 = theme.Colors.Text
	Util.setFont(self.Title, theme.Fonts.Panel)

	self:_render()
end

function Hud.Destroy(self: Hud)
	if self._destroyed then
		return
	end

	self._destroyed = true

	self._maid:Clean()
	self._maid:Destroy()

	if self.Root ~= nil then
		self.Root:Destroy()
	end
end

return Hud
