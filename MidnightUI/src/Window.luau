--!strict
--[[
	MidnightUI · Window
	------------------------------------------------------------------
	The main surface: header with logo + top tabs + search/settings,
	sidebar, content area with the masonry grid of groupboxes, an
	overlay layer for popups/tooltips, notifications, dragging,
	resizing, flags, configs and live re-theming.

	Everything the window draws is computed from its own metrics, so
	the layout never depends on layout read-back and is identical on
	the first frame.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Icon = require(script.Parent.Icon)
local Maid = require(script.Parent.Maid)
local Notification = require(script.Parent.Notification)
local Popup = require(script.Parent.Popup)
local Section = require(script.Parent.Section)
local Signal = require(script.Parent.Signal)
local Tab = require(script.Parent.Tab)
local Theme = require(script.Parent.Theme)
local Util = require(script.Parent.Util)

local Window = {}
Window.__index = Window

export type Config = {
	Title: string?,
	Icon: string?,
	Size: (Vector2 | { number })?,
	Position: UDim2?,
	Theme: (string | { [string]: any })?,
	Parent: Instance?,
	Columns: number?,
	Sidebar: boolean?,
	Search: boolean?,
	Settings: boolean?,
	Draggable: boolean?,
	Resizable: boolean?,
	Keybind: (string | EnumItem)?,
	Notifications: boolean?,
	IgnoreGuiInset: boolean?,
	DisplayOrder: number?,
	Scale: number?,
	Radius: number?,
}

export type Window = typeof(setmetatable(
	{} :: {
		Config: Config,
		Theme: any,
		Gui: ScreenGui,
		Root: Frame,
		Instance: CanvasGroup,
		Header: Frame,
		TabBar: Frame,
		SidebarFrame: Frame,
		SidebarContent: ScrollingFrame,
		Content: Frame,
		Overlay: Frame,
		Tabs: { any },
		Pages: { any },
		Elements: { [string]: any },
		Flags: { [string]: any },
		Notifications: { any },
		Visible: boolean,
		Size: { Width: number, Height: number },
		ActiveTab: any,
		ActivePage: any,
		VisibilityChanged: any,
		ThemeChanged: any,
		FlagChanged: any,
		Scale: number,
		_maid: any,
		_popup: any,
		_dragConnections: { any },
		_tooltip: any,
		_destroyed: boolean,
		_sidebarItems: { any },
		_toggleKeybind: Enum.KeyCode?,
		_resizing: boolean,
		_dragging: boolean,
	},
	Window
))

--// Helpers ----------------------------------------------------------

local function resolveKeyName(value: any): Enum.KeyCode?
	if value == nil then
		return nil
	end

	if typeof(value) == "EnumItem" then
		if value.EnumType == Enum.KeyCode then
			return value :: Enum.KeyCode
		end

		return nil
	end

	if type(value) == "string" then
		local ok, keyCode = pcall(function()
			return Enum.KeyCode[value]
		end)

		if ok and keyCode ~= nil then
			return keyCode
		end
	end

	return nil
end

local function createPanelStack(window: any, parent: Frame)
	local section: any = {
		Theme = window.Theme,
		Window = window,
		Elements = {},
		Content = parent,
		_elementOrder = 0,
		_isDestroyed = false,
		_onChanged = nil,
	}

	function section:_addElement(element: any)
		section._elementOrder += 1
		element.Container.LayoutOrder = section._elementOrder
		element.Container.Parent = section.Content

		table.insert(section.Elements, element)
		element:SetSection(section)

		window:_registerElement(element)

		if section._onChanged ~= nil then
			section._onChanged()
		end

		return element
	end

	function section:_notifyLayoutChanged()
		if section._onChanged ~= nil then
			section._onChanged()
		end
	end

	function section:IsDestroyed(): boolean
		return section._isDestroyed
	end

	function section:Destroy()
		section._isDestroyed = true

		for index = #section.Elements, 1, -1 do
			local element = section.Elements[index]
			section.Elements[index] = nil

			element:Destroy()
		end
	end

	setmetatable(section, { __index = Section })

	Util.addList(parent, {
		Padding = window.Theme.Metrics.Panel.Gap,
		Direction = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	return section
end

--// Construction -----------------------------------------------------

function Window.new(config: Config): Window
	config = config or {}

	local self: any = setmetatable({}, Window)

	local theme = Theme.resolve(config.Theme)
	local metrics = theme.Metrics

	self.Config = config
	self.Theme = theme
	self.Tabs = {}
	self.Pages = {}
	self.Elements = {}
	self.Flags = {}
	self.Notifications = {}
	self.Visible = true
	self.Scale = config.Scale or 1
	self._maid = Maid.new()
	self._dragConnections = {}
	self._sidebarItems = {}
	self._destroyed = false
	self._resizing = false
	self._dragging = false
	self._popup = nil
	self._tooltip = nil

	self.VisibilityChanged = Signal.new()
	self.ThemeChanged = Signal.new()
	self.FlagChanged = Signal.new()

	local size = config.Size
	local width = metrics.Window.Width
	local height = metrics.Window.Height

	if type(size) == "table" then
		if (size :: any).X ~= nil then
			width = (size :: Vector2).X
			height = (size :: Vector2).Y
		else
			width = (size :: any)[1] or width
			height = (size :: any)[2] or height
		end
	elseif typeof(size) == "Vector2" then
		width = (size :: Vector2).X
		height = (size :: Vector2).Y
	end

	width = math.max(width, metrics.Window.MinWidth)
	height = math.max(height, metrics.Window.MinHeight)

	self.Size = { Width = width, Height = height }

	--// ScreenGui -------------------------------------------------------
	local parent = config.Parent

	if parent == nil then
		local player = Players.LocalPlayer

		while player == nil do
			task.wait()

			player = Players.LocalPlayer
		end

		parent = player:WaitForChild("PlayerGui")
	end

	local gui = Instance.new("ScreenGui")

	gui.Name = "MidnightUI"
	gui.DisplayOrder = config.DisplayOrder or 10
	gui.IgnoreGuiInset = config.IgnoreGuiInset ~= false
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = parent

	self.Gui = gui

	--// Root -------------------------------------------------------------
	local root = Instance.new("Frame")

	root.Name = "MidnightRoot"
	root.BackgroundTransparency = 1
	root.BorderSizePixel = 0
	root.Size = UDim2.fromScale(1, 1)
	root.ZIndex = 1
	root.Parent = gui

	self.Root = root

	--// Window frame -------------------------------------------------------
	local frame = Instance.new("CanvasGroup")

	frame.Name = config.Title or "Midnight"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = theme.Colors.Window
	frame.BackgroundTransparency = 0
	frame.BorderSizePixel = 0
	frame.GroupTransparency = 1
	frame.Position = config.Position or UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(width, height)
	frame.ZIndex = 5
	frame.Parent = root

	Util.addCorner(frame, config.Radius or metrics.Window.Radius)
	Util.addStroke(frame, theme.Colors.WindowBorder, 1)

	local uiscale = Instance.new("UIScale")

	uiscale.Scale = 0.97 * self.Scale
	uiscale.Parent = frame

	self.Instance = frame
	self.UIScale = uiscale

	--// Shadow (kept in sync while dragging/resizing) -----------------------
	local shadow = Instance.new("Frame")

	shadow.Name = "Shadow"
	shadow.AnchorPoint = frame.AnchorPoint
	shadow.BackgroundColor3 = theme.Colors.WindowShadow
	shadow.BackgroundTransparency = 1
	shadow.BorderSizePixel = 0
	shadow.Position = frame.Position
	shadow.Size = UDim2.fromOffset(width + metrics.Window.ShadowSize, height + metrics.Window.ShadowSize)
	shadow.ZIndex = 4
	shadow.Parent = root

	Util.addCorner(shadow, (config.Radius or metrics.Window.Radius) + metrics.Window.ShadowSize / 2)

	self.Shadow = shadow

	--// Header ---------------------------------------------------------------
	local headerHeight = metrics.Window.HeaderHeight

	local header = Instance.new("Frame")

	header.Name = "Header"
	header.BackgroundTransparency = 1
	header.BorderSizePixel = 0
	header.Size = UDim2.new(1, 0, 0, headerHeight)
	header.ZIndex = 6
	header.Parent = frame

	self.Header = header

	Icon.create(config.Icon or "logo", {
		Size = 21,
		Color = theme.Colors.TabActive,
		Parent = header,
		Position = UDim2.fromOffset(24, (headerHeight - 21) / 2),
		Name = "Logo",
		ZIndex = 7,
	})

	local title = Instance.new("TextLabel")

	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(24 + 21 + 11, 0)
	title.Size = UDim2.new(0, 150, 1, 0)
	title.Text = (config.Title or "Midnight"):upper()
	title.TextColor3 = theme.Colors.TabActive
	title.TextSize = 15
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextYAlignment = Enum.TextYAlignment.Center
	title.ZIndex = 7
	title.Parent = header

	Util.setFont(title, theme.Fonts.Title)

	self.Title = title

	local tabBar = Instance.new("Frame")

	tabBar.Name = "TabBar"
	tabBar.BackgroundTransparency = 1
	tabBar.BorderSizePixel = 0
	tabBar.Position = UDim2.fromOffset(metrics.Window.SidebarWidth + 28, 0)
	tabBar.Size = UDim2.new(1, -(metrics.Window.SidebarWidth + 28 + 110), 1, 0)
	tabBar.ZIndex = 6
	tabBar.Parent = header

	Util.addList(tabBar, {
		Padding = metrics.Tabs.Gap,
		Direction = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	self.TabBar = tabBar

	local divider = Instance.new("Frame")

	divider.Name = "HeaderDivider"
	divider.AnchorPoint = Vector2.new(0, 1)
	divider.BackgroundColor3 = theme.Colors.Divider
	divider.BorderSizePixel = 0
	divider.Position = UDim2.new(0, 0, 0, headerHeight)
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.ZIndex = 6
	divider.Parent = header

	--// Header buttons (search / settings) ------------------------------------
	local buttonsRight = 24
	local buttons: { [string]: Frame } = {}

	local function addHeaderButton(name: string, iconName: string, callback: () -> ())
		local hitbox = Instance.new("TextButton")

		hitbox.Name = name
		hitbox.AutoButtonColor = false
		hitbox.AnchorPoint = Vector2.new(1, 0.5)
		hitbox.BackgroundTransparency = 1
		hitbox.BorderSizePixel = 0
		hitbox.Position = UDim2.new(1, -buttonsRight, 0.5, 0)
		hitbox.Size = UDim2.fromOffset(24, 24)
		hitbox.Text = ""
		hitbox.ZIndex = 7
		hitbox.Parent = header

		local icon = Icon.create(iconName, {
			Size = 17,
			Color = theme.Colors.TabInactive,
			Parent = hitbox,
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Name = "Icon",
			ZIndex = 8,
		})

		hitbox.MouseEnter:Connect(function()
			Icon.setColor(icon, theme.Colors.TabHover)
		end)

		hitbox.MouseLeave:Connect(function()
			Icon.setColor(icon, theme.Colors.TabInactive)
		end)

		hitbox.MouseButton1Click:Connect(callback)

		buttonsRight += 30
		buttons[name] = hitbox

		return hitbox
	end

	if config.Settings ~= false then
		addHeaderButton("Settings", "settings", function()
			self:_openSettings()
		end)
	end

	if config.Search ~= false then
		addHeaderButton("Search", "search", function()
			self:_openSearch()
		end)
	end

	self.HeaderButtons = buttons

	--// Body -------------------------------------------------------------------
	local padding = metrics.Window.Padding

	local body = Instance.new("Frame")

	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.BorderSizePixel = 0
	body.Position = UDim2.fromOffset(padding, headerHeight + padding)
	body.Size = UDim2.new(1, -padding * 2, 1, -(headerHeight + padding * 2))
	body.ZIndex = 5
	body.Parent = frame

	self.Body = body

	--// Sidebar ------------------------------------------------------------------
	local sidebarFrame = Instance.new("Frame")

	sidebarFrame.Name = "Sidebar"
	sidebarFrame.BackgroundTransparency = 1
	sidebarFrame.BorderSizePixel = 0
	sidebarFrame.Size = UDim2.new(0, metrics.Window.SidebarWidth, 1, 0)
	sidebarFrame.ZIndex = 5
	sidebarFrame.Parent = body

	sidebarFrame.Visible = config.Sidebar ~= false

	self.SidebarFrame = sidebarFrame

	local sidebarScroll = Instance.new("ScrollingFrame")

	sidebarScroll.Name = "Scroll"
	sidebarScroll.BackgroundTransparency = 1
	sidebarScroll.BorderSizePixel = 0
	sidebarScroll.CanvasSize = UDim2.fromOffset(0, 0)
	sidebarScroll.ScrollBarImageColor3 = theme.Colors.Scrollbar
	sidebarScroll.ScrollBarThickness = theme.Metrics.Scrollbar.Thickness
	sidebarScroll.ScrollingDirection = Enum.ScrollingDirection.Y
	sidebarScroll.Size = UDim2.fromScale(1, 1)
	sidebarScroll.ZIndex = 5
	sidebarScroll.Parent = sidebarFrame

	Util.addList(sidebarScroll, {
		Padding = 0,
		Direction = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	sidebarScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

	self.SidebarContent = sidebarScroll
	self.SidebarWidth = metrics.Window.SidebarWidth

	--// Content --------------------------------------------------------------------
	local content = Instance.new("Frame")

	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.ClipsDescendants = true
	content.Position = UDim2.fromOffset(metrics.Window.SidebarWidth + 16, 0)
	content.Size = UDim2.new(1, -(metrics.Window.SidebarWidth + 16), 1, 0)
	content.ZIndex = 5
	content.Parent = body

	self.Content = content

	--// Overlay -------------------------------------------------------------------
	local overlay = Instance.new("Frame")

	overlay.Name = "Overlay"
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.ClipsDescendants = false
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.ZIndex = 30
	overlay.Parent = frame

	self.Overlay = overlay

	--// Resize handle ----------------------------------------------------------------
	if config.Resizable ~= false then
		local handle = Instance.new("TextButton")

		handle.Name = "Resize"
		handle.AnchorPoint = Vector2.new(1, 1)
		handle.AutoButtonColor = false
		handle.BackgroundTransparency = 1
		handle.BorderSizePixel = 0
		handle.Position = UDim2.fromScale(1, 1)
		handle.Size = UDim2.fromOffset(18, 18)
		handle.Text = ""
		handle.ZIndex = 9
		handle.Parent = frame

		for index = 1, 3 do
			local line = Instance.new("Frame")

			line.Name = "Grip"
			line.AnchorPoint = Vector2.new(1, 1)
			line.BackgroundColor3 = theme.Colors.TextMuted
			line.BackgroundTransparency = 0.45
			line.BorderSizePixel = 0
			line.Position = UDim2.new(1, -3 - index * 3, 1, -3 - index * 3)
			line.Rotation = -45
			line.Size = UDim2.fromOffset(2, 2 + index * 4)
			line.ZIndex = 9
			line.Parent = handle

			Util.addCorner(line, 1)
		end

		handle.MouseEnter:Connect(function()
			self:_setCursor("SizeNWSE")
		end)

		handle.MouseLeave:Connect(function()
			self:_setCursor(nil)
		end)

		handle.InputBegan:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				self:_startResize(input)
			end
		end)

		self.ResizeHandle = handle
	end

	--// Dragging -------------------------------------------------------------------
	if config.Draggable ~= false then
		header.InputBegan:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				self:_startDrag(input)
			end
		end)
	end

	--// Keybind --------------------------------------------------------------------
	if config.Keybind ~= nil then
		self:SetKeybind(config.Keybind)

		self._maid:Add(UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
			if gameProcessed or self._destroyed then
				return
			end

			if self._toggleKeybind ~= nil and input.KeyCode == self._toggleKeybind then
				self:Toggle()
			end
		end))
	end

	--// Open animation ------------------------------------------------------------
	Util.tween(uiscale, { Scale = self.Scale }, theme, {
		Duration = theme.Animation.VerySlow,
		Style = theme.Animation.Easing,
	})
	Util.tween(frame, { GroupTransparency = 0 }, theme, {
		Duration = theme.Animation.Slow,
	})

	return self :: Window
end

--// Internal helpers ----------------------------------------------------

function Window._syncShadow(self: Window)
	if self.Shadow == nil then
		return
	end

	self.Shadow.Position = self.Instance.Position
	self.Shadow.Size = UDim2.fromOffset(
		self.Size.Width + self.Theme.Metrics.Window.ShadowSize,
		self.Size.Height + self.Theme.Metrics.Window.ShadowSize
	)
end

--- Cosmetic cursor switching (silently ignored when unsupported).
function Window._setCursor(self: Window, cursor: string?)
	local ok = pcall(function()
		if cursor == nil then
			UserInputService.MouseIcon = ""
		else
			UserInputService.MouseIcon = "rbxasset://SystemCursors/" .. cursor
		end
	end)

	if not ok and cursor ~= nil then
		-- resource missing: fall back to the default cursor
		pcall(function()
			UserInputService.MouseIcon = ""
		end)
	end
end

function Window._startDrag(self: Window, input: InputObject)
	if self._dragging then
		return
	end

	local frame = self.Instance
	local root = self.Root

	local startMouse = Vector2.new(input.Position.X, input.Position.Y)
	local startPosition = frame.AbsolutePosition - root.AbsolutePosition

	self._dragging = true

	frame.AnchorPoint = Vector2.new(0, 0)
	frame.Position = UDim2.fromOffset(startPosition.X, startPosition.Y)

	self:_syncShadow()

	local function onMoved(changed: InputObject)
		if changed.UserInputType ~= Enum.UserInputType.MouseMovement
			and changed.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		local delta = Vector2.new(changed.Position.X, changed.Position.Y) - startMouse
		local screen = root.AbsoluteSize
		local x = startPosition.X + delta.X
		local y = startPosition.Y + delta.Y

		x = Util.clamp(x, -(self.Size.Width - 120), math.max(0, screen.X - 120))
		y = Util.clamp(y, 0, math.max(0, screen.Y - 40))

		frame.Position = UDim2.fromOffset(x, y)

		self:_syncShadow()
	end

	local function stop()
		self._dragging = false

		for _, connection in self._dragConnections do
			connection:Disconnect()
		end

		table.clear(self._dragConnections)
	end

	table.insert(self._dragConnections, UserInputService.InputChanged:Connect(onMoved))

	table.insert(
		self._dragConnections,
		UserInputService.InputEnded:Connect(function(ended: InputObject)
			if ended.UserInputType == Enum.UserInputType.MouseButton1
				or ended.UserInputType == Enum.UserInputType.Touch
			then
				stop()
			end
		end)
	)
end

function Window._startResize(self: Window, input: InputObject)
	if self._resizing then
		return
	end

	local startMouse = Vector2.new(input.Position.X, input.Position.Y)
	local startWidth = self.Size.Width
	local startHeight = self.Size.Height
	self._resizing = true

	local function stop()
		self._resizing = false

		for _, connection in self._dragConnections do
			connection:Disconnect()
		end

		table.clear(self._dragConnections)
	end

	local function onMoved(changed: InputObject)
		if changed.UserInputType ~= Enum.UserInputType.MouseMovement
			and changed.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		local delta = Vector2.new(changed.Position.X, changed.Position.Y) - startMouse

		self:SetSize(startWidth + delta.X, startHeight + delta.Y)
	end

	table.insert(self._dragConnections, UserInputService.InputChanged:Connect(onMoved))

	table.insert(
		self._dragConnections,
		UserInputService.InputEnded:Connect(function(ended: InputObject)
			if ended.UserInputType == Enum.UserInputType.MouseButton1
				or ended.UserInputType == Enum.UserInputType.Touch
			then
				stop()
			end
		end)
	)

end

--- Width available to the groupbox grid (deterministic, no read-back).
function Window.GetSectionAreaWidth(self: Window): number
	local metrics = self.Theme.Metrics
	local width = self.Size.Width - metrics.Window.Padding * 2

	if self.Config.Sidebar ~= false then
		width -= metrics.Window.SidebarWidth + 16
	end

	return math.max(160, width)
end

function Window.GetScale(self: Window): number
	return self.UIScale.Scale
end

--// Tabs & pages ---------------------------------------------------------

function Window._selectTab(self: Window, tab: any)
	if self.ActiveTab == tab or tab == nil then
		return
	end

	local previousPage = self.ActivePage

	self.ActiveTab = tab
	self.ActivePage = nil

	for _, other in self.Tabs do
		other:SetActive(other == tab)
	end

	self:_rebuildSidebar()

	-- Hide pages of every other tab.
	for _, other in self.Tabs do
		if other ~= tab then
			for _, page in other.Pages do
				page:Hide(true)
			end
		end
	end

	local pages = tab.Pages
	local targetPage = pages[1]

	if previousPage ~= nil and previousPage.Tab == tab then
		targetPage = previousPage
	end

	if targetPage ~= nil then
		self:_selectPage(targetPage)
	elseif self.ActivePage == nil then
		self:_getDefaultPageFor(tab)
	end
end

function Window._getDefaultPageFor(self: Window, tab: any)
	local page = tab:_getDefaultPage()

	if page ~= nil then
		self:_selectPage(page)
	end

	return page
end

function Window._selectPage(self: Window, page: any)
	if page == nil or self.ActivePage == page then
		return
	end

	if page.Tab ~= nil and page.Tab ~= self.ActiveTab then
		self:_selectTab(page.Tab)
	end

	if self.ActivePage ~= nil then
		self.ActivePage:Hide()
	end

	self.ActivePage = page

	page:Show()

	self:_rebuildSidebar()
end

function Window._onPagesChanged(self: Window)
	self:_rebuildSidebar()
end

function Window._removeTab(self: Window, tab: any)
	for index, stored in self.Tabs do
		if stored == tab then
			table.remove(self.Tabs, index)
			break
		end
	end

	if self.ActiveTab == tab then
		self.ActiveTab = nil
		self.ActivePage = nil

		if #self.Tabs > 0 then
			self:_selectTab(self.Tabs[1])
		end
	end
end

--- Rebuilds the sidebar for the active tab.
function Window._rebuildSidebar(self: Window)
	local content = self.SidebarContent

	Util.clearChildren(content)
	table.clear(self._sidebarItems)

	if self.Config.Sidebar == false then
		return
	end

	local tab = self.ActiveTab

	if tab == nil then
		return
	end

	local theme = self.Theme
	local metrics = theme.Metrics.Sidebar
	local order = 0
	local lastGroup: string? = nil
	local hasGroups = false

	for _, page in tab.Pages do
		if page.Group ~= nil then
			hasGroups = true
			break
		end
	end

	for _, page in tab.Pages do
		if hasGroups and page.Group ~= nil and page.Group ~= lastGroup then
			lastGroup = page.Group
			order += 1

			local groupLabel = Instance.new("TextLabel")

			groupLabel.Name = "Group_" .. page.Group
			groupLabel.BackgroundTransparency = 1
			groupLabel.LayoutOrder = order
			groupLabel.Size = UDim2.new(1, -metrics.Padding, 0, metrics.GroupHeight)
			groupLabel.Text = (page.Group or ""):upper()
			groupLabel.TextColor3 = theme.Colors.SidebarGroup
			groupLabel.TextSize = 10
			groupLabel.TextXAlignment = Enum.TextXAlignment.Left
			groupLabel.TextYAlignment = Enum.TextYAlignment.Bottom
			groupLabel.ZIndex = 6
			groupLabel.Parent = content

			Util.addPadding(groupLabel, metrics.Padding, 0, 0, 0)
			Util.setFont(groupLabel, theme.Fonts.Bold)
		end

		order += 1

		local item = Instance.new("TextButton")

		item.Name = "Page_" .. page.Name
		item.AutoButtonColor = false
		item.BackgroundColor3 = theme.Colors.SidebarItemHover
		item.BackgroundTransparency = 1
		item.BorderSizePixel = 0
		item.LayoutOrder = order
		item.Size = UDim2.new(1, 0, 0, metrics.ItemHeight)
		item.Text = ""
		item.ZIndex = 6
		item.Parent = content

		Util.addCorner(item, metrics.ItemRadius)

		local icon = Icon.create(page.Icon or "dot", {
			Size = metrics.IconSize,
			Color = theme.Colors.SidebarItem,
			Parent = item,
			Position = UDim2.fromOffset(metrics.Padding, (metrics.ItemHeight - metrics.IconSize) / 2),
			AnchorPoint = Vector2.new(0, 0),
			Name = "Icon",
			ZIndex = 7,
		})

		local label = Instance.new("TextLabel")

		label.Name = "Label"
		label.BackgroundTransparency = 1
		label.Position = UDim2.fromOffset(metrics.Padding + metrics.IconSize + metrics.IconGap, 0)
		label.Size = UDim2.new(1, -(metrics.Padding * 2 + metrics.IconSize + metrics.IconGap), 1, 0)
		label.Text = page.Name
		label.TextColor3 = theme.Colors.SidebarItem
		label.TextSize = metrics.TextSize
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.TextTruncate = Enum.TextTruncate.AtEnd
		label.ZIndex = 7
		label.Parent = item

		Util.setFont(label, theme.Fonts.Text)

		local entry = {
			Page = page,
			Item = item,
			Label = label,
			Icon = icon,
			Active = false,
		}

		local function paint(active: boolean, hovering: boolean)
			entry.Active = active

			if active then
				item.BackgroundTransparency = 0
				item.BackgroundColor3 = theme.Colors.SidebarItemActive
				label.TextColor3 = theme.Colors.SidebarItemActiveText
				Icon.setColor(icon, theme.Colors.IconActive)
			elseif hovering then
				item.BackgroundTransparency = 0
				item.BackgroundColor3 = theme.Colors.SidebarItemHover
				label.TextColor3 = theme.Colors.SidebarItemActiveText
				Icon.setColor(icon, theme.Colors.SidebarItem)
			else
				item.BackgroundTransparency = 1
				label.TextColor3 = theme.Colors.SidebarItem
				Icon.setColor(icon, theme.Colors.SidebarItem)
			end
		end

		entry.Paint = paint

		item.MouseEnter:Connect(function()
			paint(entry.Active, true)
		end)

		item.MouseLeave:Connect(function()
			paint(entry.Active, false)
		end)

		item.MouseButton1Click:Connect(function()
			self:_selectPage(page)
		end)

		table.insert(self._sidebarItems, entry)
	end

	local selected = self.ActivePage

	for _, entry in self._sidebarItems do
		entry.Paint(entry.Page == selected, false)
	end
end

--- Repaints the sidebar selection without rebuilding it.
function Window._updateSidebarSelection(self: Window)
	for _, entry in self._sidebarItems do
		entry.Paint(entry.Page == self.ActivePage, false)
	end
end

--// Flags & configs -------------------------------------------------------

function Window._registerElement(self: Window, element: any)
	if element.Flag == nil then
		return
	end

	self.Elements[element.Flag] = element

	if element.Value ~= nil then
		self.Flags[element.Flag] = element.Value
	end

	element:OnChanged(function(value: any)
		self.Flags[element.Flag] = value
		self.FlagChanged:Fire(element.Flag, value)
	end)
end

function Window._setFlag(self: Window, flag: string, value: any)
	self.Flags[flag] = value
	self.FlagChanged:Fire(flag, value)
end

--- Value of a flag (nil when the flag does not exist yet).
function Window.GetFlag(self: Window, flag: string): any
	return self.Flags[flag]
end

--- Sets a flag and updates the matching element on screen.
function Window.SetFlag(self: Window, flag: string, value: any): boolean
	local element = self.Elements[flag]

	if element == nil or element:IsDestroyed() then
		self:_setFlag(flag, value)

		return false
	end

	element:SetValue(value)

	return true
end

function Window.GetFlags(self: Window): { [string]: any }
	return table.clone(self.Flags)
end

--- Snapshot of every flag (ready to be serialised).
function Window.SaveConfig(self: Window): { [string]: any }
	return table.clone(self.Flags)
end

--- Applies a snapshot produced by SaveConfig.
function Window.LoadConfig(self: Window, config: { [string]: any })
	for flag, value in config do
		self:SetFlag(flag, value)
	end
end

function Window._requestLayout(self: Window)
	for _, tab in self.Tabs do
		for _, page in tab.Pages do
			page:_requestLayout()
		end
	end
end

--// Popups, tooltips --------------------------------------------------------

function Window._createPopup(self: Window, config: any): any
	if self._popup ~= nil and self._popup:IsOpen() then
		self._popup:Close()
	end

	config.Window = self

	local popup = Popup.new(self, config)

	self._popup = popup

	return popup
end

function Window._closePopup(self: Window)
	if self._popup ~= nil and self._popup:IsOpen() then
		self._popup:Close()
	end
end

function Window._showTooltip(self: Window, text: string)
	Window._hideTooltip(self, true)

	local theme = self.Theme
	local gui = Instance.new("CanvasGroup")

	gui.Name = "Tooltip"
	gui.BackgroundColor3 = theme.Colors.Tooltip
	gui.BackgroundTransparency = 0
	gui.BorderSizePixel = 0
	gui.GroupTransparency = 1
	gui.ZIndex = 70
	gui.Parent = self.Overlay

	Util.addCorner(gui, 4)
	Util.addStroke(gui, theme.Colors.TooltipBorder, 1, 0.2)
	Util.addPadding(gui, 7, 7, 4, 4)

	local label = Instance.new("TextLabel")

	label.Name = "Text"
	label.AutomaticSize = Enum.AutomaticSize.XY
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromOffset(0, 0)
	label.Text = text
	label.TextColor3 = theme.Colors.Text
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.ZIndex = 71
	label.Parent = gui

	Util.setFont(label, theme.Fonts.Small)

	local mouse = UserInputService:GetMouseLocation()
	local offset = self.Overlay.AbsolutePosition

	gui.Position = UDim2.fromOffset(mouse.X - offset.X + 14, mouse.Y - offset.Y + 16)

	self._tooltip = gui

	Util.tween(gui, { GroupTransparency = 0 }, theme, {
		Duration = theme.Animation.Fast,
	})

	-- Keep it next to the cursor.
	local connection: any

	connection = UserInputService.InputChanged:Connect(function(input: InputObject)
		if gui.Parent == nil then
			connection:Disconnect()

			return
		end

		if input.UserInputType == Enum.UserInputType.MouseMovement then
			local position = self.Overlay.AbsolutePosition

			gui.Position = UDim2.fromOffset(input.Position.X - position.X + 14, input.Position.Y - position.Y + 16)
		end
	end)

	self._tooltipConnection = connection
end

function Window._hideTooltip(self: Window, instant: boolean?)
	local tooltip = self._tooltip
	self._tooltip = nil

	if self._tooltipConnection ~= nil then
		self._tooltipConnection:Disconnect()
		self._tooltipConnection = nil
	end

	if tooltip == nil then
		return
	end

	if instant == true then
		tooltip:Destroy()

		return
	end

	Util.tween(tooltip, { GroupTransparency = 1 }, self.Theme, {
		Duration = self.Theme.Animation.Fast,
	})

	task.delay(self.Theme.Animation.Fast + 0.02, function()
		if tooltip.Parent ~= nil then
			tooltip:Destroy()
		end
	end)
end

--// Search palette -----------------------------------------------------------

function Window._searchItems(self: Window): { any }
	local results = {}

	for _, tab in self.Tabs do
		for _, page in tab.Pages do
			for _, section in page:GetSections() do
				for _, element in section:GetElements() do
					if element.Title ~= nil and element.Title ~= "" then
						table.insert(results, {
							Tab = tab,
							Page = page,
							Section = section,
							Element = element,
							Text = element.Title,
							SectionName = section.Name,
						})
					end
				end
			end
		end
	end

	return results
end

function Window._openSearch(self: Window)
	if self._popup ~= nil and self._popup:IsOpen() then
		self:_closePopup()

		return
	end

	local theme = self.Theme
	local metrics = theme.Metrics
	local anchor = self.HeaderButtons and self.HeaderButtons["Search"]

	if anchor == nil then
		return
	end

	local query = ""
	local searchBox: TextBox? = nil
	local results: ScrollingFrame? = nil

	local function matches(): { any }
		local found = {}

		for _, item in self:_searchItems() do
			if query == ""
				or item.Text:lower():find(query:lower(), 1, true) ~= nil
				or item.SectionName:lower():find(query:lower(), 1, true) ~= nil
			then
				table.insert(found, item)
			end
		end

		return found
	end

	local function renderContent(parent: Frame): number
		local total = 0
		local searchHeight = metrics.Popup.SearchHeight

		if searchBox == nil or searchBox.Parent == nil then
			local box = Instance.new("TextBox")

			box.Name = "Search"
			box.BackgroundColor3 = theme.Colors.Element
			box.BorderSizePixel = 0
			box.ClearTextOnFocus = false
			box.PlaceholderText = "Search a feature…"
			box.PlaceholderColor3 = theme.Colors.TextMuted
			box.Size = UDim2.new(1, 0, 0, searchHeight)
			box.Text = query
			box.TextColor3 = theme.Colors.Text
			box.TextSize = metrics.Popup.ItemTextSize
			box.TextXAlignment = Enum.TextXAlignment.Left
			box.ZIndex = 32
			box.Parent = parent

			Util.addCorner(box, 4)
			Util.addPadding(box, 8, 8, 0, 0)
			Util.addStroke(box, theme.Colors.ElementBorder, 1)
			Util.setFont(box, theme.Fonts.Text)

			box:GetPropertyChangedSignal("Text"):Connect(function()
				if box.Text == query then
					return
				end

				query = box.Text

				if self._popup ~= nil then
					Popup.Refresh(self._popup)
				end
			end)

			searchBox = box

			task.defer(function()
				if box.Parent ~= nil then
					box:CaptureFocus()
				end
			end)
		else
			searchBox.Parent = parent
		end

		total += searchHeight + 6

		if results ~= nil then
			results:Destroy()
			results = nil
		end

		local found = matches()
		local rowHeight = 30
		local listHeight = math.min(math.max(#found, 1) * rowHeight, 200)

		local list = Instance.new("ScrollingFrame")

		list.Name = "Results"
		list.BackgroundTransparency = 1
		list.BorderSizePixel = 0
		list.CanvasSize = UDim2.fromOffset(0, math.max(#found * rowHeight, rowHeight))
		list.Position = UDim2.fromOffset(0, total)
		list.ScrollBarImageColor3 = theme.Colors.Scrollbar
		list.ScrollBarThickness = metrics.Scrollbar.Thickness
		list.Size = UDim2.new(1, 0, 0, listHeight)
		list.ZIndex = 32
		list.Parent = parent

		Util.addList(list, { Padding = 0, SortOrder = Enum.SortOrder.LayoutOrder })

		if #found == 0 then
			local empty = Instance.new("TextLabel")

			empty.Name = "Empty"
			empty.BackgroundTransparency = 1
			empty.Size = UDim2.new(1, 0, 0, rowHeight)
			empty.Text = "Nothing found"
			empty.TextColor3 = theme.Colors.TextMuted
			empty.TextSize = metrics.Popup.ItemTextSize
			empty.ZIndex = 33
			empty.Parent = list

			Util.setFont(empty, theme.Fonts.Small)
		end

		for index, item in found do
			local row = Instance.new("TextButton")

			row.Name = item.Text
			row.AutoButtonColor = false
			row.BackgroundTransparency = 1
			row.BorderSizePixel = 0
			row.LayoutOrder = index
			row.Size = UDim2.new(1, 0, 0, rowHeight)
			row.Text = ""
			row.ZIndex = 33
			row.Parent = list

			Util.addCorner(row, 4)

			local titleLabel = Instance.new("TextLabel")

			titleLabel.Name = "Result"
			titleLabel.BackgroundTransparency = 1
			titleLabel.Position = UDim2.fromOffset(8, 2)
			titleLabel.Size = UDim2.new(1, -16, 0, 14)
			titleLabel.Text = item.Text
			titleLabel.TextColor3 = theme.Colors.Text
			titleLabel.TextSize = metrics.Popup.ItemTextSize
			titleLabel.TextXAlignment = Enum.TextXAlignment.Left
			titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
			titleLabel.ZIndex = 34
			titleLabel.Parent = row

			Util.setFont(titleLabel, theme.Fonts.Text)

			local pathLabel = Instance.new("TextLabel")

			pathLabel.Name = "Path"
			pathLabel.BackgroundTransparency = 1
			pathLabel.Position = UDim2.fromOffset(8, 15)
			pathLabel.Size = UDim2.new(1, -16, 0, 12)
			pathLabel.Text = ("%s › %s › %s"):format(item.Tab.Name, item.Page.Name, item.SectionName)
			pathLabel.TextColor3 = theme.Colors.TextMuted
			pathLabel.TextSize = 10
			pathLabel.TextXAlignment = Enum.TextXAlignment.Left
			pathLabel.TextTruncate = Enum.TextTruncate.AtEnd
			pathLabel.ZIndex = 34
			pathLabel.Parent = row

			Util.setFont(pathLabel, theme.Fonts.Small)

			row.MouseEnter:Connect(function()
				row.BackgroundColor3 = theme.Colors.PopupHover
				row.BackgroundTransparency = 0
			end)

			row.MouseLeave:Connect(function()
				row.BackgroundTransparency = 1
			end)

			row.MouseButton1Click:Connect(function()
				self:_closePopup()
				self:_selectTab(item.Tab)
				self:_selectPage(item.Page)
				item.Page:ScrollToSection(item.Section)
				self:_flash(item.Section)
			end)
		end

		results = list
		total += listHeight

		return total
	end

	self:_createPopup({
		Name = "Search",
		Anchor = anchor,
		Width = math.max(260, self.Size.Width * 0.38),
		Rebuild = false,
		Content = renderContent,
		OnClose = function()
			searchBox = nil
			results = nil
			query = ""
		end,
	})
end

--- Highlights a section (used when jumping to a search result).
function Window._flash(self: Window, section: any)
	local theme = self.Theme
	local stroke = Util.findClass(section.Instance, "UIStroke")

	if stroke == nil then
		return
	end

	local original = theme.Colors.PanelBorder

	Util.tween(stroke, { Color = theme.Colors.Accent, Transparency = 0 }, theme, {
		Duration = theme.Animation.Fast,
	})

	task.delay(theme.Animation.Slow + 0.5, function()
		if stroke.Parent ~= nil then
			Util.tween(stroke, { Color = original, Transparency = 1 }, theme, {
				Duration = theme.Animation.Slow,
			})
		end
	end)
end

--// Settings panel --------------------------------------------------------------

function Window._openSettings(self: Window)
	if self._popup ~= nil and self._popup:IsOpen() then
		self:_closePopup()

		return
	end

	local theme = self.Theme
	local metrics = theme.Metrics
	local anchor = self.HeaderButtons and self.HeaderButtons["Settings"]

	if anchor == nil then
		return
	end

	local stack: any = nil
	local contentHeight = 0

	local function renderContent(parent: Frame): number
		if stack == nil then
			stack = createPanelStack(self, parent)

			stack._onChanged = function()
				if self._popup ~= nil then
					Popup.Refresh(self._popup)
				end
			end

			stack:Label({ Text = "INTERFACE", Color = "TextMuted", TextSize = 10, Bold = true })

			stack:Dropdown({
				Title = "Theme",
				Options = Theme.getPresets(),
				Default = theme.Name,
				Arrow = true,
				Callback = function(value: string)
					self:SetTheme(value)
				end,
			})

			stack:Slider({
				Title = "Interface scale",
				Min = 0.75,
				Max = 1.4,
				Default = self.Scale,
				Decimals = 2,
				Suffix = "x",
				Callback = function(value: number)
					self:SetScale(value)
				end,
			})

			stack:Toggle({
				Title = "Animations",
				Default = theme.Animation.Enabled,
				Callback = function(value: boolean)
					self:SetAnimations(value)
				end,
			})

			stack:Keybind({
				Title = "Toggle interface",
				Default = self._toggleKeybind,
				Callback = function(key: string?)
					self:SetKeybind(key)
				end,
			})

			stack:Divider({})

			stack:Label({
				Text = "Right click a keybind to clear it. Flags: " .. tostring(self:_countFlags()),
				Color = "TextMuted",
				TextSize = 11,
				Height = 28,
				Wrapped = true,
			})
		end

		contentHeight = Section._getContentHeight(stack)

		return contentHeight
	end

	self:_createPopup({
		Name = "Settings",
		Anchor = anchor,
		Width = 300,
		Content = renderContent,
		OnClose = function()
			if stack ~= nil then
				stack:Destroy()
				stack = nil
			end
		end,
	})
end

function Window._countFlags(self: Window): number
	local count = 0

	for _ in self.Flags do
		count += 1
	end

	return count
end

--// Notifications ------------------------------------------------------------------

function Window._layoutNotifications(self: Window, animate: boolean?)
	local metrics = self.Theme.Metrics.Notification
	local offset = 0

	for index = #self.Notifications, 1, -1 do
		local notification = self.Notifications[index]

		if not notification.Closing then
			local target = UDim2.new(1, -metrics.Margin, 1, -(metrics.Margin + offset))

			if animate == false then
				notification.Root.Position = target
			else
				Util.tween(notification.Root, { Position = target }, self.Theme, {
					Duration = self.Theme.Animation.Slow,
					Style = self.Theme.Animation.Easing,
				})
			end

			offset += notification.Height + metrics.Gap
		end
	end
end

--- Shows a toast notification.
function Window.Notify(self: Window, props: any)
	if self.Config.Notifications == false or self._destroyed then
		return nil
	end

	if type(props) == "string" then
		props = { Text = props }
	end

	local metrics = self.Theme.Metrics.Notification
	local notification: any = nil

	notification = Notification.new(self, props, function()
		self:_layoutNotifications()
	end, function()
		for index, stored in self.Notifications do
			if stored == notification then
				table.remove(self.Notifications, index)

				break
			end
		end

		self:_layoutNotifications()
	end)

	table.insert(self.Notifications, notification)

	while #self.Notifications > metrics.MaxVisible do
		local oldest = table.remove(self.Notifications, 1)

		if oldest ~= nil then
			oldest:Close()
		end
	end

	self:_layoutNotifications()

	return notification
end

--// Appearance, visibility, lifetime ------------------------------------------------

function Window.SetTitle(self: Window, title: string)
	self.Config.Title = title
	self.Title.Text = title:upper()
	self.Instance.Name = title
end

function Window.SetAnimations(self: Window, enabled: boolean)
	self.Theme.Animation.Enabled = enabled
end

function Window.SetScale(self: Window, scale: number)
	self.Scale = Util.clamp(scale, 0.5, 2)

	Util.tween(self.UIScale, { Scale = self.Scale }, self.Theme, {
		Duration = self.Theme.Animation.Normal,
	})
end

function Window.SetSize(self: Window, width: number, height: number)
	local metrics = self.Theme.Metrics

	width = math.max(width, metrics.Window.MinWidth)
	height = math.max(height, metrics.Window.MinHeight)

	self.Size = { Width = width, Height = height }
	self.Instance.Size = UDim2.fromOffset(width, height)

	self:_syncShadow()
	self:_requestLayout()
end

--- Switches the theme live (all elements re-colour themselves).
function Window.SetTheme(self: Window, newTheme: (string | { [string]: any }))
	local previous = self.Theme

	self.Theme = Theme.resolve(newTheme)
	self.Theme.Animation.Enabled = previous.Animation.Enabled

	local theme = self.Theme
	local metrics = theme.Metrics

	self.Instance.BackgroundColor3 = theme.Colors.Window

	local frameStroke = Util.findClass(self.Instance, "UIStroke")

	if frameStroke ~= nil then
		frameStroke.Color = theme.Colors.WindowBorder
	end

	if self.Shadow ~= nil then
		self.Shadow.BackgroundColor3 = theme.Colors.WindowShadow
	end

	local logo = self.Header:FindFirstChild("Logo")

	if logo ~= nil then
		Icon.setColor(logo :: any, theme.Colors.TabActive)
	end

	self.Title.TextColor3 = theme.Colors.TabActive

	for _, button in self.HeaderButtons or {} do
		local icon = button:FindFirstChild("Icon")

		if icon ~= nil then
			Icon.setColor(icon :: any, theme.Colors.TabInactive)
		end
	end

	local divider = self.Header:FindFirstChild("HeaderDivider")

	if divider ~= nil then
		(divider :: any).BackgroundColor3 = theme.Colors.Divider
	end

	self.SidebarContent.ScrollBarImageColor3 = theme.Colors.Scrollbar
	self.SidebarContent.ScrollBarThickness = metrics.Scrollbar.Thickness

	for _, tab in self.Tabs do
		tab.Theme = theme
		tab:OnThemeChanged()

		for _, page in tab.Pages do
			page.Theme = theme
			page.Scrolling.ScrollBarImageColor3 = theme.Colors.Scrollbar

			for _, section in page:GetSections() do
				section.Theme = theme
				section.Instance.BackgroundColor3 = theme.Colors.Panel

				local sectionStroke = Util.findClass(section.Instance, "UIStroke")

				if sectionStroke ~= nil then
					sectionStroke.Color = theme.Colors.PanelBorder
				end

				section.Title.TextColor3 = theme.Colors.PanelHeader
				section.Title.TextSize = metrics.Panel.HeaderTextSize

				local sectionDivider = section.Instance:FindFirstChild("Divider")

				if sectionDivider ~= nil then
					(sectionDivider :: any).BackgroundColor3 = theme.Colors.PanelDivider
				end

				for _, element in section:GetElements() do
					element.Theme = theme
					element:ApplyTheme()
				end
			end
		end
	end

	self:_rebuildSidebar()

	if self._popup ~= nil and self._popup:IsOpen() then
		self:_closePopup()
	end

	self.ThemeChanged:Fire(theme)
end

function Window.IsVisible(self: Window): boolean
	return self.Visible
end

function Window.SetVisible(self: Window, visible: boolean, instant: boolean?)
	if self.Visible == visible and not instant then
		return
	end

	local theme = self.Theme
	self.Visible = visible

	if instant == true or not theme.Animation.Enabled then
		self.Instance.Visible = visible
		self.Instance.GroupTransparency = visible and 0 or 1
		self.UIScale.Scale = self.Scale
		self:_syncShadow()

		self.VisibilityChanged:Fire(visible)

		return
	end

	if visible then
		self.Instance.Visible = true
		self.Instance.GroupTransparency = 1
		self.UIScale.Scale = self.Scale * 0.97

		Util.tween(self.Instance, { GroupTransparency = 0 }, theme, {
			Duration = theme.Animation.Normal,
		})
		Util.tween(self.UIScale, { Scale = self.Scale }, theme, {
			Duration = theme.Animation.Slow,
			Style = theme.Animation.Easing,
		})
	else
		Util.tween(self.Instance, { GroupTransparency = 1 }, theme, {
			Duration = theme.Animation.Fast,
		})
		Util.tween(self.UIScale, { Scale = self.Scale * 0.97 }, theme, {
			Duration = theme.Animation.Fast,
		})

		task.delay(theme.Animation.Fast + 0.02, function()
			if not self.Visible and not self._destroyed then
				self.Instance.Visible = false
			end
		end)
	end

	self.VisibilityChanged:Fire(visible)
end

function Window.Toggle(self: Window, visible: boolean?)
	if visible == nil then
		visible = not self.Visible
	end

	self:SetVisible(visible)
end

function Window.SetKeybind(self: Window, key: any)
	self._toggleKeybind = resolveKeyName(key)

	return self._toggleKeybind
end

function Window.GetKeybind(self: Window): Enum.KeyCode?
	return self._toggleKeybind
end

function Window.IsDestroyed(self: Window): boolean
	return self._destroyed
end

function Window.Destroy(self: Window)
	if self._destroyed then
		return
	end

	self._destroyed = true

	self:_closePopup()
	Window._hideTooltip(self, true)

	for index = #self.Notifications, 1, -1 do
		local notification = self.Notifications[index]
		self.Notifications[index] = nil

		notification:Close()
	end

	for index = #self.Tabs, 1, -1 do
		local tab = self.Tabs[index]
		self.Tabs[index] = nil

		tab:Destroy()
	end

	for _, connection in self._dragConnections do
		connection:Disconnect()
	end

	table.clear(self._dragConnections)

	self._maid:Destroy()
	self.VisibilityChanged:DisconnectAll()
	self.ThemeChanged:DisconnectAll()
	self.FlagChanged:DisconnectAll()

	if self.Gui.Parent ~= nil then
		self.Gui:Destroy()
	end
end

--// Public constructors -------------------------------------------------------------

--- Creates a top bar tab and returns it.
function Window.Tab(self: Window, title: string, options: any?): any
	local tab = Tab.new(self, title, options)

	table.insert(self.Tabs, tab)

	if self.ActiveTab == nil then
		self:_selectTab(tab)
	end

	return tab
end

--- Aliases.
Window.CreateTab = Window.Tab

--- Selects a tab by instance, name or index.
function Window.SelectTab(self: Window, target: any): any
	local tab = target

	if type(target) == "string" then
		for _, candidate in self.Tabs do
			if candidate.Name == target then
				tab = candidate

				break
			end
		end
	elseif type(target) == "number" then
		tab = self.Tabs[target]
	end

	if tab == nil then
		return nil
	end

	self:_selectTab(tab)

	return tab
end

--- Selects a page by name inside the active tab.
function Window.SelectPage(self: Window, name: string): any
	local tab = self.ActiveTab

	if tab == nil then
		return nil
	end

	local page = tab:FindPage(name)

	if page ~= nil then
		self:_selectPage(page)
	end

	return page
end

--- Status of every element, keyed by flag (alias of GetFlags).
function Window.GetElements(self: Window): { [string]: any }
	return self.Elements
end

return Window
