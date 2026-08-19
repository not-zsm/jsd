local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )

local Distort = require( ReplicatedStorage.Modules.Player.Replication.Global.Distort )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local ScreenPulse = require( ReplicatedStorage.Modules.Player.Replication.Global.ScreenPulse )

local Afterimage = require( ReplicatedStorage.Modules.Player.Replication.Global.Afterimage )

local CharacterTransparency = require( ReplicatedStorage.Modules.Player.Replication.Global.CharacterTransparency )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local WalkJobs = {}

function VFX.Walk(RootPart : BasePart, Radius : number)
	if (WalkJobs[RootPart] ~= nil) then return end

	local Character : Model = RootPart.Parent

	local NewJob = Job.new()
	WalkJobs[RootPart] = NewJob

	if LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) then
		Yuki_FOV.Tween(100, {0.5})
		
		local Shake = CameraShake(2, 20, 0.1, 0, Vector3.one * 0.8, Vector3.one * 0.35)

		NewJob:Task(function()
			if Shake then
				Shake:StartFadeOut(0.1)
			end
		end)
	end
	
	local Afterimages = {}
	local AfterimageApart = 0

	local Vanishes = {}

	local Rocks = {}

	local function ShakeDistortEffect(Model : Model)
		local Vanish = script.Vanish:Clone()
		Vanish.Parent = workspace.Visuals

		EffectUtility.Toggle(Vanish, true)
		EffectUtility.Weld(Vanish, Model.Torso)

		Distort({Character = Model, StartPercentage = 6})
		CharacterTransparency(Model, 0.3)

		--for _, Item : Instance in ipairs(Model:GetDescendants()) do
		--	if Item:IsA("BasePart") then
		--		if Model == Character then
		--			PreviousStuffs[Item] = {Color = Item.Color, Material = Item.Material}
		--		end

		--		Item.Color = Color3.fromRGB(136, 0, 220)
		--		Item.Material = Enum.Material.ForceField
		--	end
		--end

		NewJob:Task(Vanish)
	end

	Character.Archivable = true
	local BaseAfterimage = Character:Clone()
	Character.Archivable = false
	
	BaseAfterimage.Name ..= " Afterimage"

	local BaseAfterimageHumanoid : Humanoid = BaseAfterimage:WaitForChild("Humanoid")
	
	BaseAfterimageHumanoid.DisplayDistanceType = "None"
	BaseAfterimageHumanoid.HealthDisplayType = "AlwaysOff"
	BaseAfterimageHumanoid.BreakJointsOnDeath = false
	BaseAfterimageHumanoid.EvaluateStateMachine = false
	BaseAfterimageHumanoid.RequiresNeck = false
	BaseAfterimageHumanoid.AutomaticScalingEnabled = false

	BaseAfterimageHumanoid.RootPart.Anchored = true
	BaseAfterimageHumanoid.RootPart.CFrame = RootPart.CFrame

	local DestroyList = {
		["LuaSourceContainer"] = true,
		["Weld"] = true,
		["Attachment"] = true,
		["Sound"] = true,
		["ParticleEmitter"] = true,
		["PointLight"] = true,
	}

	for _, Item : Instance in ipairs(BaseAfterimage:GetDescendants()) do
		if Item:IsA("BasePart") and Item:HasTag("RagdollCollider") then
			Item:Destroy()
		end

		for Type in DestroyList do
			if not (Type == "Attachment" and string.find(Item.Name, "Foot")) and Item:IsA(Type) then
				Item:Destroy()
				break
			end
		end

		if Item:IsA("BasePart") then
			Item.CollisionGroup = "NoCollision"
			Item.CanCollide = false
			Item.CanTouch = false
			Item.CanQuery = false
			Item.Massless = true
			Item.CastShadow = false
		end
	end

	for Index = 1, 2 do
		local NewAfterimage = nil
		
		if Index == 2 then
			NewAfterimage = BaseAfterimage
		else
			NewAfterimage = BaseAfterimage:Clone()
		end
		
		local NewAfterimageHumanoid : Humanoid = NewAfterimage:WaitForChild("Humanoid")
		local NewAfterimageRootPart = NewAfterimageHumanoid.RootPart
		local NewAfterimageAnimator : Animator = NewAfterimageHumanoid:WaitForChild("Animator")

		NewAfterimage.Parent = workspace.Visuals
		NewJob:Task(NewAfterimage)

		local Start = os.clock()

		local Connection : RBXScriptConnection; Connection =  RunService.PostSimulation:Connect(function(Delta)
			if (NewAfterimage.Parent == nil) then
				return Connection:Disconnect()
			end

			if os.clock() - Start >= 1.75 then
				AfterimageApart = math.max(AfterimageApart - (0.1 * (Delta * 60)), 0)
			else
				AfterimageApart = math.min(AfterimageApart + (0.35 * (Delta * 60)), Radius / 1.5)
			end

			NewAfterimageRootPart.CFrame = NewAfterimageRootPart.CFrame:Lerp(RootPart.CFrame * CFrame.new(Index == 1 and AfterimageApart or -AfterimageApart, 0, 0), 15 * Delta)
		end)

		ShakeDistortEffect(NewAfterimage)

		local Animation = NewAfterimageAnimator:LoadAnimation(script.Afterimage)

		Animation:GetMarkerReachedSignal("footstep"):Connect(function(Leg : string)
			VFX.Footstep(Leg == "Left Leg" and NewAfterimage["Left Leg"].LeftFootAttachment or NewAfterimage["Right Leg"].RightFootAttachment)
		end)

		Animation:Play()
	end

	ShakeDistortEffect(Character)

	local Playing = true
	local MeshTime = 0.3

	task.spawn(function()
		while Playing do
			if LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) then
				Vignette(Color3.fromRGB(123, 46, 255), 0.75, 0.3)
			end

			local Mesh3 = ReplicatedStorage.Effects.Parts.MeshVFX.Start:Clone()
			Mesh3.Transparency = 0.94
			Mesh3.Parent = workspace.Visuals

			EffectUtility.Weld(Mesh3, RootPart, CFrame.new(0, -2.5, 0))

			TweenService:Create(Mesh3, TweenInfo.new(MeshTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
				Transparency = 1,
				Size = Vector3.new(35, 1.25, 35)
			}):Play()

			task.delay(MeshTime, Mesh3.Destroy, Mesh3)

			task.wait(0.075)
		end
	end)

	local Mesh1 = script.SpinWave:Clone()
	Mesh1.Parent = workspace.Visuals

	local Mesh2 = script.SpinWave2:Clone()
	Mesh2.Parent = workspace.Visuals

	local SpinRad = 0
	local SpinRad2 = 0

	TweenService:Create(Mesh1, TweenInfo.new(0.085, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, -1, true), {
		Transparency = 0.94,
		Size = Vector3.new(27.5, 7.5, 27.5)
	}):Play()

	local Connection : RBXScriptConnection; Connection = RunService.PostSimulation:Connect(function(Delta)
		if (Mesh1.Parent == nil) then
			return Connection:Disconnect()
		end

		SpinRad += 40 * (Delta * 60)
		Mesh1.CFrame = RootPart.CFrame * CFrame.new(0, -1.5, 0) * CFrame.Angles(0, math.rad(SpinRad), 0)
	end)

	TweenService:Create(Mesh2, TweenInfo.new(0.04, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, -1, true), {
		Transparency = 0.975,
		Size = Vector3.new(17.5, 13, 17.5)
	}):Play()

	local Connection2 : RBXScriptConnection; Connection2 = RunService.PostSimulation:Connect(function(Delta)
		if (Mesh2.Parent == nil) then
			return Connection2:Disconnect()
		end

		SpinRad2 += 50 * (Delta * 60)
		Mesh2.CFrame = RootPart.CFrame * CFrame.new(0, 3.5, 0) * CFrame.Angles(0, math.rad(SpinRad2), 0)
	end)

	NewJob:Task(function()
		Playing = false

		--for _, Item : Instance in ipairs(Character:GetDescendants()) do
		--	if Item:IsA("BasePart") then
		--		Item.Color = PreviousStuffs[Item].Color
		--		Item.Material = PreviousStuffs[Item].Material
		--	end
		--end

		CharacterTransparency(Character, 0)

		Mesh1:Destroy()
		Mesh2:Destroy()

		if LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) then
			Yuki_FOV.Tween(70, {0.5})
		end
	end)
	
	NewJob:Task(RootPart.AncestryChanged:Connect(function(_, Parent)
		if (Parent == nil) then
			VFX.StopWalk(RootPart)
		end
	end))
