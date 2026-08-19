local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local PlayerService = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = PlayerService.LocalPlayer

local GameSettings = UserSettings().GameSettings
local MaxQuality = 10

local Assets = script.Assets

-----------------------------------------------------------------------------------------------

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

-----------------------------------------------------------------------------------------------

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local SwrermMeshVFX = require( ReplicatedStorage.Modules.Player.Replication.Global.SwrermMeshVFX )

-----------------------------------------------------------------------------------------------

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )

return {
	Slash = function(Model : Model, StartCFrame : CFrame, EndCFrame : CFrame, Duration : number)
		local RootPart : BasePart = Model:FindFirstChild("HumanoidRootPart")
		
		local CurrentQuality = Utility.GetQuality()
		local Ratio = CurrentQuality / MaxQuality

		do
			local Slash = Assets.Slash:Clone()
			Slash.CFrame = RootPart.CFrame * CFrame.new(0.289, 1.378, -0.873)
			Slash.Parent = workspace.Visuals

			for Idx, Obj in Slash:GetDescendants() do
				if Obj:IsA("ParticleEmitter") then
					task.delay(Obj:GetAttribute("EmitDelay") or 0, function()
						Obj:Emit(Obj:GetAttribute("EmitCount") or 5)
					end)
				end
			end

			task.delay(4, Slash.Destroy, Slash)
		end
		
		local Origin = StartCFrame

		local TornadoVFXEnabled = true

		local LastRock = os.clock()
		local LastEmit = os.clock()
		local LastMain = os.clock()

		local StartTime = os.clock()
		local RNG = Random.new()

		local LastPos = Vector3.zero

		local Elapsed = 0
		local MovementAlpha = 0

		local AlteredRatio = Ratio

		task.spawn(function()
			local Summon = Assets.Summon:Clone()
			Summon.CFrame = (Origin * CFrame.new(0, Summon.Size.Y / 2, 0)) * CFrame.Angles(math.rad(90), 0, 0)
			Summon.Parent = workspace.Visuals
		
			do
				local CF = (Origin * CFrame.new(0, Summon.Size.Y, 0))

				local Visual_Data = {
					[Assets.ReleaseMeshes.Last3] = {[1] = 0.6, [2] = CFrame.new(-0.532714844, 0.000189304352, 12.7113457, 1, 0, 0, 0, -4.37113883e-08, -1, 0, 1, -4.37113883e-08), [3] = .8, [4] = {[1] = {[1] = Enum.EasingStyle.Cubic, [2] = Enum.EasingDirection.Out, [3] = {["Color"] = Color3.new(0.972549, 0.972549, 0.972549), ["CFrame"] = CF * CFrame.new(-0.533004761, -2.43186951e-05, 14.4013329, 1, 0, 0, 0, -4.37113883e-08, -1, 0, 1, -4.37113883e-08), ["Transparency"] = 1, ["Size"] = Vector3.new(27.386247634887695, 0.22907276451587677, 27.386247634887695), }, }, }, },
					[Assets.ReleaseMeshes.mesh2] = {[1] = 0.8, [2] = CFrame.new(-0.000473022461, 0.499762058, 13.2657127, -0.173648089, 0, -0.984807849, 0.984807849, 0, -0.173648089, 0, -1, -0), [3] = .5, [4] = {[1] = {[1] = Enum.EasingStyle.Cubic, [2] = Enum.EasingDirection.Out, [3] = {["Color"] = Color3.new(0.972549, 0.972549, 0.972549), ["CFrame"] = CF * CFrame.new(0.000839233398, 0.499395847, -0.235668182, -0.422617674, -3.0846132e-15, 0.906308055, -0.906308055, -1.87612716e-15, -0.422617674, -4.85886262e-15, -1, 6.6316344e-15), ["Transparency"] = 1, ["Size"] = Vector3.new(19.782346725463867, 32.233585357666016, 20.014787673950195), }, }, }, },
					[Assets.ReleaseMeshes.SideWind] = {[1] = 0.3, [2] = CFrame.new(0, -0.844979763, 23.4117851, 1, 0, 0, 0, 1, 0, 0, 0, 1), [3] = .5, [4] = {[1] = {[1] = Enum.EasingStyle.Cubic, [2] = Enum.EasingDirection.Out, [3] = {["Color"] = Color3.new(0.972549, 0.972549, 0.972549), ["CFrame"] = CF * CFrame.new(0, 1.00167036, -0.781730652, 1, 0, 0, 0, 1, 0, 0, 0, 1), ["Transparency"] = 1, ["Size"] = Vector3.new(41.863426208496094, 10.682177543640137, 53.327117919921875), }, }, }, },
				}

				for i,v in pairs(Visual_Data) do
					local Visual = i.Start:Clone()
					Visual.Name = i.Name
					Visual.Transparency = v[3]
					Visual.Anchored = true
					Visual.CanCollide = false
					Visual.CanQuery = false
					Visual.CanTouch = false
					Visual.Locked = true
					Visual.CFrame = CF * v[2]
					Visual.Parent = workspace.Visuals

					TweenService:Create(Visual, TweenInfo.new(v[1], v[4][1][1], v[4][1][2]), v[4][1][3]):Play()
					task.delay(v[1],Visual.Destroy,Visual)
				end
			end
			
			EffectUtility.Emit(Summon)
		end)

		local function LockToOrigin(Part : (Attachment | BasePart), Offset)
			Offset = Offset or CFrame.identity

			task.spawn(function()
				while Part and Part.Parent do
					task.wait()
					
					if Part:IsA("Attachment") then
						Part.WorldPosition = (Origin * Offset).Position
					else
						Part.Position = (Origin * Offset).Position
					end
				end
			end)
		end

		local function GroundRocks()
			if not LastPos or (LastPos - Origin.Position).Magnitude >= 2.5 / Ratio then
				LastPos = Origin.Position

				local LookVector = (EndCFrame.Position - StartCFrame.Position).Unit

				for Idx = 1, 2 do
					local SideOffset = CFrame.new((Idx == 1 and 1 or -1) * (1.3 - MovementAlpha) * 3.5, 0, 0)

					local RandomPos = Origin * SideOffset
					local RayRes = workspace:Raycast(RandomPos.Position + Vector3.new(0, 7.5, 0), Vector3.new(0, -15, 0), Utility.VisualParams)

					if RayRes then
						task.spawn(function()
							local Size = NumberRange.new(.5, 1)
							local SideVelocity = NumberRange.new(-35, 35)
							local UpVelocity = NumberRange.new(15, 20)

							local Part = Assets.Trails["1"]:Clone()
							Part.CFrame = Origin
							Part.Size = Vector3.new(RNG:NextNumber(Size.Min, Size.Max), RNG:NextNumber(Size.Min, Size.Max), RNG:NextNumber(Size.Min, Size.Max))
							Part.Anchored = false
							Part.CanCollide = true
							Part.CanQuery = true
							Part.CanTouch = true
							Part.CastShadow = false
							Part.BottomSurface = Enum.SurfaceType.Smooth
							Part.TopSurface = Enum.SurfaceType.Smooth
							Part.Color = RayRes.Instance.Color
							Part.Material = RayRes.Material
							Part.Transparency = 0
							Part.Orientation = Vector3.new(RNG:NextNumber(-180, 180), RNG:NextNumber(-180, 180), RNG:NextNumber(-180, 180))
							Part.CollisionGroup = "Rockst"
							Part.Parent = workspace.Visuals

							local Scale = Part.Size.Magnitude / 2

							for _, Child in pairs(RayRes.Instance:GetChildren()) do
								if Child:IsA("Decal") or Child:IsA("Texture") then
									Child:Clone().Parent = Part
								end
							end

							for _, Attachment in Part:GetDescendants() do
								if not Attachment:IsA("Attachment") then
									continue
								end

								Attachment.Position = Vector3.new(Attachment.Position.X, Attachment.Position.Y * Scale, Attachment.Position.Z)
							end

							local Attachment = Instance.new("Attachment")
							Attachment.Parent = Part		

							local LinearVelocity = Instance.new("LinearVelocity")
							LinearVelocity.MaxForce = math.huge
							LinearVelocity.VectorVelocity = Vector3.new(RNG:NextNumber(SideVelocity.Min, SideVelocity.Max), RNG:NextNumber(UpVelocity.Min, UpVelocity.Max), RNG:NextNumber(SideVelocity.Min, SideVelocity.Max))
							LinearVelocity.Attachment0 = Attachment
							LinearVelocity.Parent = Attachment

							local Start = os.clock()
							local Connection = nil

							Connection = Part.Touched:Connect(function(Hit)
								if Hit.Parent and Part.Parent and Hit.CanCollide == true and os.clock() - Start > .2 then
									if Connection then
										EffectUtility.Toggle(Part, false)
										Connection:Disconnect()
										Connection = nil
									end
								end
							end)

							task.delay(1.5, function()
								local Tween = TweenService:Create(Part, TweenInfo.new(2), {
									Size = Vector3.zero
								})

								Tween:Play()

								Tween.Completed:Connect(function()
									Part:Destroy()
								end)
							end)

							task.delay(0.1, LinearVelocity.Destroy, LinearVelocity)
						end)

						local ResultInstance = RayRes.Instance
						local RandomAngle = math.rad(RNG:NextNumber(0, 360))

						local Part = Instance.new("Part")
						Part.Anchored = true
						Part.CanCollide = false
						Part.CanTouch = false
						Part.CastShadow = false
						Part.Material = RayRes.Material
						Part.Color = ResultInstance.Color
						Part.CFrame = CFrame.new(RayRes.Position) * CFrame.Angles(RandomAngle, RandomAngle, RandomAngle)
						Part.Size = Vector3.one * RNG:NextNumber(0.9, 1.6) * ((1.3 - Elapsed) * .75)
						Part.BottomSurface = Enum.SurfaceType.Smooth
						Part.TopSurface = Enum.SurfaceType.Smooth

						for _, Child in pairs(ResultInstance:GetChildren()) do
							if Child:IsA("Decal") or Child:IsA("Texture") then
								Child:Clone().Parent = Part
							end
						end

						Part.Parent = workspace.Visuals

						local Tween = TweenService:Create(Part, TweenInfo.new(1.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.In, 0, false, .5), {
							Size = Vector3.zero
						})

						Tween.Completed:Connect(function()
							Part:Destroy()
						end)

						Tween:Play()
					end
				end
			end
		end

		local function Tornado()
			if os.clock() - LastMain > 0.12 / AlteredRatio then
				LastMain = os.clock()
				
				if Player:DistanceFromCharacter(RootPart.Position) <= 50 then
					CameraShake(1, 15, 0.02, 0.1, Vector3.one * 0.7, Vector3.one * 0.2)
				end

				local Main = Assets.Main:Clone()
				Main.CFrame = Origin * CFrame.new(0, Main.Size.Y / 2, 0) * CFrame.Angles(0, math.rad(RNG:NextNumber(-180, 180)), 0)
				Main.Parent = workspace.Visuals
				Main.Transparency = RNG:NextNumber(.72, .9)

				local Tween = TweenService:Create(Main, TweenInfo.new(.6, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
					Transparency = 1,
					Orientation = Main.Orientation + Vector3.new(0, 300, 0),
					Size = Main.Size * Vector3.new(2, 1.3, 2) * RNG:NextNumber(.8, 1.2)
				})

				Tween.Completed:Connect(function()
					Main:Destroy()
				end)

				Tween:Play()

				LockToOrigin(Main, CFrame.new(0, Main.Size.Y / 2, 0))
			end
		end

		local function TornadoShockwaveAndTrails()
			if os.clock() - LastEmit > .08 / AlteredRatio then
				LastEmit = os.clock()

				local Scale = 20

				local Shockwave = Assets.Shockwave:Clone()
				Shockwave.CFrame = (Origin * CFrame.new(0, 1, 0)) * CFrame.Angles(0, math.rad(RNG:NextNumber(-180, 180)), 0)
				Shockwave.Size /= Scale
				Shockwave.Parent = workspace.Visuals

				local Tween = TweenService:Create(Shockwave, TweenInfo.new(.6, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
					Transparency = 1,
					Orientation = Shockwave.Orientation + Vector3.new(0, 360, 0),
					Size = Shockwave.Size * Vector3.new(2.2, 1.1, 2.2) * Scale * RNG:NextNumber(.8, 1.2)
				})

				Tween.Completed:Connect(function()
					Shockwave:Destroy()
				end)

				LockToOrigin(Shockwave, CFrame.new(0, 1, 0))

				Tween:Play()

				local StartOffset = CFrame.new(RNG:NextNumber(-1.5, 1.5), 0, RNG:NextNumber(-1.5, 1.5))
				local StartCFrame = Origin * StartOffset

				local Trail = Assets.Trails[math.random(1, #Assets.Trails:GetChildren())]:Clone()
				Trail.CFrame = StartCFrame
				Trail.Parent = workspace.Visuals

				task.delay(RNG:NextNumber(.3, .4), function()
					EffectUtility.Toggle(Trail, false)
					task.delay(1, Trail.Destroy, Trail)
				end)

				task.spawn(function()
					local Scale = .4

					local RadiusMultiplier = RNG:NextNumber(0,.5)

					local RadiusAddition = RNG:NextNumber(1.5, 2.25) * Scale
					local HeightAddition = RNG:NextNumber(1.2, 2.25) * Scale * 1.3
					local DegreeAddition = RNG:NextNumber(26, 40)
					local Max = DegreeAddition

					local Height = 0
					local Radius = 0

					local Degree = RNG:NextNumber(-360, 360)

					local StartTime = os.clock()

					while Trail:IsDescendantOf(game) do
						Trail.Position = (Origin * StartOffset * CFrame.new(math.cos(math.rad(Degree)) * RadiusMultiplier, Height, -math.sin(math.rad(Degree)) * RadiusMultiplier)).Position

						local Delta = task.wait()
						local FPSScale = Delta * 60

						Degree += DegreeAddition * FPSScale
						Height += HeightAddition * FPSScale

						RadiusMultiplier += RadiusAddition * FPSScale
					end
				end)
			end
		end

		local function TornadoRocks()
			local SizeDown = .2 

			if os.clock() - LastRock > 0.02 / Ratio then
				local RandomPos = Origin.Position + Vector3.new(RNG:NextNumber(-15, 15) * SizeDown, 0, RNG:NextNumber(-15, 15) * SizeDown)
				local RayRes = workspace:Raycast(RandomPos + Vector3.new(0, 7.5, 0), Vector3.new(0, -25, 0), Utility.VisualParams)

				if RayRes then
					LastRock = os.clock()

					local ResultInstance = RayRes.Instance
					local RandomAngle = math.rad(RNG:NextNumber(0, 360))

					local Part = Instance.new("Part")
					Part.Anchored = true
					Part.CanCollide = false
					Part.CanTouch = false
					Part.CastShadow = false
					Part.Material = RayRes.Material
					Part.Color = ResultInstance.Color
					Part.CFrame = CFrame.new(RayRes.Position) * CFrame.Angles(RandomAngle, RandomAngle, RandomAngle)
					Part.Size = Vector3.one * RNG:NextNumber(1.5, 3.5) * SizeDown * 2
					Part.BottomSurface = Enum.SurfaceType.Smooth
					Part.TopSurface = Enum.SurfaceType.Smooth
					Part.Parent = workspace.Visuals

					local StartCFrame = CFrame.new(RayRes.Position)
					local Offset = StartCFrame:ToObjectSpace(Origin)

					task.delay(RNG:NextNumber(.2, .4), function()
						local Tween = TweenService:Create(Part, TweenInfo.new(.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
							Size = Vector3.zero
						})

						Tween.Completed:Connect(function()
							Part:Destroy()
						end)

						Tween:Play()
					end)

					for _, Child in pairs(ResultInstance:GetChildren()) do
						if Child:IsA("Decal") or Child:IsA("Texture") then
							Child:Clone().Parent = Part
						end
					end

					local FinishAngle = math.rad(RNG:NextNumber(0, 360))
					local Goal = {
						Orientation = Vector3.new(RNG:NextNumber(500, 600), RNG:NextNumber(500, 600), RNG:NextNumber(500, 600))
					}

					TweenService:Create(Part, TweenInfo.new(1.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), Goal):Play()

					task.spawn(function()
						SizeDown *= 1.85

						local RadiusMultiplier = RNG:NextNumber(0, 0.5)

						local RadiusAddition = RNG:NextNumber(1.75, 2.5) * SizeDown
						local HeightAddition = RNG:NextNumber(1.6, 1.8) * SizeDown * 1.3
						local DegreeAddition = (RNG:NextNumber(100, 200) / RNG:NextNumber(15, 50)) * SizeDown * 2
						local Max = DegreeAddition

						local Height = 0
						local Radius = 0

						local Degree = RNG:NextNumber(-360, 360)

						local StartTime = os.clock()

						while Part:IsDescendantOf(game) do
							Part.Position = (StartCFrame * Offset * CFrame.new(math.cos(math.rad(Degree)) * RadiusMultiplier, Height, -math.sin(math.rad(Degree)) * RadiusMultiplier)).Position

							local Delta = task.wait()
							local FPSScale = Delta * 60

							Degree += DegreeAddition * FPSScale
							Height += HeightAddition * FPSScale

							RadiusMultiplier += RadiusAddition * FPSScale
						end
					end)
				end
			end
		end
		
		do
			local SFXAttachment = Instance.new("Attachment")
			local SFX = script.Tornado:Clone()

			SFXAttachment.Name = "TornadoSFX"
			SFXAttachment.WorldPosition = Origin.Position
			
			LockToOrigin(SFXAttachment, CFrame.new(0, 7, 0))

			SFXAttachment.Parent = workspace.Terrain
			SFX.Parent = SFXAttachment

			SFX:Play()
			task.delay(4, SFXAttachment.Destroy, SFXAttachment)
		end

		local TornadoGroundVFX = Assets.Effect:Clone()
		TornadoGroundVFX.CFrame = Origin
		TornadoGroundVFX.Parent = workspace.Visuals

		EffectUtility.Emit(TornadoGroundVFX.wind.ground, true)
		LockToOrigin(TornadoGroundVFX)

		local Connection; Connection = RunService.PostSimulation:Connect(function()
			if Elapsed > (Duration + 2) then
				return Connection:Disconnect()
			end

			Elapsed = os.clock() - StartTime
			MovementAlpha = TweenService:GetValue(Elapsed / Duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			Origin = StartCFrame:Lerp(EndCFrame, MovementAlpha)
			
			AlteredRatio = math.max(Ratio, 0.75)

			if Elapsed < (Duration / 1.25) then
				task.spawn(Tornado)
				task.spawn(TornadoShockwaveAndTrails)
				task.spawn(TornadoRocks)
				task.spawn(GroundRocks)
			else
				if TornadoVFXEnabled then
					EffectUtility.Toggle(TornadoGroundVFX, false)
					task.delay(5, TornadoGroundVFX.Destroy, TornadoGroundVFX)
				end
			end
		end)
		
		task.spawn(Tornado)
		task.spawn(TornadoShockwaveAndTrails)
		task.spawn(TornadoRocks)
		task.spawn(GroundRocks)
	end,
	
	Start = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, ReplicatedStorage.Animations.Attacks.Kratos["Draupnir Spin"].Windup)
		if (Retrieved == nil) then return end

		local Animation = Retrieved.Animation
		local Job = Retrieved.Job
		local RootPart = Retrieved.RootPart
	
		Job:Task(Animation:GetMarkerReachedSignal("slash"):Connect(function()
			task.spawn(function()
				local SpearModel = Model:FindFirstChild("Spear")

				if SpearModel then
					EffectUtility.Toggle(SpearModel.spear, false)
				end
			end)
			
			if Player:DistanceFromCharacter(RootPart.Position) <= 40 then
				CameraShake(1.65, 16, 0.03, 0.4, Vector3.one * 0.8, Vector3.one * 0.5)
				Vignette(Color3.fromRGB(255, 216, 116), 0.75, 0.25)
			end
		end))

		Job:Task(Animation:GetMarkerReachedSignal("spin"):Connect(function(Index : string)
			Index = tonumber(Index)
			
			if Index == 1 then
				task.spawn(function()
					local SpearModel = Model:FindFirstChild("Spear")

					if SpearModel then
						EffectUtility.Toggle(SpearModel.spear, true)
					end
				end)
			end
			
			if Player:DistanceFromCharacter(RootPart.Position) <= 25 then
				CameraShake(1.25, 10, 0.03, 0.55, Vector3.one * 0.8, Vector3.one * 0.4)
				Vignette(Color3.fromRGB(255, 216, 116), 0.75, 0.35)
			end

			local Activate = Assets.Activate:Clone()
			Activate.CFrame = RootPart.CFrame * CFrame.new(0, -2.4, 0)
			Activate.Parent = workspace.Visuals
			EffectUtility.Emit(Activate)

			local Meshes = {
				Assets.Meshes.wind,
				Assets.Meshes.wind2,
			}

			if Index > 1 and Index ~= 5 then
				table.insert(Meshes, Assets.Meshes.wind3)
				table.insert(Meshes, Assets.Meshes.wind4)

				local Spin = Assets.Spin:Clone()
				Spin.CFrame = RootPart.CFrame * CFrame.new(0, 0.85, 0)
				Spin.Parent = workspace.Visuals
				EffectUtility.Emit(Spin)
			end

			for _, Obj in Meshes do
				local Mesh = Obj:Clone()
				Mesh:PivotTo(RootPart.CFrame * Obj:GetAttribute("RootOffset"))
				Mesh.Parent = workspace.Visuals
				
				SwrermMeshVFX.Emit(Mesh)
				task.delay(4, Mesh.Destroy, Mesh)
			end
		end))
	end
}