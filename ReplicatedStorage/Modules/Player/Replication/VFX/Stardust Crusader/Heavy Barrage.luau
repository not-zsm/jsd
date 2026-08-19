local VFX = {}

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Attacks["Stardust Crusader"]["Heavy Barrage"]

local StardustCrusaderAssets = ReplicatedStorage.Effects.Characters["Stardust Crusader"]
local StardustCrusaderVFX = StardustCrusaderAssets.VFX
local StardustCrusaderSFX = StardustCrusaderAssets.SFX

local SFXAssets = script.SFX

local function QuadBezier(Time : number, Start : Vector3, Middle : Vector3, End : Vector3)
	return (1 - Time) ^ 2 * Start + 2 * (1 - Time) * Time * Middle + Time ^ 2 * End
end

function VFX.CreateArm(Side : boolean, Model : Model, LoopSpeed : number, ArmSpeed : number, StartOffset : CFrame, MiddleOffset : CFrame, EndOffset : CFrame, InstantDelete : boolean)
	local Arm = (Side and "Left" or "Right")
	local Limb : BasePart = Model:FindFirstChild(Arm .. " Arm"):Clone()

	for _, Item in pairs(Limb:GetChildren()) do
		if Item:IsA("ParticleEmitter") and Item.Name == "Aura" then
			Item:Destroy()
		end
	end

	--local Trail = Limb:FindFirstChildOfClass("Trail")
	
	--if Trail then
	--	Trail.Enabled = math.random(1, 2) == 1 and true or false
	--end

	for _, Item in ipairs(script.BarrageArmEffects:GetChildren()) do
		Item:Clone().Parent = Limb
	end
	
	Limb.Anchored = true

	local Duration = ArmSpeed * 0.02
	local StartTime = os.clock()

	local Connection

	Connection = RunService.PostSimulation:Connect(function()
		local Elapsed = (os.clock() - StartTime)

		if Elapsed >= Duration then
			if InstantDelete then
				Limb:Destroy()
			else
				Debris:AddItem(Limb, ArmSpeed / 5)
			end

			Connection:Disconnect()
		else
			local AlphaRatio = Elapsed / Duration

			local Start = Model.PrimaryPart.CFrame * CFrame.new(unpack(StartOffset))
			local Middle = Model.PrimaryPart.CFrame * CFrame.new(unpack(MiddleOffset))
			local End = Model.PrimaryPart.CFrame * CFrame.new(unpack(EndOffset))

			local Position = QuadBezier(AlphaRatio, Start.Position, Middle.Position, End.Position)
			local LookAtPosition = QuadBezier(AlphaRatio + 0.01, Start.Position, Middle.Position, End.Position)

			TweenService:Create(Limb, TweenInfo.new(LoopSpeed), {
				CFrame = CFrame.new(Position, LookAtPosition) * CFrame.Angles(math.rad(90), 0, 0)
			}):Play()
		end
	end)

	Limb.Parent = workspace.Visuals
	Debris:AddItem(Limb, ArmSpeed / 50)
end

--function VFX.Start(Stand : Model)
--	if (Stand == nil or Stand.Parent == nil) then
--		return
--	end
	
--	local Jotaro : Model = Stand.Parent
--	local StandRoot : BasePart = Stand:FindFirstChild("HumanoidRootPart")

--	local LoopSpeed = 0.02
--	local ArmSpeed = 10

--	local Side = false

--	local BarrageEffect = script.BarrageEffect:Clone()
--	BarrageEffect.Weld.Part1 = StandRoot
--	BarrageEffect.Parent = workspace.Visuals

--	local Raycast = workspace:Raycast(StandRoot.Position, Vector3.yAxis * -5, Utility.VisualParams)

--	if Raycast then
--		for _, Effect in ipairs(BarrageEffect:GetDescendants()) do
--			if Effect:IsA("ParticleEmitter") and string.match(Effect.Name, "Smoke") then
--				Effect.Color = ColorSequence.new(Raycast.Instance.Color)
--			end
--		end
--	end

--	local EffectConnection

--	repeat
--		Side = not Side 

--		local Offset = Side and -1 or 1

--		VFX.CreateArm(Side, Stand, LoopSpeed, ArmSpeed, 
--			{Offset * math.random(0, 2), math.random(-15, 15) / 10, 0}, 
--			{Offset * math.random(3, 6), math.random(-3, 3), -3}, 
--			{Offset * math.random(1, 2), 0, -6}
--		)
		
--		if EffectUtility.Distance_Close(Jotaro) then
--			CameraShake(0.8, 20, 0.01, LoopSpeed, Vector3.one * 0.8, Vector3.one * 0.25)
--		end

--		task.wait(LoopSpeed)
--	until (Stand.Parent == nil or not Stand:GetAttribute("Barraging"))

--	for _, Effect in ipairs(BarrageEffect:GetDescendants()) do
--		if Effect:IsA("ParticleEmitter") then
--			Effect.Enabled = false
--		end
--	end

