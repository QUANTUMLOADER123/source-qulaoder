--[[
	═══════════════════════════════════════════════════════════════════════════
	  M I D N I G H T   U I   —   демо-меню (loadstring-сборка)
	═══════════════════════════════════════════════════════════════════════════

	Вставь это целиком в executor и запусти.

	Скрипт сам скачивает библиотеку с GitHub и строит меню со ВСЕМИ
	элементами: вкладки, сайдбар, группы, чекбоксы, слайдеры, дропдауны,
	текстовые поля, кнопки, кейбинды, колор-пикеры, уведомления.

	Открыть/закрыть меню: RightControl (или кнопка в меню).
]]

local BASE = "https://raw.githubusercontent.com/QUANTUMLOADER123/source-qulaoder/arena/7cd2f990-source-qulaoder/MidnightUI/dist/"

--// 1. Загрузка библиотеки ------------------------------------------------------------------

local loaded, Midnight = pcall(function()
	return loadstring(game:HttpGet(BASE .. "Midnight.luau"))()
end)

if not loaded or Midnight == nil then
	warn("[Midnight] не удалось загрузить библиотеку: " .. tostring(Midnight))

	return
end

--// 2. Окно -------------------------------------------------------------------------------

local window = Midnight:CreateWindow({
	Title = "Midnight",
	Keybind = "RightControl",
	Size = { 1120, 700 },
	Theme = "Midnight",
	Columns = 2,
})

--// 3. Вкладки -----------------------------------------------------------------------------

local mainTab = window:Tab("MAIN", { Icon = "home" })
local featuresTab = window:Tab("FEATURES", { Icon = "box" })
local appearanceTab = window:Tab("APPEARANCE", { Icon = "palette" })
local skinTab = window:Tab("SKIN", { Icon = "skin" })
local activityTab = window:Tab("ACTIVITY", { Icon = "activity" })

--// 4. MAIN ---------------------------------------------------------------------------------

local selfPage = mainTab:Page("Self", { Group = "Main", Icon = "user" })
local worldPage = mainTab:Page("World", { Group = "World", Icon = "globe" })
local onlinePage = mainTab:Page("Online", { Group = "Online", Icon = "network" })
local visualsPage = mainTab:Page("Visuals", { Group = "Visuals", Icon = "eye" })
local miscPage = mainTab:Page("Misc", { Group = "Misc", Icon = "misc" })

local radar = selfPage:Groupbox("Off The Radar")
radar:Toggle({ Title = "Enable", Default = false, Flag = "radar_enabled", Callback = function() end })
radar:Slider({ Title = "Time", Min = 0, Max = 1000, Default = 0, Suffix = "s", Flag = "radar_time" })
radar:Dropdown({ Title = "Method", Options = { "Local", "Server", "Hybrid" }, Default = "Local", Flag = "radar_method" })
radar:Textbox({ Title = "Nickname", Placeholder = "Lester", Flag = "radar_nick" })

local health = selfPage:Groupbox("Auto Health Refill")
health:Toggle({ Title = "Enable", Default = false, Flag = "health_enabled" })
health:Slider({ Title = "Delay", Min = 0, Max = 10, Step = 0.1, Default = 2.3, Decimals = 1, Flag = "health_delay" })
health:Textbox({ Title = "Amount", Numeric = true, Min = 0, Max = 100, Default = 100, Flag = "health_amount" })
health:Dropdown({ Title = "Source", Options = { "Medkit", "Snacks", "Auto" }, Default = "Auto", Flag = "health_source" })

local armour = selfPage:Groupbox("Auto Armour Refill")
armour:Toggle({ Title = "Enable", Default = false, Flag = "armour_enabled" })
armour:Slider({ Title = "Delay", Min = 0, Max = 10, Step = 0.1, Default = 1.2, Decimals = 1, Flag = "armour_delay" })
armour:Textbox({ Title = "Amount", Numeric = true, Min = 0, Max = 100, Default = 100, Flag = "armour_amount" })

local wanted = selfPage:Groupbox("Wanted Level")
wanted:Toggle({ Title = "Freeze", Default = false, Flag = "wanted_freeze" })
wanted:Dropdown({ Title = "Level", Options = { "none", "1 star", "2 stars", "5 stars" }, Default = "none", Flag = "wanted_level" })
wanted:Slider({ Title = "Decay", Min = 0, Max = 5, Step = 0.1, Default = 0, Decimals = 1, Flag = "wanted_decay" })

