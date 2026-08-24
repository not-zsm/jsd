local Players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")

local network = require( replicatedStorage.modules.network )
local ContentProvider = game:GetService("ContentProvider")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")

----------------------------------------------------------------------------------



local VFX = script.VFX

----------------------------------------------------------------------------------

local Replication = {}
Replication.__index = Replication

local EffectUtility = require( script.EffectUtility )

local ReplicationPart = require( replicatedStorage.modules.shared.Utilities.ReplicationPart )
local Instances = require( replicatedStorage.packages.Instances )
local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )
local Job = require( replicatedStorage.modules.shared.Utilities.Job )

local CharacterTransparency = require( script.Global.CharacterTransparency )

local GrabHandler = require(script.GrabHandler)
local Projectiles = require(script.Projectiles)
local Destruction = require( script.Destruction )
local CustomDestruction = require( script.Destruction.Custom )

task.spawn(require, script.Maps)

----------------------------------------------------------------------------------

function Replication:_Init()
	network.grabSet.listen(function(data)
		GrabHandler.Set(data.part, data.boundTo, data.offset, data.preset)
	end)

	network.grabSetOffset.listen(function(data)
		GrabHandler.SetOffset(data.part, data.offset)
	end)

	network.grabSetBound.listen(function(data)
		GrabHandler.SetBound(data.part, data.boundTo)
	end)

	network.grabDetach.listen(GrabHandler.Remove)

	network.projectileCreate.listen(function(data)
		Projectiles.Create(data.config, data.origin, data.direction)
	end)

	network.projectileUpdate.listen(function(data)
		Projectiles.Update(data.config, data.position, data.direction)
	end)

	network.collabProxy.listen(function(data)
		self:CollabProxy(data.player, data.prompt)
	end)

	network.collabJoined.listen(function(Prompt)
		self:JoinedCollabEmote(Prompt)
	end)

	network.destruction.listen(function(data)
		self:Destruct(data.part, data.effect)
	end)

	self:ConnectToVFXRemotes()
end

function Replication:CollabProxy(PlayerDoingEmote : Player, Prompt : ProximityPrompt)
	if not (Prompt ~= nil and Prompt.Parent ~= nil) then return end
	
	if (PlayerDoingEmote ~= nil and PlayerDoingEmote.Parent ~= nil) then
		Prompt.Enabled = (PlayerDoingEmote ~= self.LuaPlayer.Player)
	end
end

function Replication:JoinedCollabEmote(Prompt : ProximityPrompt)
	if (Prompt ~= nil and Prompt.Parent ~= nil) then
		Prompt.Enabled = false
	end
end

function Replication:Destruct(Object : (BasePart | Model), CustomEffect : string)
	if (Object == nil or Object.Parent == nil or self.Destructed[Object] == true) then return end

	local Type = Object:GetAttribute("DestructibleName")

	local function CallDestructionVisuals(WantedObject : (BasePart | Model))
		if (CustomEffect ~= nil and CustomEffect == "None") then
			return
		end

		if (CustomEffect and CustomDestruction[CustomEffect]) then
			task.spawn(CustomDestruction[CustomEffect], WantedObject) 
		else
			local IsBasePart = WantedObject:IsA("BasePart")

			if IsBasePart then
				if (WantedObject.Size.Y > 7) then
					EffectUtility.RaycastCraterSmoke("Normal", WantedObject.Position, Vector3.yAxis * -10)
				else
					EffectUtility.RaycastCraterSmoke("Small", WantedObject.Position, Vector3.yAxis * -10)
				end
			end

			if Type and Destruction[Type] then
				task.spawn(Destruction[Type], WantedObject) 
			end
		end
	end

	self.Destructed[Object] = true

	local VisualObject = nil
	local PivotCFrame = Object:GetPivot()

	if self.LuaPlayer.Player:DistanceFromCharacter(PivotCFrame.Position) <= ((20 * Utility.GetQuality()) ^ 1.85) then
		local IsBasePart = Object:IsA("BasePart")

		if Object:GetAttribute("DestructibleDontClone") then
			CallDestructionVisuals(Object)
		else 
			VisualObject = Object:Clone()
			VisualObject:RemoveTag("MoveWithWind")

			if not IsBasePart then
				for _, Item in ipairs(VisualObject:GetDescendants()) do
					if Item:IsA("BasePart") then
						Item:RemoveTag("MoveWithWind")
					end
				end
			end

			VisualObject.Parent = workspace.Visuals
			CallDestructionVisuals(VisualObject)

			task.delay(5, VisualObject.Destroy, VisualObject) -- fail safe
		end;
	end;

	Object:PivotTo(CFrame.new(0, 10e8, 0))

	local Connection : RBXScriptConnection; Connection = Object:GetAttributeChangedSignal("Destructed"):Connect(function()
		if not Object:GetAttribute("Destructed") then
			Connection:Disconnect()

			if (VisualObject ~= nil) then
				VisualObject:Destroy()
			end

			Object:PivotTo(PivotCFrame)
			self.Destructed[Object] = nil
		end;
	end);
end

function Replication:ConnectToVFXRemotes()
	local function Receive(data)
		local args = data.args

		if args then
			self:FireEffect(data.directory, data.fn, table.unpack(args, 1, args.n))
		else
			self:FireEffect(data.directory, data.fn)
		end
	end

	network.vfx.listen(Receive)
	network.vfxReliable.listen(Receive)
end

function Replication:FireEffect(Name : string, Function : string, ...)
	local Split = string.split(Name, "/")
	local Module = VFX

	for _, Index in ipairs(Split) do
		local LastModule = Module;
		Module = Module:FindFirstChild(Index);
		
		if not Module then
			warn(`Unable to FireEffect: {Index} does not exist under {Instances.get_directory(LastModule, VFX, "/")}`)
			break;
		end;
	end;
	
	if Module then
		local Success, Result = pcall(require, Module)

		if not Success then
			return warn(Result, Module.Name)
		end

		if RunService:IsStudio() or shared.IsTestPlace then
			local Fn = Result[Function]

			if (Fn == nil) then
				return warn(`The function {Function} does not exist in {Module.Name} module inside of {Module.Parent.Name}`)
			end

			task.spawn(Fn, ...)
		else
			if Result[Function] then
				pcall(Result[Function], ...)
			end
		end
	end
end

----------------------------------------------------------------------------------

function Replication.new(LuaPlayer)
	local self = setmetatable({}, Replication)

	self.LuaPlayer = LuaPlayer
	self.Destructed = {}

	--self.Attributes = workspace.PlayerReplication:WaitForChild(self.LuaPlayer.Player.Name, 100)

	self.Attributes = self.LuaPlayer.Player:WaitForChild("Replication", 100)
	
	return self
end

----------------------------------------------------------------------------------

table.freeze(Replication)

return Replication