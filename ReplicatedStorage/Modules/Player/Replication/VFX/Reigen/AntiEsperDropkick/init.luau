local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local ScreenPulse = require( ReplicatedStorage.Modules.Player.Replication.Global.ScreenPulse )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local Smoke = require( ReplicatedStorage.Modules.Player.Replication.Global.Smoke )
local RunCameraRig = require( ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig )
local AttributeListener = require( ReplicatedStorage.Modules.Player.Replication.Global.AttributeListener )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local MeshVFX = require( ReplicatedStorage.Modules.Player.Replication.Global.SwrermMeshVFX )
local Meshes = script.Meshes

local CurrentCamera = workspace.CurrentCamera

local Barrage = setmetatable({}, {__mode = "k"})
local DropStuff = setmetatable({}, {__mode = "k"})
local SpinStuff = setmetatable({}, {__mode = "k"})
local SlideStuff = setmetatable({}, {__mode = "k"})
local Crush = setmetatable({}, {__mode = "k"}) --- makes it a weak table so it removes rootpart refernece when root removes

function VFX.Startup(RootPart : BasePart)
	local Trails = {}

	for _, Item in ipairs(RootPart.Parent:GetChildren()) do
		if Item:IsA("BasePart") and string.find(Item.Name, "Leg") then 
			Trails[EffectUtility.WeldArmTrail(Item)] = true
		end
	end

	task.delay(0.6, function()
		for Trail in Trails do
			Trail:Destroy()
		end
	end)
end

function VFX.Drop(RootPart : BasePart)
	local Ring = script.Ring:Clone()
	Ring.CFrame = RootPart.CFrame * CFrame.new(0, -2, -5) * CFrame.Angles(math.rad(-45), 0, 0)
	Ring.Size = Vector3.one * 0.1
	Ring.Parent = workspace.Visuals

	task.delay(0.2, Ring.Destroy, Ring)

	TweenService:Create(Ring, TweenInfo.new(0.15, Enum.EasingStyle.Linear), {Transparency = 1, Size = Vector3.new(8, 8, 0.35)}):Play()
end

function VFX.Slam(Torso : BasePart)
	local RootPart = Torso.Parent.HumanoidRootPart

	local Position = Torso.Position + Vector3.yAxis * 5
	local LookVector = Vector3.yAxis * -20

	EffectUtility.RaycastCraterSmoke("Normal", Position, LookVector)

	coroutine.wrap(RockHandler.Crater)(Position, LookVector, {
		Amount = 6,
		Distance = 4,
		SizeMultiplier = 1.15,
	})

	if LocalPlayer:DistanceFromCharacter(RootPart.Position) < 25 then
		CameraShake(3, 10, 0.1, 0.25, Vector3.one * 0.8)
	end
	
end


function VFX.Slide(RootPart : BasePart)
	local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)

	local RunThread = coroutine.create(function()
		while (RootPart ~= nil and RootPart.Parent ~= nil) do
			RockHandler.Rocks("Side Dash", RootPart)
			Smoke(RootPart, 5, 4)

			task.wait(0.07)
		end
	end)

	local Shake

	if Players:GetPlayerFromCharacter(RootPart.Parent) == LocalPlayer then
		Shake = CameraShake(1, 7.5, 0.1, 0, Vector3.one * 0.7)
	end

	coroutine.resume(RunThread)
	SlideStuff[RootPart] = {RunThread, Shake}	
end

function VFX.Hit(VictimRootPart : BasePart)
	EffectUtility.EmitEffects(script.Hit, VictimRootPart)
end

function VFX.SlideEnd(RootPart : BasePart, VictimRootPart : BasePart)
	if (RootPart == nil or RootPart.Parent == nil) or (SlideStuff[RootPart] == nil) then return end

	for _, Item in SlideStuff[RootPart] do
		if typeof(Item) == "thread" then
			task.cancel(Item)

		elseif typeof(Item) == "table" and Item.IsACameraShakeInstance then
			Item:StartFadeOut(0.1)
		end
	end

	table.clear(SlideStuff[RootPart])
	SlideStuff[RootPart] = nil
end

function VFX.SFX(Torso : BasePart, VictimTorso : BasePart)
	EffectUtility.EmitEffects(script.FinisherSFX.User, Torso)
	EffectUtility.EmitEffects(script.FinisherSFX.Music, Torso)
	EffectUtility.EmitEffects(script.FinisherSFX.Voiceline, Torso)
	EffectUtility.EmitEffects(script.FinisherSFX.Victim, VictimTorso)
end

