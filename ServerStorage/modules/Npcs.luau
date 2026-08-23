local ServerScriptService = game:GetService("ServerScriptService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local ServerStorage = game:GetService("ServerStorage")
local Job = require( replicatedStorage.modules.shared.Utilities.Job )


local Player = require( ServerStorage.modules.Player )
local LuaPlayerList = require( ServerStorage.modules.LuaPlayerList )

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
	
	-- health is the humanoid's own bar now; the billboard above a dummy says
	-- whether it is stunned, nothing else
	LuaCharacter.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	LuaCharacter.Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn

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
		local Indicator = NewJob:Task(script.stunIndicator:Clone())
		local Light = Indicator.stunLight

		local function ShowStun(Stunned : boolean)
			if (Indicator.Parent == nil) then return end

			Light.BackgroundColor3 = Stunned and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
			Light.smile.Text = Stunned and ":(" or ":)"
		end

		ShowStun(LuaCharacter.Combat:GetState("Stunned") == true)
		Indicator.Parent = LuaCharacter.RootPart

		NewJob:Task(LuaCharacter.Combat:GetStateChanged("Stunned"):Connect(ShowStun))
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