local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Attacks.Mori["Dragon Dropkick"]

--------------------------------------------------------------------------------

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

--------------------------------------------------------------------------------

local Smoke = require( ReplicatedStorage.Modules.Player.Replication.Global.Smoke )

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local VelocityUtil = require( ReplicatedStorage.Modules.Shared.Game.Velocity.VelocityUtil )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local Dojyan_Util = require( ReplicatedStorage.Modules.Player.Replication.Global.Dojyan_Util )
local MeshEmit = require( ReplicatedStorage.Modules.Player.Replication.Global.Dojyan_Util.MeshEmit )

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )

local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

--------------------------------------------------------------------------------

local Effects = script.effects
local HitEffects = Effects.hit
local Meshes = Effects.meshes
local HitMeshes = HitEffects.meshes

local resources = script.resources
local quickutil = require( script.quickutil )

local MoriEffects = ReplicatedStorage.Effects.Characters.Mori

local Jin_Color = Color3.fromRGB(84, 144, 255)

-- old size of slam vfx 12.761, 1.169, 13.381

local function PushForward(RootPart : BasePart, Amount : number, IndexTime : number)
	for Index = 1, (Amount or 10) do
		RockHandler.Rocks("Dragged", RootPart)
		Smoke(RootPart, 7.5, 1.5)

		task.wait(IndexTime or 0.05)
	end
end

local function ColorEffectsWithRaycast(VFX : Instance, Raycast : RaycastResult)
	for _, item in ipairs(VFX:GetDescendants()) do
		if item:IsA("ParticleEmitter") then
			item.Color = ColorSequence.new(Raycast.Instance.Color)
		end
	end
end

local function BlueHighlight(Model : Model, Duration : number?)
	local clone = resources.highlight:Clone()
	clone.FillColor = Jin_Color
	clone.Parent = Model
	quickutil:tween_single(clone, Duration or 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {FillTransparency = 1}, true)
end

