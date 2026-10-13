--[[
	Minimal Roblox API definitions used by tools/lint.mjs.

	Every global the library touches is declared as `any` so that the
	strict-mode analysis focuses on MidnightUI's own code (module
	interfaces, typos, type mismatches) instead of trying to model the
	whole Roblox API surface. The runtime behaviour of these globals is
	validated by tests/MockRoblox.luau instead.

	Roblox *type* names (Frame, GuiObject, …) are injected per module as
	a one line alias shim by the linter, because Luau definition files
	cannot export type aliases.
]]

declare Instance: any
declare Color3: any
declare Vector2: any
declare Vector3: any
declare UDim: any
declare UDim2: any
declare Rect: any
declare Enum: any
declare game: any
declare workspace: any
declare script: any
declare task: any
declare typeof: any
declare warn: any
declare tick: any
declare Font: any
declare TweenInfo: any
declare NumberSequence: any
declare NumberSequenceKeypoint: any
declare ColorSequence: any
declare ColorSequenceKeypoint: any
declare BrickColor: any
declare Random: any
declare settings: any
declare shared: any
declare delay: any
declare spawn: any
declare wait: any
declare require: (module: any) -> any