--	Debris:AddItem(BarrageEffect, .15)
--end

function VFX.BarrageHit(VictimRoot : BasePart)
	local NewSFX = SFXAssets.BarrageHit:Clone()
	NewSFX.Parent = VictimRoot
	NewSFX:Play()
	task.delay(1, NewSFX.Destroy, NewSFX)
	
	if EffectUtility.Distance_Close(VictimRoot.Parent) then
		CameraShake(2, 30, 0.01, 0.065, Vector3.one * 0.8)
	end
	
	EffectUtility.CloneAndEmit(StardustCrusaderVFX.BarrageHit, VictimRoot)
end

function VFX.Bleed(VictimRoot : BasePart, BloodSteps : number, BloodTime : number)
	local VictimModel : Model = VictimRoot.Parent

	BloodSteps = BloodSteps or 10
	BloodTime = BloodTime or 0.2

	task.spawn(function()
		local Head = VictimRoot.Parent:WaitForChild("Head")
		local BloodEnabled = LocalPlayer:GetAttribute("Blood")

		for Index = 1, BloodSteps do
			Blood.BloodRaysWithoutPreset(Head, {
				DontHaveRange = true,
				Power = 35,

				Amount = Vector2.new(3, 5),
				Spread = Vector2.new(65, 65),

				Face = Enum.NormalId.Back,

				Color = Color3.fromRGB(66, 0, 0),

				PoolSize = 1.5,

				PoolDuration = 5,
				PoolDurationTransition = 1.5,
			})
			
			Blood.BloodRaysWithoutPreset(Head, {
				DontHaveRange = true,
				Power = 35,

				Amount = Vector2.new(3, 5),
				Spread = Vector2.new(65, 65),

				Face = Enum.NormalId.Front,

				Color = Color3.fromRGB(66, 0, 0),

				PoolSize = 1.5,

				PoolDuration = 5,
				PoolDurationTransition = 1.5,
			})

			if BloodEnabled then
				EffectUtility.EmitEffects(ReplicatedStorage.Effects.Blood.SmallSplash, Head)
			end

			if LocalPlayer.Character == VictimModel then
				CameraShake(1, 10, 0.01, 0.2, Vector3.one * 0.8, Vector3.one * 0.3)
				Vignette(Color3.fromRGB(66, 0, 0), 0.4, 0.2)
			end

			task.wait(BloodTime)
		end
	end)
end

function VFX.HeavyHit(VictimRoot : BasePart, BloodSteps : number, BloodTime : number)
	BloodSteps = BloodSteps or 10
	BloodTime = BloodTime or 0.2
	
	local NewSFX = StardustCrusaderSFX.HeavyHit:Clone()
	NewSFX.Parent = VictimRoot
	NewSFX:Play()
	task.delay(5, NewSFX.Destroy, NewSFX)
	
	if EffectUtility.Distance_Close(VictimRoot.Parent, 30) then
		CameraShake(5, 45, 0.01, 0.6, Vector3.one * 0.8, Vector3.one * 0.5)
	end
	
	VFX.Bleed(VictimRoot, BloodSteps, BloodTime)
	EffectUtility.CloneAndEmit(StardustCrusaderVFX.HeavyHit, VictimRoot)
end

function VFX.HeavyHitFinisher(VictimRoot : BasePart)
	local NewSFX = StardustCrusaderSFX.BigHeavyHit:Clone()
	NewSFX.Parent = VictimRoot
	NewSFX.Volume = 1.5
	NewSFX.RollOffMaxDistance = 750
	NewSFX.RollOffMinDistance = 100
	NewSFX:Play()
	task.delay(5, NewSFX.Destroy, NewSFX)
	
	local VictimModel : Model = VictimRoot.Parent

	if EffectUtility.Distance_Close(VictimModel) then
		CameraShake(5 * 2, 45 * 2, 0.01, 0.6 * 1.5, Vector3.one * 0.8, Vector3.one * 0.05)
	end
	
	task.spawn(function()
		local Head = VictimRoot.Parent:WaitForChild("Head")
		local BloodEnabled = LocalPlayer:GetAttribute("Blood")
		
		for Index = 1, 30 do
			Blood.BloodRaysWithoutPreset(Head, {
				DontHaveRange = true,
				Power = 35,

				Amount = Vector2.new(6, 9),
				Spread = Vector2.new(65, 65),

				Face = Enum.NormalId.Back,

				PoolSize = 1.5,
				PoolSizeRandom = Vector2.new(-0.1, 0.5),

				Color = Color3.fromRGB(66, 0, 0),

				PoolDuration = 5,
				PoolDurationTransition = 1.5,
			})
			
			Blood.BloodRaysWithoutPreset(Head, {
				DontHaveRange = true,
				Power = 35,

				Amount = Vector2.new(6, 9),
				Spread = Vector2.new(65, 65),

				Face = Enum.NormalId.Front,

				PoolSize = 1.5,
				PoolSizeRandom = Vector2.new(-0.1, 0.5),

				Color = Color3.fromRGB(66, 0, 0),

				PoolDuration = 5,
				PoolDurationTransition = 1.5,
			})
			
			if BloodEnabled then
				EffectUtility.EmitEffects(ReplicatedStorage.Effects.Blood.SmallSplash, Head)
			end
			
			if LocalPlayer.Character == VictimModel then
				CameraShake(1, 10, 0.01, 0.2, Vector3.one * 0.8, Vector3.one * 0.3)
				Vignette(Color3.fromRGB(66, 0, 0), 0.4, 0.2)
			end
			
			task.wait(0.075)
		end
	end)

	EffectUtility.CloneAndEmit(StardustCrusaderVFX.HeavyHit, VictimRoot)
