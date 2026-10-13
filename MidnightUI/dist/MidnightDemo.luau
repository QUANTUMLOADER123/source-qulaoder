--[[
	═══════════════════════════════════════════════════════════════════════════
	  M I D N I G H T   U I   —   демо-меню + все элементы
	═══════════════════════════════════════════════════════════════════════════

	Запуск (executor):
		loadstring(game:HttpGet("<ссылка на этот файл>"))()

	Открыть/закрыть меню — RightControl.
	Внутри — все элементы библиотеки: чекбоксы, круглые чекбоксы, слайдеры,
	дропдауны, текстовые поля, кнопки, кейбинды, колор-пикеры, лейблы,
	разделители, уведомления.
]]

local BASE = "https://raw.githubusercontent.com/QUANTUMLOADER123/source-qulaoder/arena/7cd2f990-source-qulaoder/MidnightUI/dist/"

--// 1. Библиотека ------------------------------------------------------------

local ok, Midnight = pcall(function()
	return loadstring(game:HttpGet(BASE .. "Midnight.luau"))()
end)

if not ok or Midnight == nil then
	warn("[Midnight] ошибка загрузки: " .. tostring(Midnight))

	return
end

--// 2. Окно -----------------------------------------------------------------

local window = Midnight:CreateWindow({
	Title = "Midnight",
	Keybind = "RightControl",
	Size = { 1120, 700 },
	Theme = "Midnight",
	Columns = 2,
})

--// 3. Вкладки ---------------------------------------------------------------

local globalsTab = window:Tab("GLOBALS")
local weaponsTab = window:Tab("WEAPONS")

--// 4. GLOBALS ▸ Combat ▸ Aimbot ---------------------------------------------

local aimbot = globalsTab:Page("Aimbot", { Group = "Combat", Icon = "crosshair" })

local weapon = aimbot:Groupbox("Weapon")

weapon:Dropdown({ Options = { "AWP", "AK-47", "M4A1", "Karambit" }, Default = "AWP", Flag = "weapon" })

local aim = aimbot:Groupbox("Aimbot")

aim:Toggle({ Title = "Enable", Flag = "aim_enabled" })
aim:Dropdown({ Title = "Hitboxes", Options = { "Head", "Chest", "Stomach" }, Multi = true, Default = { "Head", "Chest", "Stomach" }, Flag = "aim_hitboxes" })
aim:Dropdown({ Title = "Ignore jump", Options = { "Yes", "No" }, Placeholder = "", Flag = "aim_ignore_jump" })
aim:Dropdown({ Title = "Fov type", Options = { "Dynamic", "Static" }, Default = "Dynamic", Dim = true, Flag = "aim_fov_type" })
aim:Dropdown({ Title = "Smooth type", Options = { "Decrease", "Increase" }, Default = "Decrease", Dim = true, Flag = "aim_smooth_type" })
aim:Slider({ Title = "Auto-fire hitchance", Min = 0, Max = 100, Default = 0, Flag = "aim_hitchance" })

local settings = aimbot:Groupbox("Settings")

settings:Slider({ Title = "FOV", Min = 0, Max = 10, Step = 0.1, Decimals = 1, Default = 2.3, Flag = "fov" })
settings:Toggle({ Title = "Draw FOV", Circle = true, Flag = "draw_fov" })
settings:Keybind({ Title = "Toggle key", Default = "MouseButton2", Flag = "aim_key" })

local trigger = aimbot:Groupbox("Triggerbot")

trigger:Toggle({ Title = "Enable", Flag = "trigger_enabled" })
trigger:Dropdown({ Title = "Hitboxes", Options = { "Head", "Chest", "Stomach" }, Multi = true, Default = { "Head", "Chest", "Stomach" }, Flag = "trigger_hitboxes" })
trigger:Dropdown({ Title = "Type", Options = { "Normal", "Rage", "Legit" }, Default = "Normal", Flag = "trigger_type" })
trigger:Toggle({ Title = "Only zoom", Circle = true, Flag = "trigger_only_zoom" })
trigger:Slider({ Title = "Hitchance", Min = 0, Max = 100, Default = 73, Flag = "trigger_hitchance" })
trigger:Slider({ Title = "Delay before shot", Min = 0, Max = 1, Step = 0.001, Decimals = 3, Default = 0, Flag = "trigger_delay_before" })
trigger:Slider({ Title = "Delay after shot", Min = 0, Max = 1, Step = 0.001, Decimals = 3, Default = 0, Flag = "trigger_delay_after" })
trigger:Toggle({ Title = "Auto wall", Circle = true, Flag = "trigger_auto_wall" })
trigger:Slider({ Title = "Min damage", Min = 0, Max = 100, Default = 100, Flag = "trigger_min_damage" })

local delays = aimbot:Groupbox("Delays")

delays:Slider({ Title = "Chams delay", Min = 0, Max = 1000, Default = 250, Suffix = "ms", Flag = "chams_delay" })
delays:Slider({ Title = "ESP delay", Min = 0, Max = 1000, Default = 100, Suffix = "ms", Flag = "esp_delay" })

--// 5. GLOBALS ▸ Visuals / Misc ----------------------------------------------

local players = globalsTab:Page("Players", { Group = "Visuals", Icon = "users" })

local playerEsp = players:Groupbox("Player ESP")