return {
	--["Hyper_Armor_Effect"] = function(Mori : Model)
	--	local Highlight = resources.highlight:Clone()
	--	Highlight.OutlineColor = Jin_Color
	--	Highlight.Parent = Mori
	--	quickutil:tween_single(Highlight, 0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {OutlineTransparency = 0.85})
	--end,
	
	["Dropkick"] = function(Mori : Model)
		if EffectUtility.Distance_Close(Mori) then
			CameraShake(1, 10, 0.01, 0.35, Vector3.one * 0.8, Vector3.one * 0.25)
		end

		EffectUtility.Arc.CloneAndEmit(Effects.kick, Mori.HumanoidRootPart)

		local clone = resources.beams:Clone()
		EffectUtility.Weld(clone, Mori.Torso)
		clone.Parent = workspace.Visuals

		quickutil:tween_single(clone, 2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {["Orientation"] = clone.Orientation + Vector3.new(0, 0, 180)})
		quickutil:tween_descendant(clone, "Beam", .85, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {TextureSpeed = 2, Brightness = 0}, true)

		local Mesh = Meshes.starthit:Clone()
		Mesh:PivotTo(Mori.HumanoidRootPart.CFrame)

		for _, Start in ipairs(Mesh:GetDescendants()) do
			if Start.Name == "Start" then
				MeshEmit(Start, true)
			end
		end

		Mesh:Destroy()
	end,
	
	["Hit_Effect"] = function(Victim : Model, Type : string)
		local RootPart = Victim:FindFirstChild("HumanoidRootPart")
		if (RootPart == nil) then return end

		local Distance = LocalPlayer:DistanceFromCharacter(Victim.PrimaryPart.Position)

		if (Distance < 15) then
			CameraShake(1, 10, 0.01, 0.25, Vector3.one * 0.8)
			Vignette(Color3.fromRGB(84, 144, 255), 0.9, 0.2, true)
		end

		if (Distance < 100) then
			EffectUtility.Arc.CloneAndEmit(MoriEffects.Basic_Hit, RootPart)
			EffectUtility.AddSFX(script.sfx.Hits[Type], RootPart)
			--EffectUtility.EmitEffects(MoriEffects.M1Sounds[tostring(math.random(1, 4))], RootPart)
		
			BlueHighlight(Victim)
		end
	end,
	
	["VictimPush"] = function(Model : Model)
		local VictimRetrieved = AnimationRetriever.new(Model, Animations.VictimPush)
		if (VictimRetrieved == nil) then return end
		
		local MainAnimation = VictimRetrieved.Animation
		local MainJob = VictimRetrieved.Job
		
		MainJob:Task(MainAnimation:GetMarkerReachedSignal("slide"):Connect(function()
			PushForward(VictimRetrieved.RootPart)
		end))
	end,
	
	--["Kick"] = function(Model : Model)
	--	local RootPart = Model:FindFirstChild("HumanoidRootPart")
	--	if (RootPart == nil) then return end
		
	--	if EffectUtility.Distance_Close(Model) then
	--		CameraShake(1, 10, 0.01, 0.35, Vector3.one * 0.8, Vector3.one * 0.25)
	--	end

	--	EffectUtility.Arc.CloneAndEmit(Effects.kick, RootPart)

	--	local clone = resources.beams:Clone()
	--	EffectUtility.Weld(clone, Model.Torso)
	--	clone.Parent = workspace.Visuals

	--	quickutil:tween_single(clone, 2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {["Orientation"] = clone.Orientation + Vector3.new(0, 0, 180)})
	--	quickutil:tween_descendant(clone, "Beam", .85, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {TextureSpeed = 2, Brightness = 0}, true)
		
	--	local Mesh = Meshes.starthit:Clone()
	--	Mesh:PivotTo(RootPart.CFrame)

	--	for _, Start in ipairs(Mesh:GetDescendants()) do
	--		if Start.Name == "Start" then
	--			MeshEmit(Start, true)
	--		end
	--	end

	--	Mesh:Destroy()
	--end,
	
	["Hit"] = function(Model : Model, VictimModel : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Hit)
		if (Retrieved == nil) then return end
		
		local VictimRootPart = VictimModel:FindFirstChild("HumanoidRootPart")

		local MainAnimation = Retrieved.Animation
		local MainJob = Retrieved.Job

		local RootPart = Retrieved.RootPart
		local Torso = Retrieved.Torso

		local Is_Source = (LocalPlayer.Character == Model)

		if Is_Source then
			local NumberValue = MainJob:Task(Instance.new("NumberValue"))
			local CurrentTween
			
			MainJob:Task(function()
				Yuki_FOV.Tween(70, {0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
			end)

			local function Create_Velocity(Force : number, Time : number, Ease : Enum.EasingStyle, Direction : Enum.EasingDirection)
				if CurrentTween then
					CurrentTween:Cancel()
				end

				local Velocity = MainJob:Task(VelocityUtil.Create(RootPart))
				Velocity.MaxForce = Vector3.new(1, 0, 1) * 80000
				Velocity.Parent = RootPart

				NumberValue.Value = Force

				Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, Velocity, function(Delta : number)
					Velocity.Velocity = RootPart.CFrame.LookVector * NumberValue.Value
				end)

				CurrentTween = TweenService:Create(NumberValue, TweenInfo.new(Time, Ease, Direction), {Value = 0})
				CurrentTween:Play()

				CurrentTween.Completed:Once(function()
					Velocity:Destroy()
				end)
			end
			
			local UpVelocity = MainJob:Task(Instance.new("LinearVelocity"))
			UpVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
			UpVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
			UpVelocity.LineDirection = vector.create(0, 1, 0)
			UpVelocity.MaxForce = math.huge
			UpVelocity.Attachment0 = RootPart.RootAttachment
			
			MainJob:Task(MainAnimation:GetMarkerReachedSignal("leg_grab"):Connect(function()
				Create_Velocity(15, 1.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end))
			
			MainJob:Task(MainAnimation:GetMarkerReachedSignal("kick_up_init"):Connect(function()
				Create_Velocity(10, 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

				UpVelocity.Parent = RootPart
				UpVelocity.LineVelocity = 25
			end))
			
			MainJob:Task(MainAnimation:GetMarkerReachedSignal("kick_up"):Connect(function()
				Create_Velocity(30, 1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
				
				UpVelocity.LineVelocity = 65
				TweenService:Create(UpVelocity, TweenInfo.new(0.65, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {LineVelocity = 0}):Play()
			end))
			
			MainJob:Task(MainAnimation:GetMarkerReachedSignal("throw"):Connect(function()
				TweenService:Create(UpVelocity, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {LineVelocity = 35}):Play()
				
				task.wait(0.225)

				UpVelocity:Destroy()
			end))
			
			Create_Velocity(40, 1.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
		end
		
		EffectUtility.AddSFX(script.sfx.Dropkick, Retrieved.Torso)
		
		MainJob:Task(task.delay(3 / 60, function()
			EffectUtility.Arc.CloneAndEmit(HitEffects.victim.gardenofblue_hit, VictimRootPart)
			--BlueHighlight(VictimModel)
			
			local Good_Luck_GOB = resources.highlight:Clone()
			Good_Luck_GOB.OutlineColor = Color3.fromRGB(108, 133, 188)
			Good_Luck_GOB.FillColor = Color3.fromRGB(198, 223, 255)
			Good_Luck_GOB.FillTransparency = -6
			Good_Luck_GOB.OutlineTransparency = -6
			Good_Luck_GOB.Parent = VictimModel
			quickutil:tween_single(Good_Luck_GOB, 0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {FillTransparency = 1, OutlineTransparency = 1}, true)
		end))
		
		local function CreateMesh(mesh : Model)
			local Mesh = mesh:Clone()
			Mesh:PivotTo(RootPart.CFrame)

			for _, Start in ipairs(Mesh:GetDescendants()) do
				if Start.Name == "Start" then
					MeshEmit(Start, true)
				end
			end

			Mesh:Destroy()
		end

		MainJob:Task(MainAnimation:GetMarkerReachedSignal("spin"):Connect(function()
			MainJob:Task(EffectUtility.AddSFX(script.sfx.Hit, Retrieved.Torso, 0.3))

			if EffectUtility.Distance_Close(Model) then
				CameraShake(1, 7.5, 0.01, 0.65, Vector3.one * 0.275, Vector3.one * 0.75)
			end
			
			CreateMesh(HitMeshes.throw)
			
			EffectUtility.Arc.CloneAndEmit(HitEffects.breakdance, RootPart)
			
			local clone = resources.throwbeam:Clone()
			clone:PivotTo(RootPart.CFrame - Vector3.yAxis * 3)
			clone.Parent = workspace.Visuals

			quickutil:tween_single(clone, 2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {["CFrame"] = clone.CFrame * CFrame.new(0, 0, 3) * CFrame.Angles(0, math.rad(180), 0)})
			quickutil:tween_descendant(clone, "Beam", 1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {TextureSpeed = .3, Brightness = 0}, true)

			local clone = resources.highlight:Clone()
			clone.Parent = VictimModel
			quickutil:tween_single(clone, 1.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {FillTransparency = 1}, true)
		end))
		
		local freezehit = MainJob:Task(HitEffects.victim.freezehit:Clone())
		
		local spin = MainJob:Task(HitEffects.spin:Clone())
		local spinbeams = MainJob:Task(HitEffects.spinbeams:Clone())
		
		if VictimRootPart then
			freezehit.Parent = VictimRootPart
		end
		
		spin.Parent = RootPart
		spinbeams.Parent = Torso
		
		local blue_highlight = nil
		
		MainJob:Task(MainAnimation:GetMarkerReachedSignal("kick_up_init"):Connect(function()
			if Is_Source then
				Yuki_FOV.Tween(65, {0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out})
			end
			
			if EffectUtility.Distance_Close(Model) then
				CameraShake(3, 30, 0.01, 0.2, Vector3.one * 0.5, Vector3.one * 0.25)
				Vignette(Jin_Color, 0.5, 0.3)
			end
			
			blue_highlight = resources.highlight:Clone()
			blue_highlight.OutlineColor = Color3.fromRGB(21, 31, 40)
			blue_highlight.FillColor = Color3.fromRGB(220, 255, 254)
			blue_highlight.FillTransparency = 0.1
			blue_highlight.OutlineTransparency = 0 --0.25
			blue_highlight.Parent = VictimModel
			MainJob:Task(blue_highlight)

			quickutil:interact(freezehit, "ParticleEmitter", "TimeScale", 1)
			quickutil:emit(freezehit)
			quickutil:tween_descendant(freezehit, "ParticleEmitter", .06, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {TimeScale = 0})
			
			EffectUtility.Arc.CloneAndEmit(HitEffects.victim.freezehitimpact, VictimRootPart)
		end))
		
		MainJob:Task(MainAnimation:GetMarkerReachedSignal("kick_up"):Connect(function()
			if Is_Source then
				Yuki_FOV.Tween(70, {0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut})
			end
			
			if EffectUtility.Distance_Close(Model) then
				CameraShake(3, 20, 0.01, 0.5, Vector3.one * 0.5, Vector3.one * 0.35)
				Vignette(Jin_Color, 0.75, 0.5)
			end
			
			if blue_highlight then
				quickutil:tween_single(blue_highlight, 1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {FillTransparency = 1}, true)
			end
		
			quickutil:tween_descendant(freezehit, "ParticleEmitter", .03, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {TimeScale = 1})

			CreateMesh(HitMeshes.dropkick)

			EffectUtility.Arc.CloneAndEmit(HitEffects.victim.freezehitend, VictimRootPart)
			EffectUtility.Arc.CloneAndEmit(HitEffects.victim.dropkick, VictimRootPart)

			local clone = resources.dropkickbeams:Clone()
			clone.CFrame = RootPart.CFrame * CFrame.new(-0.037, 2.602, 0.229) * CFrame.Angles(math.rad(71.143), 0, 0)
			clone.Parent = workspace.Visuals

			quickutil:tween_single(clone, .6, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out, {["CFrame"] = clone.CFrame * CFrame.new(0, 0, -6) * CFrame.Angles(0, 0, math.rad(-190))})
			quickutil:tween_descendant(clone, "Beam", .3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {Width0 = 0, Width1 = 0}, true)
		end))
		
		MainJob:Task(MainAnimation:GetMarkerReachedSignal("leg_grab"):Connect(function()
			if EffectUtility.Distance_Close(Model) then
				CameraShake(1.5, 15, 0.01, 0.4, Vector3.one * 0.5, Vector3.one * 0.25)
				Vignette(Jin_Color, 0.75, 0.5)
			end
			
			local lil_blue_highlight = resources.highlight:Clone()
			lil_blue_highlight.OutlineColor = Color3.fromRGB(21, 31, 40)
			lil_blue_highlight.FillColor = Color3.fromRGB(220, 255, 254)
			lil_blue_highlight.FillTransparency = 0.1
			lil_blue_highlight.OutlineTransparency = 0
			lil_blue_highlight.Parent = VictimModel
			task.delay(3 / 60, lil_blue_highlight.Destroy, lil_blue_highlight)

		
			EffectUtility.Arc.CloneAndEmit(HitEffects.victim.catch, VictimRootPart)
		end))
		
		MainJob:Task(MainAnimation:GetMarkerReachedSignal("both_spin"):Connect(function()
			if Is_Source then
				Yuki_FOV.Tween(55, {1.75, Enum.EasingStyle.Sine, Enum.EasingDirection.In})
			end
			
			if EffectUtility.Distance_Close(Model) then
				CameraShake(0.75, 10, 0.01, 1.25, Vector3.one * 0.5, Vector3.one * 0.4)
			end
			
			quickutil:interact(spin, "ParticleEmitter", "Enabled", true)

			quickutil:interact(spinbeams, "Beam", "Brightness", 0)
			quickutil:interact(spinbeams.beams1.beam1, "Beam", "TextureSpeed", -.1)
			quickutil:interact(spinbeams.beams1.beam2, "Beam", "TextureSpeed", .1)

			for _, beam in ipairs(spinbeams:GetDescendants()) do
				if beam.Name == "beam1" then
					quickutil:tween_single(beam, 3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {TextureSpeed = -2})
					
				elseif beam.Name == "beam2" then
					quickutil:tween_single(beam, 3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {TextureSpeed = 2})
				end
			end

			quickutil:tween_descendant(spinbeams, "Beam", 4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, {Brightness = 2})

			task.delay(0.2, function()
				quickutil:tween_descendant(spinbeams, "Beam", 1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {Brightness = 0})
			end)
		end))
		
		MainJob:Task(MainAnimation:GetMarkerReachedSignal("throw"):Connect(function()
			if Is_Source then
				Yuki_FOV.Tween(75, {0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
			end
			
			if EffectUtility.Distance_Close(Model) then
				CameraShake(4, 40, 0.01, 0.75, Vector3.one * 0.5, Vector3.one * 0.3)
				Vignette(Jin_Color, 0.5, 0.5)
			end
			
			quickutil:interact(spin, "ParticleEmitter", "Enabled", false)
			
			local Raycast = workspace:Raycast(RootPart.Position, Vector3.yAxis * -125, Utility.VisualParams)
			
			if Raycast then
				local CF = RootPart.CFrame - (Vector3.yAxis * Raycast.Distance) + Vector3.yAxis
				local Direction = Vector3.yAxis * -10
				
				coroutine.wrap(RockHandler.Crater)(CF.Position, Direction, {
					Amount = 25,

					Distance = {
						Min = 7.5, 
						Max = 17.5
					},

					LookAt = { -- Where the rocks face towards (y axis)
						Min = 6,
						Max = -6
					},

					Exposure = {
						Min = 0.55,
						Max = 0.75
					},

					BaseZ = 1.75,
					SizeMultiplier = 1.5,
				})

				coroutine.wrap(RockHandler.Rockst)(CF.Position, Direction, {
					Count = 20,
					Size = {0.5, 2},
					Velocity = 75,
				})

				local slam = HitEffects.slam:Clone()
				slam.CFrame = CF
				ColorEffectsWithRaycast(slam, Raycast)
				slam.Parent = workspace.Visuals
				EffectUtility.Arc.EmitAttachment(slam)
				
				local Mesh = HitMeshes.slam:Clone()
				Mesh:PivotTo(CF + Vector3.yAxis * 3)

				for _, Start in ipairs(Mesh:GetDescendants()) do
					if Start.Name == "Start" then
						MeshEmit(Start, true)
					end
				end

				Mesh:Destroy()
			end
		end))
	end,
	
	["Start"] = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Windup)
		if (Retrieved == nil) then return end

		local MainAnimation = Retrieved.Animation
		local MainJob = Retrieved.Job

		local RootPart = Retrieved.RootPart

		local Is_Source = (LocalPlayer.Character == Model)

		MainJob:Task(EffectUtility.AddSFX(script.sfx.Windup, Retrieved.Torso, 0.3))
		
		if Is_Source then
			local NumberValue = MainJob:Task(Instance.new("NumberValue"))
			local CurrentTween
			
			local function Create_Velocity(Force : number, Time : number, Ease : Enum.EasingStyle, Direction : Enum.EasingDirection)
				if CurrentTween then
					CurrentTween:Cancel()
				end
				
				local Velocity = MainJob:Task(VelocityUtil.Create(RootPart))
				Velocity.MaxForce = Vector3.new(1, 0, 1) * 80000
				Velocity.Parent = RootPart
				
				NumberValue.Value = Force

				Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, Velocity, function(Delta : number)
					Velocity.Velocity = RootPart.CFrame.LookVector * NumberValue.Value
				end)

				CurrentTween = TweenService:Create(NumberValue, TweenInfo.new(Time, Ease, Direction), {Value = 0})
				CurrentTween:Play()

				CurrentTween.Completed:Once(function()
					Velocity:Destroy()
				end)
			end
			
			MainJob:Task(MainAnimation:GetMarkerReachedSignal("push"):Connect(function()
				Create_Velocity(22.5, 0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut)
			end))
			
			MainJob:Task(MainAnimation:GetMarkerReachedSignal("lunge"):Connect(function()
				local UpVelocity = Instance.new("LinearVelocity")
				UpVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
				UpVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
				UpVelocity.LineDirection = vector.create(0, 1, 0)
				UpVelocity.LineVelocity = 10
				UpVelocity.MaxForce = math.huge
				UpVelocity.Attachment0 = RootPart.RootAttachment
				UpVelocity.Parent = RootPart

				task.delay(0.2, UpVelocity.Destroy, UpVelocity)
				
				Create_Velocity(40, 1, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
			end))
			
			MainJob:Task(MainAnimation:GetMarkerReachedSignal("jump"):Connect(function()
				Create_Velocity(15, 1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			end))
			
			MainJob:Task(MainAnimation:GetMarkerReachedSignal("kick_up"):Connect(function()
				local UpVelocity = Instance.new("LinearVelocity")
				UpVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
				UpVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
				UpVelocity.LineDirection = vector.create(0, 1, 0)
				UpVelocity.LineVelocity = 12.5
				UpVelocity.MaxForce = math.huge
				UpVelocity.Attachment0 = RootPart.RootAttachment
				UpVelocity.Parent = RootPart

				TweenService:Create(UpVelocity, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {LineVelocity = 0}):Play()

				task.delay(0.4, function()
					TweenService:Create(UpVelocity, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {LineVelocity = -12.5}):Play()
					task.delay(0.5, UpVelocity.Destroy, UpVelocity)
				end)
				
				Create_Velocity(27.5, 0.675, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
			end))
			
			MainJob:Task(MainAnimation:GetMarkerReachedSignal("kick"):Connect(function()
				--Create_Velocity(35, 1.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut)
				Create_Velocity(65, 1.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
			end))
		end
		
		local LeftTrail = MainJob:Task(Effects.trails.LeftController:Clone())
		LeftTrail.Weld.Part0 = Model["Left Leg"]
		LeftTrail.Parent = Model
		
		local RightTrail = MainJob:Task(Effects.trails.RightController:Clone())
		RightTrail.Weld.Part0 = Model["Right Leg"]
		RightTrail.Parent = Model
		
		local function Slam(effect : Attachment)
			if EffectUtility.Distance_Close(Model) then
				CameraShake(1.25, 12.5, 0.01, 0.5, Vector3.one * 0.8, Vector3.one * 0.3)
			end
			
			local cf = RootPart.CFrame * effect.CFrame
			local direction = Vector3.yAxis * -20
			
			local raycast = workspace:Raycast(cf.Position, direction, Utility.VisualParams)
			if (raycast == nil) then return end
			
			local new_effect = effect:Clone()
			new_effect.WorldCFrame = cf - Vector3.new(0, raycast.Distance, 0)
			ColorEffectsWithRaycast(new_effect, raycast)
			new_effect.Parent = workspace.Terrain
			EffectUtility.Arc.EmitAttachment(new_effect)

			task.spawn(RockHandler.Crater, cf.Position, direction, {
				Amount = 6,

				Distance = {
					Min = 1, 
					Max = 2.5
				},

				LookAt = { -- Where the rocks face towards (y axis)
					Min = 6,
					Max = -6
				},

				Exposure = {
					Min = 0.3,
					Max = 0.4
				},

				BaseZ = 1.75,
				SizeMultiplier = 0.6,
				
				CanCollide = false,
			})
			
			task.spawn(RockHandler.Rockst, cf.Position, direction, {
				SpawnVariance = 0.5,
				Count = 7,
				Size = {0.1, 0.5},
				Velocity = 25,
			})
			
			return cf
		end

		MainJob:Task(MainAnimation:GetMarkerReachedSignal("hit"):Connect(function()
			EffectUtility.Arc.CloneAndEmit(Effects.kick1, RootPart)
		end))

		MainJob:Task(MainAnimation:GetMarkerReachedSignal("kick_down"):Connect(function()
			Slam(Effects.slam1)
		end))

		MainJob:Task(MainAnimation:GetMarkerReachedSignal("smack"):Connect(function()
			Slam(Effects.slam2)
		end))

		MainJob:Task(MainAnimation:GetMarkerReachedSignal("kick_up"):Connect(function()
			EffectUtility.Arc.CloneAndEmit(Effects.kick2, RootPart)
			
			if EffectUtility.Distance_Close(Model) then
				CameraShake(1, 10, 0.01, 0.35, Vector3.one * 0.8)
			end
		end))
		
		MainJob:Task(MainAnimation:GetMarkerReachedSignal("dropkick"):Connect(function()
			LeftTrail:Destroy()
			RightTrail:Destroy()
		end))
		
		MainJob:Task(MainAnimation:GetMarkerReachedSignal("fall"):Connect(function()
			if EffectUtility.Distance_Close(Model) then
				CameraShake(1, 10, 0.01, 0.4, Vector3.one * 0.8, Vector3.one * 0.3)
			end

			local effect = Effects.fall:Clone()
			effect:PivotTo(RootPart.CFrame - Vector3.yAxis * 2.716)
			effect.Parent = workspace.Visuals
			EffectUtility.Emit(effect)
		end))
	end,
	
	--["Start"] = function(Model : Model)
	--	local Retrieved = AnimationRetriever.new(Model, Animations.Windup)
	--	if (Retrieved == nil) then return end

	--	local MainAnimation = Retrieved.Animation
	--	local MainJob = Retrieved.Job
		
	--	local RootPart = Retrieved.RootPart
		
	--	local Is_Source = (LocalPlayer.Character == Model)
		
	--	local Velocity
	--	local Multiply = 0
	--	local Max = 45
		
	--	if Is_Source then
	--		Velocity = VelocityUtil.Create(RootPart, "Dragon Dropkick")
	--		Velocity.MaxForce = Vector3.new(1, 0, 1) * 80000
	--		Velocity.Parent = RootPart
			
	--		local NumberValue = Instance.new("NumberValue")
	--		NumberValue.Parent = Velocity

	--		Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, Velocity, function(Delta : number)
	--			Velocity.Velocity = RootPart.CFrame.LookVector * NumberValue.Value
	--		end)

	--		local CurrentTween = TweenService:Create(NumberValue, TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Value = 35})
	--		CurrentTween:Play()
			
	--		MainJob:Task(MainAnimation:GetMarkerReachedSignal("left_step"):Connect(function()
	--			CurrentTween:Cancel()
	--			NumberValue.Value = 10
	--			CurrentTween = TweenService:Create(NumberValue, TweenInfo.new(0.65, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Value = 45})
	--			CurrentTween:Play()
	--		end))
			
	--		MainJob:Task(MainAnimation:GetMarkerReachedSignal("right_step"):Connect(function()
	--			CurrentTween:Cancel()
	--			NumberValue.Value = 10
	--			CurrentTween = TweenService:Create(NumberValue, TweenInfo.new(0.65, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Value = 15})
	--			CurrentTween:Play()
	--		end))

	--		MainJob:Task(MainAnimation:GetMarkerReachedSignal("jump"):Connect(function()
	--			CurrentTween:Cancel()
	--			NumberValue.Value = 45
	--		end))
			
	--		MainJob:Task(MainAnimation:GetMarkerReachedSignal("kick"):Connect(function()
	--			CurrentTween:Cancel()
	--			CurrentTween = TweenService:Create(NumberValue, TweenInfo.new(0.8, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Value = 0})
	--			CurrentTween:Play()
	--		end))

	--		MainJob:Task(Velocity)
	--	end
		
	--	local function Step(name : string)
	--		local Attachment = EffectUtility.Arc.CloneAndEmit(Effects[name], RootPart)
			
	--		local Position = Attachment.WorldPosition
	--		local Direction = Vector3.yAxis * -10
			
	--		if EffectUtility.Distance_Close(Model) then
	--			CameraShake(1, 10, 0.01, 0.4, Vector3.one * 0.8, Vector3.one * 0.3)
	--			Vignette(Jin_Color, 0.6, 0.25)
	--		end
			
	--		coroutine.wrap(RockHandler.Crater)(Position, Direction, {
	--			Amount = 8,
	--			Distance = 2,

	--			LookAt = { -- Where the rocks face towards (y axis)
	--				Min = 5,
	--				Max = -5
	--			},

	--			Exposure = {
	--				Min = 0.2,
	--				Max = 0.3
	--			},

	--			BaseZ = 1.4,
	--			SizeMultiplier = 0.625,
	--		})

	--		coroutine.wrap(RockHandler.Rockst)(Position, Direction, {
	--			Count = 10,
	--			Size = {0.3, 0.75},
	--			Velocity = 65,
	--			SpawnVariance = 1.35,
	--		})
			
	--		task.wait(0.05)

	--		Dojyan_Util:afterimage(Model, 2.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, Color3.fromRGB(99, 127, 148), 0.2)
	--	end

	--	MainJob:Task(MainAnimation:GetMarkerReachedSignal("left_step"):Connect(function()
	--		Step("step1")
	--	end))
		
	--	MainJob:Task(MainAnimation:GetMarkerReachedSignal("right_step"):Connect(function()
	--		Step("step2")
	--	end))
		
	--	MainJob:Task(MainAnimation:GetMarkerReachedSignal("jump"):Connect(function()
	--		local Mesh = Meshes.jump:Clone()
	--		Mesh:PivotTo(RootPart.CFrame)

	--		for _, Start in ipairs(Mesh:GetDescendants()) do
	--			if Start.Name == "Start" then
	--				MeshEmit(Start, true)
	--			end
	--		end

	--		Mesh:Destroy()
	--	end))

	--	MainJob:Task(MainAnimation:GetMarkerReachedSignal("kick"):Connect(function()
	--		if EffectUtility.Distance_Close(Model) then
	--			CameraShake(1.5, 20, 0.01, 0.45, Vector3.one * 0.8, Vector3.one * 0.3)
	--		end
			
	--		EffectUtility.Arc.CloneAndEmit(Effects.kick, RootPart)

	--		local Mesh = Meshes.starthit:Clone()
	--		Mesh:PivotTo(RootPart.CFrame)

	--		for _, Start in ipairs(Mesh:GetDescendants()) do
	--			if Start.Name == "Start" then
	--				MeshEmit(Start, true)
	--			end
	--		end
			
	--		Mesh:Destroy()
	--	end))
		
	--	MainJob:Task(MainAnimation:GetMarkerReachedSignal("fall"):Connect(function()
	--		if EffectUtility.Distance_Close(Model) then
	--			CameraShake(1, 10, 0.01, 0.4, Vector3.one * 0.8, Vector3.one * 0.3)
	--		end

	--		local effect = Effects.fall:Clone()
	--		effect:PivotTo(RootPart.CFrame - Vector3.yAxis * 2.716)
	--		effect.Parent = workspace.Visuals
	--		EffectUtility.Emit(effect)
	--	end))
	--end,
}