end

local YAxis10 = Vector3.yAxis * -10

function VFX.Footstep(Foot : Attachment)
	if Foot == nil then
		return
	end
	
	local Mesh1 = ReplicatedStorage.Effects.Parts.MeshVFX.Start:Clone()
	Mesh1.Transparency = 0.725
	Mesh1.Parent = workspace.Visuals

	EffectUtility.Weld(Mesh1, Foot, CFrame.new(0, 0.2, 0))

	TweenService:Create(Mesh1, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{Transparency = 1, Size = Vector3.new(5, 0.175, 5)}
	):Play()

	task.delay(0.5, Mesh1.Destroy, Mesh1)

	local Raycast = workspace:Raycast(Foot.WorldPosition + Vector3.yAxis * 1.5, YAxis10, Utility.VisualParams)

	if (Raycast ~= nil) then
		EffectUtility.CraterSmoke("Small", Raycast)
	end

	EffectUtility.CraterSmoke("Small", Raycast)
end

function VFX.Hit(RootPart : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)

	local Hit = script.Holder.Hit:Clone()
	Hit.Parent = RootPart

	EffectUtility.EmitAttachment(Hit)

	if (Distance < 25) then
		ScreenPulse("Bio Electric Burst Hit")
		CameraShake(3.5, 35, 0.1, 0.1, Vector3.one * 0.825)
	end
