--!strict
--[[
	MidnightUI · Section
	------------------------------------------------------------------
	A Section is the "groupbox" panel seen on the screenshots: a
	rounded card with a bold header, a hairline divider, an optional
	collapse chevron and a vertical stack of elements.

	Sections participate in the masonry layout of their page: they
	report their own height (computed from the elements they contain,
	never from layout read-back, which keeps everything deterministic)
	and are placed by `Page:_relayout()`.
]]

local Icon = require(script.Parent.Icon)
local Maid = require(script.Parent.Maid)
local Util = require(script.Parent.Util)

local Element = require(script.Parent.Element)
local Button = require(script.Parent.Elements.Button)
local ColorPicker = require(script.Parent.Elements.ColorPicker)
local Divider = require(script.Parent.Elements.Divider)
local Dropdown = require(script.Parent.Elements.Dropdown)
local Keybind = require(script.Parent.Elements.Keybind)
local Label = require(script.Parent.Elements.Label)
local Slider = require(script.Parent.Elements.Slider)
local Textbox = require(script.Parent.Elements.Textbox)
local Toggle = require(script.Parent.Elements.Toggle)

local Section = {}
Section.__index = Section

export type Options = {
	Side: (string | number)?,
	Column: number?,
	Width: number?,
	Icon: string?,
	Collapsed: boolean?,
	Description: string?,
	Collapsible: boolean?,
	Chevron: boolean?,
	Divider: boolean?,
	Order: number?,
}

export type Section = typeof(setmetatable(
	{} :: {
		Name: string,
		Page: any,
		Window: any,
		Theme: any,
		Instance: Frame,
		Header: Frame,
		Title: TextLabel,
		Content: CanvasGroup,
		Elements: { any },
		Options: Options,
		Collapsed: boolean,
		Height: number,
		_maid: any,
		_order: number,
		_column: number?,
		_destroyed: boolean,
		_animating: boolean,
	},
	Section
))

--// Construction -----------------------------------------------------

