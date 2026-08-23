local replicatedStorage = game:GetService("ReplicatedStorage")

local network = require( replicatedStorage.modules.network )
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")


----------------------------------------------------------------------------------



local Shared = replicatedStorage.modules.shared
local SharedUtilities = Shared.Utilities

local Animations = replicatedStorage.Animations

----------------------------------------------------------------------------------

local VaultHandler = {}
VaultHandler.__index = VaultHandler	

local Vault = require( replicatedStorage.modules.client.replication.VFX.Global.Vault )
local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )

----------------------------------------------------------------------------------

function VaultHandler:OnHumanoidLoaded()
	for _, Animation : Animation in self.Animations do
		Animation:Destroy()
	end

	table.clear(self.Animations)

	local Animator : Animator = self.LuaCharacter.Animator

	for _, Animation : Animation in ipairs(Animations.ClientActions[script.Name]:GetChildren()) do
		if Animation:IsA("Animation") then
			self.Animations[Animation.Name] = Animator:LoadAnimation(Animation)
			self.Animations[Animation.Name].Priority = Enum.AnimationPriority.Movement
		end
	end
end


function VaultHandler:_Init()
	RunService:BindToRenderStep("Vaulting", Enum.RenderPriority.Camera.Value + 3, function(Delta)
		if not self.LuaCharacter.HumanoidAlive then return end

		local Moving = self.LuaCharacter:CheckIfMovingForward() and not self.LuaCharacter:IsFlyingOrSitting()
		self.VaultingUpdate += Delta

		if (Moving and self.VaultingUpdate >= self.VaultingUpdateIncrement) then
			self.VaultingUpdate = 0
			self:Cast()
		end
	end)
end


function VaultHandler:Velocity(ChosenZ : number, ChosenY : number)
	local RootPart : BasePart = self.LuaCharacter.RootPart
	
	--local OldVaultVelocity = RootPart:FindFirstChildOfClass("BodyVelocity")

	--if (OldVaultVelocity ~= nil and OldVaultVelocity:HasTag("Vault")) then
	--	OldVaultVelocity:Destroy()
	--end
	
	local Velocity = self.Combat:CreateBodyVelocity()
	if (Velocity == nil) then return end
	
	Velocity:AddTag("Vault")
	Velocity.MaxForce = Vector3.one * 30000

	local ForceValueBeforeVault = math.max(0, -RootPart.CFrame:VectorToObjectSpace(RootPart.AssemblyLinearVelocity).Z)

	local Connection : RBXScriptConnection = nil Connection = RunService.PreSimulation:Connect(function()
		if not Velocity:IsDescendantOf(game) then
			return Connection:Disconnect()
		end

		ChosenY -= 1
		Velocity.Velocity = (RootPart.CFrame.LookVector * (ChosenZ + ForceValueBeforeVault) + Vector3.yAxis * ChosenY)
	end)

	Velocity.Parent = RootPart
	task.delay(0.125, Velocity.Destroy, Velocity)
end


function VaultHandler:CanActivate()
	return 
		not self.Combat:GetState("Stunned") and 
		not self.Combat:GetState("Ragdolled") and 
		not self.Combat:GetState("Attacking") and
		not self.Combat:GetState("Dashing") and
		not self.Combat:GetState("Blocking") and 
		not self.Combat:GetState("M1ing") and 
		not self.Combat:GetState("Emoting") and 
		not workspace:GetAttribute("IsRankedLobby") and
		not self.Vaulting and not self.Combat.ClientHandlers.WallJump.WallJumping
		and not self.Combat.ClientHandlers.Roll.Rolling
end


