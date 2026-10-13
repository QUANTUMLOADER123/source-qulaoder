--!nocheck
--[[
	Selftest — instantiates the whole library inside MockRoblox and
	exercises every element, popup, animation and lifecycle path.

	Returns a report table; `tools/run_tests.mjs` prints it and turns
	failures into a non-zero exit code.
]]

local Mock = require(script.Parent.MockRoblox)

Mock.install()

local Midnight = require(script.Parent.Parent.src.init)

local Enum = _G.Enum
local Vector2 = _G.Vector2
local Vector3 = _G.Vector3
local Color3 = _G.Color3

local report = {
	Passed = 0,
	Failed = 0,
	Failures = {},
	Notes = {},
}

local function check(name: string, condition: any, details: any?)
	if condition then
		report.Passed += 1
	else
		report.Failed += 1
		table.insert(report.Failures, ("%s%s"):format(name, details ~= nil and (": " .. tostring(details)) or ""))
	end

	return condition
end

local function step(name: string, callback: () -> ())
	local before = #Mock.Output
	local ok, err = xpcall(callback, function(message)
		local text = typeof(message) == "string" and message or tostring(message)

		if rawget(_G, "debug") ~= nil and debug.traceback ~= nil then
			local okTrace, trace = pcall(debug.traceback, "", 2)

			if okTrace and type(trace) == "string" then
				text = text .. "\n@@TRACE@@" .. trace
			end
		end

		return (text:gsub("\n", " ⏎ "))
	end)

	if not ok then
		local tail = {}

		for index = math.max(1, before), #Mock.Output do
			table.insert(tail, Mock.Output[index])
		end

		check(name, false, ("%s | last output: %s"):format(tostring(err), table.concat(tail, " | ")))
	end
end

local function note(text: string)
	table.insert(report.Notes, text)
end

--// 1. Window construction -------------------------------------------------

local window