playerEsp:Toggle({ Title = "Enable", Flag = "esp_enabled" })
playerEsp:Toggle({ Title = "Boxes", Default = true, Flag = "esp_boxes" })
playerEsp:Toggle({ Title = "Names", Default = true, Flag = "esp_names" })
playerEsp:ColorPicker({ Title = "Colour", Default = Color3.fromRGB(44, 165, 216), Flag = "esp_color" })
playerEsp:Slider({ Title = "Opacity", Min = 0, Max = 1, Step = 0.05, Decimals = 2, Default = 0.85, Flag = "esp_opacity" })

local items = globalsTab:Page("Items", { Group = "Visuals", Icon = "cube" })

local itemEsp = items:Groupbox("Items")

itemEsp:Toggle({ Title = "Enable", Flag = "item_esp" })
itemEsp:Slider({ Title = "Range", Min = 0, Max = 500, Default = 150, Suffix = "m", Flag = "item_range" })
itemEsp:Label({ Text = "Подсветка предметов вокруг игрока" })
itemEsp:Divider({})

local view = globalsTab:Page("View", { Group = "Visuals", Icon = "eye" })

local viewBox = view:Groupbox("View")

viewBox:Toggle({ Title = "Fullbright", Flag = "fullbright" })
viewBox:Slider({ Title = "Ambient", Min = 0, Max = 100, Default = 50, Flag = "ambient" })
viewBox:Dropdown({ Title = "Preset", Options = { "None", "Warm", "Cold" }, Default = "None", Flag = "view_preset" })

local hud = globalsTab:Page("Hud", { Group = "Visuals", Icon = "layout" })

local hudBox = hud:Groupbox("HUD")

hudBox:Toggle({ Title = "Watermark", Default = true, Flag = "watermark" })
hudBox:Textbox({ Title = "Text", Default = "midnight", Flag = "watermark_text" })

local main = globalsTab:Page("Main", { Group = "Misc", Icon = "settings" })

local mainBox = main:Groupbox("Menu")

mainBox:Dropdown({ Title = "Theme", Options = { "Midnight", "Carbon", "Amethyst", "Emerald", "Daybreak" }, Default = "Midnight", Flag = "theme", Callback = function(value)
	window:SetTheme(value)
end })
mainBox:Slider({ Title = "Scale", Min = 0.75, Max = 1.5, Step = 0.05, Decimals = 2, Default = 1, Flag = "scale", Callback = function(value)
	window:SetScale(value)
end })
mainBox:Keybind({ Title = "Menu key", Default = "RightControl", Flag = "menu_key", Callback = function(value)
	window:SetKeybind(value)
end })

local cloud = globalsTab:Page("Cloud", { Group = "Misc", Icon = "cloud" })

local cloudBox = cloud:Groupbox("Configs")

cloudBox:Textbox({ Title = "Config name", Default = "default", Flag = "config_name" })
cloudBox:Button({ Title = "Save config", Style = "Accent", Callback = function()
	window:Notify({ Title = "Config", Text = "Сохранено", Kind = "Success" })
end })
cloudBox:Button({ Title = "Reset all", Style = "Danger", Callback = function()
	for _, element in window:GetElements() do
		element:Reset()
	end

	window:Notify({ Title = "Config", Text = "Сброшено", Kind = "Warning" })
end })

--// 6. WEAPONS ---------------------------------------------------------------

local weaponPage = weaponsTab:Page("Weapon", { Group = "Weapons", Icon = "gun" })

local skinBox = weaponPage:Groupbox("Skins")

skinBox:Dropdown({ Title = "Skin", Options = { "Default", "Gold", "Blood" }, Default = "Default", Flag = "skin" })
skinBox:Slider({ Title = "Wear", Min = 0, Max = 1, Step = 0.01, Decimals = 2, Default = 0, Flag = "wear" })
skinBox:ColorPicker({ Title = "Tint", Default = Color3.fromRGB(44, 165, 216), Flag = "tint" })

local ammoBox = weaponPage:Groupbox("Ammo")

ammoBox:Toggle({ Title = "Infinite ammo", Flag = "infinite_ammo" })
ammoBox:Toggle({ Title = "No reload", Flag = "no_reload" })
ammoBox:Textbox({ Title = "Magazine size", Numeric = true, Min = 1, Max = 999, Default = 30, Flag = "mag_size" })

local extraBox = weaponPage:Groupbox("Extra")

extraBox:Button({ Title = "Test notification", Style = "Accent", Callback = function()
	window:Notify({ Title = "Midnight", Text = "Уведомление работает", Kind = "Success", Duration = 3 })
end })
extraBox:Button({ Title = "Second one", Callback = function()
	window:Notify({ Text = "Ещё одно уведомление", Kind = "Info" })
end })
extraBox:Gap(4)

local triggerPage = weaponsTab:Page("Triggerbot", { Group = "Weapons", Icon = "target" })

local triggerBox = triggerPage:Groupbox("Triggerbot")

triggerBox:Toggle({ Title = "Enable", Flag = "wt_enabled" })
triggerBox:Slider({ Title = "Delay", Min = 0, Max = 500, Default = 100, Suffix = "ms", Flag = "wt_delay" })
triggerBox:Keybind({ Title = "Key", Default = "MouseButton2", Flag = "wt_key" })

--// 7. Старт -----------------------------------------------------------------

window:SelectTab("GLOBALS")
window:SelectPage("Aimbot")

window:Notify({ Title = "Midnight", Text = "Меню загружено — RightControl", Duration = 5 })

_G.MidnightWindow = window