function VaultHandler:RaycastForLedge(Raycast: RaycastResult, Offset: Vector3)
	local Size : Vector3 = Raycast.Instance.CFrame:VectorToWorldSpace(Raycast.Instance.Size)
	self.LedgeParams.FilterDescendantsInstances = {Raycast.Instance}

	local LedgeOrigin = (Raycast.Position + (Size * Vector3.yAxis + Offset) - Raycast.Normal * 0.25);
	local LedgeRaycast = workspace:Raycast(LedgeOrigin, (-Size * Vector3.yAxis * 2), self.LedgeParams)

	local Bounds = workspace:GetPartBoundsInRadius(LedgeOrigin, 0.25)

	if #Bounds ~= 0 then
		return self:RaycastForLedge(Raycast, Offset + Vector3.yAxis * 4)
	end
	
	return LedgeRaycast;
end

function VaultHandler:AttachmentDebug(Position : Vector3)
	local Attachment = Instance.new("Attachment")
	Attachment.WorldPosition = Position
	Attachment.Visible = true
	Attachment.Parent = workspace.Terrain

	task.delay(1, Attachment.Destroy, Attachment)
end


function VaultHandler:Cast()
	if not self:CanActivate() then return end

	local Humanoid : Humanoid = self.LuaCharacter.Humanoid
	local RootPart : BasePart = self.LuaCharacter.RootPart

	local Offset = (RootPart.CFrame * CFrame.new(0, -0.5, (RootPart.CFrame:VectorToObjectSpace(RootPart.AssemblyLinearVelocity).Z / 15) + 0.5))
	local Raycast = workspace:Raycast(Offset.Position, Offset.LookVector * 4, Utility.VisualParams)

	if (Raycast ~= nil and self.LedgeCooldowns[Raycast.Instance] == nil) then
		--self:AttachmentDebug(Raycast.Position)

		local LedgeRaycast = self:RaycastForLedge(Raycast, Vector3.zero)
		
		if (LedgeRaycast ~= nil and LedgeRaycast.Instance.CanCollide and not Raycast.Instance:HasTag("CannotVaultOn")) then
			--self:AttachmentDebug(LedgeRaycast.Position)
			
			local Angle = math.deg(LedgeRaycast.Normal:Angle(Raycast.Normal)) -- angle so that wedges or slopes are not attempted to be vaulted
			local DistanceFromLedge = (LedgeRaycast.Position - Raycast.Position).Magnitude

			if ((Raycast.Instance.Name ~= "Rock" and Angle < 50) or DistanceFromLedge > 4) then return end
			
			self.Vaulting = true
			self.LedgeCooldowns[LedgeRaycast.Instance] = true
			
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

			network.useMove.send({ move = "Vault", state = true })
			
			task.delay(0.5, function()
				self.Vaulting = false
				
				if self:CanActivate() then
					Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
					Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
				end
				
				self.LedgeCooldowns[LedgeRaycast.Instance] = nil
			end)
			
			self.Combat:ResetJumpFatigue()
		
			if DistanceFromLedge < 2 then
				self.Animations.Vault1:Play()
				task.delay(0.075, self.Velocity, self, 25, 25)
			else
				self.Animations.Vault2:Play()
				self.Animations.Vault2.TimePosition = 0.1
				task.delay(0.075, self.Velocity, self, 15, 35 + (DistanceFromLedge * 2))
			end
			
			--local RNG = math.random(1, 2)

			--local Animation = self.Animations["Vault" .. RNG]
			--Animation:Play(0.025, 1, 1.15)

			--if RNG == 2 then
			--	Animation.TimePosition = 0.1
			--end
			
			task.spawn(Vault.SFX, RootPart, true)
		end
	end
end

----------------------------------------------------------------------------------

function VaultHandler.new(Combat)
	local self = setmetatable({}, VaultHandler)

	self.Combat = Combat
	self.LuaCharacter = Combat.LuaCharacter
	self.LuaPlayer = Combat.LuaCharacter.LuaPlayer

	self.Animations = {}

	self.VaultingUpdate = 0
	self.VaultingUpdateIncrement = 0.05

	self.LedgeCooldowns = {};

	self.LedgeParams = RaycastParams.new();
	self.LedgeParams.FilterType = Enum.RaycastFilterType.Include;

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(VaultHandler)

return VaultHandler