step("window construction", function()
	window = Midnight:CreateWindow({
		Title = "Midnight",
		Keybind = "RightControl",
		Size = { 1120, 700 },
		Theme = "Midnight",
		Columns = 2,
	})

	check("window object created", window ~= nil)
	check("ScreenGui created", window.Gui ~= nil and window.Gui.Name == "MidnightUI")
	check("root frame fills the screen", window.Root ~= nil)
	check("default tab selected automatically", window.ActiveTab ~= nil)
	check("window registered in Midnight._windows", #Midnight:GetWindows() == 1)
	check("default keybind resolved", window:GetKeybind() == Enum.KeyCode.RightControl)
	check("section area width is deterministic", window:GetSectionAreaWidth() > 400)
end)

--// 2. Screenshot-like menu ---------------------------------------------------

local features, mainPage, combatPage, boxes

step("menu structure", function()
	features = window:Tab("Features")
	window:Tab("Appearance")

	mainPage = features:Page("Self", { Group = "Main", Icon = "user" })
	combatPage = features:Page("Weapons", { Group = "Combat", Icon = "crosshair" })

	check("tabs registered", #window.Tabs == 3)
	check("pages registered", #features.Pages == 2)
	check("sidebar built", #window._sidebarItems == 2, "sidebar items: " .. tostring(#window._sidebarItems))

	boxes = {}

	boxes.radar = mainPage:Groupbox("Off The Radar")
	boxes.armour = mainPage:Groupbox("Auto Armour Refill")
	boxes.invisibility = mainPage:Groupbox("Invisibility")
	boxes.health = mainPage:Groupbox("Auto Health Refill")

	check("groupboxes created", #mainPage:GetSections() == 4)
	check("masonry positions the first box at the origin", boxes.radar.Instance.Position.X.Offset == 0)
	check(
		"masonry fills the second column next",
		boxes.armour.Instance.Position.X.Offset > boxes.radar.Instance.Position.X.Offset
	)
	check("panels share the same top", boxes.radar.Instance.Position.Y.Offset == 0)

	local widthA = boxes.radar.Instance.Size.X.Offset
	local widthB = boxes.armour.Instance.Size.X.Offset

	check("columns have equal widths", math.abs(widthA - widthB) < 0.01, ("%s vs %s"):format(widthA, widthB))
end)

--// 3. Every element type -------------------------------------------------------

local toggle, slider, dropdown, textbox, button, keybind, picker, label, divider

step("element construction", function()
	toggle = boxes.radar:Toggle({ Title = "Enable", Flag = "radar_enabled", Default = false })
	slider = boxes.radar:Slider({
		Title = "Time",
		Min = 0,
		Max = 1000,
		Default = 500,
		Flag = "radar_time",
	})
	dropdown = boxes.radar:Dropdown({
		Title = "Method",
		Options = { "Local", "Server", "Hybrid" },
		Default = "Local",
		Flag = "radar_method",
	})
	textbox = boxes.radar:Textbox({ Title = "Name", Default = "", Placeholder = "Type…", Flag = "radar_name" })
	button = boxes.radar:Button({ Title = "Set", Flag = "radar_set" })
	keybind = boxes.radar:Keybind({ Title = "Type", Default = "E", Flag = "radar_key" })
	picker = boxes.radar:ColorPicker({ Title = "Colour", Default = Color3.fromRGB(147, 168, 195), Flag = "radar_color" })
	label = boxes.radar:Label({ Text = "Helper text" })
	divider = boxes.radar:Divider({})

	check("toggle value is boolean", toggle:GetValue() == false)
	check("slider default respected", slider:GetValue() == 500)
	check("dropdown default respected", dropdown:GetValue() == "Local")
	check("keybind default resolved", keybind:GetValue() == "E")
	check("picker default is Color3", typeof(picker:GetValue()) == "Color3")
	check("labels expose text", label:GetText() == "Helper text")

	check("flags registered", window:GetFlag("radar_enabled") == false)
	check("slider flag registered", window:GetFlag("radar_time") == 500)
	check("dropdown flag registered", window:GetFlag("radar_method") == "Local")
	check("colour flag registered", window:GetFlag("radar_color") ~= nil)

	local height = boxes.radar.Height

	check("panel height accounts for its elements", height > 9 * 20, "height: " .. tostring(height))
end)

--// 4. Numeric textbox, multi dropdown, paragraph --------------------------------

step("extra element variants", function()
	boxes.health:Toggle({ Title = "Enable", Flag = "health_enabled" })
	local numeric = boxes.health:Textbox({
		Title = "Amount",
		Numeric = true,
		Min = 0,
		Max = 100,
		Default = 25,
		Flag = "health_amount",
	})
	check("numeric textbox stores a number", numeric:GetValue() == 25)

	numeric.Input.Text = "250"

	local focused = numeric.Input

	focused:ReleaseFocus()
	check("numeric textbox clamps to Max", numeric:GetValue() == 100, tostring(numeric:GetValue()))

	local multi = boxes.health:Dropdown({
		Title = "Extras",
		Options = { "A", "B", "C" },
		Multi = true,
		Default = { "A" },
		Flag = "health_extras",
	})
	check("multi dropdown default", type(multi:GetValue()) == "table" and #multi:GetValue() == 1)

	local paragraph = boxes.health:Paragraph({ Text = "A longer hint that wraps.", Height = 30 })
	check("paragraph created", paragraph ~= nil and paragraph.Height == 30)

	boxes.health:Gap(4)
	check("gap element created", #boxes.health:GetElements() == 5)
end)

--// 5. Interaction: toggle --------------------------------------------------------

step("toggle interaction", function()
	local fired = {}

	toggle:OnChanged(function(value)
		table.insert(fired, value)
	end)

	Mock.clickObject(toggle.Instance)
	Mock.flush()

	check("toggle switched on", toggle:GetValue() == true)
	check("toggle callback fired", #fired == 1 and fired[1] == true)
	check("flag updated", window:GetFlag("radar_enabled") == true)
	check("check glyph scale animated to 1", toggle._checkScale.Scale == 1)

	local flagEvents = {}

	local connection = window.FlagChanged:Connect(function(flag, value)
		table.insert(flagEvents, flag .. "=" .. tostring(value))
	end)

	window:SetFlag("radar_enabled", false)

	check("SetFlag updates the element", toggle:GetValue() == false)
	check("FlagChanged signal fired", #flagEvents == 1 and flagEvents[1] == "radar_enabled=false", tostring(#flagEvents))

	connection:Disconnect()
end)

--// 6. Interaction: slider -----------------------------------------------------------

step("slider interaction", function()
	Mock.layout()

	local trackArea = slider._trackArea
	local layout = Mock.computeLayout(trackArea)
	local startX = layout.AbsolutePosition.X
	local width = layout.AbsoluteSize.X

	check("slider track has a width", width > 50, tostring(width))

	Mock.inputBegan({
		UserInputType = Enum.UserInputType.MouseButton1,
		Position = Vector3.new(startX + width * 0.25, layout.AbsolutePosition.Y + 5, 0),
	})
	Mock.flush()

	check("clicking the track jumps to the value", math.abs(slider:GetValue() - 250) <= 12, tostring(slider:GetValue()))

	Mock.inputChanged({
		UserInputType = Enum.UserInputType.MouseMovement,
		Position = Vector3.new(startX + width * 0.5, layout.AbsolutePosition.Y + 5, 0),
		Delta = Vector3.new(width * 0.25, 0, 0),
	})
	Mock.flush()

	check("dragging moves the value", slider:GetValue() > 450, tostring(slider:GetValue()))

	Mock.inputEnded({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(0, 0, 0) })
	Mock.flush()

	check("drag released", slider._dragging == false)

	slider:SetValue(1000)
	check("value can be set programmatically", slider:GetValue() == 1000)
	check("fill follows the value", math.abs(slider.Fill.Size.X.Scale - 1) < 0.001)

	slider:SetValue(0)
	check("snapping/clamping works", slider:GetValue() == 0)
end)

--// 7. Interaction: dropdown ----------------------------------------------------------

step("dropdown interaction", function()
	Mock.layout()

	local opened = dropdown:Open()

	check("popup created", dropdown._popup ~= nil)
	check("popup lives in the overlay", dropdown._popup.Root.Parent == window.Overlay)
	check("popup is open", dropdown._popup:IsOpen())

	Mock.flush()

	local optionButtons = {}

	for _, child in dropdown._popup.Inner:GetDescendants() do
		if child.ClassName == "TextButton" and child.Name == "Server" then
			table.insert(optionButtons, child)
		end
	end

	check("options rendered", #optionButtons == 1, "found " .. tostring(#optionButtons))

	if #optionButtons == 1 then
		Mock.clickObject(optionButtons[1])
		Mock.flush(8)
	end

	check("selection updated", dropdown:GetValue() == "Server", tostring(dropdown:GetValue()))
	check("flag updated", window:GetFlag("radar_method") == "Server")
	check("single select closes the popup", dropdown._popup == nil)

	dropdown:SetOptions({ "Alpha", "Beta" })
	check("SetOptions replaces the list", #dropdown:GetOptions() == 2)
	check("value cleared when it is gone", dropdown:GetValue() == nil, tostring(dropdown:GetValue()))
end)

--// 8. Interaction: textbox / button ----------------------------------------------------

step("textbox and button", function()
	local committed = nil

	textbox:OnChanged(function(value)
		committed = value
	end)

	textbox.Input.Text = "hello"
	textbox.Input:ReleaseFocus()
	Mock.flush()

	check("textbox stored the value", textbox:GetValue() == "hello", tostring(textbox:GetValue()))
	check("textbox callback fired", committed == "hello")
	check("textbox flag updated", window:GetFlag("radar_name") == "hello")

	local clicks = 0

	button:OnChanged(function()
		clicks += 1
	end)

	Mock.clickObject(button.Instance)
	Mock.flush()

	check("button callback fired", clicks == 1)

	button:SetDisabled(true)
	Mock.clickObject(button.Instance)
	Mock.flush()

	check("disabled button ignores clicks", clicks == 1)

	button:SetDisabled(false)
end)

--// 9. Interaction: keybind ---------------------------------------------------------------

step("keybind capture", function()
	check("badge shows the key", keybind.BadgeText.Text == "E", keybind.BadgeText.Text)

	keybind:StartCapture()

	check("capture mode enabled", keybind:IsCapturing())

	Mock.inputBegan({ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.F })
	Mock.flush()

	check("capture finished", keybind:IsCapturing() == false)
	check("key stored", keybind:GetValue() == "F", tostring(keybind:GetValue()))
	check("flag updated", window:GetFlag("radar_key") == "F")
	check("badge re-rendered", keybind.BadgeText.Text == "F", keybind.BadgeText.Text)

	local pressed = nil

	keybind = keybind

	keybind:OnChanged(function() end)

	local holdKeybind = boxes.radar:Keybind({
		Title = "Hold",
		Default = "G",
		Mode = "Hold",
		OnPress = function(state)
			pressed = state
		end,
	})

	Mock.inputBegan({ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.G })
	Mock.flush()

	check("hold keybind pressed", pressed == true and holdKeybind:IsPressed() == true)

	Mock.inputEnded({ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.G })
	Mock.flush()

	check("hold keybind released", pressed == false and holdKeybind:IsPressed() == false)
end)

--// 10. Colour picker -------------------------------------------------------------------------

step("colour picker", function()
	picker:Open()
	Mock.flush()

	check("picker popup created", picker._popup ~= nil)

	local area = nil

	for _, child in picker._popup.Inner:GetChildren() do
		if child.Name == "SaturationValue" then
			area = child
		end
	end

	check("saturation/value square exists", area ~= nil)

	if area ~= nil then
		Mock.layout()

		local layout = Mock.computeLayout(area)

		Mock.inputBegan({
			UserInputType = Enum.UserInputType.MouseButton1,
			Position = Vector3.new(layout.AbsolutePosition.X + layout.AbsoluteSize.X - 2, layout.AbsolutePosition.Y + 2, 0),
		})
		Mock.flush()

		local color = picker:GetValue()
		local hue, saturation, value = Color3.toHSV(color)

		check("saturation increased", saturation > 0.9, tostring(saturation))
		check("value stays high", value > 0.9, tostring(value))
		check("flag updated with a colour", typeof(window:GetFlag("radar_color")) == "Color3")

		Mock.inputEnded({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(0, 0, 0) })
	end

	picker:Close()
	Mock.flush(8)

	check("picker popup closed", picker._popup == nil or picker._popup:IsOpen() == false)
end)

--// 11. Search palette & settings ------------------------------------------------------------

step("search palette", function()
	window:_openSearch()
	Mock.flush()

	check("search popup opened", window._popup ~= nil)

	local searchBox = nil

	for _, child in window._popup.Inner:GetDescendants() do
		if child.ClassName == "TextBox" then
			searchBox = child
			break
		end
	end

	check("search box exists", searchBox ~= nil)

	if searchBox ~= nil then
		searchBox.Text = "Time"
		Mock.flush()

		local rows = 0

		for _, child in window._popup.Inner:GetDescendants() do
			if child.ClassName == "TextButton" then
				rows += 1
			end
		end

		check("results filtered", rows >= 1, "rows: " .. tostring(rows))

		local firstRow = nil

		for _, child in window._popup.Inner:GetDescendants() do
			if child.ClassName == "TextButton" then
				firstRow = child
				break
			end
		end

		if firstRow ~= nil then
			Mock.clickObject(firstRow)
			Mock.flush(8)

			check("search navigation selected a page", window.ActivePage ~= nil)
		end
	end
end)

step("settings panel", function()
	window:_openSettings()
	Mock.flush()

	check("settings popup opened", window._popup ~= nil)

	local sliderCount = 0

	for _, child in window._popup.Inner:GetDescendants() do
		if child.Name == "TrackArea" then
			sliderCount += 1
		end
	end

	check("settings rendered element rows", sliderCount >= 1, tostring(sliderCount))

	window:SetScale(1.15)
	Mock.flush()

	check("scale applied", math.abs(window:GetScale() - 1.15) < 0.001, tostring(window:GetScale()))

	window:SetScale(1)

	window:_closePopup()
	Mock.flush(8)
end)

--// 12. Notifications ------------------------------------------------------------------------------

step("notifications", function()
	local notification = window:Notify({ Title = "Loaded", Text = "MidnightUI ready", Duration = 2 })

	check("notification created", notification ~= nil)
	check("notification parented to the root", notification.Root.Parent == window.Root)
	check("notification registered", #window.Notifications == 1)

	Mock.flush()

	check("notification faded in", notification.Root.BackgroundTransparency == 0)

	for index = 1, 6 do
		window:Notify({ Text = "Toast " .. tostring(index), Duration = 0.1 })
	end

	check(
		"visible notifications capped",
		#window.Notifications <= window.Theme.Metrics.Notification.MaxVisible,
		tostring(#window.Notifications)
	)

	Mock.Clock += 5
	Mock.flush(10)

	check("notifications dismissed over time", #window.Notifications == 0, tostring(#window.Notifications))
end)

--// 13. Theme switching, scaling, flags ---------------------------------------------------------------

step("theming", function()
	local accentBefore = toggle.Box.BackgroundColor3

	window:SetTheme("Daybreak")
	Mock.flush()

	check("theme name switched", window.Theme.Name == "Daybreak")
	check("window recoloured", window.Instance.BackgroundColor3 == window.Theme.Colors.Window)
	check("toggle repainted", toggle.Box.BackgroundColor3 ~= accentBefore)

	window:SetTheme({ Colors = { Accent = Color3.fromRGB(255, 100, 100) } })

	check("partial theme merged", window.Theme.Name == "Midnight")
	check("accent overridden", window.Theme.Colors.Accent == Color3.fromRGB(255, 100, 100))
	check("other colours kept", window.Theme.Colors.Window ~= nil)

	local custom = Midnight:CreateTheme(Color3.fromRGB(10, 200, 120), "Custom")

	check("CreateTheme produced a full theme", custom.Colors.Window ~= nil and custom.Name == "Custom")
	check("theme list populated", #Midnight:GetThemes() >= 5)

	window:SetTheme("Midnight")

	local saved = window:SaveConfig()

	check("SaveConfig returned flags", saved.radar_time ~= nil)

	window:SetFlag("radar_time", 0)
	check("flag changed before load", window:GetFlag("radar_time") == 0)

	window:LoadConfig(saved)
	check("LoadConfig restored the value", slider:GetValue() == saved.radar_time, tostring(slider:GetValue()))
end)

--// 14. Tabs, pages, visibility and keybind toggle ------------------------------------------------------

step("navigation and visibility", function()
	window:SelectTab("Features")
	Mock.flush()

	check("SelectTab by name", window.ActiveTab == features)

	local appearance = window:SelectTab(2)

	check("SelectTab by index", appearance ~= nil and window.ActiveTab == appearance)
	check("sidebar rebuilt for the new tab", #window._sidebarItems == 1, tostring(#window._sidebarItems))

	window:SelectTab(features)
	window:SelectPage("Weapons")
	Mock.flush()

	check("SelectPage works", window.ActivePage == combatPage)

	Mock.layout()

	check("visible page uses scale alpha 1", combatPage.Root.GroupTransparency == 0)
	check("hidden page is hidden", mainPage.Root.Visible == false)

	window:SetVisible(false)
	Mock.flush(8)

	check("window hidden", window.Visible == false)

	Mock.inputBegan({ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.RightControl })
	Mock.flush(8)

	check("keybind shows the window again", window.Visible == true)
	check("window visible on screen", window.Instance.Visible == true)
end)

--// 15. Collapse, add/remove, errors ---------------------------------------------------------------

step("sections and errors", function()
	local before = boxes.radar.Height

	boxes.radar:SetCollapsed(true)
	Mock.flush()

	check("collapsed panel shrinks", boxes.radar.Height < before, tostring(boxes.radar.Height))
	check("collapsed state stored", boxes.radar.Collapsed == true)

	boxes.radar:SetCollapsed(false)
	Mock.flush()

	check("expanded panel restored", math.abs(boxes.radar.Height - before) < 0.01)

	local extra = boxes.radar:Toggle({ Title = "Extra", Flag = "extra_flag" })
	local withExtra = boxes.radar.Height

	check("adding an element grows the panel", withExtra > before, ("%s -> %s"):format(before, withExtra))

	boxes.radar:RemoveElement(extra)
	Mock.flush()

	check("removing restores the height", math.abs(boxes.radar.Height - before) < 0.01)

	extra:SetValue(true)
	check("destroyed element ignores writes", extra:IsDestroyed() == true)
end)

--// 16. Rendering smoke test (every frame path that touches layout) ------------------------------------

step("render pass", function()
	Mock.layout()

	check("window has a size", Mock.computeLayout(window.Instance).AbsoluteSize.X > 1000)
	check("window is centred", Mock.computeLayout(window.Instance).AbsolutePosition.X > 0)
	check("overlay covers the window", Mock.computeLayout(window.Overlay).AbsoluteSize.X > 1000)

	window:Toggle(true)
	Mock.flush(10)

	check("no warnings emitted", #Mock.Warnings == 0, table.concat(Mock.Warnings, " | "))

	note(("output lines: %d"):format(#Mock.Output))
end)

--// 17. Teardown -----------------------------------------------------------------------------------

step("destroy", function()
	local gui = window.Gui

	window:Destroy()
	Mock.flush(4)

	check("window marked destroyed", window:IsDestroyed() == true)
	check("gui removed", gui.Parent == nil)
	check("no windows left", #Midnight:GetWindows() == 0)

	window:Destroy()
	check("double destroy is safe", true)
end)

--// Summary (parsed by tools/run_tests.mjs) ---------------------------------------

print("TEST:PASS " .. tostring(report.Passed))
print("TEST:FAIL " .. tostring(report.Failed))

for _, failure in report.Failures do
	print("TEST:FAILURE " .. failure)
end

for _, item in report.Notes do
	print("TEST:NOTE " .. item)
end

return report