function Section.new(page: any, name: string, options: Options?): Section
	local self: any = setmetatable({}, Section)
	local opts: Options = options or {}
	local theme = page.Theme
	local metrics = theme.Metrics

	self.Name = name
	self.Page = page
	self.Window = page.Window
	self.Theme = theme
	self.Options = opts
	self.Elements = {}
	self.Collapsed = opts.Collapsed == true
	self.Height = metrics.Panel.HeaderHeight
	self._maid = Maid.new()
	self._order = opts.Order or 1
	self._column = opts.Column
	self._destroyed = false
	self._animating = false
	self._elementOrder = 0
	self._appearOffset = 0
	self._width = nil

	--// Panel ---------------------------------------------------------
	local panel = Instance.new("Frame")

	panel.Name = "Section"
	panel.BackgroundColor3 = theme.Colors.Panel
	panel.BackgroundTransparency = 1
	panel.BorderSizePixel = 0
	panel.Size = UDim2.new(1, 0, 0, self.Height)
	panel.LayoutOrder = self._order

	Util.addCorner(panel, metrics.Panel.Radius)
	Util.addStroke(panel, theme.Colors.PanelBorder, 1, 1)

	self.Instance = panel

	--// Header --------------------------------------------------------
	local header = Instance.new("Frame")

	header.Name = "Header"
	header.BackgroundTransparency = 1
	header.BorderSizePixel = 0
	header.Size = UDim2.new(1, 0, 0, metrics.Panel.HeaderHeight)
	header.ZIndex = 3
	header.Parent = panel

	local headerPadding = metrics.Panel.Padding
	local titleX = headerPadding

	if opts.Icon ~= nil then
		Icon.create(opts.Icon, {
			Size = 15,
			Color = theme.Colors.PanelHeader,
			Parent = header,
			Position = UDim2.fromOffset(headerPadding, (metrics.Panel.HeaderHeight - 15) / 2),
			Name = "SectionIcon",
			ZIndex = 4,
		})

		titleX = headerPadding + 15 + 8
	end

	local title = Instance.new("TextLabel")

	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(titleX, 0)
	title.Size = UDim2.new(1, -(titleX + headerPadding + 18), 1, 0)
	title.Text = name
	title.TextColor3 = theme.Colors.PanelHeader
	title.TextSize = metrics.Panel.HeaderTextSize
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextYAlignment = Enum.TextYAlignment.Center
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.ZIndex = 4
	title.Parent = header

	Util.setFont(title, theme.Fonts.Panel)

	self.Header = header
	self.Title = title

	-- Chevron is opt-in: the reference groupbox headers are plain text.
	local chevron = nil

	if opts.Chevron == true then
		chevron = Icon.create("chevronDown", {
			Size = 14,
			Color = theme.Colors.TextMuted,
			Parent = header,
			Position = UDim2.new(1, -(headerPadding + 14), 0, (metrics.Panel.HeaderHeight - 14) / 2),
			AnchorPoint = Vector2.new(0, 0),
			Name = "Chevron",
			ZIndex = 4,
		})

		chevron.Rotation = self.Collapsed and -90 or 0
	end

	--// Divider (opt-in, the reference header is plain text) -----------
	if opts.Divider == true then
		local divider = Instance.new("Frame")

		divider.Name = "Divider"
		divider.AnchorPoint = Vector2.new(0.5, 0)
		divider.BackgroundColor3 = theme.Colors.PanelDivider
		divider.BorderSizePixel = 0
		divider.Position = UDim2.new(0.5, 0, 0, metrics.Panel.HeaderHeight - 1)
		divider.Size = UDim2.new(1, -headerPadding * 2, 0, 1)
		divider.ZIndex = 3
		divider.Parent = panel
	end

	--// Content -------------------------------------------------------
	local content = Instance.new("CanvasGroup")

	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.ClipsDescendants = true
	content.Position = UDim2.fromOffset(headerPadding, metrics.Panel.HeaderHeight + metrics.Panel.TopPadding)
	content.Size = UDim2.new(1, -headerPadding * 2, 0, 0)
	content.ZIndex = 2
	content.Parent = panel

	Util.addList(content, {
		Padding = metrics.Panel.Gap,
		Direction = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top,
	})

	self.Content = content

	--// Behaviour -----------------------------------------------------
	if opts.Collapsible ~= false then
		self:Connect(header.MouseButton1Click, function()
			self:ToggleCollapse()
		end)
	end

	self:_applyVisualState(true)
	self:_updateHeight()

	return self :: Section
end

--// Internals --------------------------------------------------------

function Section.Connect(self: Section, signal: any, callback: (...any) -> ()): any
	local connection = signal:Connect(callback)

	self._maid:Add(connection)

	return connection
end

--- Reveals the panel by sliding it up; the page fades the whole
--- content in one go, sections only need to stagger their offset.
function Section.Appear(self: Section, delay: number?, instant: boolean?)
	local theme = self.Theme

	if instant == true then
		self._appearOffset = 0
		self:_updatePosition()

		return
	end

	self._appearOffset = 16

	self:_updatePosition()

	Util.tween(self.Instance, { Position = UDim2.fromOffset(self._layoutX or 0, self._layoutY or 0) }, theme, {
		Duration = theme.Animation.Slow,
		DelayTime = delay or 0,
	})
end

--- Applies the panel size, preserving an explicitly assigned column width.
function Section._applySize(self: Section)
	if self._width ~= nil then
		self.Instance.Size = UDim2.new(0, self._width, 0, self.Height)
	else
		self.Instance.Size = UDim2.new(1, 0, 0, self.Height)
	end
end