local noclip = worldPage:Groupbox("Noclip")
noclip:Toggle({ Title = "Enable", Default = false, Flag = "noclip", Callback = function() end })
noclip:Keybind({ Title = "Hotkey", Default = "E", Flag = "noclip_key" })

local speed = worldPage:Groupbox("Speedhack")
speed:Toggle({ Title = "Enable", Default = false, Flag = "speed_enabled" })
speed:Slider({ Title = "Multiplier", Min = 1, Max = 20, Step = 0.1, Default = 2.5, Decimals = 1, Flag = "speed_mul" })
speed:Keybind({ Title = "Hold", Default = "LeftShift", Mode = "Hold", Flag = "speed_key" })

local teleport = worldPage:Groupbox("Teleport")
teleport:Textbox({ Title = "Target", Placeholder = "Local", Flag = "tp_target" })
teleport:Textbox({ Title = "Ground Z", Placeholder = "0.000", Flag = "tp_z" })
teleport:Dropdown({ Title = "Mode", Options = { "Instant", "Smooth" }, Default = "Smooth", Flag = "tp_mode" })
teleport:Button({ Title = "Teleport", Style = "Accent", Flag = "tp_go", Callback = function()
	window:Notify({ Title = "Teleport", Text = "Выполнено", Kind = "Success", Duration = 3 })
end })

local players = onlinePage:Groupbox("Players")
players:Toggle({ Title = "Show list", Default = true, Flag = "players_show" })
players:Dropdown({ Title = "Sort", Options = { "Distance", "Name", "Team" }, Default = "Distance", Flag = "players_sort" })
players:Slider({ Title = "Range", Min = 0, Max = 500, Default = 150, Suffix = "m", Flag = "players_range" })

local esp = visualsPage:Groupbox("Player ESP")
esp:Toggle({ Title = "Enable", Default = false, Flag = "esp_enabled" })
esp:Toggle({ Title = "Boxes", Default = true, Flag = "esp_boxes" })
esp:Toggle({ Title = "Names", Default = true, Flag = "esp_names" })
esp:ColorPicker({ Title = "Colour", Default = Color3.fromRGB(30, 155, 215), Flag = "esp_color" })
esp:Slider({ Title = "Opacity", Min = 0, Max = 1, Step = 0.05, Default = 0.85, Decimals = 2, Flag = "esp_opacity" })

local worldVis = visualsPage:Groupbox("World")
worldVis:Toggle({ Title = "Fullbright", Default = false, Flag = "fullbright" })
worldVis:Toggle({ Title = "No fog", Default = false, Flag = "no_fog" })
worldVis:Slider({ Title = "Ambient", Min = 0, Max = 100, Default = 50, Flag = "ambient" })