end

function VFX.Slam(RootPart : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)

	local Slam = script.Holder.Slam:Clone()
	Slam.Parent = RootPart

	EffectUtility.EmitAttachment(Slam)

	if Distance < 25 then
		ScreenPulse("Bio Electric Burst Hit")
		CameraShake(10, 25, 0.1, 0.25, Vector3.one * 0.75)
	end
end

--function VFX.TpHits(RootPart : BasePart)
--	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)

--	local function TpHit(Number : number)
--		local TpHit = script.Holder["tphit".. Number]:Clone()
--		TpHit.Parent = RootPart

--		EffectUtility.EmitAttachment(TpHit)

--		Afterimage(RootPart.Parent, {0.75}, {0.25}, 5)

--		if (Distance < 25) then
--			ScreenPulse("Bio Electric Burst Hit")
--			CameraShake(3.5, 25, 0.1, 0.1, Vector3.one * 0.75)
--		end
--	end

--	TpHit(1)

--	task.wait(0.5)

--	TpHit(2)

--	task.wait(0.2)

--	TpHit(3)

--	task.wait(0.1)

--	TpHit(4)

--	task.wait(0.15)

--	TpHit(4)
--end

function VFX.TpHit(RootPart : BasePart, Parameter : string)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)

	local TpHit = script.Holder[`tphit{Parameter}`]:Clone()
	TpHit.Parent = RootPart

	EffectUtility.EmitAttachment(TpHit)
	Afterimage(RootPart.Parent, {0.75}, {0.25}, 5)

	if (Distance < 25) then
		ScreenPulse("Bio Electric Burst Hit")
		CameraShake(3.5, 25, 0.1, 0.1, Vector3.one * 0.75)
	end
end

function VFX.Kick(RootPart : BasePart, Victim : Model)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)

	local Kick = script.Holder.kick:Clone()
	Kick.Parent = RootPart

	EffectUtility.EmitAttachment(Kick)

	if Players.LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) or Players.LocalPlayer == Players:GetPlayerFromCharacter(Victim) then
		Yuki_FOV.Tween(55, {0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In})
	end

	if (Distance < 25) then
		ScreenPulse("Bio Electric Burst Hit")
		CameraShake(3.5, 35, 0.1, 0.1, Vector3.one * 0.825)
	end
end

function VFX.Grab(RootPart : BasePart, Victim : Model)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)

	local Grab = script.Holder.grab:Clone()
	Grab.Parent = RootPart

	EffectUtility.EmitAttachment(Grab)
	
	if Players.LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) or Players.LocalPlayer == Players:GetPlayerFromCharacter(Victim) then
		Yuki_FOV.Tween(35, {0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In})
	end

	if (Distance < 25) then
		CameraShake(1.5, 15, 0.05, 0.2)
	end
end

function VFX.GrabCrack(RootPart : BasePart, Victim : Model)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)

	local GrabCrack = script.Holder.grabcrack:Clone()
	GrabCrack.Parent = RootPart

	EffectUtility.EmitAttachment(GrabCrack)

	if Distance < 25 then
		ScreenPulse("Bio Electric Burst Final Hit")
		CameraShake(10, 35, 0.1, 0.25, Vector3.one * 0.85)
	end
	
	if Players.LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) or Players.LocalPlayer == Players:GetPlayerFromCharacter(Victim) then
		Yuki_FOV.Tween(70, {0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
	end
end

function VFX.Throw(RootPart : BasePart)
	local Throw = script.Holder.throw:Clone()
	Throw.Parent = RootPart

	EffectUtility.EmitAttachment(Throw)
	
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	
	if Distance < 25 then
		CameraShake(15, 35, 0.1, 0.25, Vector3.one * 0.85)
	end
end

function VFX.TorsoShock(Torso : BasePart)
	local TorsoShock = script.Holder.torsoshock:Clone()
	TorsoShock.Parent = Torso

	EffectUtility.EmitAttachment(TorsoShock)
end

function VFX.StopWalk(RootPart : BasePart)
	if WalkJobs[RootPart] then
		WalkJobs[RootPart]:Destroy()
		WalkJobs[RootPart] = nil
	end
end

return VFX