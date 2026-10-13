--!strict
--[[
	MidnightUI · Tab
	------------------------------------------------------------------
	A top bar tab ("MAIN", "FEATURES", "APPEARANCE"…).

	Each tab owns a list of pages (the sidebar entries) and a lazily
	created default page, so simple menus can skip pages entirely:

		local tab = Window:Tab("Features")
		local box = tab:Groupbox("Aimbot")   -- goes to the default page
]]

local Maid = require(script.Parent.Maid)
local Util = require(script.Parent.Util)

local Page = require(script.Parent.Page)

local Tab = {}
Tab.__index = Tab

export type Options = {
	Icon: string?,
	Order: number?,
}

export type PageOptions = {
	Group: string?,
	Icon: string?,
	Order: number?,
	Columns: number?,
}

export type Tab = typeof(setmetatable(
	{} :: {
		Name: string,
		Window: any,
		Theme: any,
		Instance: TextButton,
		Label: TextLabel,
		Underline: Frame,
		Pages: { any },
		Active: boolean,
		Order: number,
		_maid: any,
		_hovering: boolean,
		_destroyed: boolean,
	},
	Tab
))

--// Construction -----------------------------------------------------

function Tab.new(window: any, title: string, options: Options?): Tab
	local opts = options or {}
	local theme = window.Theme

	local self: any = setmetatable({}, Tab)

	self.Name = title
	self.Window = window
	self.Theme = theme
	self.Pages = {}
	self.Active = false
	self.Order = opts.Order or (#window.Tabs + 1)
	self._maid = window._maid:AddProxy(Maid.new())
	self._hovering = false
	self._destroyed = false
	self._defaultPage = nil

	--// Button ---------------------------------------------------------
	local button = Instance.new("TextButton")

	button.Name = "Tab_" .. title
	button.AutoButtonColor = false
	button.AutomaticSize = Enum.AutomaticSize.X
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	button.LayoutOrder = self.Order
	button.Size = UDim2.new(0, 0, 1, 0)
	button.Text = ""
	button.ZIndex = 4
	button.Parent = window.TabBar

	self.Instance = button

	local label = Instance.new("TextLabel")

	label.Name = "Label"
	label.AutomaticSize = Enum.AutomaticSize.X
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(0, 0, 1, 0)
	label.Text = title:upper()
	label.TextColor3 = theme.Colors.TabInactive
	label.TextSize = theme.Metrics.Tabs.TextSize
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.ZIndex = 5
	label.Parent = button

	Util.setFont(label, theme.Fonts.Tab)

	local underline = Instance.new("Frame")

	underline.Name = "Underline"
	underline.AnchorPoint = Vector2.new(0.5, 1)
	underline.BackgroundColor3 = theme.Colors.Accent
	underline.BackgroundTransparency = 1
	underline.BorderSizePixel = 0
	underline.Position = UDim2.new(0.5, 0, 1, 0)
	underline.Size = UDim2.new(0.35, 0, 0, theme.Metrics.Tabs.UnderlineHeight)
	underline.ZIndex = 5
	underline.Parent = button

	Util.addCorner(underline, theme.Metrics.Tabs.UnderlineHeight / 2)

	self.Label = label
	self.Underline = underline

	--// Behaviour --------------------------------------------------------
	function self.Refresh()
		local color = if self.Active
			then theme.Colors.TabActive
			elseif self._hovering then theme.Colors.TabHover
			else theme.Colors.TabInactive

		label.TextColor3 = color
		underline.BackgroundColor3 = theme.Colors.Accent
	end

	function self.SetActive(active: boolean, animate: boolean?)
		if self.Active == active then
			return
		end

		self.Active = active

		if not theme.Animation.Enabled then
			animate = false
		end

		if animate == false then
			underline.BackgroundTransparency = active and 0 or 1
			underline.Size = UDim2.new(active and 1 or 0.35, 0, 0, theme.Metrics.Tabs.UnderlineHeight)
			self:Refresh()

			return
		end

		Util.tween(underline, {
			BackgroundTransparency = active and 0 or 1,
			Size = UDim2.new(active and 1 or 0.35, 0, 0, theme.Metrics.Tabs.UnderlineHeight),
		}, theme, {
			Duration = theme.Animation.Normal,
		})

		self:Refresh()
	end

	function self.OnThemeChanged()
		label.TextSize = theme.Metrics.Tabs.TextSize
		underline.Size = UDim2.new(self.Active and 1 or 0.35, 0, 0, theme.Metrics.Tabs.UnderlineHeight)

		Util.setFont(label, theme.Fonts.Tab)
		self:Refresh()
	end

	self:Connect(button.MouseEnter, function()
		self._hovering = true
		self:Refresh()
	end)

	self:Connect(button.MouseLeave, function()
		self._hovering = false
		self:Refresh()
	end)

	button.MouseButton1Click:Connect(function()
		window:_selectTab(self)
	end)

	self:Refresh()

	return self :: Tab
end

--// Internals --------------------------------------------------------

function Tab.Connect(self: Tab, signal: any, callback: (...any) -> ()): any
	local connection = signal:Connect(callback)

	self._maid:Add(connection)

	return connection
end

function Tab._removePage(self: Tab, page: any)
	for index, stored in self.Pages do
		if stored == page then
			table.remove(self.Pages, index)
			break
		end
	end

	if self._defaultPage == page then
		self._defaultPage = nil
	end

	self.Window:_onPagesChanged()
end

--- The page used when elements are added straight to the tab.
function Tab._getDefaultPage(self: Tab): any
	if self._defaultPage ~= nil and not self._defaultPage:IsDestroyed() then
		return self._defaultPage
	end

	for _, page in self.Pages do
		if not page:IsDestroyed() and page.Group == nil then
			self._defaultPage = page

			return page
		end
	end

	self._defaultPage = self:Page("Main")

	return self._defaultPage
end

--// Public API -------------------------------------------------------

--- Creates a sidebar page inside this tab.
function Tab.Page(self: Tab, title: string, options: PageOptions?): any
	local page = Page.new(self.Window, self, title, options)

	table.insert(self.Pages, page)
	self.Window:_onPagesChanged()

	return page
end

--- Lazily created page for tabs that do not need a sidebar.
function Tab.Groupbox(self: Tab, title: string, options: any?): any
	return self:_getDefaultPage():Groupbox(title, options)
end

Tab.Panel = Tab.Groupbox
Tab.Section = Tab.Groupbox
Tab.Card = Tab.Groupbox

function Tab.GetPages(self: Tab): { any }
	return self.Pages
end

function Tab.FindPage(self: Tab, title: string): any
	for _, page in self.Pages do
		if page.Name == title then
			return page
		end
	end

	return nil
end

function Tab.Select(self: Tab)
	self.Window:_selectTab(self)
end

function Tab.SetTitle(self: Tab, title: string)
	self.Name = title
	self.Label.Text = title:upper()
end

function Tab.IsDestroyed(self: Tab): boolean
	return self._destroyed
end

function Tab.Destroy(self: Tab)
	if self._destroyed then
		return
	end

	self._destroyed = true

	for index = #self.Pages, 1, -1 do
		local page = self.Pages[index]
		self.Pages[index] = nil

		page:Destroy()
	end

	self._maid:Destroy()
	self.Instance:Destroy()

	if self.Window ~= nil then
		self.Window:_removeTab(self)
	end

	self.Window = nil
end

return Tab
