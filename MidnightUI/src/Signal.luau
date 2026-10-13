--!strict
--[[
	MidnightUI · Signal
	------------------------------------------------------------------
	A tiny, allocation-friendly event implementation used everywhere
	inside the library. It intentionally mirrors the RBXScriptSignal
	API (:Connect / :Once / :Wait / :Disconnect) so that library code
	and user code can treat internal and Roblox signals the same way.
]]

local Signal = {}
Signal.__index = Signal

export type Callback<T...> = (T...) -> ()
export type Connection = {
	Connected: boolean,
	Disconnect: (self: Connection) -> (),
	Destroy: (self: Connection) -> (),
}

export type Signal<T...> = typeof(setmetatable(
	{} :: {
		_handlers: { [number]: Callback<T...> },
		_nextId: number,
	},
	Signal
))

--// Internal ---------------------------------------------------------

local function newConnection(owner: any, id: number): Connection
	local connection = {
		Connected = true,
	}

	function connection.Disconnect(_self: Connection)
		if not connection.Connected then
			return
		end

		connection.Connected = false
		owner._handlers[id] = nil
	end

	connection.Destroy = connection.Disconnect

	return connection
end

--// Public API -------------------------------------------------------

--- Creates a brand new signal.
function Signal.new<T...>(): Signal<T...>
	return setmetatable({
		_handlers = {} :: { [number]: Callback<T...> },
		_nextId = 0,
	}, Signal :: any) :: Signal<T...>
end

--- Connects `callback` to the signal.
function Signal.Connect<T...>(self: Signal<T...>, callback: Callback<T...>): Connection
	assert(type(callback) == "function", "[MidnightUI] Signal:Connect expects a function")

	self._nextId += 1

	local id = self._nextId
	self._handlers[id] = callback

	return newConnection(self, id)
end

--- Connects `callback` and disconnects it right after the first fire.
function Signal.Once<T...>(self: Signal<T...>, callback: Callback<T...>): Connection
	local connection: Connection

	connection = self:Connect(function(...)
		connection:Disconnect()
		callback(...)
	end)

	return connection
end

--- Fires the signal with the given arguments.
function Signal.Fire<T...>(self: Signal<T...>, ...: T...)
	-- Snapshot: handlers may disconnect (or connect) while we iterate.
	local snapshot = table.clone(self._handlers)

	for _, handler in snapshot do
		local ok, err = pcall(handler, ...)

		if not ok then
			warn(("[MidnightUI] Signal handler errored: %s"):format(tostring(err)))
		end
	end
end

--- Yields the current thread until the signal fires.
function Signal.Wait<T...>(self: Signal<T...>): T...
	local thread = coroutine.running()
	local connection: Connection

	connection = self:Connect(function(...)
		connection:Disconnect()

		task.spawn(thread, ...)
	end)

	return coroutine.yield()
end

--- Removes every connected handler.
function Signal.DisconnectAll<T...>(self: Signal<T...>)
	table.clear(self._handlers)
end

--- Returns the amount of connected handlers.
function Signal.GetHandlerCount<T...>(self: Signal<T...>): number
	return #table.clone(self._handlers)
end

--- Roblox-like alias, mostly for API symmetry.
Signal.Destroy = Signal.DisconnectAll

return Signal
