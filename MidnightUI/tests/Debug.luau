--!nocheck
local Mock = require(script.Parent.MockRoblox)
Mock.install()

local ok, err = xpcall(function()
local Midnight = require(script.Parent.Parent.src.init)
local function phase(name, fn)
	local ok, err = xpcall(fn, function(message)
		return tostring(message) .. "\n" .. (debug and debug.traceback("", 2) or "")
	end)

	if not ok then
		warn("ПАДЕНИЕ В " .. name .. ": " .. tostring(err))
	end

	return ok
end

local window
phase("создание окна", function()
	window = Midnight:CreateWindow({ Size = { 800, 570 } })
end)

local spectators = window:Hud({ Title = "Spectators", Icon = "eye", Position = "TopLeft" })
local binds = window:Hud({ Title = "Binds", Icon = "keybind", Position = "TopRight", Rows = { "RightControl — Menu", "E — Noclip" } })
local tab = window:Tab("Main")
local mainPage = tab:Page("Main", { Group = "Misc", Icon = "sliders" })

local main = mainPage:Groupbox("Main")
main:Toggle({ Title = "Aim target hitbox", Color = Color3.fromRGB(245, 245, 248), Flag = "a1" })
main:Toggle({ Title = "Aim recoil dot", Color = Color3.fromRGB(233, 70, 70), Flag = "a2" })
main:Toggle({ Title = "Aim FOV", Flag = "a3" })
main:Toggle({ Title = "Remove smoke", Flag = "a4" })
main:Toggle({ Title = "Blind list", Flag = "a5" })
main:Toggle({ Title = "Spectator list", Flag = "a6" })

local radar = mainPage:Groupbox("Radar")
radar:Toggle({ Title = "Enable", Flag = "r1" })
radar:Label({ Text = "In-game", Indent = 28, Dim = true })
radar:Toggle({ Title = "Show bomb", Flag = "r2" })
radar:Slider({ Title = "Scale", Min = 0, Max = 2, Step = 0.01, Decimals = 2, Default = 1.7, Flag = "r3" })
radar:Slider({ Title = "Alpha", Min = 0, Max = 1, Step = 0.01, Decimals = 2, Default = 0.6, Flag = "r4" })
radar:Label({ Text = "Teammates", Bold = true })
radar:ColorPicker({ Title = "Enemy visible", Default = Color3.fromRGB(47, 128, 237), Flag = "r5" })
radar:ColorPicker({ Title = "Enemy invisible", Default = Color3.fromRGB(255, 212, 59), Flag = "r6" })
radar:ColorPicker({ Title = "Bomb carry", Default = Color3.fromRGB(255, 80, 190), Flag = "r7" })

Mock.layout()

local function rgb(color)
	return ("#%02X%02X%02X"):format(math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
end

local function rect(item)
	local l = Mock.computeLayout(item)
	return ("x=%.0f y=%.0f w=%.0f h=%.0f"):format(l.AbsolutePosition.X, l.AbsolutePosition.Y, l.AbsoluteSize.X, l.AbsoluteSize.Y)
end

warn("окно: " .. rect(window.Instance) .. "  фон=" .. rgb(window.Instance.BackgroundColor3))
warn("шапка: " .. rect(window.Header) .. "  высота=" .. tostring(window.Theme.Metrics.Window.HeaderHeight))
warn("панель вкладок видна: " .. tostring(window.TabBar.Visible))
warn("сайдбар: ширина=" .. tostring(window.SidebarWidth) .. " пунктов=" .. tostring(#window._sidebarItems))
warn("колонки: " .. tostring(window.Config.Columns))
warn("панель Main: " .. rect(main.Instance) .. " фон=" .. rgb(main.Instance.BackgroundColor3) .. " заголовок=" .. rgb(main.Title.TextColor3))
warn("панель Radar: " .. rect(radar.Instance))
warn("")

for _, element in main:GetElements() do
	warn(("  Main  %-20s %s"):format(tostring(element.Title), rect(element.Instance)))
end

for _, element in radar:GetElements() do
	local okRow, rowErr = pcall(function()
		local extra = ""

		if element.Class == "Toggle" then
			extra = " чек=" .. rgb(element.Box.BackgroundColor3) .. " кружок=" .. tostring(element.Dot ~= nil) .. " свотч=" .. (element.Swatch and rgb(element.Swatch.BackgroundColor3) or "нет")
		elseif element.Class == "Slider" then
			extra = " ползунок=" .. rgb(element.Knob.BackgroundColor3) .. " заливка=" .. rgb(element.Fill.BackgroundColor3) .. " значение=" .. (element.ValueLabel and element.ValueLabel.Text or "?")
		elseif element.Class == "ColorPicker" then
			extra = " свотч=" .. rgb(element.Swatch.BackgroundColor3)
		elseif element.Class == "Label" then
			extra = " текст=" .. tostring(element.Label.Text) .. " цвет=" .. rgb(element.Label.TextColor3)
		end

		warn(("  Radar %-18s %s%s [%s]"):format(tostring(element.Title or element.Class), rect(element.Instance), extra, tostring(element.Class)))
	end)

	if not okRow then
		warn("  Radar ОШИБКА на элементе: " .. tostring(rowErr))
	end
end

warn("")
warn("HUD " .. tostring(spectators.Title.Text) .. ": " .. rect(spectators.Root))
warn("HUD " .. tostring(binds.Title.Text) .. ": " .. rect(binds.Root) .. " строк=" .. tostring(#binds.Rows))
warn("флаги: " .. tostring(window:GetFlag("r3")) .. " / " .. tostring(window:GetFlag("r4")))


end, function(message)
	return tostring(message) .. "\n" .. (rawget(_G, "debug") and debug.traceback("", 2) or "")
end)

warn("ok=" .. tostring(ok) .. " err=" .. tostring(err))