--- Keeps the content frame's height in sync with the elements it holds.
--- The content clips its children, so a stale height would hide them.
function Section._syncContentSize(self: Section, targetHeight: number?)
	local content = self.Content
	local height = targetHeight or self:_getContentHeight()

	if self.Collapsed then
		height = 0
	end

	content.Size = UDim2.new(content.Size.X.Scale, content.Size.X.Offset, 0, height)
end

--- Snaps the collapsed/expanded state without animating.
function Section._applyVisualState(self: Section)
	local content = self.Content
	local targetHeight = self:_getContentHeight()
	local panelHeight = self:_getPanelHeight(targetHeight)

	self:_syncContentSize(targetHeight)

	content.GroupTransparency = self.Collapsed and 1 or 0
	content.Visible = not self.Collapsed

	self.Height = panelHeight
	self:_applySize()
end

--- Content height = sum of element heights + gaps.
function Section._getContentHeight(self: Section): number
	local visibleCount = 0
	local total = 0

	for _, element in self.Elements do
		if not element:IsDestroyed() and element:IsVisible() then
			visibleCount += 1
			total += element:GetHeight()
		end
	end

	if visibleCount > 1 then
		total += self.Theme.Metrics.Panel.Gap * (visibleCount - 1)
	end

	return math.max(0, total)
end

function Section._getPanelHeight(self: Section, contentHeight: number?): number
	local metrics = self.Theme.Metrics

	if self.Collapsed then
		return metrics.Panel.HeaderHeight + 4
	end

	local height = contentHeight or self:_getContentHeight()

	return metrics.Panel.HeaderHeight + metrics.Panel.TopPadding + height + metrics.Panel.BottomPadding
end

--- Recomputes the height and asks the window to re-run the layout.
function Section._updateHeight(self: Section)
	local contentHeight = self:_getContentHeight()
	local panelHeight = self:_getPanelHeight(contentHeight)

	self.Height = panelHeight
	self:_applySize()

	if not self._animating then
		self:_syncContentSize(contentHeight)
	end
end

function Section._notifyLayoutChanged(self: Section)
	self:_updateHeight()

	if self.Page ~= nil then
		self.Page:_requestLayout()
	end
end

