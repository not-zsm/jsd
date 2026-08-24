local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local ServerStorage = game:GetService("ServerStorage")
local Remotes = replicatedStorage.Remotes
local HotbarRemotes = Remotes.Combat.UI.Hotbar

----------------------------------------------------------------------------------

local BaseAttack = require( ServerStorage.serverCombat.Attacks.BaseAttack )
local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )

local Destruction = require( ServerStorage.modules.Destruction )

----------------------------------------------------------------------------------

local RockThrowProjectileData = require( replicatedStorage.modules.client.replication.VFX.Kratos["Nature's Arsenal"]["Rock Throw"].ProjectileData)

----------------------------------------------------------------------------------
local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Rock()
	self.Combat:StackState("Attacking", true)
	self.Combat:StackState("HitboxImmunity", true)
	self.Combat:DivideSpeed(100)

	local Weapons = self.Combat.Attacks.Weapons

	if Weapons then
		Weapons:SetCurrent("Fists")
	end
	
	--local Rock = replicatedStorage.modules.client.replication.VFX.Kratos["Rock Throw"].Rock2:Clone()
	
	--local Weld = Instance.new("Motor6D", Rock)
	--Weld.Part0 = self.LuaCharacter.Torso
	--Weld.Part1 = Rock.RootPart
	--Weld.C0 = CFrame.Angles(0, math.rad(-90), 0)
	
	--Rock.Parent = self.LuaCharacter.Torso

	--local Animation = Rock.AnimationController.Animator:LoadAnimation(replicatedStorage.Animations.Attacks.Kratos["Rock Throw"].Windup)
	--Animation:Play(0)
	
	--self.Thread.Job:Task(Rock)
	
	self.Thread.CancelJob:Task(self:CreateMoveSFX("Kratos", "Nature's Arsenal", "RockThrowSFX"))

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(12)
		self.Combat:TimesSpeed(100)
		
		self.Combat.Mouse:EndRequesting()

		self.Combat:StackState("Attacking", false)
		self.Combat:StackState("HitboxImmunity", false)
	end)
	
	self.Thread.Job:Task(task.delay(2.5, function()
		self.Combat.Mouse:BeginRequesting(nil, "Default")
	end))
	
	self.Thread.Job:Task(self.Animations.Rock:GetMarkerReachedSignal("pull"):Once(function()
		local Hitbox = self:CreateHitbox(true);
		Hitbox.Params.Size = 7
		Hitbox.Params.Offset = CFrame.new(3.817, 0, 0.464)

		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			self:Afflict(VictimLuaPlayer, {
				Damage = 7.5,
				Ragdoll = 2,
				Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 30 + Vector3.yAxis * 15, 0.1}
			})
		end)

		Hitbox:Detect()
		
		self.Combat.Hitbox:SphereDestruction(Hitbox.Adornee.Position, Hitbox.Params.Size, 2)
	end))

	self.Thread.Job:Task(self.Animations.Rock:GetMarkerReachedSignal("throw"):Once(function()
		--Rock:Destroy()
		
		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 0.675
		VelocityObject.Settings.RemoveTime = 0.675
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Z = 50
		VelocityObject:Fire()
		
		local MaxDistance = RockThrowProjectileData.MaxDistance
		local StartFallingAt = RockThrowProjectileData.StartFallingAt
		local Gravity = RockThrowProjectileData.Gravity

		local Root : BasePart = self.Combat:GetSimulatedRoot()
		local CF = CFrame.lookAlong(Root.Position, self.Combat.Mouse.Hit.LookVector)

		local StartCF = CF * CFrame.new(0, 1.5, -3) * CFrame.Angles(0, math.pi, 0)
		local Velocity : Vector3 = CF.LookVector * 175 + Vector3.yAxis * 25

		self.Thread.Job:Task(VelocityObject)

		self.RockCF = StartCF

		--local Camera = Instance.new("Camera")
		--Camera.Name = "RockCamera"
		--Camera.Parent = workspace

		--local FakeRock = Instance.new("Part")
		--FakeRock.Anchored = true
		--FakeRock.CanCollide = false
		--FakeRock.Transparency = 1
		--FakeRock.Size = Vector3.one
		--FakeRock.Parent = Camera

		self.RockProjectileHitbox = self:CreateHitbox(false, true);
		self.RockProjectileHitbox.Adornee = self.RockCF
		self.RockProjectileHitbox.Params.Offset = CFrame.identity
		self.RockProjectileHitbox.Params.Size = Vector3.new(5.796, 4.939, 7.122) * 1.2

		local PersonHit = nil
		
		self.RockProjectileHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			local Validated = self:Afflict(VictimLuaPlayer, {
				TriggerActiveCounterOverOrEqualLevel = -1,
				BreakBlock = true,
				Projectile = true,
				Ragdoll = 2,
				Velocity = {(VictimLuaPlayer.Character.RootPart.Position - self.RockCF.Position).Unit * 70 + Vector3.yAxis * 20, 0.03},
				Damage = 25
			})
			
			if Validated then
				PersonHit = VictimLuaPlayer
			end
		end)
		
		local function Hit(NewRockPosition : Vector3, RaycastPosition : Vector3, RaycastNormal : Vector3)
			self:FireReliableVFX("Kratos/Nature's Arsenal", "RockHit", self.LuaCharacter.Model, RaycastPosition, RaycastNormal)
			
			task.spawn(function() -- cant have this erroring
				local Hitbox = self:CreateHitbox(true);
				Hitbox.Adornee = RaycastPosition
				Hitbox.Params.Size = 17.5

				Hitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
					self:Afflict(NewVictimLuaPlayer, {
						DontCheckBlock = true,
						Damage = 10,
						Ragdoll = 2,
						Velocity = {(NewVictimLuaPlayer.Character.RootPart.Position - NewRockPosition).Unit * 30 + Vector3.yAxis * 50, 0.1}
					})
				end)

				Hitbox:Detect()

				self.Combat.Hitbox:SphereDestruction(Hitbox.Adornee, Hitbox.Params.Size - 3, 2)
			end)
		end

		@native local function RunKratosRockProjectile()
			self.RockProjectileConnection = self.Job:Task(RunService.PreSimulation:Connect(function(Delta : number)
				local RockCF : CFrame = self.RockCF
				local RockPosition : Vector3 =  RockCF.Position

				local DistanceFromStart : number = (StartCF.Position - RockPosition).Magnitude

				if DistanceFromStart > MaxDistance then
					return self:StopProjectileRunner()
				end

				local NewRockPosition = RockPosition + Velocity.Unit * (Velocity.Magnitude * Delta)
				local NewCF = CFrame.lookAlong(NewRockPosition, RockCF.LookVector)
				
				self.RockProjectileHitbox.Adornee = NewCF
				--FakeRock.CFrame = NewCF
				
				self.RockProjectileHitbox:Detect()

				if PersonHit then
					task.spawn(Hit, NewRockPosition, PersonHit.Character.RootPart.Position, Vector3.yAxis)
					return self:StopProjectileRunner()
				end

				local Raycast = workspace:Raycast(RockPosition, (NewRockPosition - RockPosition) * 1.5, Utility.VisualParams)

				if Raycast and Raycast.Instance.CanCollide then
					local Destructible = Destruction.Destruct(Raycast.Instance, 8)

					if not (Destructible and Destructible:GetAttribute("Destructed")) then
						task.spawn(Hit, NewRockPosition, Raycast.Position, Raycast.Normal)
						return self:StopProjectileRunner()
					end
				end
				
				if DistanceFromStart > StartFallingAt then
					Velocity += Gravity * Delta
				end
				
				Velocity += Gravity * Delta
				self.RockCF = RockCF + Velocity * Delta
			end))
		end

		RunKratosRockProjectile()
		self:FireReliableVFX("Kratos/Nature's Arsenal", "RockThrow", self.LuaCharacter.Model, StartCF, Velocity)
	end))

	self.Animations.Rock:Play()
	self:FireReliableVFX("Kratos/Nature's Arsenal", "RockStart", self.LuaCharacter.Model)--, Rock)

	task.wait(4)

	self:Close()
