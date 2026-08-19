local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )
local RunCameraRig = require( ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local ScreenPulse = require( ReplicatedStorage.Modules.Player.Replication.Global.ScreenPulse )

local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV)
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )

local JobApplication = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local ATrainAfterimage = require(ReplicatedStorage.Modules.Player.Replication.Global.ATrainAfterimage)
local Afterimage = require(ReplicatedStorage.Modules.Player.Replication.Global.Afterimage)

local ImpactFrames = LocalPlayer.PlayerGui.ImpactFrames.GreatSplitVerical

local function Clear(RootPart : BasePart, Type : "BodyVelocity" | "LinearVelocity")
	for _, Item in RootPart:GetDescendants() do
		if not Item:IsA(Type) then
			continue
		end

		Item:Destroy()
	end
end

local function ZoroRockThing(Data)
	local Amount = Data.Amount or 12
	local RockSizeMultiplier = Data.RockSizeMultiplier or 1
	local VelocityMultiplier = Data.VelocityMultiplier or 1
	local Size = Data.Size
	local Origin = Data.Origin
	local TimeTillNext = Data.Delay
	
	local XAxis = (Size.X / 2)
	local ZAxis = (Size.Z / 2)
	
	local Casts = {}

	for _ = 1, Amount do
		local Result = workspace:Raycast(Origin * CFrame.new(Utility.Seed:NextNumber(-XAxis, XAxis), 0, Utility.Seed:NextNumber(-ZAxis, ZAxis)).Position, Vector3.new(0, -50, 0), Utility.VisualParams)

		if Result then table.insert(Casts, Result) end
	end
	
	for i, Result in Casts do
		local Part = Instance.new("Part")
		Part.Position = Result.Position + vector.create(0, 3, 0)
		Part.Size = Vector3.new(Utility.Seed:NextNumber(1, 3), Utility.Seed:NextNumber(1, 3), Utility.Seed:NextNumber(1, 3)) * RockSizeMultiplier
		Part.Anchored = false
		Part.CanCollide = true
		Part.BottomSurface = Enum.SurfaceType.Smooth
		Part.TopSurface = Enum.SurfaceType.Smooth
		Part.Color = Result.Instance.Color
		Part.Material = Result.Material
		Part.Orientation = Vector3.new(Utility.Seed:NextNumber(-180, 180), Utility.Seed:NextNumber(-180, 180), Utility.Seed:NextNumber(-180, 180))
		Part.CollisionGroup = "Rockst"
		Part.Parent = workspace.Visuals
		
		for _, Child in Result.Instance:GetChildren() do
			if Child:IsA("Decal") or Child:IsA("Texture") then
				Child:Clone().Parent = Part
			end
		end

		local Attachment = Instance.new("Attachment")
		Attachment.Parent = Part

		local LinearVelocity = Instance.new("LinearVelocity")
		LinearVelocity.MaxForce = math.huge
		LinearVelocity.VectorVelocity = Vector3.new(0, Utility.Seed:NextNumber(15, 30), 0) * 3 * VelocityMultiplier
		LinearVelocity.Attachment0 = Attachment
		LinearVelocity.Parent = Attachment

		task.delay(5, Part.Destroy, Part)
		task.delay(0.1, LinearVelocity.Destroy, LinearVelocity)

		local Connection = nil

		local function Clean()
			if Connection then
				Connection:Disconnect()
				Connection = nil
				
				local Tween = TweenService:Create(Part, TweenInfo.new(3), {
					Size = Vector3.zero
				})

				Tween:Play()

				Tween.Completed:Connect(function()
					Part:Destroy()
				end)
			end
		end

		Connection = RunService.Heartbeat:Connect(function(Delta)
			if not Part.Parent then
				Clean()
			end
			
			local Position = Part.Position
			local Direction = Part.AssemblyLinearVelocity.Unit * Part.AssemblyLinearVelocity.Magnitude * Part.Size.Magnitude * Delta
			
			local Result = workspace:Raycast(Position, Direction, Utility.VisualParams)

			if not Result then
				return
			end

			Clean()
		end)
		
		if TimeTillNext then
			task.wait(TimeTillNext)
		end
	end
