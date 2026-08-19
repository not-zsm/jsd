--!nonstrict
local EffectsModule = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local TekrinnDialogue = require( ReplicatedStorage.Modules.TekrinnDialogue )

function Emit(Path)
	for _,v in pairs(Path:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			task.delay(v:GetAttribute("EmitDelay"),function()
				v:Emit(v:GetAttribute("EmitCount"))
			end)
		end
	end
end

local function flash()
	local NewLighting = Instance.new("ColorCorrectionEffect",game.Lighting)
	NewLighting.Parent = game.Lighting
	task.delay(5,NewLighting.Destroy,NewLighting)

	NewLighting.Saturation = -20
	NewLighting.Contrast = -100
	NewLighting.Saturation = -1.2

	task.wait(0.05)

	NewLighting.Brightness = 10
	NewLighting.Contrast = 100
	NewLighting.Saturation = -1.2
	task.wait(0.05)

	NewLighting:Destroy()
end

local function blur(size)
	local Blur = Instance.new("BlurEffect")
	Blur.Parent = game.Lighting
	Blur.Size = size or 24
	TweenService:Create(Blur,TweenInfo.new(2),{
		Size = 0
	}):Play()
	task.delay(3,Blur.Destroy,Blur)
end

function EffectsModule.StartVFX(HumanoidRootPart : BasePart) --// Assuming "Target" is the HumanoidRootPart

	--// Variables

	local Folder = script.Parent
	local Character = HumanoidRootPart.Parent
	
	local BezierModule = require(script.AkosBezierModule)
	local RocksModule = require(script.RocksModule)
	local FloatRocks = require(script.FloatRocks)
	local Camera = workspace.CurrentCamera

	--// CameraShaker Init

	local CamShake = require(script.CameraShaker)
	local CameraShaker = CamShake.new(Enum.RenderPriority.Camera.Value,function(shakeCf)
		workspace.CurrentCamera.CFrame *= shakeCf
	end)
	CameraShaker:Start()

	--// Params for raycast
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = {workspace.Map} --// CHANGE. THIS. 

	--// Main raycast
	local result = workspace:Raycast(HumanoidRootPart.Position,Vector3.new(0,-100,0),raycastParams)

	--// Just incase
	if not result or not result.Position then warn("Chibaku Tensei: Raycast Failed, yielding") return end --// no surface detected, or something went wrong
	local SHRP = result.Position
	
	local SFX = Folder.SFX:Clone()
	SFX.Parent = HumanoidRootPart
	SFX:Play()

	if not SFX.IsLoaded then
		SFX.Loaded:Wait()
	end

	task.delay(45,SFX.Destroy,SFX)

	local Rain = Folder.newRain:Clone()
	Rain.Parent = workspace
	Rain:PivotTo(CFrame.new(SHRP))
	
	local function Speak(Text : string, Time : number, TypeSpeed : number?)
		local TypeSpeed = TypeSpeed or string.len(Text) / 100
		local DialogueTime = Time / 1.5

		TekrinnDialogue.Speak(Character, 

			{
				Text = Text,
				Image = "17189234841",
				ExtraImageSize = UDim2.fromOffset(15, 15),
				TextStrokeColor = Color3.new(0, 0, 0),
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),
					ColorSequenceKeypoint.new(0.25, Color3.fromRGB(181, 53, 53)),
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(109, 32, 32)),
					ColorSequenceKeypoint.new(0.75, Color3.fromRGB(181, 53, 53)),
					ColorSequenceKeypoint.new(1, Color3.new(1, 0, 0))
				}),
				Shake = {
					Lifetime = DialogueTime,
					Enabled = true,
					Intensity = 5,
				},
				TypeSpeed = TypeSpeed,
			}, 

			{
				StrokeColor = Color3.new(0, 0, 0),
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),
					ColorSequenceKeypoint.new(0.25, Color3.fromRGB(181, 53, 53)),
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(109, 32, 32)),
					ColorSequenceKeypoint.new(0.75, Color3.fromRGB(181, 53, 53)),
					ColorSequenceKeypoint.new(1, Color3.new(1, 0, 0))
				}),
			}, 

			DialogueTime
		)

		task.wait(Time)
	end


	task.spawn(function()
		--local Jimpee = Instance.new("Configuration")
		--Jimpee.Name = "Jimpee"

		Speak("[Laughing]", 6)
		Speak("[Sigh]", 3)
		Speak("Run?", 2.35)
		Speak("Who's Running?", 2.5, 0.075)
		Speak("Running Where?", 3.5, 0.075)
		Speak("AND WHY?!", 5)

		--Jimpee:Destroy()
	end)

	task.wait(18)
	Rain:Destroy()

	--// LIGHTINGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG
	local newLighting = Instance.new("ColorCorrectionEffect")
	newLighting.Parent = game.Lighting

	TweenService:Create(newLighting,TweenInfo.new(1),{
		Brightness = -0.1;
		Contrast = 0.1;
		Saturation = 0.1;
	}):Play()
	CameraShaker:ShakeOnce(5,5,0.1,1)

	local StartEffects = Folder.FirstStage:Clone()
	StartEffects.Parent = workspace
	StartEffects:PivotTo(CFrame.new(SHRP + Vector3.new(0,-5,0)))
	task.delay(15,StartEffects.Destroy,StartEffects)

	local EmitPart = Folder.Emit:Clone()
	EmitPart.Parent = workspace
	EmitPart.Position = SHRP
	Emit(EmitPart)
	task.delay(5,EmitPart.Destroy,EmitPart);
	flash()
	CameraShaker:ShakeOnce(5,5,0.5,2)

	task.wait(1)

	local FirstExplosionVFX = Folder.PART2BOOM:Clone()
	FirstExplosionVFX.Parent = workspace
	FirstExplosionVFX.Position = SHRP
	Emit(FirstExplosionVFX)
	task.delay(5,FirstExplosionVFX.Destroy,FirstExplosionVFX);

	local Uppies = Folder.idk:Clone()
	Uppies.Parent = workspace
	Uppies.Position = SHRP
	for _,v in pairs(Uppies:GetDescendants()) do 
		if v:IsA("ParticleEmitter") then
			TweenService:Create(v,TweenInfo.new(5),{
				Acceleration = v.Acceleration * 8;
			}):Play()
		end
	end



	local LineFXTable = {}
	local Connections = {}

	local Radius = 240 --/80

	local IntValue = Instance.new("IntValue",workspace)
	IntValue.Value = Radius
	TweenService:Create(IntValue,TweenInfo.new(7,Enum.EasingStyle.Exponential,Enum.EasingDirection.In),{
		Value = 0;
	}):Play()

	TweenService:Create(newLighting,TweenInfo.new(5),{
		Contrast = 1;
		Brightness = -0.3;
		Saturation = 0.1;
	}):Play()

	for i = 0, 360, 60 do
		task.spawn(function()
			for j = 1, 5 do
				task.spawn(function()
					--// Init line fx
					local LineFX = Folder.LineFX:Clone()
					table.insert(LineFXTable,LineFX)

					LineFX.Parent = workspace
					LineFX.Position = SHRP
					LineFX.Orientation = Vector3.new(0,i,0)

					--// tween
					TweenService:Create(LineFX,TweenInfo.new(1),{
						CFrame = LineFX.CFrame * CFrame.new(0,0,-Radius);
					}):Play()

					task.wait(1)

					LineFX.CFrame *= CFrame.Angles(0,math.rad(90),0)
					local Speed = 1 
					local Angle = math.rad(i)


					local connection
					table.insert(Connections,connection)
					connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
						Angle += Speed * dt
						Radius = IntValue.Value

						local x = math.cos(Angle) * Radius
						local z = math.sin(Angle) * Radius

						local tangent = Vector3.new(-math.sin(Angle), 0, math.cos(Angle))
						local position = SHRP + Vector3.new(x, 0, z)

						LineFX.CFrame = CFrame.lookAt(position, position + tangent)
					end)

					--task.wait(5)
					--connection:Disconnect()
					--LineFX:Destroy()
				end)
				task.wait(0.8)
			end
		end)
	end

	CameraShaker:ShakeOnce(3,50,3,7)
	CameraShaker:ShakeOnce(5,5,0.1,1)


	task.wait(7)

	--// Start Disabling Effects

	for _,v in pairs(Connections) do
		v:Disconnect()
	end

	for _,v in pairs(LineFXTable) do
		v:Destroy()
	end


	local SecondExplosionVFXX = Folder.DAODIAJKDWIPA0:Clone()
	SecondExplosionVFXX.Parent = workspace
	SecondExplosionVFXX.Position = SHRP
	Emit(SecondExplosionVFXX)
	task.delay(5,SecondExplosionVFXX.Destroy,SecondExplosionVFXX);

	for _,v in pairs(StartEffects:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			v.Enabled = false;
		elseif v:IsA("Beam") then
			TweenService:Create(v,TweenInfo.new(1),{
				Width0 = 0;
				Width1 = 0;
			}):Play()
		end
	end
	for _,v in pairs(Uppies:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			v.Enabled = false;
		end
	end

	flash()
	CameraShaker:ShakeOnce(5,5,0.1,0.1)
	TweenService:Create(newLighting,TweenInfo.new(1),{
		Contrast = 0;
		Brightness = 0;
		Saturation = 0;
	}):Play()
	
	task.spawn(function()
		Speak("I AM ATOMIC", 5, 0.02)
	end)

	local Impacts = Folder.Impact:Clone()
	Impacts.Parent = workspace
	Impacts.Position = SHRP
	Emit(Impacts)

	task.wait(4)

	local FinalExplosion = Folder.FINALBOOM:Clone()
	FinalExplosion.Parent = workspace
	FinalExplosion.Position = SHRP
	Emit(FinalExplosion)
	task.delay(5,FinalExplosion.Destroy,FinalExplosion);

	local Ending = Folder.Ending:Clone()
	Ending.Parent = workspace
	Ending:PivotTo(CFrame.new(SHRP))

	for _,v in pairs(Ending:GetDescendants()) do
		if v:IsA("ParticleEmitter") or v:IsA("Beam") then
			v.Enabled = true
		end
	end

	CameraShaker:ShakeOnce(10,50,0.1,7)
	flash()
	TweenService:Create(newLighting,TweenInfo.new(1),{
		Contrast = 50;
		Brightness = 1;
		Saturation = -0.1;
		TintColor = Color3.fromRGB(255,24,224)
	}):Play()

	for i = 1 , 25 do
		task.delay(math.random(0,200)/100,function()

			local dist = 200 * 3

			local rock = Folder.EndingBlocks:Clone()
			rock.Parent = workspace
			rock.Position = SHRP + Vector3.new(math.random(-dist,dist),math.random(-150,60),math.random(-dist,dist))
			rock.Orientation = Vector3.new(math.random(-360,360),math.random(-360,360),math.random(-360,360))

			TweenService:Create(rock,TweenInfo.new(10),{
				Position = rock.Position + Vector3.new(0,math.random(150,300),0)
			}):Play()

			task.wait(6)
			rock.Flashstep.Enabled = false;

			TweenService:Create(rock,TweenInfo.new(0.1),{
				Size = Vector3.new(0,0,0)
			}):Play()

			task.wait(0.2)
			rock:Destroy()


		end)
	end

	task.wait(6)

	local SecondExplosionVFX = Folder.FINALBOOM:Clone()
	SecondExplosionVFX.Parent = workspace
	SecondExplosionVFX.Position = SHRP
	Emit(SecondExplosionVFX)
	task.delay(5,SecondExplosionVFX.Destroy,SecondExplosionVFX);
	CameraShaker:ShakeOnce(15,25,0.1,3)
	flash()

	Ending:Destroy()
	newLighting:Destroy()
	Uppies:Destroy()
	Impacts:Destroy()
	IntValue:Destroy()
end


return EffectsModule