end

function Attack:Tree(Model : Model)
	local Weapons = self.Combat.Attacks.Weapons

	if Weapons then
		Weapons:SetCurrent("Fists")
	end

	self.Combat:StackState("Attacking", true)
	self.Combat:StackState("HitboxImmunity", true)
	self.Combat:DivideSpeed(100)

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(12)
		self.Combat:TimesSpeed(100)

		self.Combat:StackState("Attacking", false)
		self.Combat:StackState("HitboxImmunity", false)
	end)

	self.Thread.Job:Task(self.Animations.Tree:GetMarkerReachedSignal("hit"):Once(function()
		local Hitbox = self:CreateHitbox(true);
		Hitbox.Params.Offset = CFrame.new(0, 2, -12)
		Hitbox.Params.Size = 25

		Hitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
			local Validated = self:Afflict(NewVictimLuaPlayer, {
				DontCheckBlock = true,
				Damage = 40,
				Ragdoll = 2,
				Velocity = {self.Combat:CalculateUnitDifference(NewVictimLuaPlayer) * 50 + Vector3.yAxis * 75, 0.05}
			})
			
			if Validated then
				self:FireReliableVFX("Kratos/Nature's Arsenal", "TreeHit", NewVictimLuaPlayer.Character.Model)
			end
		end)

		Hitbox:Detect()

		self.Combat.Hitbox:SphereDestruction(Hitbox.Adornee.Position, Hitbox.Params.Size, 3)
	end))
	
	self.Animations.Tree:Play(0, 1, 1.15)
	self:FireReliableVFX("Kratos/Nature's Arsenal", "TreeStart", self.LuaCharacter.Model)
	Destruction.Destruct(Model, -1, "Nature's Arsenal")
	
	task.wait(2)

	self:Close()