end

return {
	Startup = function(Character : Model)
		local Retrieved = AnimationRetriever.new(Character, ReplicatedStorage.Animations.Attacks["Gebura Red Mist"]["Great Split - Vertical"].Windup)
		if (Retrieved == nil) then return end
		
		local Job = Retrieved.Job

		local VFXpack = script.Assets:Clone()
		VFXpack.Parent = workspace.Visuals
		VFXpack.Weld.Part0 = Character.HumanoidRootPart
		
		Job:Task(VFXpack)

		EffectUtility.EmitAttachment(VFXpack["ui"])

		Job:Task(task.delay(0.9333333333333333,function()
			local Mimicry = Character:FindFirstChild("Mimicry")
			
			if Mimicry then
				EffectUtility.CloneAndEmit(Mimicry.Blade.bladesparks, Mimicry.Blade)
				EffectUtility.ToggleForTime(Mimicry.Blade.bladesparks, 1, false, true)
			end
		end)) 
		
		Job:Task(task.delay(2.3,function()
			local Attachment = VFXpack["1"]

			EffectUtility.EmitAttachment(Attachment) -- if you want to emit
		end))
		
		Job:Task(task.delay(2.35,function()
			local Attachment = VFXpack["t1"]

			EffectUtility.EmitAttachment(Attachment) -- if you want to emit
		end))
	end,
	
	SlashHit = function(Character : Model, VictimModel : Model)
		local Retrieved = AnimationRetriever.new(Character, ReplicatedStorage.Animations.Attacks["Gebura Red Mist"]["Great Split - Vertical"].BeatdownUser)
		if (Retrieved == nil) then return end
		
		local Job = Retrieved.Job
		local RootPart = Retrieved.RootPart

		local VFXpack = script.Assets:Clone()
		VFXpack.Parent = workspace.Visuals
		VFXpack.Weld.Part0 = Character.HumanoidRootPart
		
		Job:Task(VFXpack)

		local PlayerIsAttackerOrVictim = (LocalPlayer.Character == Character or (VictimModel and LocalPlayer.Character == VictimModel))

		if PlayerIsAttackerOrVictim then
			local Camera : Model = Job:Task(script.Camera:Clone())
			Camera:PivotTo(RootPart.CFrame)
			Camera.Parent = workspace.Visuals

			local CameraAnimation : AnimationTrack = Camera.Humanoid.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks["Gebura Red Mist"]["Great Split - Vertical"].BeatdownCam)
			CameraAnimation:Play(0)
			
			Job:Task(CameraAnimation.Stopped:Connect(function()
				Camera:Destroy()
			end))

			Job:Task(RunCameraRig(RootPart, Camera, nil))
			Job:Task(Yuki_FOV.AnimateWithMoonFile(ReplicatedStorage.FOVFiles["Great Split - Vertical"]))
			Job:Task(Camera)
			
			EffectUtility.ToggleImpactFrames(ImpactFrames.Stage1, true)
			EffectUtility.ToggleImpactFrames(ImpactFrames.Stage2, true)
			
			Job:Task(function()
				EffectUtility.ToggleImpactFrames(ImpactFrames.Stage1, false)
				EffectUtility.ToggleImpactFrames(ImpactFrames.Stage2, false)
			end)
			
			Job:Task(task.delay(3.45, function()
				EffectUtility.EmitImpactFrames(ImpactFrames.Stage1, 20)
			end))
			
			Job:Task(task.delay(4.25, function()
				CameraShake(10, 6, 0.6, 0.75, Vector3.one * 0.75)
			end))
			
			Job:Task(task.delay(4.4, function()
				EffectUtility.EmitImpactFrames(ImpactFrames.Stage2, 20)
			end))
		end
		
		Job:Task(task.delay(1.6166666666666667,function()
			local Attachment = VFXpack["3"]

			EffectUtility.EmitAttachment(Attachment, true) -- if you want to emit
			EffectUtility.ToggleForTime(Attachment, 1) -- if you want to toggle enabled (can also change the number if you want a set time to disable automatically)
		end))
		
		Job:Task(task.delay(2.0833333333333335,function()
			local Attachment = VFXpack["4"]
			
			EffectUtility.EmitAttachment(Attachment, true) -- if you want to emit
			EffectUtility.ToggleForTime(Attachment, 1) -- if you want to toggle enabled (can also change the number if you want a set time to disable automatically)
		end))
		
		Job:Task(task.delay(2.7333333333333334,function()
			local Mimicry = Character:FindFirstChild("Mimicry")
			
			if Mimicry then
				EffectUtility.CloneAndEmit(Mimicry.Blade.effecs2, Mimicry.Blade)
				EffectUtility.ToggleForTime(Mimicry.Blade.effecs2, 0.5, false, true)
			end
		end))
		
		Job:Task(task.delay(3.4166666666666665,function()
			local Attachment =  VFXpack["t1"]
			EffectUtility.EmitAttachment(Attachment) -- if you want to emit
		end))
		
		Job:Task(task.delay(3.433333333333333,function()
			local Attachment =  VFXpack["5"]
			EffectUtility.EmitAttachment(Attachment) -- if you want to emit
		end))
		
		Job:Task(task.delay(3.466666666666667,function()
			local Attachment =  VFXpack["6"]

			EffectUtility.EmitAttachment(Attachment, true) -- if you want to emit
			EffectUtility.ToggleForTime(Attachment, 1) -- if you want to toggle enabled (can also change the number if you want a set time to disable automatically)
		end))
		
		Job:Task(task.delay(4.45,function()
			local Attachment =  VFXpack["5"]
			EffectUtility.EmitAttachment(Attachment) -- if you want to emit
		end))
		
		Job:Task(task.delay(4.483333333333333,function()
			local Attachment =  VFXpack["t1"]
			EffectUtility.EmitAttachment(Attachment) -- if you want to emit
		end))
		
		local Attachment = VFXpack["2"]
		EffectUtility.EmitAttachment(Attachment) -- if you want to emit

		if (VictimModel and VictimModel.Parent) then
			Blood.BloodRays("SpitOut", VictimModel.HumanoidRootPart)
		end
	end,
	
	LeapVelocity = function(Character : Model, Reference : Folder)
		local RootPart = Character:FindFirstChild("HumanoidRootPart")
		
		Clear(RootPart, "LinearVelocity")
		Clear(RootPart, "BodyVelocity")
		
		local UpVelocity = Instance.new("LinearVelocity")
		UpVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
		UpVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
		UpVelocity.LineDirection = vector.create(0, 1, 0)
		UpVelocity.MaxForce = math.huge
		UpVelocity.Attachment0 = RootPart.RootAttachment
		UpVelocity.LineVelocity = 40
		UpVelocity.Parent = RootPart

		task.delay(0.4, UpVelocity.Destroy, UpVelocity)

		local UserBodyVelocity = Instance.new("BodyVelocity")
		UserBodyVelocity.Name = "GreatSplit Boost"
		UserBodyVelocity.Velocity = RootPart.CFrame.LookVector * 0
		UserBodyVelocity.MaxForce = vector.create(80_000, 0, 80_000)
		UserBodyVelocity.Parent = RootPart

		task.delay(1, UserBodyVelocity.Destroy, UserBodyVelocity)
		
		Reference.Destroying:Once(function()
			if UpVelocity then
				UpVelocity:Destroy()
			end
			
			if UserBodyVelocity then
				UserBodyVelocity:Destroy()
			end
		end)

		local NumberValue = Instance.new("NumberValue")
		NumberValue.Value = 75
		NumberValue.Parent = UserBodyVelocity

		task.delay(100/60, function()
			TweenService:Create(NumberValue, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Value = 0
			}):Play()
		end)

		while UserBodyVelocity:IsDescendantOf(workspace) and RootPart:IsDescendantOf(game) do
			UserBodyVelocity.Velocity = RootPart.CFrame.LookVector * NumberValue.Value
			task.wait()
		end

		if UserBodyVelocity then
			UserBodyVelocity:Destroy()
		end
	end,
	
	Trail = function(Character : Model, Reference : Folder)
		local RootPart = Character:FindFirstChild("HumanoidRootPart")
		local Job = JobApplication.new()
		
		if (Reference == nil or Reference.Parent == nil) then
			return
		end
		
		--ATrainAfterimage(Character, true)
		
		Job:Task(Reference.Destroying:Once(function()
			--ATrainAfterimage(Character, false)
			Job:Destroy()
		end))
		
		Job:Task(task.delay(20, function()
			Job:Destroy()
		end))
		
		local RunVFX = Job:Task(script.LineFx:Clone())
		RunVFX.Weld.Part0 = RootPart
		RunVFX.Parent = workspace.Visuals
		
		EffectUtility.Toggle(RunVFX, true, false)
		
		for _, Item in EffectUtility.WeldTrailsToAllLimbs(Character) do
			Job:Task(Item)
		end
		
		Job:Task(task.spawn(function()
			local AfterimageVanishInfo = {0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out}
			local AfterimageMoveInfo = {0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out}
			
			local function Afterimage_Effect(Afterimage : Model)
				local Highlight = Instance.new("Highlight")
				Highlight.FillTransparency = -10
				Highlight.FillColor = Color3.fromRGB(111, 0, 0)
				Highlight.OutlineTransparency = 1
				Highlight.OutlineColor = Color3.new()
				Highlight.Enabled = true
				Highlight.Parent = Afterimage
				
				TweenService:Create(Highlight, TweenInfo.new(table.unpack(AfterimageVanishInfo)),
					{FillTransparency = 1, OutlineTransparency = 1}
				):Play()
			end
			
			while (Reference ~= nil and Reference:IsDescendantOf(RootPart.Parent)) do
				Afterimage(Character, AfterimageVanishInfo, AfterimageMoveInfo, 2, Afterimage_Effect)
				
				task.wait(0.05)
			end
		end))
	end,
	
	WhiffSlam = function(Character : Model, ServerCFrame : CFrame)
		local VFXpack = script.Assets:Clone()
		VFXpack.Anchored = true
		VFXpack.CFrame = ServerCFrame --* CFrame.new(0, 0, ) * CFrame.Angles(0, -math.pi/2, 0)
		VFXpack.w3.w3:Destroy()
		VFXpack.w3.Anchored = true
		VFXpack.w3.CFrame = ServerCFrame * CFrame.new(0, 0, -28) * CFrame.Angles(0, -math.pi/2, 0)
		VFXpack.Parent = workspace.Visuals
		
		local Result = workspace:Raycast(ServerCFrame.Position, vector.create(0, -50, 0), Utility.VisualParams)
		
		if Result then
			VFXpack.Position = vector.create(
				VFXpack.Position.X,
				Result.Position.Y + 3,
				VFXpack.Position.Z
			)
			
			VFXpack.w3.Position = vector.create(
				VFXpack.w3.Position.X,
				Result.Position.Y + 0.05,
				VFXpack.w3.Position.Z
			)
		end
		
		EffectUtility.EmitAttachment(VFXpack.w1, true)
		EffectUtility.EmitAttachment(VFXpack.w2, true)
		EffectUtility.EmitAttachment(VFXpack.w3, true)
		
		task.delay(4, VFXpack.Destroy, VFXpack)
		
		coroutine.wrap(RockHandler.RegularRockLines)(ServerCFrame, {
			RandomJitter = 0,
			SizeIndex = 0.1,
			Amount = 25,
			Angle = 0,
		})
		
		ZoroRockThing({
			Origin = ServerCFrame * CFrame.new(0, 0, -28);
			Size = vector.create(10, 20, 50),
			RockSizeMultiplier = 2,
		})
		
		local Distance = Players.LocalPlayer:DistanceFromCharacter(ServerCFrame.Position)
		
		if Distance < 25 or LocalPlayer.Character == Character then
			ScreenPulse("Black Flash", true)
			CameraShake(10, 25, 0.1, 0.25, Vector3.one * 0.75)
		end
	end,
}