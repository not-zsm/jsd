local Utility = {}

function Utility.AirLock(Combat, State : boolean)
	if typeof(State) ~= "boolean" then
		return
	end
	
	local PreviousValue = Combat:GetRawState("AirLocked").Value
	
	if PreviousValue == 0 and State == false then
		return
	end
	
	Combat:StackState("AirLocked", State)
	
	local CurrentValue = Combat:GetRawState("AirLocked").Value
	
	Combat.LuaPlayer.Replication.Attributes:SetAttribute("AirLocked", CurrentValue)
	
	if PreviousValue == 0 and CurrentValue == 1 then
		if (Combat.AirLockVelocity ~= nil) then
			Combat.AirLockVelocity:Destroy()
		end
		
		if Combat.LuaCharacter.HumanoidExists then
			Combat.AirLockVelocity = Instance.new("LinearVelocity")
			Combat.AirLockVelocity.Attachment0 = Combat.LuaCharacter.RootAttachment
			Combat.AirLockVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
			Combat.AirLockVelocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis
			Combat.AirLockVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
			Combat.AirLockVelocity.MaxAxesForce = vector.create(0, 20000, 0)
			Combat.AirLockVelocity.VectorVelocity = vector.create(0, -1, 0)
			Combat.AirLockVelocity.Name = "AnubisAirLock"
			Combat.AirLockVelocity.Parent = Combat.LuaCharacter.RootPart

			return Combat.AirLockVelocity
		end
		
	elseif PreviousValue == 1 and CurrentValue == 0 and Combat.AirLockVelocity ~= nil then
		Combat.AirLockVelocity:Destroy()
	end
end

function Utility.SetUpTilted(Combat, State : boolean)
	if typeof(State) ~= "boolean" then
		return
	end
	
	Combat:StackState("UpTilted", State)
	Combat.LuaPlayer.Replication.Attributes:SetAttribute("UpTilted", Combat:GetRawState("UpTilted").Value)
end

return Utility