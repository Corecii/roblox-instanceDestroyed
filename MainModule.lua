--[[
	Edit 5:
		Clarify comments on coroutine.yield because behavior has changed
		 from [end of current execution cycle] to [beginning of next execution cycle]
	Version 4:
		Fixed garbage collection detection.
	Edit 3:
		Clarified/fixed some terminology. (comments only)
	Version 2:
		Made it not prevent garbage collection by using ObjectValues
	Version 1:
		Initial
		
	Documentation:
		This module can be used to detect when an instance is destroyed at any point after it is used on the object.
		It will detect when the object is destroyed from the game hierarchy, when it is destroyed from nil
		 and when it is garbage-collected.
		The call returns a pseudo-signal which can be used to check if the function is connected and can
		 be used to disconnect the on-destroy-function without causing it to fire.
		
		
		pseudoSignal module(Instance instance, function func)
			Attach the function 'func' to be called when the Instance 'instance' is destroyed
		
		
		pseudoSignal
		
			boolean         .connected, .Connected
				If the function provided is still connected then this is true. When the object is destroyed
				 this is set to false before the function is called.
				This can only be false if the object is destroyed or if this is manually disconnected.
			
			void            :disconnect(), :Disconnect()
				Manually disconnects the connected function before the object is destroyed.
				
			RBXScriptSignal .connection
				This is the actual connection to the instance's AncestryChanged event. This should not
				 be messed with.
			
--]]

local cyield = coroutine.yield
local cwrap = coroutine.wrap

local disconnectMeta = {
	__index = {
		connected = true,
		Connected = true,
		disconnect = function(this)
			this.connected = false
			this.Connected = false
			this.connection:Disconnect()
		end
	}
}
disconnectMeta.__index.Disconnect = disconnectMeta.__index.disconnect

return function(instance, func)
	local reference = Instance.new("ObjectValue")
	reference.Value = instance
	-- ObjectValues have weak-like Instance references
	-- If the Instance can no longer be accessed then it can be collected despite
	--  the ObjectValue having a reference to it
	local manualDisconnect = setmetatable({}, disconnectMeta)
	local con
	local changedFunction = function(obj, par)
		if not reference.Value then
			manualDisconnect.connected = false
			manualDisconnect.Connected = false
			return func(reference.Value)
		elseif obj == reference.Value and not par then
			obj = nil
			cyield()  -- Push further execution of this script to the beginning of the next execution cycle
			          --  This is needed because when the event first runs it's always still connected
			-- The object may have been reparented or the event manually disconnected or disconnected and ran in that time...
			if (not reference.Value or not reference.Value.Parent) and manualDisconnect.connected then
				if not con.connected then
					manualDisconnect.connected = false
					manualDisconnect.Connected = false
					return func(reference.Value)
				else
					-- Since this event won't fire if the instance is destroyed while in nil, we have to check
					--  often to make sure it's not destroyed. Once it's parented outside of nil we can stop doing
					--  this. We also must check to make sure it wasn't manually disconnected or disconnected and ran.
					while wait(1/5) do
						if not manualDisconnect.connected then
							-- Don't run func, we were disconnected manually
							return
						elseif not con.connected then
							-- Otherwise, if we're disconnected it's because instance was destroyed
							manualDisconnect.connected = false
							manualDisconnect.Connected = false
							return func(reference.Value)
						elseif reference.Value.Parent then
							-- If it's still connected then it's not destroyed. If it has a parent then
							--  we can quit checking if it's destroyed like this.
							return
						end
					end
				end
			end
		end
	end
	con = instance.AncestryChanged:Connect(changedFunction)
	manualDisconnect.connection = con
	instance = nil
	-- If the object is currently in nil then we need to start our destroy checking loop
	-- We need to spawn a new Roblox Lua thread right now before any other code runs.
	--  spawn() starts it on the next cycle or frame, coroutines don't have ROBLOX's coroutine.yield handler
	--  The only option left is BindableEvents, which run as soon as they are called and use ROBLOX's yield
	local quickRobloxThreadSpawner = Instance.new("BindableEvent")
	quickRobloxThreadSpawner.Event:Connect(changedFunction)
	quickRobloxThreadSpawner:Fire(reference.Value, reference.Value.Parent)
	quickRobloxThreadSpawner:Destroy()
	return manualDisconnect
end
