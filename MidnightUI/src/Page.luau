--!strict
--[[
	MidnightUI · Page
	------------------------------------------------------------------
	A page is one entry of the sidebar ("Self", "Players", "Aimbot"…)
	and owns the masonry grid of groupboxes.

	Layout is fully deterministic: the available width comes from the
	window's own metrics (never from layout read-back) and each section
	reports its height, so the page can lay everything out in one pass:

		· columns are filled like a masonry grid (the next groupbox goes
		  into the currently shortest column)
		· `Column = 1|2|"Left"|"Right"` pins a groupbox to a column
]]

local Maid = require(script.Parent.Maid)
local Util = require(script.Parent.Util)

local Section = require(script.Parent.Section)

local Page = {}
Page.__index = Page

export type Options = {
	Group: string?,
	Icon: string?,
	Order: number?,
	Columns: number?,
}

export type Page = typeof(setmetatable(
	{} :: {
		Name: string,
		Tab: any,
		Window: any,
		Theme: any,
		Group: string?,
		Icon: string?,
		Root: CanvasGroup,
		Scrolling: ScrollingFrame,
		Sections: { any },
		Columns: number,
		Order: number,
		_maid: any,
		_visible: boolean,
		_destroyed: boolean,
		_layoutQueued: boolean,
	},
	Page
))

local SCROLLBAR_RESERVE = 10

--// Construction -----------------------------------------------------

function Page.new(window: any, tab: any, name: string, options: Options?): Page
	local opts = options or {}
	local theme = window.Theme

	local self: any = setmetatable({}, Page)

	self.Name = name
	self.Tab = tab
	self.Window = window
	self.Theme = theme
	self.Group = opts.Group
	self.Icon = opts.Icon
	self.Order = opts.Order or 1
	self.Columns = opts.Columns or window.Config.Columns or 2
	self.Sections = {}
	self._visible = false
	self._destroyed = false
	self._layoutQueued = false
	self._maid = window._maid:AddProxy(Maid.new())

	--// Root -----------------------------------------------------------
	local root = Instance.new("CanvasGroup")

	root.Name = name
	root.BackgroundTransparency = 1
	root.BorderSizePixel = 0
	root.GroupTransparency = 1
	root.Size = UDim2.fromScale(1, 1)
	root.Visible = false
	root.Parent = window.Content

	self.Root = root

	--// Scrolling -------------------------------------------------------
	local scrolling = Instance.new("ScrollingFrame")

	scrolling.Name = "Scroll"
	scrolling.BackgroundTransparency = 1
	scrolling.BorderSizePixel = 0
	scrolling.CanvasSize = UDim2.fromOffset(0, 0)
	scrolling.ScrollBarImageColor3 = theme.Colors.Scrollbar
	scrolling.ScrollBarThickness = theme.Metrics.Scrollbar.Thickness
	scrolling.ScrollingDirection = Enum.ScrollingDirection.Y
	scrolling.Size = UDim2.fromScale(1, 1)
	scrolling.Parent = root

	self.Scrolling = scrolling

	return self :: Page
end

--// Layout -----------------------------------------------------------

--- Width available for a grid of groupboxes.
function Page.GetAreaWidth(self: Page): number
	return math.max(120, self.Window:GetSectionAreaWidth() - SCROLLBAR_RESERVE)
end

--- Returns the index of the shortest column (ties prefer the leftmost).
local function shortestColumn(bottoms: { number }): number
	local best = 1

	for index = 2, #bottoms do
		if bottoms[index] < bottoms[best] - 0.5 then
			best = index
		end
	end

	return best
end

--- Re-runs the masonry layout.
function Page.Relayout(self: Page)
	if self._destroyed then
		return
	end

	local metrics = self.Theme.Metrics
	local columns = math.max(1, math.floor(self.Columns))
	local gapX = metrics.Panel.ColumnGap
	local gapY = metrics.Panel.RowGap
	local areaWidth = self:GetAreaWidth()
	local sectionWidth = math.max(60, (areaWidth - gapX * (columns - 1)) / columns)

	local bottoms: { number } = {}

	for index = 1, columns do
		bottoms[index] = 0
	end

	local maxBottom = 0

	for _, section in self.Sections do
		if not section:IsDestroyed() and section.Instance.Visible then
			local column = section:GetColumn()

			if type(column) == "string" then
				local lowered = (column :: any):lower()

				column = (lowered == "left" or lowered == "first") and 1 or columns
			end

			if type(column) ~= "number" then
				column = shortestColumn(bottoms)
			end

			column = Util.clamp(math.floor(column :: number), 1, columns)

			local x = (column - 1) * (sectionWidth + gapX)
			local y = bottoms[column]

			section:SetWidth(sectionWidth)
			section:SetPosition(x, y)

			local height = section.Height

			bottoms[column] = y + height + gapY
			maxBottom = math.max(maxBottom, bottoms[column])
		end
	end

	local canvasHeight = math.max(0, maxBottom - (maxBottom > 0 and gapY or 0))

	self.Scrolling.CanvasSize = UDim2.fromOffset(0, canvasHeight)
