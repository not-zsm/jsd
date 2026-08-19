local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService('TweenService')
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local ScreenPulse = require( ReplicatedStorage.Modules.Player.Replication.Global.ScreenPulse )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local Shockwave = require( ReplicatedStorage.Modules.Player.Replication.Global.Shockwave )

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )

local Yuki_InfinityBubble = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_InfinityBubble )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local VFX = {}

function VFX.Start(Leg : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(Leg.Position)
	if (Distance > 100) then return end

	local Trail = EffectUtility.WeldArmTrail(Leg)
	task.delay(1, Trail.Destroy, Trail)
end

function VFX.Stomp(Leg : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(Leg.Position)
	if (Distance > 100) then return end

	local RootPart : BasePart = Leg.Parent.HumanoidRootPart
	local CF = RootPart.CFrame
	
	local LegPosition = Leg.Position
	local Direction = (Vector3.yAxis * -10)
	
	coroutine.wrap(RockHandler.Crater)(LegPosition, Direction, {
		Amount = 7,
		Distance = 4,
		SizeMultiplier = 0.85,
	})

	coroutine.wrap(RockHandler.Rockst)(LegPosition, Direction, {
		Size = {0.4, 0.75},
		Count = 3,
		Velocity = 35,
	})
	
	--local _, Attachment = EffectUtility.EmitEffects(script.SFX, workspace.Terrain, CF)
	
	--TweenService:Create(Attachment, TweenInfo.new(0.44999999999999996), {
	--	WorldCFrame = CF * CFrame.new(0, 0, -50)
	--}):Play()
end

function VFX.GroundBurst(Position : CFrame, Index : number)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(Position.Position)
	if (Distance > 100) then return end
	
	if (Distance < 40) then
		CameraShake(2, 15, 0.1, 0.25, Vector3.one * 0.8)
	end
	
	local Direction = Vector3.yAxis * -10
	local Raycast = workspace:Raycast(Position.Position, Direction, Utility.VisualParams)
	
	if (Raycast ~= nil) then
		Shockwave(CFrame.new(Position.Position) * CFrame.new(0, -3, 0) * CFrame.Angles(-(math.pi / 2), 0, 0), nil, nil, Vector3.new(0.1, 17.5, 17.5))
		
		local Burst = script[Index == 1 and "BiggerBurst" or "Burst"]:Clone()
		Burst.Position = Raycast.Position
		Burst.Dustfb.Color = ColorSequence.new(Raycast.Instance.Color)
		Burst.Parent = workspace.Visuals

		--coroutine.wrap(RockHandler.Crater)(Raycast.Position, Direction, {
		--	Amount = 10,
		--	Distance = 6,
		--	SizeMultiplier = 0.95,
			
		--	Exposure = {
		--		Min = 0.5,
		--		Max = 0.6
		--	},
		--})
		
		coroutine.wrap(RockHandler.Crater)(Raycast.Position, Direction, {
			Amount = 12,
			Distance = 5,
			SizeMultiplier = 0.95,

			LookAt = {
				Min = -5,
				Max = 5
			},
			
			Exposure = {
				Min = 0.5,
				Max = 0.7
			},
		})

		coroutine.wrap(RockHandler.Rockst)(Raycast.Position, Direction, {
			Size = {0.75, 1.5},
			Count = 3,
			Velocity = 35,
		})

		EffectUtility.Emit(Burst)
	end
end

local FinisherAssets = script.Finisher
local FinisherAssetsHolder = FinisherAssets.Holder

local FinisherStuff = {
	["Hands"] = {},
	["Pulls"] = {},
	["Spins"] = {},
	["Rocks"] = {}
}

function VFX.FinisherHand(Arm : BasePart)
	if (FinisherStuff.Hands[Arm] ~= nil) then return end
	
	local Distance = Players.LocalPlayer:DistanceFromCharacter(Arm.Position)
	if (Distance > 150) then return end

	local Effect = FinisherAssetsHolder.Hand:Clone()
	Effect.Parent = Arm
	EffectUtility.Toggle(Effect, true)
	FinisherStuff.Hands[Arm] = Effect
	
	Yuki_InfinityBubble(Arm, 1, Vector3.one * 3.5, 1, CFrame.new(0, -1, 0))
end

function VFX.RemoveFinisherHand(Arm : BasePart)
	if FinisherStuff.Hands[Arm] then
		EffectUtility.Toggle(FinisherStuff.Hands[Arm], false)
		task.delay(1, FinisherStuff.Hands[Arm].Destroy, FinisherStuff.Hands[Arm])
		FinisherStuff.Hands[Arm] = nil
	end
end

function VFX.FinisherPull(RootPart : BasePart, VictimRootPart : BasePart, Distance : number)
	if (FinisherStuff.Pulls[VictimRootPart] == nil) then
		FinisherStuff.Pulls[VictimRootPart] = {}

		local Sound = FinisherAssets.Pull.stompfinisherpullloop:Clone()
		Sound.Parent = VictimRootPart
		Sound:Play()

		FinisherStuff.Pulls[VictimRootPart][Sound] = true

		for _, Attachment : Attachment in ipairs(FinisherAssetsHolder.Pull:GetChildren()) do
			local NewAttachment = Attachment:Clone()
			NewAttachment.Parent = VictimRootPart
			EffectUtility.Toggle(NewAttachment, true)
			FinisherStuff.Pulls[VictimRootPart][NewAttachment] = true
		end
	end
	
	TweenService:Create(VictimRootPart,  TweenInfo.new(Distance, Enum.EasingStyle.Linear), 
		{CFrame = RootPart.CFrame * CFrame.new(0, 0, -2.5) * CFrame.Angles(0, math.pi, 0)}
	):Play()

	if Players:GetPlayerFromCharacter(RootPart.Parent) == Players.LocalPlayer or Players:GetPlayerFromCharacter(VictimRootPart.Parent) == Players.LocalPlayer then
		Yuki_FOV.Tween(85, {0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
		
		task.delay(0.6, function()
			Yuki_FOV.Tween(70, {0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
		end)
	end
	
	if ( Players.LocalPlayer:DistanceFromCharacter(RootPart.Position) < 35) then 
		ScreenPulse("Bio Electric Burst Final Hit")
	end
end

function VFX.RemoveFinisherPull(VictimRootPart : BasePart)
	if (FinisherStuff.Pulls[VictimRootPart] ~= nil) then 
		for Item in FinisherStuff.Pulls[VictimRootPart] do
			if Item:IsA("Attachment") then
				EffectUtility.Toggle(Item, false)
				task.delay(2, Item.Destroy, Item)

			elseif Item:IsA("Sound") then
				Item:Destroy()
			end
		end

		FinisherStuff.Pulls[VictimRootPart] = nil
	end
end

function VFX.FinisherGrab(RootPart : BasePart, VictimRootPart : BasePart)
	VFX.RemoveFinisherPull(VictimRootPart)
	EffectUtility.EmitEffects(FinisherAssets.Grab, RootPart)
	
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	
	if (Distance < 150) then 
		for _, Item in ipairs(RootPart.Parent:GetChildren()) do
			if Item:IsA("BasePart") and (string.find(Item.Name, "Right") or string.find(Item.Name, "Left")) then
				local FakeArm = EffectUtility.WeldArmTrail(Item)
				task.delay(0.75, FakeArm.Destroy, FakeArm)
			end
		end
	end
end

function VFX.FinisherSlam(Arm : BasePart, RootPart : BasePart)
	VFX.RemoveFinisherHand(Arm)
	
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if (Distance > 100) then return end

	if (Distance < 40) then
		ScreenPulse("Bio Electric Burst Final Hit")
		CameraShake(5, 40, 0.1, 0.45, Vector3.one * 0.8)
	end
	
	local Direction = Vector3.yAxis * -10
	local Raycast = workspace:Raycast(RootPart.Position, Direction, Utility.VisualParams)

	if (Raycast ~= nil) then
		
		local CF = RootPart.CFrame * CFrame.new(0, -Raycast.Distance, -4.5)
		local Position = CF.Position
		
		Shockwave(CFrame.new(Position) * CFrame.new(0, -2, 0) * CFrame.Angles(-(math.pi / 2), 0, 0), nil, nil, Vector3.new(25, 0.75, 25))

		local Effect = FinisherAssetsHolder.Slam:Clone()
		Effect.WorldCFrame = CF
		Effect.Parent = workspace.Terrain
		EffectUtility.Emit(Effect)

		coroutine.wrap(RockHandler.Crater)(Position, Direction, {
			Amount = 13,
			Distance = 9.75,

			LookAt = { -- Where the rocks face towards (y axis)
				Min = -7,
				Max = 7
			},

			Exposure = {
				Min = 0.3,
				Max = 0.5
			},

			BaseZ = 1.5,
			SizeMultiplier = 1.2,
		})

		coroutine.wrap(RockHandler.Crater)(Position, Direction, {
			Amount = 17,
			Distance = 12,
			SizeMultiplier = 1.6,
			
			LookAt = { -- Where the rocks face towards (y axis)
				Min = -8.5,
				Max = 8.5
			},
		})
		
		coroutine.wrap(RockHandler.Rockst)(Raycast.Position, Direction, {
			Size = {0.75, 0.9},
			Count = 8,
			Velocity = 40,
		})
	else
		local Effect = FinisherAssetsHolder.Slam:Clone()
		Effect.WorldCFrame = RootPart.CFrame * CFrame.new(0, -2.5, -4.5)
		Effect.Parent = workspace.Terrain
		EffectUtility.Emit(Effect)
	end
end

function VFX.FinisherRocks(RootPart : BasePart)
	local Direction = Vector3.yAxis * -10
	
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if (Distance > 200) then return end

	if (Distance < 35) then
		ScreenPulse("Vector Punch")
		CameraShake(3.5, 35, 0.1, 1.5, Vector3.one * 0.8)
	end
	
	local Raycast = workspace:Raycast(RootPart.Position, Direction, Utility.VisualParams)
	
	local Spin = FinisherAssetsHolder.Spin:Clone()
	Spin.Parent  = RootPart
	EffectUtility.Toggle(Spin, true)
	FinisherStuff.Spins[RootPart] = Spin
	
	if (FinisherStuff.Rocks[RootPart] == nil) then
		FinisherStuff.Rocks[RootPart] = {}
	end

	for Index = 1, 4 do
		local Rock : typeof(FinisherAssets.Rock1) = FinisherAssets["Rock" .. Index]:Clone()
		Rock.Root.CFrame = RootPart.CFrame * CFrame.new(0, -3, 0)
		
		if Raycast then
			for _, Item in ipairs(Rock:GetChildren()) do
				if Item:IsA("BasePart") then
					Item.Color = Raycast.Instance.Color
					Item.Material = Raycast.Instance.Material
					Item.MaterialVariant = Raycast.Instance.MaterialVariant
				end
			end
		end
		
		Rock.Parent = workspace.Visuals
		
		task.delay(0.25, function()
			local Position = Rock["1"].Position
			
			coroutine.wrap(RockHandler.Crater)(Position, Direction, {
				Amount = 7,
				Distance = 5,

				LookAt = { -- Where the rocks face towards (y axis)
					Min = -5,
					Max = 5
				},

				Exposure = {
					Min = 0.4,
					Max = 0.6
				},

				SizeMultiplier = 0.8,
			})

			coroutine.wrap(RockHandler.Rockst)(Position, Direction, {
				Size = {0.35, 0.5},
				Count = 3,
				Velocity = 15,
			})

			EffectUtility.RaycastCraterSmoke("Small", Position, Direction)
		end)
		
		local Animation = Rock.AnimationController.Animator:LoadAnimation(Rock.Animation)
		Animation:Play(0)
		
		Animation.Stopped:Once(function()
			Rock:Destroy()
		end)
		
		FinisherStuff.Rocks[RootPart][Rock] = true
	end
end

function VFX.RemoveFinisherRocks(RootPart : BasePart)
	if FinisherStuff.Spins[RootPart] then
		EffectUtility.Toggle(FinisherStuff.Spins[RootPart])
		task.delay(1, FinisherStuff.Spins[RootPart].Destroy, FinisherStuff.Spins[RootPart])
		FinisherStuff.Spins[RootPart] = nil
	end
	
	if FinisherStuff.Rocks[RootPart] then
		for Rock in FinisherStuff.Rocks[RootPart] do
			Rock:Destroy()
		end
		
		FinisherStuff.Rocks[RootPart] = nil
	end
end

function VFX.FinisherPop(RootPart : BasePart, Victim : Model)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)

	if (Distance < 35) then
		ScreenPulse("Vector Punch")
		CameraShake(8, 80, 0.05, 1, Vector3.one * 0.8)
	end
	
	if (Distance < 150) then
		local Explode = FinisherAssets.Explode:Clone()
		Explode.CFrame = RootPart.CFrame * CFrame.new(0, 0, 2)
		Explode.Parent  = workspace.Visuals
		EffectUtility.Emit(Explode)

		local RocksExplode = FinisherAssetsHolder.RocksExplode:Clone()
		RocksExplode.Parent  = RootPart
		EffectUtility.Emit(RocksExplode)
	end

	if (FinisherStuff.Rocks[RootPart] ~= nil) then
		for Rock in FinisherStuff.Rocks[RootPart] do
			for _, Item in ipairs(Rock:GetChildren()) do
				if Item:IsA("BasePart") and Item.Name ~= "Root" then
					local ExplodeRock = Item:Clone()

					for _, ParticleOrWeld in ipairs(ExplodeRock:GetChildren()) do
						if ParticleOrWeld:IsA("Motor6D") then
							ParticleOrWeld:Destroy()

						elseif ParticleOrWeld:IsA("ParticleEmitter") then
							task.delay(0.75, function()
								ParticleOrWeld.Enabled = false
							end)
						end
					end

					ExplodeRock.CanCollide = true
					ExplodeRock.CanQuery = true
					ExplodeRock.CanTouch = true
					ExplodeRock.CFrame = Item.CFrame
					ExplodeRock.Parent = workspace.Visuals
					ExplodeRock.AssemblyLinearVelocity = Vector3.new(Utility.Seed:NextNumber(-65, 65), Utility.Seed:NextNumber(57.5, 65), Utility.Seed:NextNumber(-65, 65))
					ExplodeRock.AssemblyAngularVelocity = Vector3.one * Utility.Seed:NextNumber(-35, 35)

					local Touched : RBXScriptConnection; Touched = ExplodeRock.Touched:Connect(function(Part)
						if not Part:IsDescendantOf(workspace.Map) then return end

						if Touched.Connected then
							Touched:Disconnect()
						end

						local Position = ExplodeRock.Position
						local Direction = ExplodeRock.AssemblyLinearVelocity.Unit * (ExplodeRock.AssemblyLinearVelocity.Magnitude / 4.5)

						EffectUtility.RaycastCraterSmoke("Small", Position, Direction)

						coroutine.wrap(RockHandler.Crater)(Position, Direction, {
							Amount = 9,
							Distance = 6,

							LookAt = { -- Where the rocks face towards (y axis)
								Min = -5,
								Max = 5
							},

							Exposure = {
								Min = 0.5,
								Max = 0.75
							},

							SizeMultiplier = 0.85,
						})

						CameraShake(1, 10, 0.05, 0.25, Vector3.one * 0.8)
					end)

					ExplodeRock.AncestryChanged:Connect(function(_, Parent) 
						if (Parent == nil) then -- safe because it could fall through floor and give a mem leak if i connect to destroying
							Touched:Disconnect()
						end
					end)

					task.delay(3.5, function()
						TweenService:Create(ExplodeRock, TweenInfo.new(1),
							{Size = Vector3.zero}
						):Play()

						task.delay(1, ExplodeRock.Destroy, ExplodeRock)
					end)
				end
			end
			
			Rock:Destroy()
		end
	end
	
	FinisherStuff.Rocks[RootPart] = nil
	
	if Victim then
		for _, Item in ipairs(Victim:GetDescendants()) do
			if Item:IsA("BasePart") or Item:IsA("Decal") then
				Item.Transparency = 1
			end
		end
		
		if Distance < 150 then
			for _, Item in ipairs(Victim:GetChildren()) do
				if Item:IsA("BasePart") and Item.Name ~= "HumanoidRootPart" then
					EffectUtility.EmitEffects(ReplicatedStorage.Effects.Blood.Splash, Item)

					Blood.BloodRaysWithoutPreset(Item, {
						Amount = Vector2.new(3, 4),

						Spread = Vector2.new(85, 85),
						Power = 50,
						Face = Enum.NormalId.Top,

						PoolSize = 1.65,
					})
				end
			end
		end
	end
end

function VFX.KickVanish(PreviousCF : CFrame, CF : CFrame)
	if Players.LocalPlayer:DistanceFromCharacter(PreviousCF.Position) <= 25 then
		CameraShake(2, 15, 0.01, 0.1, Vector3.one * 0.8)
		Vignette(Color3.fromRGB(130, 41, 255), 0.75, 0.1)
	end

	EffectUtility.EmitEffects(script.Vanish, workspace.Terrain, PreviousCF)
	EffectUtility.EmitEffects(script.Vanish, workspace.Terrain, CF)
end

function VFX.Kick(Model : Model)
	if Model ~= nil and Model.Parent ~= nil then
		local Pivot : CFrame = Model:GetPivot()
		
		if Players.LocalPlayer:DistanceFromCharacter(Pivot.Position) <= 25 then
			CameraShake(2.5, 20, 0.01, 0.45, Vector3.one * 0.8)
			Vignette(Color3.fromRGB(130, 41, 255), 0.65, 0.075)
		end

		EffectUtility.EmitEffects(script.Kick, workspace.Terrain, Pivot)
	end
end

----------------------------------------------------------------------

return VFX