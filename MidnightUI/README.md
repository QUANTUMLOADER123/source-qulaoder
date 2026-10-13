# MidnightUI

Меню для Roblox в стиле **MIDNIGHT**: тёмное окно, вкладки сверху с синим подчёркиванием,
сайдбар с категориями, сворачиваемые группы и все элементы — чекбоксы, слайдеры,
дропдауны, текстовые поля, кнопки, кейбинды, колор-пикеры, уведомления.

## Запуск (loadstring)

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/QUANTUMLOADER123/source-qulaoder/arena/7cd2f990-source-qulaoder/MidnightUI/dist/MidnightDemo.luau"))()
```

`MidnightDemo.luau` сам подтягивает библиотеку (`Midnight.luau`) и строит демо-меню
со всеми элементами. Открыть/закрыть — **RightControl**.

## Своё меню

```lua
local Midnight = loadstring(game:HttpGet("https://raw.githubusercontent.com/QUANTUMLOADER123/source-qulaoder/arena/7cd2f990-source-qulaoder/MidnightUI/dist/Midnight.luau"))()

local window = Midnight:CreateWindow({ Title = "Midnight", Keybind = "RightControl", Size = { 1120, 700 } })

local page = window:Tab("MAIN"):Page("Self", { Group = "Main", Icon = "user" })
local box = page:Groupbox("Off The Radar")

box:Toggle({ Title = "Enable", Flag = "enabled" })
box:Slider({ Title = "Time", Min = 0, Max = 1000, Default = 0 })
box:Dropdown({ Title = "Method", Options = { "Local", "Server" }, Default = "Local" })
box:Textbox({ Title = "Nickname", Placeholder = "Lester" })
box:Button({ Title = "Apply", Style = "Accent" })
box:Keybind({ Title = "Hotkey", Default = "E" })
box:ColorPicker({ Title = "Colour" })

window:Notify({ Title = "Midnight", Text = "Готово", Kind = "Success" })
```

## Структура

```
MidnightUI/
├── src/                  — исходники библиотеки (Rojo-совместимые модули)
│   └── Elements/         — Toggle, Slider, Dropdown, Textbox, Button, Keybind, ColorPicker, Label, Divider
├── dist/
│   ├── Midnight.luau     — собранная библиотека в один файл (loadstring)
│   └── MidnightDemo.luau — демо-меню со всеми элементами (loadstring)
├── tools/build.py        — сборка dist/ из src/
└── tests/                — оффлайн-тесты (MockRoblox) и Selftest
```

Пересобрать бандл после правок в `src/`:

```bash
python3 tools/build.py
```
