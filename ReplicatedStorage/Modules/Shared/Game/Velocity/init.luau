local Velocity = {}
Velocity.__index = Velocity

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

function Velocity:Remove()
	if self.Removed then return end

	self.Removed = true
	self.Job:Destroy()
end

function Velocity:Destroy()
	if self.Removed then return end
	
	self:Remove()
	
	if RunService:IsServer() then
		self.LuaPlayer.Replication.Attributes:SetAttribute("Velocity", nil)
	end
end

function Velocity:Create()
	if self.Removed then return end
	
	local NewBodyVelocity : BodyVelocity? = self.Combat:CreateBodyVelocity(self.Settings.Name)

	if (NewBodyVelocity ~= nil) then
		NewBodyVelocity:SetAttribute("RemoveOn", self.LuaPlayer.Player.name)
		NewBodyVelocity:AddTag("RemoveOnEvasive", true)
		NewBodyVelocity.MaxForce = self.Settings.MaxForce or Vector3.one * 80000
		
		local Start = os.clock()

		local function UpdateVelocityForServer()
			local DurationTaper = 1;

			if not self.Settings.DontScale and self.Settings.Duration then
				-- It was bugged 💔 and i cant apply the fix globally without breaking everything
				if self.Settings.FixScale then
					DurationTaper = math.max(0, 1 - (os.clock() - Start) / self.Settings.Duration)
				else
					DurationTaper = math.max(0, self.Settings.Duration - (os.clock() - Start) / self.Settings.Duration)
				end
			end

			if self.Settings.Controllable then
				if Utility.IsFacingOnAWall(self.LuaCharacter.RootPart) then
					NewBodyVelocity.Velocity = Vector3.zero
				else
					local CF : CFrame = self.LuaCharacter.RootPart.CFrame;
					local ControlledVelocity: Vector3 = self.Settings.Velocity or Vector3.zero;

					if self.Settings.X then
						ControlledVelocity += CF.RightVector * self.Settings.X
					end

					if self.Settings.Y then
						ControlledVelocity += CF.UpVector * self.Settings.Y
					end

					if self.Settings.Z then
						ControlledVelocity += CF.LookVector * self.Settings.Z
					end

					NewBodyVelocity.Velocity = ControlledVelocity * DurationTaper;
				end

			elseif self.Settings.Velocity then
				NewBodyVelocity.Velocity = self.Settings.Velocity * DurationTaper;
			end
		end;
		
		task.spawn(UpdateVelocityForServer);
		self.Job:Task(RunService.PreAnimation:Connect(UpdateVelocityForServer))

		NewBodyVelocity.Destroying:Once(function()
			self:Remove()
		end)

		self.Object = NewBodyVelocity
		NewBodyVelocity.Parent = self.LuaCharacter.RootPart
		
		self.Job:Task(NewBodyVelocity)
	end
end

function Velocity:Fire()
	if self.Removed or not self.LuaCharacter.HumanoidExists then return end

	if RunService:IsServer() then	
		if self.LuaPlayer.IsNPC then
			self:Create()
		else
			self.LuaPlayer.Remotes.Combat.Velocity:FireClient(self.LuaPlayer.Player, self.Settings)
		end
		
		self.LuaPlayer.Replication.Attributes:SetAttribute("Velocity", true)
	else
		--if not self.Settings.NeedsVelocityAttribute or self.LuaPlayer.Replication.Attributes:GetAttribute("Velocity") then
		if self.Settings.DoesntNeedVelocityAttribute or self.LuaPlayer.Replication.Attributes:GetAttribute("Velocity") then
			self:Create()

			if RunService:IsClient() then
				self.Job:Task(self.LuaPlayer.Replication.Attributes:GetAttributeChangedSignal("Velocity"):Connect(function()
					if not self.LuaPlayer.Replication.Attributes:GetAttribute("Velocity") then
						self:Remove()
					end
				end))
			end
		end
	end
	
	if self.Settings.RemoveTime then
		task.delay(self.Settings.RemoveTime, self.Remove, self)
	end
end

local Main = {}
Main.Utility = require( script.VelocityUtil )

function Main.new(Combat : {})
	local self = setmetatable({}, Velocity)
	
	self.Combat = Combat
	self.LuaCharacter = Combat.LuaCharacter
	self.LuaPlayer = Combat.LuaPlayer
	
	self.Settings = {}
	self.Job = Job.new()
	
	self.Removed = false
	
	self.Job:Task(self.LuaCharacter.OnHumanoidAvailabilityChanged:Connect(function()
		if not self.LuaCharacter.HumanoidExists then
			self:Remove()
		end
	end))
	
	--local Params = RaycastParams.new()
	--Params.FilterDescendantsInstances = {workspace.Visuals, self.LuaCharacter.Model, workspace.Projectiles}
	--Params.FilterType = Enum.RaycastFilterType.Exclude

	--self.Params = Params
	
	--if RunService:IsClient() then
	--	self.Job:Task(self.LuaPlayer.Replication.Attributes:GetAttributeChangedSignal("Velocity"):Connect(function()
	--		if not self.LuaPlayer.Replication.Attributes:GetAttribute("Velocity") then
	--			self:Remove()
	--		end
	--	end))
	--end
	
	return self
end

return Main
