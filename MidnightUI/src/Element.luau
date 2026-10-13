--!strict
--[[
	MidnightUI · Element
	------------------------------------------------------------------
	Base class for every interactive element (Toggle, Slider, Dropdown,
	Textbox, Button, Keybind, ColorPicker, ...).

	It owns the boring but critical parts so that individual elements
	stay small and consistent:

		· container lifetime + :Destroy()
		· Flags (Window.Flags) + :OnChanged callbacks
		· theme colour bindings + live re-theming
		· height accounting used by the masonry layout
		· visibility / disabled state
		· hover helpers and tooltips
]]

local Maid = require(script.Parent.Maid)
local Signal = require(script.Parent.Signal)
local Util = require(script.Parent.Util)

local Element = {}
Element.__index = Element

export type Props = {
	Title: string?,
	Description: string?,
	Tooltip: string?,
	Flag: string?,
	Default: any?,
	Visible: boolean?,
	Disabled: boolean?,
	Height: number?,
	Order: number?,
	Callback: ((value: any) -> ())?,
	Class: any?,
}

export type ColorBinding = {
	Instance: any,
	Property: string,
	Key: string,
	Transparency: number?,
	TransparencyProperty: string?,
}

export type Element = typeof(setmetatable(
	{} :: {
		Class: string,
		Instance: Frame,
		Container: Frame,
		Title: string?,
		Flag: string?,
		Value: any,
		Height: number,
		Section: any,
		Theme: any,
		Window: any,
		Changed: any,
		_bindings: { ColorBinding },
		_maid: any,
		_destroyed: boolean,
		_disabled: boolean,
		_visible: boolean,
		_tooltip: string?,
		_defaultValue: any,
	},
	Element
))

--// Construction -----------------------------------------------------

function Element.new(props: Props): Element
	local class = props.Class or Element

	local self: any = setmetatable({}, class)

	self.Class = class.Name or "Element"
	self.Title = props.Title
	self.Flag = props.Flag
	self.Value = props.Default
	self._defaultValue = props.Default
	self._tooltip = props.Tooltip
	self.Description = props.Description
	self.Height = props.Height or 20
	self._bindings = {}
	self._maid = Maid.new()
	self._destroyed = false
	self._disabled = props.Disabled == true
	self._visible = props.Visible ~= false
	self.Changed = Signal.new()
	self._callback = props.Callback

	local container = Instance.new("Frame")

	container.Name = self.Class
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.Size = UDim2.new(1, 0, 0, self.Height)
	container.LayoutOrder = props.Order or 1
	container.Visible = self._visible

	self.Container = container
	self.Instance = container

	return self :: Element
end

--// Registration helpers ---------------------------------------------

function Element.SetSection(self: Element, section: any)
	self.Section = section
	self.Theme = section.Theme
	self.Window = section.Window

	if self._tooltip ~= nil then
		self:_attachTooltip()
	end

	self:OnThemeChanged()
end

--- Registers a color that follows the active theme.
function Element.Bind(self: Element, instance: any, property: string, key: string): any
	table.insert(self._bindings, {
		Instance = instance,
		Property = property,
		Key = key,
	})

	local color = self.Theme and self.Theme.Colors[key]

	if color ~= nil then
		instance[property] = color
	end

	return instance
end

--- Registers a transparency tied to the theme's color key transparency
--- (kept simple: the caller passes the value, we just remember it).
function Element.BindTransparency(
	self: Element,
	instance: any,
	property: string,
	_transparencyKey: string,
	value: number
): any
	instance[property] = value

	return instance
end

--- Applies every registered theme binding. Called on window:SetTheme().
function Element.ApplyTheme(self: Element)
	for _, binding in self._bindings do
		local color = self.Theme.Colors[binding.Key]

		if color ~= nil then
			binding.Instance[binding.Property] = color
		end
	end

	if self.OnThemeChanged then
		self:OnThemeChanged()
	end
end

--// Value handling ---------------------------------------------------

function Element.GetValue(self: Element): any
	return self.Value
end