end


function VFX.Start(Stand : Model)
	local Retrieved = AnimationRetriever.new(Stand, Animations.Stand)
	if (Retrieved == nil) then return end
	
	local StandAnimation = Retrieved.Animation
	local StandJob = Retrieved.Job
	local StandRootPart = Retrieved.RootPart

	local Jotaro : Model = Stand.Parent

	local LoopSpeed = 0.02
	local ArmSpeed = 10

	local Side = false

	local BarrageSFX = StandJob:Task(EffectUtility.AddSFX(SFXAssets.Barrage[tostring(math.random(1, 2))], StandRootPart, 0.5))
	
	local BarrageEffect = script.VFX.Barrage:Clone()
	EffectUtility.Weld(BarrageEffect, StandRootPart, CFrame.new(0, 0.25, -3.5) * CFrame.Angles(0, math.rad(-90), 0))
	BarrageEffect.Parent = workspace.Visuals
	
	local Highlight = Instance.new("Highlight")
	Highlight.FillColor = Color3.fromRGB(105, 66, 255)
	Highlight.OutlineColor = Color3.fromRGB(150, 2, 255)
	Highlight.FillTransparency = 0.75
	Highlight.OutlineTransparency = 0.75
	Highlight.Parent = Jotaro
	
	TweenService:Create(Highlight, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{FillTransparency = 1, OutlineTransparency = 1}
	):Play()
	
	StandJob:Task(Highlight)
	
	if EffectUtility.Distance_Close(Jotaro) then
		CameraShake(1, 10, 0.01, 0.6, Vector3.one * 0.8, Vector3.one * 0.2)
		Vignette(Color3.fromRGB(109, 60, 255), 0.75, 0.2)
	end
	
	local BarrageThread = coroutine.create(function()
		while true do
			Side = not Side 

			local Offset = Side and -1 or 1

			VFX.CreateArm(Side, Stand, LoopSpeed, ArmSpeed, 
				{Offset * math.random(0, 2), math.random(-15, 15) / 10, 0}, 
				{Offset * math.random(3, 6), math.random(-3, 3), -3}, 
				{Offset * math.random(1, 2), 0, -6}
			)

			if EffectUtility.Distance_Close(Jotaro) then
				CameraShake(0.8, 20, 0.01, LoopSpeed, Vector3.one * 0.8, Vector3.one * 0.25)
			end

			task.wait(LoopSpeed)
		end
	end)

	StandJob:Task(BarrageThread)
	StandJob:Task(BarrageEffect)

	StandJob:Task(StandAnimation:GetMarkerReachedSignal("barrage"):Connect(function(Parameter : string)
		if (Parameter == "true") then
			EffectUtility.Toggle(BarrageEffect, true)
			EffectUtility.Emit(BarrageEffect, true)
			coroutine.resume(BarrageThread)
		else
			Utility.CloseThreadSafe(BarrageThread)
			EffectUtility.Toggle(BarrageEffect, false)
		end
	end))
	
	StandJob:Task(StandAnimation:GetMarkerReachedSignal("punch"):Connect(function()
		if EffectUtility.Distance_Close(Jotaro) then
			CameraShake(2, 25, 0.01, 0.3, Vector3.one * 0.8, Vector3.one * 0.3)
			Vignette(Color3.fromRGB(109, 60, 255), 0.75, 0.2)
		end
		
		EffectUtility.CloneAndEmit(StardustCrusaderVFX.Heavy, StandRootPart)
		
		local Size_I_Like = Vector3.new(10, 2, 10)
		
		local Mesh = StardustCrusaderVFX.Shockwave:Clone()
		Mesh.Size = Size_I_Like * 0.1
		Mesh:PivotTo(StandRootPart.CFrame * CFrame.new(0, 0.5, -3) * CFrame.Angles(math.rad(90), 0, 0))
		Mesh.Parent = workspace.Visuals
		
		TweenService:Create(Mesh, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{Size = Size_I_Like * 2, CFrame = Mesh:GetPivot() * CFrame.new(0, 0, -0.5) * CFrame.Angles(0, math.pi * 5, 0), Transparency = 1}
		):Play()
		
		task.delay(0.6, Mesh.Destroy, Mesh)
	end))
end

return VFX