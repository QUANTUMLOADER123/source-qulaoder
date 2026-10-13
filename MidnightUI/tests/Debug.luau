--!nocheck
local Mock = require(script.Parent.MockRoblox)
Mock.install()
local Midnight = require(script.Parent.Parent.src.init)
local window = Midnight:CreateWindow({})

warn("версия: " .. tostring(Midnight.Version))
warn("гуи лежит в: " .. tostring(window.Gui.Parent and window.Gui.Parent.Name) .. " (класс " .. tostring(window.Gui.Parent and window.Gui.Parent.ClassName) .. ")")
warn("CoreGui найден: " .. tostring(Mock.services.CoreGui ~= nil) .. ", родитель == CoreGui: " .. tostring(window.Gui.Parent == Mock.services.CoreGui))
warn("IgnoreGuiInset=" .. tostring(window.Gui.IgnoreGuiInset) .. " ResetOnSpawn=" .. tostring(window.Gui.ResetOnSpawn))

local page = window:Tab("GLOBALS"):Page("Aimbot", { Group = "Combat", Icon = "crosshair" })
local box = page:Groupbox("Aimbot")
local dd = box:Dropdown({ Title = "Hitboxes", Options = { "Head", "Chest" }, Default = "Head" })
local toggled = box:Toggle({ Title = "Enable" })
local circle = box:Toggle({ Title = "Only zoom", Circle = true })
local slider = box:Slider({ Title = "Hitchance", Min = 0, Max = 100, Default = 73 })

Mock.layout()

warn(("тема: акцент R=%d G=%d B=%d"):format(window.Theme.Colors.Accent.R * 255, window.Theme.Colors.Accent.G * 255, window.Theme.Colors.Accent.B * 255))
warn(("дропдаун бокс: R=%d G=%d B=%d"):format(dd.Box.BackgroundColor3.R * 255, dd.Box.BackgroundColor3.G * 255, dd.Box.BackgroundColor3.B * 255))
warn(("заголовок панели: R=%d"):format(box.Title.TextColor3.R * 255))
warn(("кружок: dim=%s"):format(tostring(circle.Dot ~= nil)))
warn(("слайдер: knob R=%d G=%d B=%d, fill R=%d"):format(slider.Knob.BackgroundColor3.R * 255, slider.Knob.BackgroundColor3.G * 255, slider.Knob.BackgroundColor3.B * 255, slider.Fill.BackgroundColor3.R * 255))
warn(("контент панели: h=%.0f, нужно=%.0f"):format(box.Content.Size.Y.Offset, box:_getContentHeight()))
warn(("панель: h=%.0f"):format(box.Instance.Size.Y.Offset))
return nil
