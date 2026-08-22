local TweenService = game:GetService("TweenService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerStorage.serverCombat.Attacks.BaseAttack )
local VelocityUtil = require( ReplicatedStorage.Shared.Game.Velocity.VelocityUtil )
local Utility = require( ReplicatedStorage.Shared.Utilities.Utility )

local Destruction = require(ServerScriptService.Modules.Destruction)

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)


----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(50)

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(15)
		
		self.Combat:TimesSpeed(50)
		self.Combat:StackState("Attacking", false)
	end)

	--self.Thread.Job:Task(self.Animations.Windup.Ended:Connect(function()
	--	self:Close()
	--end))

	local VelocityObject = self.Combat:Velocity()
	VelocityObject.Settings.Duration = 0.95
	VelocityObject.Settings.RemoveTime = 0.95
	VelocityObject.Settings.MaxForce = Vector3.one * 40000000
	VelocityObject.Settings.Controllable = true
	VelocityObject.Settings.Z = 0
	VelocityObject.Settings.Y = 150
	
	self.Thread.Job:Task(VelocityObject)

	--local FallVelocityObject = self.Combat:Velocity()
	--FallVelocityObject.Settings.MaxForce = Vector3.one * 80000000
	--FallVelocityObject.Settings.Controllable = true
	----FallVelocityObject.Settings.Z = 200 -- u can edit this value and it'll work oh ight
	----FallVelocityObject.Settings.Y = -200

	--FallVelocityObject.Settings.Z = 230
	--FallVelocityObject.Settings.Y = -230

	--self.Thread.Job:Task(FallVelocityObject)
	-- FallVelocityObject.Settings.NeedsVelocityAttribute = true -- fixes inf slide

	local LaunchHitbox = self:CreateHitbox(true)
	LaunchHitbox.Params.Offset = CFrame.new(0, 0, 0)
	LaunchHitbox.Params.Size = 10
	LaunchHitbox.Params.DestroyOnEndCast = false
	
	LaunchHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			BreakBlock = true,
			Ragdoll = 2,
			Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 75 + Vector3.yAxis * 50, 0.1},
			Damage = 5
		})
	end)


	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("launch"):Connect(function()
		VelocityObject:Fire()
		LaunchHitbox:Detect()
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("startloop"):Connect(function()
		self.Animations.Windup:Stop(0)
		self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())

		if VelocityObject then
			VelocityObject:Destroy()
		end 
		
		if self.LuaPlayer.IsNPC then
			local VelocityObject = self.Combat:Velocity()
			VelocityObject.Settings.Duration = 0.4
			VelocityObject.Settings.RemoveTime = 0.35
			VelocityObject.Settings.MaxForce = Vector3.one * 125000
			VelocityObject.Settings.Controllable = false
			VelocityObject.Settings.Velocity = self.LuaCharacter.RootPart.CFrame:VectorToObjectSpace(Vector3.new(0, -300, 300));
			VelocityObject.Settings.FixScale = true;
			VelocityObject:Fire();
		end;
		
		local SlamHitbox = self:CreateHitbox(true)
		SlamHitbox.Params.Offset = CFrame.new(0, 0, 0)
		SlamHitbox.Params.Size = 25
		SlamHitbox.Params.DestroyOnEndCast = false

		local SlamHit = false
		
		SlamHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			SlamHit = self:Afflict(VictimLuaPlayer, {
				BreakBlock = true,
				Ragdoll = 3,
				Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 100 + Vector3.yAxis * 75, 0.1},
				Damage = 20
			})
		end)

		local Root : BasePart = self.Combat:GetSimulatedRoot()
		local OriginCF : CFrame = Root.CFrame
		local Origin : Vector3 = OriginCF.Position
		
		local Map = workspace:FindFirstChild("Map")
		local Models = workspace:FindFirstChild("Models")
		
		local MapModel = Map:FindFirstChild("Model")
		local Props = MapModel:FindFirstChild("Props")

		local Params = RaycastParams.new()
		Params.FilterType = Enum.RaycastFilterType.Exclude
		Params.FilterDescendantsInstances = {Models, Props, workspace.Visuals, workspace.Ball}

		local Raycast = workspace:Raycast(
			Origin, 
			(self.LuaCharacter.RootPart.CFrame * CFrame.Angles(math.rad(45), 0, 0)).UpVector * -1000,
			Params
		)
	
		if Raycast then
			local Studs = 450
			local Distance = (Origin - Raycast.Position).Magnitude
			local Duration = math.clamp(Distance / Studs, 0.05, 0.5)
			
			local CF = CFrame.lookAlong(Raycast.Position, OriginCF.LookVector)
			self:FireReliableVFX("Invincible/Death Leap", "Loop", self.LuaCharacter.Model, CF, Duration)

			local Landed = false
			
			task.spawn(function()
				while not Landed do
					self.Combat.Hitbox:SphereDestruction(Root.Position, 30, 10, nil, {
						dont_create_debris = true
					})

					task.wait(0.05)
				end
			end)

			self.Thread.Job:Task(task.delay(Duration, function()
				Landed = true
				
				SlamHitbox.Adornee = Raycast.Position
				SlamHitbox:Detect()
				
				local Rnd = Random.new();

				self.Combat.Hitbox:CreateHavocReplicated({
					parameters = {
						origin = SlamHitbox:GetCFrame(),
						shape = "Sphere", 
						radius = 13,
						block_size = 7,
					},
					debris = {
						scale = 0.9,
						radius = 40,
						velocity = function(part)
							return Rnd:NextUnitVector() * 45 + Vector3.yAxis * Rnd:NextNumber(60, 100);
						end,
					},
				});
				
				self.Combat.Hitbox:SphereDestruction(Raycast.Position, 15, 8)

				self.LuaCharacter.RootPart.AssemblyLinearVelocity = Vector3.zero
				self.LuaCharacter.RootPart.AssemblyAngularVelocity = Vector3.zero

				self.Animations.Slam:Play(0)
				self:FireReliableVFX("Invincible/Death Leap", "Slam", self.LuaCharacter.Model, CF)
				
				if SlamHit then
					self.Combat:StackState("Attacking", true, 0.6)
				end
				
				task.wait(SlamHit and 0.6 or 1.5) -- FUCK THIS MOVE ONG

				self.Animations.Slam:Stop(0.25) 
				self:Close()
			end))
			
			self.Thread.OnClosed:Connect(function()
				Landed = true
			end)
		else
			self:Close()
		end

		--local Elapsed = 0

		--local FallHitbox = self:CreateHitbox(true)
		--SlamHitbox.Params.Offset = CFrame.new(0, -20, 20)
		--SlamHitbox.Params.Size = 30
		--SlamHitbox.Params.DestroyOnEndCast = false

		--local KickDownConnection; KickDownConnection = self.Thread.Job:Task(RunService.PostSimulation:Connect(function(Delta)
		--	--Elapsed += Delta

		--	--local GrowthZ = math.sin(Elapsed * 300)
		--	--local GrowthY = math.sin(Elapsed * 300) -- i dont think whatever im doing here is right

		--	--FallVelocityObject.Settings.Z = math.clamp(FallVelocityObject.Settings.Z ^ 1.05, 0, 200)
		--	--FallVelocityObject.Settings.Y = math.clamp(FallVelocityObject.Settings.Y ^ 1.05, -200, 0)

		--	--print(math.round(FallVelocityObject.Settings.Z))

		--	local SimulatedRoot = self.Combat:GetSimulatedRoot()

		--	--FallHitbox:Detect()
		--	--self.Combat.Hitbox:Destruction(FallHitbox.Params.Offset, Vector3.new(30,30,30), 16)

		--	local Raycast = workspace:Raycast(
		--		self.LuaCharacter.RootPart.Position, 
		--		(self.LuaCharacter.RootPart.CFrame * CFrame.Angles(math.rad(50), 0, 0)).UpVector * -60,
		--		Utility.VisualParams
		--	)

		--	--local Raycast = workspace:Raycast(
		--	--	SimulatedRoot.Position, 
		--	--	Vector3.new(0, -8, 0),
		--	--	Utility.VisualParams
		--	--)

		--	if Raycast and not Raycast.Instance.Parent:GetAttribute("Destructed") then
		--		local Success, Destructible = Destruction.CanBeDestructed(Raycast.Instance, 3)

		--		if Success then
		--			Destruction.DestroyObject(Destructible)
		--		else
		--			KickDownConnection:Disconnect()
		--			SlamHitbox.Adornee = Raycast.Position

		--			SlamHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		--				local VictimLuaCharacter = VictimLuaPlayer.Character
		--				local VictimCombat = VictimLuaCharacter.Combat

		--				local Validated = self:Afflict(VictimLuaPlayer, {
		--					BreakBlock = true,
		--					Ragdoll = 3,
		--					Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 80 + Vector3.yAxis * 75, 0.1},
		--					Damage = 30
		--				})
		--			end)

		--			SlamHitbox:Detect()
		--			self.Combat.Hitbox:Destruction(SlamHitbox.Params.Offset, Vector3.one * 25, 8)

		--			if not self.DropkickHit and not self.Thread.Closed then
		--				-- self.LuaCharacter:Anchor(true)

		--				if FallVelocityObject then
		--					FallVelocityObject:Destroy()
		--				end

		--				self.LuaCharacter.RootPart.AssemblyLinearVelocity = Vector3.zero
		--				self.LuaCharacter.RootPart.AssemblyAngularVelocity = Vector3.zero

		--				--self.Thread.Job:Task(RunService.PostSimulation:Connect(function()
		--				--	self.LuaCharacter.RootPart.AssemblyLinearVelocity = Vector3.zero
		--				--	self.LuaCharacter.RootPart.AssemblyAngularVelocity = Vector3.zero
		--				--end))

		--				--self.Thread.OnClosed:Connect(function()
		--				--	self.LuaCharacter:Anchor(false)
		--				--end)

		--				self.Animations.Loop:Stop(0)
		--				self.Animations.Slam:Play(0)

		--				self:FireReliableVFX("Invincible/Death Leap", "Slam", self.LuaCharacter.Model)
		--			end
		--		end
		--	end
		--end))
	end))

	self:FireReliableVFX("Invincible/Death Leap", "Start", self.LuaCharacter.Model)
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack