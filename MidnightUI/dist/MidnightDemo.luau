--[[
	═══════════════════════════════════════════════════════════════════════════
	  M I D N I G H T   U I   —   демо-меню (по референсу)
	═══════════════════════════════════════════════════════════════════════════

	Запуск в executor:
		loadstring(game:HttpGet("...MidnightDemo.luau"))()

	Открыть/закрыть меню — RightControl.

	Разметка повторяет референс: логотип MIDNIGHT + поиск/шестерёнка в шапке,
	слева сайдбар с группами Combat / Visuals / Misc, справа колонки-панели.
	Сверху — плавающие HUD-панели SPECTATORS и BINDS.
]]

local BASE = "https://raw.githubusercontent.com/QUANTUMLOADER123/source-qulaoder/arena/7cd2f990-source-qulaoder/MidnightUI/dist/"

--// 1. Библиотека -------------------------------------------------------------

local ok, Midnight = pcall(function()
	return loadstring(game:HttpGet(BASE .. "Midnight.luau"))()
end)

if not ok or Midnight == nil then
	warn("[Midnight] ошибка загрузки: " .. tostring(Midnight))

	return
end

--// 2. Окно ------------------------------------------------------------------

local window = Midnight:CreateWindow({
	Title = "Midnight",
	Keybind = "RightControl",
	Size = { 800, 570 },
	Theme = "Midnight",
	Columns = 2,
})

--// 3. HUD-панели (как сверху на референсе) -----------------------------------

window:Hud({ Title = "Spectators", Icon = "eye", Position = "TopLeft" })
window:Hud({ Title = "Binds", Icon = "keybind", Position = "TopRight" })

-- Заполнить их можно так:
--   local spectators = window:Hud({ Title = "Spectators", Icon = "eye" })
--   spectators:SetRows({ "Player1", "Player2" })

--// 4. Навигация: одна вкладка, страницы — в сайдбаре -------------------------

local tab = window:Tab("Main")

local aimbotPage = tab:Page("Aimbot", { Group = "Combat", Icon = "crosshair" })
local playersPage = tab:Page("Players", { Group = "Visuals", Icon = "users" })
local itemsPage = tab:Page("Items", { Group = "Visuals", Icon = "cube" })
local viewPage = tab:Page("View", { Group = "Visuals", Icon = "eye" })
local hudPage = tab:Page("Hud", { Group = "Visuals", Icon = "layout" })
local mainPage = tab:Page("Main", { Group = "Misc", Icon = "sliders" })
local movementPage = tab:Page("Movement", { Group = "Misc", Icon = "speed" })
local cloudPage = tab:Page("Cloud", { Group = "Misc", Icon = "cloud" })

--// 5. Misc ▸ Main — блок точь-в-точь как на референсе ------------------------

local main = mainPage:Groupbox("Main")

main:Toggle({ Title = "Aim target hitbox", Default = true, Color = Color3.fromRGB(245, 245, 248), Flag = "aim_target_hitbox" })
main:Toggle({ Title = "Aim recoil dot", Default = true, Color = Color3.fromRGB(233, 70, 70), Flag = "aim_recoil_dot" })
main:Toggle({ Title = "Aim FOV", Default = true, Flag = "aim_fov" })
main:Toggle({ Title = "Remove smoke", Default = true, Flag = "remove_smoke" })
main:Toggle({ Title = "Blind list", Default = true, Flag = "blind_list" })
main:Toggle({ Title = "Spectator list", Default = true, Flag = "spectator_list" })

local radar = mainPage:Groupbox("Radar")

radar:Toggle({ Title = "Enable", Default = true, Flag = "radar_enabled" })
radar:Label({ Text = "In-game", Indent = 28, Dim = true })
radar:Toggle({ Title = "Show bomb", Default = true, Flag = "radar_bomb" })
radar:Slider({ Title = "Scale", Min = 0, Max = 2, Step = 0.01, Decimals = 2, Default = 1.70, Flag = "radar_scale" })
radar:Slider({ Title = "Alpha", Min = 0, Max = 1, Step = 0.01, Decimals = 2, Default = 0.60, Flag = "radar_alpha" })
radar:Label({ Text = "Teammates", Bold = true })
radar:ColorPicker({ Title = "Enemy visible", Default = Color3.fromRGB(47, 128, 237), Flag = "teammate_visible" })
radar:ColorPicker({ Title = "Enemy invisible", Default = Color3.fromRGB(255, 212, 59), Flag = "teammate_invisible" })
radar:ColorPicker({ Title = "Bomb carry", Default = Color3.fromRGB(255, 80, 190), Flag = "bomb_carry" })

--// 6. Combat ▸ Aimbot --------------------------------------------------------

local aimbot = aimbotPage:Groupbox("Aimbot")

aimbot:Toggle({ Title = "Enable", Flag = "aim_enabled" })
aimbot:Dropdown({ Title = "Hitboxes", Options = { "Head", "Chest", "Stomach" }, Multi = true, Default = { "Head", "Chest" }, Flag = "aim_hitboxes" })
aimbot:Dropdown({ Title = "Smoothing", Options = { "Linear", "Dynamic", "Static" }, Default = "Dynamic", Dim = true, Flag = "aim_smoothing" })
aimbot:Slider({ Title = "Hit chance", Min = 0, Max = 100, Default = 73, Flag = "aim_hitchance" })
aimbot:Keybind({ Title = "Toggle key", Default = "MouseButton2", Flag = "aim_key" })

local trigger = aimbotPage:Groupbox("Triggerbot")

