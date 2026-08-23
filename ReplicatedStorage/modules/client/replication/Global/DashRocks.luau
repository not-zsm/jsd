local replicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RockHandler = require( script.Parent.RockHandler )
local Smoke = require( script.Parent.Smoke )

return function(RootPart : BasePart, Type : string, Time : number, OnDashRemoved : () -> ())
	if (RootPart == nil or RootPart.Parent == nil) then return end
	local Model : Model = RootPart.Parent
	if (Model == nil or Model.Parent == nil) then return end
	
	local RockThread = coroutine.create(function()
		while (Model.Parent ~= nil) do
			if (Players.LocalPlayer:DistanceFromCharacter(RootPart.Position) < 75) then
				RockHandler.Rocks(Type, RootPart)
			end
			
			task.wait(0.05)
		end
	end)

	local SmokeThread = coroutine.create(function()
		while (Model.Parent ~= nil) do
			if (Players.LocalPlayer:DistanceFromCharacter(RootPart.Position) < 75) then
				Smoke(RootPart)
			end

			task.wait(0.025)
		end
	end)

	if Type ~= "Backward Dash" then
		coroutine.resume(RockThread)
	end
	
	coroutine.resume(SmokeThread)

	local AttributeRemoveConnection : RBXScriptConnection = nil
	local Removed = false

	local function Remove()
		if Removed then return end
		
		Removed = true

		if AttributeRemoveConnection and AttributeRemoveConnection.Connected then
			AttributeRemoveConnection:Disconnect()
		end

		if coroutine.status(RockThread) == "suspended" then
			task.cancel(RockThread)
		end

		if coroutine.status(SmokeThread) == "suspended" then
			task.cancel(SmokeThread)
		end
		
		if OnDashRemoved then
			OnDashRemoved()
		end
		
		RockThread, SmokeThread = nil, nil
	end
	
	if (Time ~= -1) then
		task.delay(Time or 1, Remove)
	end

	return Remove, Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
end