function VFX.FinisherHit(VictimRootPart : BasePart)
	EffectUtility.EmitEffects(script.FinisherHit, VictimRootPart.Parent.Head, CFrame.new(0, 0.25, -1))
	
	if LocalPlayer:DistanceFromCharacter(VictimRootPart.Position) < 25 then
		CameraShake(3, 10, 0.1, 0.35, Vector3.one * 0.85)
	end

	for Index, Mesh : Model in Meshes.Hit:GetChildren() do
		Mesh:PivotTo(VictimRootPart.Parent.Head.CFrame * CFrame.new(0, 0.25, -1))
		MeshVFX.Emit(Mesh)
	end
end

function VFX.Spin(VictimRootPart : BasePart)
	local SpinPart = script.Spin:Clone()
	SpinPart.Weld.Part0 = VictimRootPart.Parent.Torso
	SpinPart.Parent = workspace.Visuals

	SpinStuff[VictimRootPart] = {SpinPart}
end

function VFX.EndSpin(VictimRootPart : BasePart)
	if (SpinStuff[VictimRootPart] == nil) then return end

	for _, Item in SpinStuff[VictimRootPart] do
		if typeof(Item) == "Instance" then
			EffectUtility.Toggle(Item, false)

			task.delay(2, Item.Destroy, Item)
		end
	end

	table.clear(SpinStuff[VictimRootPart])
	SpinStuff[VictimRootPart] = nil
end

function VFX.FallAtEnd(VictimRootPart : BasePart)
	local FallFX = script.Fall1:Clone()
	FallFX.CFrame = VictimRootPart.CFrame * CFrame.new(0, -3, -5)
	FallFX.Parent = workspace.Visuals

	EffectUtility.Emit(FallFX)
end

function VFX.Fall(VictimRootPart : BasePart)
	local FallFX = script.Fall2:Clone()
	FallFX.CFrame = VictimRootPart.CFrame * CFrame.new(0, -3, -5)
	FallFX.Parent = workspace.Visuals

	EffectUtility.Emit(FallFX)
end

function VFX.Teleport(RootPart : BasePart)
	local FX = script.Teleport:Clone()
	FX.CFrame = RootPart.CFrame * CFrame.new(-2, -0.5, -3) * CFrame.Angles(-math.rad(90), 0, 0)
	FX.Parent = workspace.Visuals

	EffectUtility.Emit(FX)
end

function VFX.Barrage(RootPart : BasePart, VictimRootPart : BasePart)
	local FX = script.Barrage:Clone()
	FX.CFrame = RootPart.CFrame * CFrame.new(-0.5, -3, -4)
	FX.Parent = workspace.Visuals
	
	local Skeleton = script.Skeleton:Clone()
	Skeleton.Parent = workspace.Visuals
	
	for _, Part in Skeleton:GetChildren() do
		local ChosenPart = VictimRootPart.Parent:FindFirstChild(Part.Name)
		
		if ChosenPart then
			Part.Weld.Part0 = ChosenPart
		end
	end
	
	local Shake

	if LocalPlayer:DistanceFromCharacter(RootPart.Position) < 25 then
		Shake = CameraShake(1.25, 10, 0.01, 0, Vector3.one * 0.8, Vector3.one * 0.25)
	end

	local function Changed()
		local Connection; Connection = RootPart.AncestryChanged:Connect(function(_, Parent)
			if Parent == nil then
				VFX.BarrageEnd(RootPart)
			end
		end)
		
		return Connection
	end
	
	Barrage[RootPart] = {
		VFX = FX, 
		Shake = Shake, 
		AncestryChanged = Changed()
	}
	
	task.delay(10, FX.Destroy, FX)
	task.delay(10, Skeleton.Destroy, Skeleton)
	
	task.spawn(function()
		while (Barrage[RootPart] ~= nil) do
			Skeleton.Highlight.Enabled = true

			task.wait(0.075)

			Skeleton.Highlight.Enabled = false

			task.wait(0.05)
		end
		
		Skeleton:Destroy()
	end)
end

function VFX.BarrageEnd(RootPart : BasePart)
	if (RootPart == nil or Barrage[RootPart] == nil) then return end

	EffectUtility.Toggle(Barrage[RootPart].VFX, false)
	task.delay(2, Barrage[RootPart].VFX.Destroy, Barrage[RootPart].VFX)
	
	if Barrage[RootPart].Shake then
		Barrage[RootPart].Shake:StartFadeOut(0.1)
	end

	if Barrage[RootPart].AncestryChanged then
		Barrage[RootPart].AncestryChanged:Disconnect()
	end
	
	table.clear(Barrage[RootPart])
	Barrage[RootPart] = nil