end

--- Batches relayout requests into a single deferred call.
function Page._requestLayout(self: Page)
	if self._layoutQueued or self._destroyed then
		return
	end

	self._layoutQueued = true

	task.defer(function()
		self._layoutQueued = false

		if not self._destroyed then
			self:Relayout()
		end
	end)
end

--// Grid config ------------------------------------------------------

function Page.SetColumns(self: Page, columns: number)
	self.Columns = math.max(1, math.floor(columns))

	self:Relayout()
end

function Page.GetColumns(self: Page): number
	return self.Columns
end

--// Sections ---------------------------------------------------------

export type GroupboxOptions = {
	Side: (string | number)?,
	Column: number?,
	Icon: string?,
	Collapsed: boolean?,
	Collapsible: boolean?,
	Description: string?,
	Order: number?,
}

--- Creates a groupbox (panel) inside this page.
function Page.Groupbox(self: Page, title: string, options: GroupboxOptions?): any
	local opts = options or {}
	local sectionOptions = {
		Column = opts.Column or opts.Side,
		Icon = opts.Icon,
		Collapsed = opts.Collapsed,
		Collapsible = opts.Collapsible,
		Description = opts.Description,
		Order = opts.Order or (#self.Sections + 1),
	}

	local section = Section.new(self, title, sectionOptions)

	section.Instance.Parent = self.Scrolling

	table.insert(self.Sections, section)

	self:Relayout()

	return section
end

--- Aliases keep the API discoverable for different naming tastes.
Page.Panel = Page.Groupbox
Page.Section = Page.Groupbox
Page.Card = Page.Groupbox

function Page._removeSection(self: Page, section: any)
	for index, stored in self.Sections do
		if stored == section then
			table.remove(self.Sections, index)
			break
		end
	end

	self:Relayout()
end

function Page.GetSections(self: Page): { any }
	return self.Sections
end

--- Every element of every section (used by the search palette).
function Page.GetElements(self: Page): { any }
	local elements: { any } = {}

	for _, section in self.Sections do
		for _, element in section:GetElements() do
			table.insert(elements, element)
		end
	end

	return elements
end

function Page.FindSection(self: Page, title: string): any
	for _, section in self.Sections do
		if section.Name == title then
			return section
		end
	end

	return nil
end

--// Visibility -------------------------------------------------------

function Page.IsVisible(self: Page): boolean
	return self._visible
end

function Page.Show(self: Page, animate: boolean?)
	self._visible = true
	self.Root.Visible = true

	local theme = self.Theme

	if animate == false or not theme.Animation.Enabled then
		self.Root.GroupTransparency = 0

		for _, section in self.Sections do
			section:Appear(0, true)
		end

		self:Relayout()

		return
	end

	self.Root.GroupTransparency = 1
	self:Relayout()

	local index = 0

	for _, section in self.Sections do
		section:Appear(index * 0.025, false)

		index += 1
	end

	Util.tween(self.Root, { GroupTransparency = 0 }, theme, {
		Duration = theme.Animation.Normal,
	})
end

function Page.Hide(self: Page, instant: boolean?)
	self._visible = false

	if instant == true or not self.Theme.Animation.Enabled then
		self.Root.Visible = false
		self.Root.GroupTransparency = 1

		return
	end

	Util.tween(self.Root, { GroupTransparency = 1 }, self.Theme, {
		Duration = self.Theme.Animation.Fast,
	})

	task.delay(self.Theme.Animation.Fast, function()
		if not self._visible then
			self.Root.Visible = false
		end
	end)
end

--- Scrolls the page so that a section becomes visible.
function Page.ScrollToSection(self: Page, section: any, animate: boolean?)
	local position = section.Instance.Position

	Util.tween(
		self.Scrolling,
		{ CanvasPosition = Vector2.new(0, math.max(0, position.Y.Offset - 12)) },
		self.Theme,
		{ Duration = animate == false and 0 or 0.35 }
	)
end

--// Destructor -------------------------------------------------------

function Page.Destroy(self: Page)
	if self._destroyed then
		return
	end

	self._destroyed = true

	for index = #self.Sections, 1, -1 do
		local section = self.Sections[index]
		self.Sections[index] = nil

		section:Destroy()
	end

	self._maid:Destroy()
	self.Root:Destroy()

	if self.Tab ~= nil then
		self.Tab:_removePage(self)
	end

	self.Tab = nil
	self.Window = nil
end

function Page.IsDestroyed(self: Page): boolean
	return self._destroyed
end

return Page