end

--function Attack:Pillar(Model : Model)
--	local Weapons = self.Combat.Attacks.Weapons

--	if Weapons then
--		Weapons:SetCurrent("Fists")
--	end

--	self.Combat:StackState("Attacking", true)
--	self.Combat:StackState("HitboxImmunity", true)
--	self.Combat:DivideSpeed(100)
	
--	self.Thread.OnClosed:Connect(function()
--		self:AddCooldown(12)
--		self.Combat:TimesSpeed(100)

--		self.Combat:StackState("Attacking", false)
--		self.Combat:StackState("HitboxImmunity", false)
--	end)
	
--	self.Thread.Job:Task(self.Animations.Pillar:GetMarkerReachedSignal("hit"):Once(function()
--		Destruction.Destruct(Model, -1, "Nature's Arsenal")
--	end))

--	self.Animations.Pillar:Play()
	
--	task.wait(1.5)
	
--	self:Close()
--end

function Attack:Activate()
	local Root : BasePart = self.Combat:GetSimulatedRoot()
	local Position = (Root.CFrame * CFrame.new(0, 0, -5)).Position
	
	local Bounds = workspace:GetPartBoundsInRadius(Position, 6.5, Utility.DestructiblesParams)
	
	if #Bounds == 0 then
		self:Rock()
	else
		local Success = false
		
		table.sort(Bounds, function(A : BasePart, B : BasePart)
			local ADifference = (A.Position - Position)
			local BDifference = (B.Position - Position)

			return ADifference.Magnitude < BDifference.Magnitude
		end)
		
		for _, Hit in Bounds do
			local Model = Hit:FindFirstAncestorOfClass("Model")

			if not Model or not Model:HasTag("DestructibleModel") then
				continue
			end
			
			if Model:GetAttribute("Destructed") then 
				continue 
			end
			
			local Name : string? = Model:GetAttribute("DestructibleName")

			if (Name) then
				
				if table.find(self.NearNames, Name) then
					Success = true
					self[Name](self, Model)
				end

				break
			end
		end
		
		if not Success then
			self:Rock()
		end
	end
end

function Attack:StopProjectileRunner()
	if self.RockProjectileConnection and self.RockProjectileConnection.Connected then
		self.RockProjectileConnection:Disconnect()
	end

	if self.RockProjectileHitbox then
		self.RockProjectileHitbox:Destroy()
	end
	
	self:FireReliableVFX("Kratos/Nature's Arsenal", "RockStop", self.LuaCharacter.Model)

	self.RockProjectileConnection = nil
	self.RockProjectileHitbox = nil
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self.NearNames = {"Tree"}--, "Pillar"}
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack