--!nocheck
local Mock = require(script.Parent.MockRoblox)
Mock.install()
local Midnight = require(script.Parent.Parent.src.init)

local results = {}
local function step(name, fn)
	local ok, err = xpcall(fn, function(message)
		return tostring(message) .. "\n" .. (rawget(_G, "debug") and debug.traceback("", 2) or "")
	end)

	table.insert(results, name .. ": " .. (ok and "OK" or ("ОШИБКА " .. tostring(err))))
end

local window

step("окно", function()
	window = Midnight:CreateWindow({ Size = { 800, 570 } })
end)

local binds, toggle

step("hud", function()
	window:Hud({ Title = "Spectators", Icon = "eye" })
	binds = window:Hud({ Title = "Binds", Icon = "keybind", Position = "TopRight", Rows = { "RC — Menu" } })
	binds:AddRow("E — Noclip")
	binds:RemoveRow("E — Noclip")
end)

step("страницы", function()
	local tab = window:Tab("Main")
	local page = tab:Page("Main", { Group = "Misc", Icon = "sliders" })
	local box = page:Groupbox("Main")
	toggle = box:Toggle({ Title = "Aim target hitbox", Default = true, Color = Color3.fromRGB(245, 245, 248), Flag = "aim_target" })
	box:Toggle({ Title = "Aim recoil dot", Color = Color3.fromRGB(233, 70, 70), Flag = "recoil" })
	window:SelectPage("Main")
end)

step("попап свотча", function()
	Mock.layout()
	Mock.clickObject(toggle.Swatch)
	Mock.flush(6)
	if toggle._popup == nil then
		error("попап не открылся")
	end

	local cell = nil
	for _, child in toggle._popup.Inner:GetDescendants() do
		if child.ClassName == "TextButton" then cell = child break end
	end

	if cell == nil then
		error("палитра пустая")
	end

	Mock.clickObject(cell)
	Mock.flush(4)
end)

step("смена темы", function()
	window:SetTheme("Amethyst")
	window:SetTheme("Midnight")
	if binds and binds.Root.BackgroundColor3 ~= window.Theme.Colors.Window then
		error("hud не перекрасился")
	end
end)

step("уведомления", function()
	window:Notify({ Title = "Midnight", Text = "ok", Kind = "Success" })
end)

step("скрытие/показ", function()
	window:SetVisible(false)
	window:SetVisible(true)
end)

step("уничтожение", function()
	window:Destroy()
end)

for _, line in results do
	warn(line)
end

return nil
