--!strict
--[[
	MidnightUI · Dropdown
	------------------------------------------------------------------
	Closed state matches the screenshots: a label above, then a flat
	dark input box showing the current selection (no arrow unless
	`Arrow = true` is requested).

	Open state is rendered in the window's overlay through the Popup
	system, so it is never clipped by the page's ScrollingFrame and it
	stays glued to the box while the page scrolls.

	Supports single select, multi select, search and custom display.
]]

local Util = require(script.Parent.Parent.Util)

local Icon = require(script.Parent.Parent.Icon)

local Element = require(script.Parent.Parent.Element)

local Dropdown = setmetatable({}, { __index = Element })
Dropdown.__index = Dropdown
Dropdown.Name = "Dropdown"

export type Props = {
	Title: string?,
	Options: { string }?,
	Default: (string | { string })?,
	Multi: boolean?,
	Search: boolean?,
	Arrow: boolean?,
	MaxHeight: number?,
	Placeholder: string?,
	Flag: string?,
	Callback: ((value: any) -> ())?,
	Tooltip: string?,
	Visible: boolean?,
	Disabled: boolean?,
	Display: ((selection: any, options: { string }) -> string)?,
	Order: number?,
}

function Dropdown.new(section: any, props: Props?): any
	local options = props or {}
	local theme = section.Theme
	local metrics = theme.Metrics.Element
	local popupMetrics = theme.Metrics.Popup
	local multi = options.Multi == true
	local optionList: { string } = table.clone(options.Options or {})

	local defaultSelection: any

	if multi then
		defaultSelection = type(options.Default) == "table" and table.clone(options.Default) or {}
	else
		defaultSelection = options.Default
	end

	local self: any = Element.new({
		Class = Dropdown,
		Title = options.Title,
		Tooltip = options.Tooltip,
		Flag = options.Flag,
		Default = defaultSelection,
		Callback = options.Callback,
		Visible = options.Visible,
		Disabled = options.Disabled,
		Order = options.Order,
	})

	self.Options = optionList
	self.Multi = multi
	self.Search = options.Search == true
	self.Arrow = options.Arrow == true
	self.Placeholder = options.Placeholder or "Select…"
	self.MaxHeight = options.MaxHeight or popupMetrics.MaxHeight
	self.Display = options.Display
	self.Height = metrics.FieldHeight
	self.Instance.Size = UDim2.new(1, 0, 0, self.Height)

	self._open = false
	self._popup = nil
	self._query = ""
	self._searchBox = nil
	self._list = nil
	self._hovering = false

	local labelHeight = 15
	local boxHeight = metrics.FieldBoxHeight

	--// Label ---------------------------------------------------------
	local label = Instance.new("TextLabel")

	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(0, 0)
	label.Size = UDim2.new(1, 0, 0, labelHeight)
	label.Text = options.Title or ""
	label.TextColor3 = theme.Colors.Text
	label.TextSize = metrics.TitleTextSize
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Visible = options.Title ~= nil
	label.ZIndex = 2
	label.Parent = self.Instance

	Util.setFont(label, theme.Fonts.Text)

	--// Box -----------------------------------------------------------
	local box = Instance.new("Frame")

	box.Name = "Box"
	box.AnchorPoint = Vector2.new(0, 1)
	box.BackgroundColor3 = theme.Colors.Element
	box.BorderSizePixel = 0
	box.Position = UDim2.new(0, 0, 1, 0)
	box.Size = UDim2.new(1, 0, 0, boxHeight)
	box.ZIndex = 2
	box.Parent = self.Instance

	Util.addCorner(box, metrics.FieldRadius)

	local boxStroke = Util.addStroke(box, theme.Colors.ElementBorder, 1)

	local valueText = Instance.new("TextLabel")

	valueText.Name = "Value"
	valueText.BackgroundTransparency = 1
	valueText.Position = UDim2.fromOffset(metrics.FieldPadding, 0)
	valueText.Size = UDim2.new(1, -(metrics.FieldPadding * 2 + (self.Arrow and 18 or 0)), 1, 0)
	valueText.Text = ""
	valueText.TextColor3 = theme.Colors.Text
	valueText.TextSize = metrics.FieldTextSize
	valueText.TextXAlignment = Enum.TextXAlignment.Left
	valueText.TextYAlignment = Enum.TextYAlignment.Center
	valueText.TextTruncate = Enum.TextTruncate.AtEnd
	valueText.ZIndex = 3
	valueText.Parent = box

	Util.setFont(valueText, theme.Fonts.Text)

	local arrow = nil

	if self.Arrow then
		arrow = Icon.create("chevronDown", {
			Size = 13,
			Color = theme.Colors.TextMuted,
			Parent = box,
			Position = UDim2.new(1, -(metrics.FieldPadding + 13), 0.5, -6.5),
			Name = "Arrow",
			ZIndex = 3,
		})
	end

	self.Box = box
	self.ValueText = valueText
	self.Label = label

	--// Selection helpers ---------------------------------------------
	local function normalize(selection: any): any
		if multi then
			if type(selection) ~= "table" then
				return {}
			end

			local copy = {}

			for _, entry in selection do
				local text = tostring(entry)

				if table.find(optionList, text) ~= nil and table.find(copy, text) == nil then
					table.insert(copy, text)
				end
			end

			return copy
		end

		if selection == nil then
			return nil
		end

		if type(selection) ~= "string" and type(selection) ~= "number" then
			return nil
		end

		return tostring(selection)
	end

	local function isSelected(option: string): boolean
		if multi then
			return table.find(self.Value, option) ~= nil
		end

		return self.Value == option
	end

	local function formatSelection(selection: any): string
		if self.Display ~= nil then
			local ok, text = pcall(self.Display, selection, optionList)

			if ok and type(text) == "string" then
				return text
			end
		end

		if multi then
			if #selection == 0 then
				return self.Placeholder
			end

			if #selection <= 3 then
				return table.concat(selection, ", ")
			end

			return ("%s (+%d)"):format(table.concat(selection, ", ", 1, 3), #selection - 3)
		end

		if selection == nil then
			return self.Placeholder
		end

		return tostring(selection)
	end

	--// Visual refresh -------------------------------------------------
	function self.Refresh()
		local selection = self.Value
		local isEmpty = (multi and #selection == 0) or (not multi and selection == nil)
		local disabled = self:IsDisabled()

		valueText.Text = formatSelection(selection)
		valueText.TextColor3 = if disabled
			then theme.Colors.TextDisabled
			elseif isEmpty then theme.Colors.TextMuted
			else theme.Colors.Text

		box.BackgroundColor3 = if disabled
			then theme.Colors.Element
			elseif self._open then theme.Colors.ElementActive
			elseif self._hovering then theme.Colors.ElementHover
			else theme.Colors.Element

		boxStroke.Color = if self._open or self._hovering then theme.Colors.Accent else theme.Colors.ElementBorder
		boxStroke.Transparency = if disabled then 0.5 else 0

		label.TextColor3 = if disabled then theme.Colors.TextDisabled else theme.Colors.Text

		if arrow ~= nil then
			Icon.setColor(arrow, if self._open then theme.Colors.Accent else theme.Colors.TextMuted)
		end
	end

	function self.ValueChanged()
		self:Refresh()
	end

	function self.OnHoverEnter()
		self._hovering = true
		self:Refresh()
	end

	function self.OnHoverLeave()
		self._hovering = false
		self:Refresh()
	end

	function self.DisabledChanged()
		self:Refresh()
	end

	function self.OnThemeChanged()
		Util.setFont(label, theme.Fonts.Text)
		Util.setFont(valueText, theme.Fonts.Text)
		self:Refresh()
	end

	--// Content --------------------------------------------------------
	local function buildList(parent: Frame): number
		if self._list ~= nil then
			self._list:Destroy()
			self._list = nil
		end

		local itemHeight = popupMetrics.ItemHeight
		local visible: { string } = {}

		for _, option in optionList do
			if self._query == "" or option:lower():find(self._query:lower(), 1, true) then
				table.insert(visible, option)
			end
		end

		local totalHeight = #visible * itemHeight
		local listHeight = math.min(math.max(totalHeight, itemHeight), self.MaxHeight)

		local list = Instance.new("ScrollingFrame")

		list.Name = "Options"
		list.BackgroundTransparency = 1
		list.BorderSizePixel = 0
		list.CanvasSize = UDim2.fromOffset(0, totalHeight)
		list.ScrollBarImageColor3 = theme.Colors.Scrollbar
		list.ScrollBarThickness = theme.Metrics.Scrollbar.Thickness
		list.ScrollingDirection = Enum.ScrollingDirection.Y
		list.Size = UDim2.new(1, 0, 0, listHeight)
		list.ZIndex = 22
		list.Parent = parent

		Util.addList(list, {
			Padding = 0,
			Direction = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
		})

		for index, option in visible do
			local selectedNow = isSelected(option)

			local item = Instance.new("TextButton")

			item.Name = option
			item.AutoButtonColor = false
			item.BackgroundTransparency = 1
			item.BorderSizePixel = 0
			item.LayoutOrder = index
			item.Size = UDim2.new(1, 0, 0, itemHeight)
			item.Text = ""
			item.ZIndex = 23
			item.Parent = list

			Util.addCorner(item, 4)

			local itemLabel = Instance.new("TextLabel")

			itemLabel.Name = "Label"
			itemLabel.BackgroundTransparency = 1
			itemLabel.Position = UDim2.fromOffset(8, 0)
			itemLabel.Size = UDim2.new(1, -30, 1, 0)
			itemLabel.Text = option
			itemLabel.TextColor3 = if selectedNow then theme.Colors.Accent else theme.Colors.Text
			itemLabel.TextSize = popupMetrics.ItemTextSize
			itemLabel.TextXAlignment = Enum.TextXAlignment.Left
			itemLabel.TextYAlignment = Enum.TextYAlignment.Center
			itemLabel.TextTruncate = Enum.TextTruncate.AtEnd
			itemLabel.ZIndex = 24
			itemLabel.Parent = item

			Util.setFont(itemLabel, if selectedNow then theme.Fonts.Bold else theme.Fonts.Text)

			if selectedNow then
				Icon.create("check", {
					Size = 12,
					Color = theme.Colors.Accent,
					Parent = item,
					Position = UDim2.new(1, -18, 0.5, -6),
					Name = "Check",
					ZIndex = 24,
				})
			end

			item.MouseEnter:Connect(function()
				item.BackgroundColor3 = theme.Colors.PopupHover
				item.BackgroundTransparency = 0
			end)

			item.MouseLeave:Connect(function()
				item.BackgroundTransparency = 1
			end)

			item.MouseButton1Click:Connect(function()
				local chosen = option

				if multi then
					local selection = table.clone(self.Value)
					local position = table.find(selection, chosen)

					if position ~= nil then
						table.remove(selection, position)
					else
						table.insert(selection, chosen)
					end

					self:SetValue(selection)

					if self._popup ~= nil then
						self._popup:Refresh()
					end
				else
					self:SetValue(chosen)
					self:Close()
				end
			end)
		end

		if #visible == 0 then
			local empty = Instance.new("TextLabel")

			empty.Name = "Empty"
			empty.BackgroundTransparency = 1
			empty.Size = UDim2.new(1, 0, 0, itemHeight)
			empty.Text = "Nothing found"
			empty.TextColor3 = theme.Colors.TextMuted
			empty.TextSize = popupMetrics.ItemTextSize
			empty.TextXAlignment = Enum.TextXAlignment.Center
			empty.ZIndex = 24
			empty.Parent = list

			Util.setFont(empty, theme.Fonts.Small)
		end

		self._list = list

		return listHeight
	end

	local function buildContent(parent: Frame): number
		local height = 0

		if self.Search and self._searchBox == nil then
			local search = Instance.new("TextBox")

			search.Name = "Search"
			search.BackgroundColor3 = theme.Colors.Element
			search.BorderSizePixel = 0
			search.ClearTextOnFocus = false
			search.PlaceholderText = "Search…"
			search.PlaceholderColor3 = theme.Colors.TextMuted
			search.Position = UDim2.fromOffset(0, 0)
			search.Size = UDim2.new(1, 0, 0, popupMetrics.SearchHeight)
			search.Text = self._query
			search.TextColor3 = theme.Colors.Text
			search.TextSize = popupMetrics.ItemTextSize
			search.TextXAlignment = Enum.TextXAlignment.Left
			search.ZIndex = 22
			search.Parent = parent

			Util.addCorner(search, 4)
			Util.addPadding(search, 8, 8, 0, 0)
			Util.addStroke(search, theme.Colors.ElementBorder, 1)
			Util.setFont(search, theme.Fonts.Text)

			search:GetPropertyChangedSignal("Text"):Connect(function()
				if search.Text == self._query then
					return
				end

				self._query = search.Text

				if self._popup ~= nil then
					self._popup:Refresh()
				end
			end)

			self._searchBox = search

			task.defer(function()
				if search.Parent ~= nil then
					search:CaptureFocus()
				end
			end)
		elseif self._searchBox ~= nil and self._searchBox.Parent ~= parent then
			self._searchBox.Parent = parent
		end

		if self.Search and self._searchBox ~= nil then
			self._searchBox.Size = UDim2.new(1, 0, 0, popupMetrics.SearchHeight)

			height += popupMetrics.SearchHeight + 6
		end

		if self._holder ~= nil then
			self._holder:Destroy()
			self._holder = nil
		end

		local holder = Instance.new("Frame")

		holder.Name = "ListHolder"
		holder.BackgroundTransparency = 1
		holder.BorderSizePixel = 0
		holder.Position = UDim2.fromOffset(0, height)
		holder.Size = UDim2.new(1, 0, 0, 0)
		holder.ZIndex = 22
		holder.Parent = parent

		local listHeight = buildList(holder)

		holder.Size = UDim2.new(1, 0, 0, listHeight)
		self._holder = holder

		return height + listHeight
	end

	--// Open / close ----------------------------------------------------
	function self.Open()
		if self._open or self:IsDisabled() then
			return
		end

		self._open = true
		self._query = ""
		self._searchBox = nil
		self._list = nil

		self:Refresh()

		self._popup = self.Window:_createPopup({
			Name = "Dropdown",
			Anchor = box,
			Width = box.AbsoluteSize.X,
			Rebuild = false,
			Content = buildContent,
			OnClose = function()
				self._open = false
				self._popup = nil
				self._query = ""
				self._searchBox = nil
				self._list = nil
				self:Refresh()
			end,
		})
	end

	function self.Close()
		if self._popup ~= nil then
			self._popup:Close()
		end
	end

	--// Public API -------------------------------------------------------
	function self.SetOptions(newOptions: { string })
		optionList = table.clone(newOptions)
		self.Options = optionList

		self:SetValue(normalize(self.Value))
		self:Refresh()
	end

	function self.GetOptions(): { string }
		return table.clone(optionList)
	end

	function self.SetValue(value: any, fireCallback: boolean?)
		Element.SetValue(self, normalize(value), fireCallback)
	end

	--// Interaction ------------------------------------------------------
	self:Connect(box.InputBegan, function(input: InputObject)
		if self:IsDisabled() then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		if self._open then
			self:Close()
		else
			self:Open()
		end
	end)

	self:AddHover(self.Instance)
	self:Refresh()

	return self
end

return Dropdown