--- Positions the panel (called by the page's masonry layout).
function Section.SetPosition(self: Section, x: number, y: number)
	self._layoutX = x
	self._layoutY = y

	self.Instance.Position = UDim2.fromOffset(x, y + (self._appearOffset or 0))
end

function Section._updatePosition(self: Section)
	if self._layoutX == nil then
		return
	end

	self.Instance.Position = UDim2.fromOffset(self._layoutX, self._layoutY + (self._appearOffset or 0))
end

function Section.SetWidth(self: Section, width: number)
	self._width = width

	self:_updateHeight()
end

function Section.GetColumn(self: Section): number?
	return self._column
end

function Section.SetColumn(self: Section, column: number?)
	self._column = column

	if self.Page ~= nil then
		self.Page:_requestLayout()
	end
end

--// Public API -------------------------------------------------------

function Section.SetTitle(self: Section, title: string)
	self.Name = title
	self.Title.Text = title
end

function Section.SetCollapsed(self: Section, collapsed: boolean)
	if self.Collapsed == collapsed or self._destroyed then
		return
	end

	local theme = self.Theme
	local content = self.Content
	local targetHeight = self:_getContentHeight()
	local chevron = self.Header:FindFirstChild("Chevron")

	self.Collapsed = collapsed
	self._animating = true

	if not collapsed then
		content.Visible = true
	end

	local heightTween = Util.tween(
		content,
		{ Size = UDim2.new(content.Size.X.Scale, content.Size.X.Offset, 0, collapsed and 0 or targetHeight) },
		theme,
		{ Duration = theme.Animation.Normal }
	)

	Util.tween(content, { GroupTransparency = collapsed and 1 or 0 }, theme, {
		Duration = theme.Animation.Normal,
	})

	if chevron ~= nil then
		Util.tween(chevron, { Rotation = collapsed and -90 or 0 }, theme, {
			Duration = theme.Animation.Normal,
		})
	end

	local panelHeight = self:_getPanelHeight(targetHeight)

	self.Height = panelHeight

	local panelSize = if self._width ~= nil
		then UDim2.new(0, self._width, 0, panelHeight)
		else UDim2.new(1, 0, 0, panelHeight)

	Util.tween(self.Instance, { Size = panelSize }, theme, {
		Duration = theme.Animation.Normal,
	})

	heightTween.Completed:Once(function()
		self._animating = false

		if collapsed then
			content.Visible = false
		else
			self:_syncContentSize(self:_getContentHeight())
		end

		if self.Page ~= nil then
			self.Page:_requestLayout()
		end
	end)

	if self.Page ~= nil then
		self.Page:_requestLayout()
	end
end

function Section.ToggleCollapse(self: Section)
	self:SetCollapsed(not self.Collapsed)
end

function Section.SetVisible(self: Section, visible: boolean)
	self.Instance.Visible = visible

	if self.Page ~= nil then
		self.Page:_requestLayout()
	end
end

--// Element helpers --------------------------------------------------

--- Shared element finalisation: parenting, registration, animation.
function Section._addElement(self: Section, element: any): any
	self._elementOrder += 1
	element.Container.LayoutOrder = self._elementOrder
	element.Container.Parent = self.Content

	table.insert(self.Elements, element)
	element:SetSection(self)

	if self.Window ~= nil then
		self.Window:_registerElement(element)
	end

	self:_notifyLayoutChanged()

	return element
end

function Section.Toggle(self: Section, props: any): any
	return self:_addElement(Toggle.new(self, props))
end

function Section.Slider(self: Section, props: any): any
	return self:_addElement(Slider.new(self, props))
end

function Section.Dropdown(self: Section, props: any): any
	return self:_addElement(Dropdown.new(self, props))
end

function Section.Textbox(self: Section, props: any): any
	return self:_addElement(Textbox.new(self, props))
end

function Section.Button(self: Section, props: any): any
	return self:_addElement(Button.new(self, props))
end

function Section.Keybind(self: Section, props: any): any
	return self:_addElement(Keybind.new(self, props))
end

function Section.ColorPicker(self: Section, props: any): any
	return self:_addElement(ColorPicker.new(self, props))
end

function Section.Label(self: Section, props: any): any
	return self:_addElement(Label.new(self, props))
end

function Section.Paragraph(self: Section, props: any): any
	return self:_addElement(Label.new(self, {
		Text = props and props.Text or props,
		Wrapped = true,
		Title = props and props.Title or nil,
		Flag = props and props.Flag or nil,
		Callback = props and props.Callback or nil,
	}))
end

function Section.Divider(self: Section, props: any?): any
	return self:_addElement(Divider.new(self, props or {}))
end

--- Adds empty vertical space of `size` pixels (layout sugar).
function Section.Gap(self: Section, size: number?): any
	return self:_addElement(Divider.new(self, { Height = size or 6, Invisible = true }))
end

--- Removes an element.
function Section.RemoveElement(self: Section, element: any)
	for index, stored in self.Elements do
		if stored == element then
			table.remove(self.Elements, index)
			break
		end
	end

	element:Destroy()

	self:_notifyLayoutChanged()
end

function Section.GetElements(self: Section): { any }
	return self.Elements
end

--// Destructor -------------------------------------------------------

function Section.Destroy(self: Section)
	if self._destroyed then
		return
	end

	self._destroyed = true

	for index = #self.Elements, 1, -1 do
		local element = self.Elements[index]
		self.Elements[index] = nil
		element:Destroy()
	end

	self._maid:Destroy()
	self.Instance:Destroy()

	if self.Page ~= nil then
		self.Page:_removeSection(self)
	end

	self.Page = nil
	self.Window = nil
end

function Section.IsDestroyed(self: Section): boolean
	return self._destroyed
end

return Section
