local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Job = require( ReplicatedStorage.Shared.Utilities.Job )

local Utility = require( ReplicatedStorage.Shared.Utilities.Utility )

local Player = require( ServerScriptService.Modules.Player )
local LuaPlayerList = require( ServerScriptService.Modules.LuaPlayerList )

local Npcs = {}
Npcs.List = {}

function Npcs.Add(NPC : Model)
	local Clone = NPC:Clone()
	
	local NewJob = Job.new()
	local LuaPlayer = Player.new(NPC)
	
	LuaPlayerList.Add(LuaPlayer)
	Npcs.List[NPC] = NewJob
	
	NewJob:Task(NPC.AncestryChanged:Connect(function(_, Parent)
		if (Parent == nil) then
			Npcs.Remove(NPC)
		end
	end))
	
	NewJob:Task(function()
		LuaPlayerList.Remove(LuaPlayer)
		LuaPlayer:Destroy()
	end)
	
	local LuaCharacter : {} = LuaPlayer.Character
	
	LuaCharacter.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	LuaCharacter.Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff

	LuaCharacter.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	
	LuaCharacter.Humanoid.StateChanged:Connect(function(_, NewState)
		if NewState == Enum.HumanoidStateType.FallingDown then
			LuaCharacter.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end)
	
	local MassProperties = LuaCharacter.RootPart.CurrentPhysicalProperties
	
	local function FixCenter()
		LuaCharacter.RootPart.CustomPhysicalProperties = PhysicalProperties.new(
			MassProperties.Density - 0.01, 
			MassProperties.Friction, 
			MassProperties.Elasticity, 
			MassProperties.FrictionWeight,
			MassProperties.ElasticityWeight
		)

		task.wait()

		LuaCharacter.RootPart.CustomPhysicalProperties = MassProperties
	end
	
	LuaCharacter.Model.DescendantAdded:Connect(FixCenter)
	LuaCharacter.Model.DescendantRemoving:Connect(FixCenter)
	
	LuaCharacter:SetOwnership(nil)
	
	if not NPC:GetAttribute("DontAddHealthUI") then
		local Health = NewJob:Task(script.Health:Clone())
		Health.Parent = NPC.Head

		NewJob:Task(LuaCharacter.Combat:GetStateChanged("Stunned"):Connect(function(Value : boolean)
			if (Health ~= nil and Health.Parent ~= nil) then
				Health.Label.TextColor3 = Value and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 255)
			end
		end))

		local function UpdateHealth(NewHealth : number)
			if (Health ~= nil and Health.Parent ~= nil) then
				Health.Label.Text = Utility.DecimalRound(math.max(0, NewHealth), 3) .. "%"
			end
		end

		UpdateHealth(LuaCharacter.Humanoid.Health)
		NewJob:Task(LuaCharacter.Humanoid.HealthChanged:Connect(UpdateHealth))
	end
	
	if not NPC:GetAttribute("DontRespawn") then
		local Parent = NPC.Parent

		NewJob:Task(LuaCharacter.OnRespawnTimerCompleted:Connect(function()
			Clone.Parent = Parent
			NPC:Destroy()
		end))

		NewJob:Task(LuaCharacter.OnHumanoidDied:Once(function()
			Parent = NPC.Parent
		end))
	else
		NewJob:Task(LuaCharacter.OnRespawnTimerCompleted:Connect(function()
			Npcs.Remove(NPC)
			NPC:Destroy()
		end))
	end
	
	task.wait()
	
	local Module = NPC:FindFirstChild("NpcHandler")
	
	if Module then
		local Handler = require(Module)
		local Cleanup = task.spawn(Handler, LuaPlayer, NewJob)
		NewJob:Task(Cleanup)
	end
end

function Npcs.Remove(NPC : Model)
	if Npcs.List[NPC] then
		Npcs.List[NPC]:Destroy()
		Npcs.List[NPC] = nil
	end
end

for _, NPC in ipairs(CollectionService:GetTagged("NPC")) do
	Npcs.Add(NPC)
end

CollectionService:GetInstanceAddedSignal("NPC"):Connect(Npcs.Add)
CollectionService:GetInstanceRemovedSignal("NPC"):Connect(Npcs.Remove)

return Npcs