--- Commits a new value: updates visuals, flags and callbacks.
--- `fireCallback` defaults to true; internal syncs pass false.
function Element.SetValue(self: Element, value: any, fireCallback: boolean?)
	if self._destroyed then
		return
	end


	self.Value = value

	if self.ValueChanged then
		self:ValueChanged(value)
	end

	self.Changed:Fire(value)

	if self.Window ~= nil and self.Flag ~= nil then
		self.Window:_setFlag(self.Flag, value)
	end

	if fireCallback ~= false and self._callback ~= nil then
		local ok, err = pcall(self._callback, value)

		if not ok then
			warn(("[MidnightUI] Callback for element %q errored: %s"):format(tostring(self.Title), tostring(err)))
		end
	end
end

--- Returns the value back to the one passed at construction time.
function Element.Reset(self: Element)
	self:SetValue(self._defaultValue)
end

function Element.OnChanged(self: Element, callback: (value: any) -> ()): any
	return self.Changed:Connect(callback)
end

--- Optional visual update hook implemented by concrete elements.
function Element.ValueChanged(self: Element, _value: any) end

--// State ------------------------------------------------------------

function Element.SetTitle(self: Element, title: string)
	self.Title = title

	if self.TitleChanged then
		self:TitleChanged(title)
	end
end

function Element.SetVisible(self: Element, visible: boolean)
	if self._visible == visible then
		return
	end

	self._visible = visible
	self.Instance.Visible = visible

	if self.Section ~= nil then
		self.Section:_notifyLayoutChanged()
	end
end

function Element.IsVisible(self: Element): boolean
	return self._visible
end

function Element.SetDisabled(self: Element, disabled: boolean)
	self._disabled = disabled

	if self.DisabledChanged then
		self:DisabledChanged(disabled)
	end
end

function Element.IsDisabled(self: Element): boolean
	return self._disabled
end

function Element.SetTooltip(self: Element, text: string?)
	self._tooltip = text
end

--// Interaction helpers ----------------------------------------------

--- Wires hover enter/leave with optional tween presets.
export type HoverOptions = {
	OnEnter: (() -> ())?,
	OnLeave: (() -> ())?,
}

function Element.AddHover(self: Element, target: GuiObject, options: HoverOptions?)
	target.Active = true

	self:Connect(target.MouseEnter, function()
		if self._disabled then
			return
		end

		if options and options.OnEnter then
			options.OnEnter()
		end

		if self.OnHoverEnter then
			self:OnHoverEnter()
		end
	end)

	self:Connect(target.MouseLeave, function()
		if options and options.OnLeave then
			options.OnLeave()
		end

		if self.OnHoverLeave then
			self:OnHoverLeave()
		end
	end)
end

function Element._attachTooltip(self: Element)
	if self.Window == nil or self._tooltip == nil then
		return
	end

	self:Connect(self.Container.MouseEnter, function()
		self.Window:_showTooltip(self._tooltip :: string)
	end)

	self:Connect(self.Container.MouseLeave, function()
		self.Window:_hideTooltip()
	end)
end

--- Connects an RBXScriptSignal/our Signal and ties it to the element.
function Element.Connect(self: Element, signal: any, callback: (...any) -> ()): any
	local connection = signal:Connect(callback)

	if self._maid ~= nil then
		self._maid:Add(connection)
	end

	return connection
end

--- Remembers an instance created by this element for cleanup.
function Element.Track(self: Element, instance: Instance | any): any
	self._maid:Add(instance)

	return instance
end

--// Layout -----------------------------------------------------------

function Element.GetHeight(self: Element): number
	if not self._visible then
		return 0
	end

	return self.Height
end

--- Lets elements with dynamic height (e.g. multi-line paragraphs)
--- tell the section about a change.
function Element.NotifyHeightChanged(self: Element, height: number?)
	if height ~= nil then
		self.Height = height
		self.Instance.Size = UDim2.new(1, 0, 0, height)
	end

	if self.Section ~= nil then
		self.Section:_notifyLayoutChanged()
	end
end

--// Destructor -------------------------------------------------------

function Element.Destroy(self: Element)
	if self._destroyed then
		return
	end

	self._destroyed = true
	self.Changed:DisconnectAll()
	self._maid:Destroy()

	self.Instance:Destroy()

	if self.Section ~= nil then
		self.Section:_notifyLayoutChanged()
	end

	self.Section = nil
	self.Window = nil
end

function Element.IsDestroyed(self: Element): boolean
	return self._destroyed
end

return Element
