local Destruction = {}

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local ServerStorage = game:GetService("ServerStorage")
local ReplicationRemotes = ReplicatedStorage.Remotes.Replication

local Utility = require( ReplicatedStorage.modules.shared.Utilities.Utility )
local LuaPlayerList = require( ServerStorage.modules.LuaPlayerList )

local AttributeListener = require( ReplicatedStorage.modules.client.replication.Global.AttributeListener )

function Destruction.Recognise(Object : (BasePart | Model)) : (Model?)
	if Object:IsA("Model") then
		return Object
	else
		local Model = Object:FindFirstAncestorOfClass("Model")

		if (Model ~= nil and Model:HasTag("DestructibleModel")) then
			return Model
		end

		return Object
	end
end
	
function Destruction.CanBeDestructed(Object : BasePart, Power : number) : (boolean, Model?)
	local Destructible = Destruction.Recognise(Object)

	local IsADestructible = if Destructible:IsA("BasePart") then Destructible:HasTag("Destructible") else true
	
	local Strength = Destructible:GetAttribute("DestructibleStrength") or 0
	local PowerOverStrength = false
	
	if Power > 0 then
		PowerOverStrength = (Power >= Strength)
	else
		PowerOverStrength = true
	end
	
	local Success = IsADestructible and not Destructible:GetAttribute("Destructed") and PowerOverStrength
	return Success, Destructible
end;

function Destruction.RestoreObject(Destructible: (Model | BasePart)): ()
	Destructible:SetAttribute("Destructed", nil)
end

function Destruction.DestroyObject(Destructible : (Model | BasePart), CustomCallback : string, Indefinite: boolean?)
	Destructible:SetAttribute("Destructed", true)
	
	if not Indefinite then
		task.delay(Utility.DestructionRespawnTime, Destruction.RestoreObject, Destructible);
	end;
	
	ReplicationRemotes.Destruction:FireAllClients(Destructible, CustomCallback)
end;

function Destruction.Destruct(Object : BasePart, Power : number, CustomCallback : string?, Indefinite: boolean?)
	local Success, Destructible = Destruction.CanBeDestructed(Object, Power or 1)

	if Success then
		Destruction.DestroyObject(Destructible, CustomCallback, Indefinite)
	end
	
	return Destructible
end

function Destruction._Destruct(Type : string, Origin : (CFrame | Vector3), Size : (Vector3 | number), Power : number, CustomCallback : string?)
	local Bounds
	
	if Type == "Box" then
		Bounds = workspace:GetPartBoundsInBox(Origin, Size, Utility.DestructiblesParams)
		
	elseif Type == "Sphere" then
		Bounds = workspace:GetPartBoundsInRadius(Origin, Size, Utility.DestructiblesParams)
	end
	
	for _, Hit in pairs(Bounds) do
		task.spawn(Destruction.Destruct, Hit, Power, CustomCallback)
	end
end

function Destruction.Detect(...)
	Destruction._Destruct("Box", ...)
end

function Destruction.SphereDetect(...)
	Destruction._Destruct("Sphere", ...)
end

ReplicationRemotes.ClientSentDestruction.OnServerEvent:Connect(function(MainPlayer, Object : BasePart)
	if (Object == nil or typeof(Object) ~= "Instance" or not Object:IsA("BasePart") or Object.Parent == nil) then return end
	
	if not MainPlayer.Character then return end
	
	local RootPart : BasePart = MainPlayer.Character.HumanoidRootPart
	local Magnitude = (Object.Position - RootPart.Position).Magnitude

	local Replication : Configuration = AttributeListener.GetReplicationFromSource(MainPlayer)
	if (Replication == nil) then return end
	
	if Replication:GetAttribute("DestructibleDestroyLoop") and Magnitude < (RootPart.AssemblyLinearVelocity.Magnitude * 3) then
		local Success, Model = Destruction.CanBeDestructed(Object, Replication:GetAttribute("DestructibleDestroyLoopPower") or 1)
		Object = Model or Object
		
		if Success then
			Object:SetAttribute("Destructed", true)

			task.delay(Utility.DestructionRespawnTime, function()
				Object:SetAttribute("Destructed", nil)
			end)

			for _, Player in Players:GetPlayers() do
				if Player ~= MainPlayer then
					ReplicationRemotes.Destruction:FireClient(Player, Object)
				end
			end
		end
	end
end)

return Destruction
