--!strict
--[[
	MidnightUI · Maid
	------------------------------------------------------------------
	Lifecycle helper. Anything added to a Maid is cleaned up when the
	Maid is cleaned, which makes `:Destroy()` on windows/elements
	trivially leak-free.

	Supported tasks:
		· Instance            -> :Destroy()
		· RBXScriptConnection -> :Disconnect()
		· Signal connection   -> :Disconnect()
		· function            -> called
		· table with Destroy  -> :Destroy()
		· thread              -> coroutine.close() (task.cancel fallback)
]]

local Maid = {}
Maid.__index = Maid

export type Task = any

export type Maid = typeof(setmetatable(
	{} :: {
		_tasks: { [number]: Task },
		_destroyed: boolean,
	},
	Maid
))

local function isConnection(task: any): boolean
	return type(task) == "table"
		and task.Connected ~= nil
		and type(task.Disconnect) == "function"
end

--// Public API -------------------------------------------------------

function Maid.new(): Maid
	return setmetatable({
		_tasks = {},
		_destroyed = false,
	}, Maid) :: Maid
end

--- Registers a task to be cleaned up later.
function Maid.Add(self: Maid, task: Task): Task
	assert(task ~= nil, "[MidnightUI] Maid:Add received nil")

	if self._destroyed then
		Maid._clean(task)

		return task
	end

	table.insert(self._tasks, task)

	return task
end

--- Registers several tasks at once.
function Maid.AddAll(self: Maid, ...: Task)
	for index = 1, select("#", ...) do
		self:Add((select(index, ...)))
	end
end

--- Registers a task and returns a proxy whose :Destroy() removes it.
function Maid.AddProxy(self: Maid, task: Task): Task
	self:Add(task)

	return task
end

--- Internal single-task cleanup.
function Maid._clean(task: Task)
	local taskType = type(task)

	if taskType == "function" then
		task()
	elseif taskType == "thread" then
		local ok = pcall(task.cancel, task)
		if not ok then
			pcall(coroutine.close, task)
		end
	elseif taskType == "table" then
		if isConnection(task) then
			task:Disconnect()
		elseif type(task.Destroy) == "function" then
			task:Destroy()
		elseif type(task.Disconnect) == "function" then
			task:Disconnect()
		end
	elseif typeof(task) == "Instance" then
		task:Destroy()
	elseif typeof(task) == "RBXScriptConnection" then
		task:Disconnect()
	end
end

--- Cleans every registered task (the Maid stays reusable).
function Maid.Clean(self: Maid)
	local tasks = self._tasks
	self._tasks = {}

	for index = #tasks, 1, -1 do
		local ok, err = pcall(Maid._clean, tasks[index])

		if not ok then
			warn(("[MidnightUI] Maid task errored while cleaning: %s"):format(tostring(err)))
		end
	end
end

--- Cleans and permanently disables the Maid.
function Maid.Destroy(self: Maid)
	if self._destroyed then
		return
	end

	self:Clean()
	self._destroyed = true
end

--- Returns how many tasks are still tracked.
function Maid.GetTaskCount(self: Maid): number
	return #self._tasks
end

--- Wraps a task so it can be used as a connection-like handle.
function Maid.Wrap(self: Maid, task: Task): { Destroy: (self: any) -> () }
	self:Add(task)

	local handle = {}

	function handle:Destroy()
		for index, stored in self._tasks do
			if stored == task then
				table.remove(self._tasks, index)
				break
			end
		end

		Maid._clean(task)
	end

	return handle
end

return Maid