end


function VFX.Crush(RootPart : BasePart, VictimPlayer : Player?)
	local ChosenCFrame = RootPart.CFrame * CFrame.new(0, -2, -4)
	
	local FX = script.Crush:Clone()
	FX.ground.CFrame = RootPart.CFrame * CFrame.new(0, -2.2, -4)
	FX.CFrame = ChosenCFrame
	FX.Parent = workspace.Visuals

	local ImpactFX = script.CrushImpact:Clone()
	ImpactFX.CFrame = ChosenCFrame
	ImpactFX.Parent = workspace.Visuals
	EffectUtility.Emit(ImpactFX)
	
	task.delay(10, FX.Destroy, FX) -- anti memory leak

	if LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) or (VictimPlayer and LocalPlayer == VictimPlayer) then
		local Camera = script.Camera:Clone()
		Camera.RootPart.CFrame = RootPart.CFrame * CFrame.new(0, 1.85, 0)
		Camera.Parent = workspace.Visuals
		
		local Animation = Camera.AnimationController.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Reigen["SALT PUAAANNCH"].AerialFinisherCamera)
		Animation:Play()

		local Clean = RunCameraRig(RootPart, Camera, CFrame.new(0, 1.85, 0))
		AttributeListener.new(RootPart, "AntiEsperDropkickCamera", Clean)
	end

	if LocalPlayer:DistanceFromCharacter(RootPart.Position) < 25 then
		CameraShake(5, 10, 0.1, 0.35, Vector3.one)
		Vignette(Color3.new(1, 0.796078, 0.447059), 0.25, 3)
	end

	for _, Particle in FX:GetDescendants() do
		if Particle:IsA("ParticleEmitter") then
			Particle:Emit(Particle:GetAttribute("EmitCount"))

			TweenService:Create(Particle, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TimeScale = 0.005}):Play()
		elseif Particle:IsA("PointLight") then
			Particle.Enabled = true
			Particle.Brightness = 3
		end
	end

	if LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) or (VictimPlayer and LocalPlayer == VictimPlayer) then
		local ColorCorrection = Instance.new("ColorCorrectionEffect")
		ColorCorrection.Contrast = 1
		ColorCorrection.Enabled = true
		ColorCorrection.Parent = game.Lighting

		TweenService:Create(ColorCorrection, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Contrast = 0}):Play()

		task.delay(1, ColorCorrection.Destroy, ColorCorrection)
	end

	if (Crush[RootPart] == nil) then
		local function Changed()
			local Connection; Connection = RootPart.AncestryChanged:Connect(function(_, Parent)
				if Parent == nil then
					VFX.CrushRemove(RootPart)
				end
			end)

			return Connection
		end
		
		Crush[RootPart] = {VFX = FX, AncestryChanged = Changed()}
	end
end

function VFX.CrushRemove(RootPart : BasePart)
	if (RootPart ~= nil and Crush[RootPart] ~= nil) then
		if Crush[RootPart].AncestryChanged then
			Crush[RootPart].AncestryChanged:Disconnect()
		end
		
		if Crush[RootPart].VFX then
			Crush[RootPart].VFX:Destroy()
		end
	
		Crush[RootPart] = nil
	end
end

function VFX.CrushEnd(RootPart : BasePart)
	if (RootPart ~= nil and Crush[RootPart] ~= nil) then
		for _, Particle in ipairs(Crush[RootPart].VFX:GetDescendants()) do
			if Particle:IsA("ParticleEmitter") then
				TweenService:Create(Particle, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TimeScale = 1}):Play()

			elseif Particle:IsA("PointLight") then
				TweenService:Create(Particle, TweenInfo.new(0.05, Enum.EasingStyle.Linear), {Brightness = 6}):Play()

				task.wait(0.05)

				TweenService:Create(Particle, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Brightness = 0}):Play()
			end
		end
	end
	
	VFX.CrushRemove(RootPart)
	
	if LocalPlayer:DistanceFromCharacter(RootPart.Position) < 25 then
		CameraShake(3, 10, 0.1, 0.25, Vector3.one)
		Vignette(Color3.new(1, 0.796078, 0.447059), 0.75)
	end

	local BoomFX = script.Boom:Clone()
	BoomFX.CFrame = RootPart.CFrame * CFrame.new(0, -2, -4)
	BoomFX.Parent = workspace.Visuals
	EffectUtility.Emit(BoomFX)
end

return VFX