local misc = miscPage:Groupbox("Misc")
misc:Label({ Text = "Все элементы меню" })
misc:Divider({})
misc:Dropdown({ Title = "Theme", Options = { "Midnight", "Carbon", "Amethyst", "Emerald", "Daybreak" }, Default = "Midnight", Flag = "theme_pick", Callback = function(value)
	window:SetTheme(value)
end })
misc:Gap(6)
misc:Button({ Title = "Save config", Style = "Default", Callback = function()
	local saved = window:SaveConfig()

	window:Notify({ Title = "Config", Text = ("сохранено флагов: %d"):format(#saved), Kind = "Info" })
end })
misc:Button({ Title = "Reset all", Style = "Danger", Callback = function()
	for _, element in window:GetElements() do
		element:Reset()
	end

	window:Notify({ Title = "Config", Text = "всё сброшено", Kind = "Warning" })
end })

--// 5. FEATURES ------------------------------------------------------------------------------

local combatPage = featuresTab:Page("Weapons", { Group = "Combat", Icon = "gun" })
local visualsFeature = featuresTab:Page("Visuals", { Group = "Visuals", Icon = "eye" })
local miscFeature = featuresTab:Page("Misc", { Group = "Misc", Icon = "misc" })

local trigger = combatPage:Groupbox("Triggerbot")
trigger:Toggle({ Title = "Enable", Default = false, Flag = "trigger_enabled" })
trigger:Keybind({ Title = "Key", Default = "MouseButton2", Flag = "trigger_key" })
trigger:Slider({ Title = "Delay", Min = 0, Max = 500, Default = 100, Suffix = "ms", Flag = "trigger_delay" })
trigger:Dropdown({ Title = "Hitbox", Options = { "Head", "Body", "Nearest" }, Default = "Head", Flag = "trigger_hitbox" })

local aim = combatPage:Groupbox("Aimbot")
aim:Toggle({ Title = "Enable", Default = false, Flag = "aim_enabled" })
aim:Slider({ Title = "FOV", Min = 1, Max = 180, Default = 45, Flag = "aim_fov" })
aim:Slider({ Title = "Smoothness", Min = 0, Max = 10, Step = 0.1, Default = 2.3, Decimals = 1, Flag = "aim_smooth" })
aim:Dropdown({ Title = "Bone", Options = { "Head", "Neck", "Chest" }, Default = "Neck", Flag = "aim_bone" })
aim:ColorPicker({ Title = "FOV circle", Default = Color3.fromRGB(44, 165, 216), Flag = "aim_fov_color" })

local delays = visualsFeature:Groupbox("Delays")
delays:Slider({ Title = "Chams delay", Min = 0, Max = 1000, Default = 250, Suffix = "ms", Flag = "chams_delay" })
delays:Slider({ Title = "ESP delay", Min = 0, Max = 1000, Default = 100, Suffix = "ms", Flag = "esp_delay" })
delays:Textbox({ Title = "Notes", Placeholder = "нет", Flag = "delay_notes" })

local extras = miscFeature:Groupbox("Extras")
extras:Toggle({ Title = "Anti-AFK", Default = true, Flag = "antiafk" })
extras:Toggle({ Title = "Auto reconnect", Default = false, Flag = "reconnect" })
extras:Dropdown({ Title = "Priority", Options = { "Low", "Normal", "High" }, Default = "Normal", Flag = "priority" })
extras:Keybind({ Title = "Panic", Default = "Delete", Flag = "panic" })

--// 6. APPEARANCE / SKIN / ACTIVITY ------------------------------------------------------------

local themePage = appearanceTab:Page("Theme", { Group = "Main", Icon = "palette" })

local themeBox = themePage:Groupbox("Theme")
themeBox:Dropdown({ Title = "Preset", Options = { "Midnight", "Carbon", "Amethyst", "Emerald", "Daybreak" }, Default = "Midnight", Flag = "appearance_theme", Callback = function(value)
	window:SetTheme(value)
end })
themeBox:ColorPicker({ Title = "Accent", Default = Color3.fromRGB(30, 155, 215), Flag = "appearance_accent", Callback = function(color)
	window:SetTheme({ Colors = { Accent = color } })
end })
themeBox:Slider({ Title = "Scale", Min = 0.75, Max = 1.5, Step = 0.05, Default = 1, Decimals = 2, Flag = "ui_scale", Callback = function(value)
	window:SetScale(value)
end })

local skinPage = skinTab:Page("Skins", { Group = "Main", Icon = "skin" })

local skins = skinPage:Groupbox("Skins")
skins:Dropdown({ Title = "Skin", Options = { "Default", "Glossy", "Flat" }, Default = "Default", Flag = "skin" })
skins:Toggle({ Title = "Rounded corners", Default = true, Flag = "skin_round" })
skins:Slider({ Title = "Opacity", Min = 0.6, Max = 1, Step = 0.05, Default = 0.98, Decimals = 2, Flag = "skin_opacity" })

local logPage = activityTab:Page("Log", { Group = "Main", Icon = "paragraph" })

local logBox = logPage:Groupbox("Activity")
logBox:Paragraph({ Text = "Здесь видны последние действия. Нажми кнопку ниже, чтобы проверить уведомления.", Height = 34 })
logBox:Button({ Title = "Test notification", Style = "Accent", Callback = function()
	window:Notify({ Title = "Midnight", Text = "Уведомление работает", Kind = "Success", Duration = 3 })
end })
logBox:Button({ Title = "Second one", Callback = function()
	window:Notify({ Text = "Ещё одно уведомление", Kind = "Info" })
end })

--// 7. Старт -----------------------------------------------------------------------------

window:SelectTab("MAIN")

window:Notify({ Title = "Midnight", Text = "Меню загружено — RightControl чтобы открыть", Duration = 5 })

_G.MidnightWindow = window
