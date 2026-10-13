--!nocheck
--[[
	Запускает ровно тот скрипт, который пользователь вставит в executor:
	dist/MidnightDemo.luau сам подтягивает dist/Midnight.luau через
	game:HttpGet и строит меню. Раннер подставляет реальные исходники.
]]

local Mock = require(script.Parent.MockRoblox)

Mock.install()

local demoSource = rawget(_G, "__demoSource")

if demoSource == nil then
	warn("нет __demoSource")
	return
end

local chunk = loadstring(demoSource)

if chunk == nil then
	warn("демо не скомпилировалось")

	return
end

chunk()

local window = rawget(_G, "MidnightWindow")

warn("окно создано: " .. tostring(window ~= nil))

if window ~= nil then
	warn("вкладок: " .. tostring(#window.Tabs) .. ", элементов: " .. tostring(#window:GetElements()))

	for _, tab in window.Tabs do
		local pages = {}

		for _, page in tab.Pages do
			table.insert(pages, page.Name .. "(" .. tostring(#page:GetSections()) .. ")")
		end

		warn(("  tab %s -> %s"):format(tab.Name, table.concat(pages, ", ")))
	end
end


if window ~= nil then
	Mock.layout()

	local checked = 0
	local overlaps = 0

	for _, tab in window.Tabs do
		for _, page in tab.Pages do
			local boxes = {}

			for _, section in page:GetSections() do
				local layout = Mock.computeLayout(section.Instance)

				table.insert(boxes, {
					name = page.Name .. "/" .. section.Name,
					x = layout.AbsolutePosition.X,
					y = layout.AbsolutePosition.Y,
					w = layout.AbsoluteSize.X,
					h = layout.AbsoluteSize.Y,
				})
			end

			checked += #boxes

			for i = 1, #boxes do
				for j = i + 1, #boxes do
					local first, second = boxes[i], boxes[j]
					local separated = first.x + first.w <= second.x + 1
						or second.x + second.w <= first.x + 1
						or first.y + first.h <= second.y + 1
						or second.y + second.h <= first.y + 1

					if not separated then
						overlaps += 1

						warn(("НАЛОЖЕНИЕ: %s <-> %s"):format(first.name, second.name))
					end
				end
			end

			-- элементы внутри панели
			for _, section in page:GetSections() do
				local items = {}

				for _, element in section:GetElements() do
					local layout = Mock.computeLayout(element.Instance)

					table.insert(items, {
						y = layout.AbsolutePosition.Y,
						h = layout.AbsoluteSize.Y,
						title = tostring(element.Title or element.Class),
					})
				end

				table.sort(items, function(a, b)
					return a.y < b.y
				end)

				for index = 2, #items do
					if items[index].y < items[index - 1].y + items[index - 1].h - 1 then
						overlaps += 1

						warn(("НАЛОЖЕНИЕ внутри %s: %s / %s"):format(section.Name, items[index - 1].title, items[index].title))
					end
				end
			end
		end
	end

	warn(("проверено панелей: %d, наложений: %d"):format(checked, overlaps))
end

--// Контент панели обязан вмещать все элементы (иначе ClipsDescendants режет) --
if window ~= nil then
	local clipped = 0

	for _, tab in window.Tabs do
		for _, page in tab.Pages do
			for _, section in page:GetSections() do
				local needed = section:_getContentHeight()
				local actual = section.Content.Size.Y.Offset

				if actual + 0.5 < needed then
					clipped += 1

					warn(("ОБРЕЗАНО: %s/%s контент %.0f < нужно %.0f"):format(page.Name, section.Name, actual, needed))
				end
			end
		end
	end

	warn("панелей с обрезанным контентом: " .. tostring(clipped))
end

return nil

