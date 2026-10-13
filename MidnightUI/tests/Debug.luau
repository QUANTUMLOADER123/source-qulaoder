--!nocheck
local Mock = require(script.Parent.MockRoblox)
Mock.install()
local Midnight = require(script.Parent.Parent.src.init)
local window = Midnight:CreateWindow({ Parent = Mock.services.Players.LocalPlayer:WaitForChild("PlayerGui"), Size = { 1120, 700 } })

local page = window:Tab("GLOBALS"):Page("Aimbot", { Group = "Combat", Icon = "crosshair" })
local a = page:Groupbox("Weapon")
a:Dropdown({ Options = { "AWP", "AK-47" }, Default = "AWP", Flag = "g1" })
local b = page:Groupbox("Aimbot")
b:Toggle({ Title = "Enable", Flag = "g2" })
b:Dropdown({ Title = "Hitboxes", Options = { "Head", "Chest" }, Default = "Head", Flag = "g3" })
b:Slider({ Title = "Auto-fire hitchance", Min = 0, Max = 100, Flag = "g4" })
local c = page:Groupbox("Settings")
c:Slider({ Title = "FOV", Min = 0, Max = 10, Step = 0.1, Default = 2.3, Decimals = 1, Flag = "g5" })

Mock.layout()

local sections = {}

for _, s in page.Sections do
	table.insert(sections, s)
end

warn("sections: " .. tostring(#sections))

local boxes = {}

for _, s in sections do
	local l = Mock.computeLayout(s.Instance)
	table.insert(boxes, { name = s.Name, x = l.AbsolutePosition.X, y = l.AbsolutePosition.Y, w = l.AbsoluteSize.X, h = l.AbsoluteSize.Y })
	warn(("  %-10s x=%.0f y=%.0f w=%.0f h=%.0f"):format(s.Name, l.AbsolutePosition.X, l.AbsolutePosition.Y, l.AbsoluteSize.X, l.AbsoluteSize.Y))
end

local overlaps = 0

for i = 1, #boxes do
	for j = i + 1, #boxes do
		local a1, b1 = boxes[i], boxes[j]
		local separated = a1.x + a1.w <= b1.x + 0.5 or b1.x + b1.w <= a1.x + 0.5
			or a1.y + a1.h <= b1.y + 0.5 or b1.y + b1.h <= a1.y + 0.5

		if not separated then
			overlaps += 1
			warn(("OVERLAP %s <-> %s"):format(a1.name, b1.name))
		end
	end
end

warn("panel overlaps: " .. tostring(overlaps))

-- элементы внутри панели не должны пересекаться
for _, s in sections do
	local items = {}

	for _, e in s:GetElements() do
		local l = Mock.computeLayout(e.Instance)
		table.insert(items, { y = l.AbsolutePosition.Y, h = l.AbsoluteSize.Y, title = tostring(e.Title or e.Class) })
	end

	table.sort(items, function(p1, p2) return p1.y < p2.y end)

	for index = 2, #items do
		if items[index].y < items[index - 1].y + items[index - 1].h - 0.5 then
			overlaps += 1
			warn(("ELEMENT OVERLAP in %s: %s / %s"):format(s.Name, items[index - 1].title, items[index].title))
		end
	end
end

warn("total overlaps: " .. tostring(overlaps))
return nil