trigger:Toggle({ Title = "Enable", Flag = "trigger_enabled" })
trigger:Slider({ Title = "Delay before shot", Min = 0, Max = 1, Step = 0.001, Decimals = 3, Default = 0, Flag = "trigger_delay_before" })
trigger:Slider({ Title = "Delay after shot", Min = 0, Max = 1, Step = 0.001, Decimals = 3, Default = 0, Flag = "trigger_delay_after" })
trigger:Toggle({ Title = "Only zoom", Circle = true, Flag = "trigger_only_zoom" })
trigger:Toggle({ Title = "Auto wall", Circle = true, Flag = "trigger_auto_wall" })
trigger:Slider({ Title = "Min damage", Min = 0, Max = 100, Default = 100, Flag = "trigger_min_damage" })

local delays = aimbotPage:Groupbox("Delays")

delays:Slider({ Title = "Chams delay", Min = 0, Max = 1000, Default = 250, Suffix = "ms", Flag = "chams_delay" })
delays:Slider({ Title = "ESP delay", Min = 0, Max = 1000, Default = 100, Suffix = "ms", Flag = "esp_delay" })
delays:Textbox({ Title = "Notes", Placeholder = "none", Flag = "delay_notes" })

--// 7. Visuals ----------------------------------------------------------------

local players = playersPage:Groupbox("Players")

players:Toggle({ Title = "Enable", Flag = "esp_enabled" })
players:Toggle({ Title = "Boxes", Default = true, Flag = "esp_boxes" })
players:Toggle({ Title = "Names", Default = true, Flag = "esp_names" })
players:Toggle({ Title = "Health bar", Flag = "esp_health" })
players:ColorPicker({ Title = "Box colour", Default = Color3.fromRGB(47, 128, 237), Flag = "esp_color" })
players:Slider({ Title = "Max distance", Min = 0, Max = 1000, Default = 500, Suffix = "m", Flag = "esp_distance" })

local items = itemsPage:Groupbox("Items")

items:Toggle({ Title = "Enable", Flag = "item_esp" })
items:Dropdown({ Title = "Filter", Options = { "All", "Weapons", "Utility" }, Default = "All", Flag = "item_filter" })
items:Label({ Text = "Подсветка полезных предметов вокруг игрока" })
items:Divider({})
items:Slider({ Title = "Range", Min = 0, Max = 500, Default = 150, Suffix = "m", Flag = "item_range" })

local view = viewPage:Groupbox("View")

view:Toggle({ Title = "Fullbright", Flag = "fullbright" })
view:Toggle({ Title = "No fog", Flag = "no_fog" })
view:Slider({ Title = "Ambient", Min = 0, Max = 100, Default = 50, Flag = "ambient" })
view:Gap(4)
view:Slider({ Title = "FOV", Min = 70, Max = 120, Default = 90, Flag = "camera_fov" })

local hudBox = hudPage:Groupbox("Hud")

hudBox:Toggle({ Title = "Watermark", Default = true, Flag = "watermark" })
hudBox:Toggle({ Title = "FPS counter", Flag = "fps_counter" })
hudBox:Textbox({ Title = "Watermark text", Default = "midnight", Flag = "watermark_text" })
hudBox:Keybind({ Title = "Hide HUD", Default = "RightShift", Flag = "hide_hud" })

--// 8. Misc ▸ Movement / Cloud ------------------------------------------------

local movement = movementPage:Groupbox("Movement")

movement:Toggle({ Title = "Enable", Flag = "move_enabled" })
movement:Toggle({ Title = "Auto strafe", Circle = true, Flag = "auto_strafe" })
movement:Slider({ Title = "Speed", Min = 1, Max = 10, Step = 0.1, Decimals = 1, Default = 1.5, Flag = "move_speed" })
movement:Slider({ Title = "Jump power", Min = 0, Max = 500, Default = 350, Flag = "jump_power" })
movement:Keybind({ Title = "Hold key", Default = "LeftShift", Mode = "Hold", Flag = "move_key" })

local cloud = cloudPage:Groupbox("Cloud")

cloud:Dropdown({ Title = "Theme", Options = { "Midnight", "Carbon", "Amethyst", "Emerald", "Daybreak" }, Default = "Midnight", Flag = "theme", Callback = function(value)
	window:SetTheme(value)
end })
cloud:Dropdown({ Title = "Menu sound", Options = { "On", "Off" }, Default = "On", Flag = "menu_sound" })
cloud:Slider({ Title = "Menu scale", Min = 0.75, Max = 1.5, Step = 0.05, Decimals = 2, Default = 1, Flag = "menu_scale", Callback = function(value)
	window:SetScale(value)
end })
cloud:Textbox({ Title = "Config name", Default = "default", Flag = "config_name" })
cloud:Button({ Title = "Save config", Style = "Accent", Flag = "save_config", Callback = function()
	window:Notify({ Title = "Config", Text = "Конфиг сохранён", Kind = "Success" })
end })
cloud:Button({ Title = "Reset all", Style = "Danger", Callback = function()
	for _, element in window:GetElements() do
		element:Reset()
	end

	window:Notify({ Title = "Config", Text = "Всё сброшено", Kind = "Warning" })
end })
cloud:Button({ Title = "Manual save", Flag = "manual_save" })
cloud:Gap(4)

--// 9. Старт ------------------------------------------------------------------

window:SelectPage("Main")

window:Notify({
	Title = "Midnight " .. tostring(Midnight.Version),
	Text = "Меню загружено — RightControl",
	Duration = 5,
})

print(("[Midnight] версия %s, окно в %s"):format(tostring(Midnight.Version), tostring(window.Gui.Parent and window.Gui.Parent.Name)))

_G.MidnightWindow = window
