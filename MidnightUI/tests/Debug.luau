--!nocheck
local Mock = require(script.Parent.MockRoblox)
Mock.install()
local Midnight = require(script.Parent.Parent.src.init)
local window = Midnight:CreateWindow({ Parent = Mock.services.Players.LocalPlayer:WaitForChild("PlayerGui") })
local box = window:Tab("Features"):Page("Self", { Group = "Main" }):Groupbox("Test")

-- 1. dropdown
local dd = box:Dropdown({ Title = "Method", Options = { "Local", "Server" }, Default = "Local", Flag = "dd" })
warn("dd.Multi=" .. tostring(dd.Multi) .. " value=" .. tostring(dd:GetValue()))
dd:Open()
Mock.flush()
local target = nil
for _, child in dd._popup.Inner:GetDescendants() do
	if child.ClassName == "TextButton" and child.Name == "Server" then target = child end
end
warn("found option: " .. tostring(target ~= nil) .. " handlers=" .. tostring(target ~= nil and target:__signal("MouseButton1Click"):GetHandlerCount() or -1))
if target ~= nil then
	Mock.fire(target, "MouseButton1Click")
	Mock.flush(6)
	warn("after click: value=" .. tostring(dd:GetValue()) .. " typeof=" .. typeof(dd:GetValue()) .. " dd.Multi now=" .. tostring(dd.Multi))
end

-- 2. numeric textbox
local num = box:Textbox({ Title = "Amount", Numeric = true, Min = 0, Max = 100, Default = 25 })
warn("numeric default: " .. tostring(num:GetValue()))
num.Input.Text = "250"
num.Input:ReleaseFocus()
Mock.flush()
warn("numeric after 250: " .. tostring(num:GetValue()) .. " Input.Text=" .. tostring(num.Input.Text))

-- 3. slider
local sl = box:Slider({ Title = "Time", Min = 0, Max = 1000, Default = 0 })
Mock.layout()
local area = sl._trackArea
local layout = Mock.computeLayout(area)
warn(("track: x=%s y=%s w=%s h=%s"):format(layout.AbsolutePosition.X, layout.AbsolutePosition.Y, layout.AbsoluteSize.X, layout.AbsoluteSize.Y))
local clickX = layout.AbsolutePosition.X + layout.AbsoluteSize.X * 0.25
Mock.inputBegan({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(clickX, layout.AbsolutePosition.Y + 5, 0) })
Mock.flush()
warn("slider after 25% click: " .. tostring(sl:GetValue()))

-- 4. colour picker
local cp = box:ColorPicker({ Title = "Colour", Flag = "cp" })
cp:Open()
Mock.flush()
local sv = nil
for _, child in cp._popup.Inner:GetChildren() do
	if child.Name == "SaturationValue" then sv = child end
end
warn("sv found: " .. tostring(sv ~= nil))
if sv ~= nil then
	Mock.layout()
	local l = Mock.computeLayout(sv)
	warn(("sv: x=%s y=%s w=%s h=%s"):format(l.AbsolutePosition.X, l.AbsolutePosition.Y, l.AbsoluteSize.X, l.AbsoluteSize.Y))
	Mock.inputBegan({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(l.AbsolutePosition.X + l.AbsoluteSize.X - 2, l.AbsolutePosition.Y + 2, 0) })
	Mock.flush()
	local c = cp:GetValue()
	local h, s, v = Color3.toHSV(c)
	warn(("picker after corner click: h=%s s=%s v=%s"):format(h, s, v))
	Mock.inputEnded({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(0, 0, 0) })
	cp:Close()
	Mock.flush(6)
end

-- 5. notify
local okNotify, errNotify = pcall(function()
	return window:Notify({ Title = "Hi", Text = "there", Duration = 2 })
end)
warn("notify: " .. tostring(okNotify) .. " " .. tostring(errNotify))

-- 6. theme partial
window:SetTheme({ Colors = { Accent = Color3.fromRGB(255, 100, 100) } })
warn("theme name=" .. tostring(window.Theme.Name) .. " accent=" .. tostring(window.Theme.Colors.Accent.R) .. "," .. tostring(window.Theme.Colors.Accent.G) .. "," .. tostring(window.Theme.Colors.Accent.B))

-- 7. paragraph
local para = box:Paragraph({ Text = "hello", Height = 30 })
warn("paragraph height=" .. tostring(para.Height) .. " text=" .. tostring(para.Text))

return nil
