--!nonstrict
local EnkiduEffectsModule = {}

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")

local Folder = script.Parent;

local Bezier = require(script.AkosBezierModule)
local SuperTween = require(script.NumberSequenceTween)

function ColorCorrection(Lighting, TweenTime, Info)
	TweenService:Create(Lighting, TweenInfo.new(TweenTime), Info):Play()
end

function Emit(Path)
	for _,v in pairs(Path:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			task.delay(v:GetAttribute("EmitDelay"),function()
				v:Emit(v:GetAttribute("EmitCount"))
			end)
		end
	end
end
	

local function Flash()
	local newLighting = Instance.new("ColorCorrectionEffect")
	newLighting.Parent = Lighting
	
	newLighting.Contrast = 10
	newLighting.Saturation = -2
	
	task.wait(0.1)
	
	newLighting.Contrast = -10
	newLighting.Saturation = 2
	
	task.wait(0.1)
	
	newLighting.Contrast = 0
	newLighting.Saturation = 0
	
	local Blur = Instance.new("BlurEffect",Lighting)
	Blur.Size = 24
	TweenService:Create(Blur,TweenInfo.new(1),{
		Size = 0
	}):Play()
	
	task.delay(3,Blur.Destroy,Blur)
	task.delay(3,newLighting.Destroy,newLighting)
end


function EnkiduEffectsModule.StartVFX(SHRP : BasePart) --// Assuming "Target" is a part.
	
	--// CameraShaker Init
	
	local CamShake = require(script.CameraShaker)
	local CameraShaker = CamShake.new(Enum.RenderPriority.Camera.Value, function(shakeCf)
		workspace.CurrentCamera.CFrame *= shakeCf
	end)
	CameraShaker:Start()	
	
	--// Lighting
	local newLighting = Instance.new("ColorCorrectionEffect")
	newLighting.Parent = Lighting
	
	--// Start VFX
	
	TweenService:Create(Lighting,TweenInfo.new(1),{
		ClockTime = 0;
	}):Play()

	local SPOS = SHRP.Position
	
	local SFX = Folder.SFX:Clone()
	SFX.Parent = SHRP
	SFX:Play()
	task.delay(40,SFX.Destroy,SFX)
	
	--// Config Vars
	local Chains = {}
	local UsedPositions = {}
	local Pivot = 125
	local MinDistance = 25

	--// VFX
	local Floor = Folder.Floor:Clone()
	Floor.Position = SPOS
	Floor.Parent = workspace.Visuals
	
	local Enkidu2 = Folder.Enkidu2:Clone()
	Enkidu2.Parent = workspace.Visuals
	Enkidu2:PivotTo(CFrame.new(SPOS))
	
	local Start_Emit = Folder.Emit_Start:Clone()
	Start_Emit.Position = SPOS
	Start_Emit.Parent = workspace.Visuals
	Emit(Start_Emit)
	task.delay(5,Start_Emit.Destroy,Start_Emit)
	CameraShaker:ShakeOnce(2,5,0.1,0.1)
	
	local First_Splash = Folder.STARTO_SPLASHO:Clone()
	First_Splash.Position = Enkidu2.Model.PrimaryPart.Position
	First_Splash.Parent = workspace.Visuals
	Emit(First_Splash)
	task.delay(5,First_Splash.Destroy,First_Splash)
	
	CameraShaker:ShakeOnce(2,5,0.1,0.1)
	Flash()
	TweenService:Create(Enkidu2.Model.PrimaryPart,TweenInfo.new(3),{
		Position = Enkidu2.Model.PrimaryPart.Position + Vector3.new(0,250,0)
	}):Play()
	
	task.wait(2.5)
	
	--// STARTT THE WINDDDDD
	
	local Wind_Cresents = Folder.wind:Clone()
	Wind_Cresents.Position = SPOS + Vector3.new(0,150,0) --Enkidu2.Model.PrimaryPart.Position
	Wind_Cresents.Parent = workspace.Visuals
	
	local Floor2 = Folder.FLOOR2:Clone()
	Floor2.Position = SPOS + Vector3.new(0,250,0)
	Floor2.Parent = workspace.Visuals

	local Particle = Folder.Emit_Start:Clone()
	Particle.Position = Enkidu2.Model.PrimaryPart.Position
	Particle.Parent = workspace.Visuals
	Emit(Particle)
	task.delay(5,Particle.Destroy,Particle)
	CameraShaker:ShakeOnce(2,5,0.1,0.1)
	Flash()
	
	for _,v in pairs(Enkidu2:GetDescendants()) do
		if v:IsA("Beam") then
			TweenService:Create(v,TweenInfo.new(1),{
				Width0 = 0;
				Width1 = 0;
			}):Play()
		elseif v:IsA("MeshPart") then
			v.Transparency = 1
		end
	end
	
	local Top_Multiplier = 1.25
	for i = 1,50 do
		local Position
		local isUnique = false
		local attempts = 0

		repeat
			Position = Vector3.new(
				math.random(-Pivot*Top_Multiplier, Pivot*Top_Multiplier),
				-5,
				math.random(-Pivot*Top_Multiplier, Pivot*Top_Multiplier)
			)

			isUnique = true
			for _, pos in ipairs(UsedPositions) do
				if (pos - Position).Magnitude < MinDistance then
					isUnique = false
					break
				end
			end

			attempts += 1
		until isUnique or attempts > 20 -- avoid infinite loop

		if isUnique then
			table.insert(UsedPositions, Position)

			local Model = Folder.Enkidu:Clone()
			Model:PivotTo(CFrame.new(Floor2.Position + Position) * CFrame.Angles(math.rad(90 + 180),0,0))
			Model.Parent = workspace.Visuals
			Model.PrimaryPart.Orientation = Vector3.new(90 + 180,math.random(-360,360),0)
			table.insert(Chains, Model)
			
			local Particle = Folder.Emit2:Clone()
			Particle.Parent = workspace.Visuals
			Particle:PivotTo(CFrame.new(Floor2.Position + Position))
			Emit(Particle)
			task.delay(5,Particle.Destroy,Particle)
		end

		CameraShaker:ShakeOnce(2,5,0.1,0.1)
		task.wait(0.05) --0.1
	end

	
	local OriginalTime = 3
	
	for _,v in Chains do
		local Arrow = v.Model
		v.Part.default:Destroy()
		v.Part.Anchored = true
		
		local Time = math.random(OriginalTime/2,OriginalTime)
		
		task.delay(math.random(0,250)/100,function() --//
			Arrow.PrimaryPart.CFrame = CFrame.lookAt(Arrow.PrimaryPart.Position,Enkidu2.Model.PrimaryPart.Position) * CFrame.Angles(math.rad(180),0,0)

			local Particle = Folder.Emit:Clone()
			Particle.Position = Arrow.PrimaryPart.Position
			Particle.Parent = workspace.Visuals
			Emit(Particle)
			task.delay(5,Particle.Destroy,Particle)
			CameraShaker:ShakeOnce(2,5,0.1,0.1)

			
			local goal = Floor.Position + Vector3.new(math.random(-Pivot,Pivot),0,math.random(-Pivot,Pivot))
			
			TweenService:Create(Arrow.PrimaryPart,TweenInfo.new(0.25),{
				CFrame = CFrame.lookAt(goal + Vector3.new(0,0.1,0),goal)  * CFrame.Angles(math.rad(-90),0,0) 
			}):Play()
			
			task.wait(0.25)
			
			local Particle = Folder.Emit2:Clone()
			Particle.Parent = workspace.Visuals
			Particle.Position = Arrow.PrimaryPart.Position
			Emit(Particle)
			task.delay(5,Particle.Destroy,Particle)
			CameraShaker:ShakeOnce(2,5,0.1,0.1)

		end)
	end
	
	
	task.wait(3)
		
	CameraShaker:ShakeOnce(3,50,3,3)

	local Info = TweenInfo.new(
		4,
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.InOut
	)
	
	--// you cant tween beams normaly... plz forgive this slop code
	for _,v in pairs(Floor.MAGICA:GetChildren()) do
		if v:IsA("ParticleEmitter") then
			local TargetSequence = NumberSequence.new({ 
				NumberSequenceKeypoint.new(0, 0), 
				NumberSequenceKeypoint.new(0.5,0), 
				NumberSequenceKeypoint.new(1, 0)
			})

			local Tween = SuperTween.new(v, TargetSequence, Info, "Size")
			Tween:Play()			
		end
	end
	
	for _,v in pairs(Floor:GetChildren()) do
		if v:IsA("ParticleEmitter") then
			v.Enabled = false;			
		end
	end
	for _,v in pairs(Floor["I WNAT UPPIES TOO CMON IM SO LONLEY"]:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			v.Enabled = false;			
		end
	end
	
	for _,v in pairs(Floor2.MAGICA:GetChildren()) do
		if v:IsA("ParticleEmitter") then
			local TargetSequence = NumberSequence.new({ 
				NumberSequenceKeypoint.new(0, 0), 
				NumberSequenceKeypoint.new(0.5,0), 
				NumberSequenceKeypoint.new(1, 0)
			})

			local Tween = SuperTween.new(v, TargetSequence, Info, "Size")
			Tween:Play()			
		end
	end


	for _,v in pairs(Floor.EXTTRAAA:GetChildren()) do
		if v:IsA("ParticleEmitter") then
			local TargetSequence = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0), 
				NumberSequenceKeypoint.new(0.5,0), 
				NumberSequenceKeypoint.new(1, 0)
			})

			local Tween = SuperTween.new(v, TargetSequence, Info, "Size")
			Tween:Play()			
		end
	end

	for _,v in pairs(Floor2.EXTTRAAA:GetChildren()) do
		if v:IsA("ParticleEmitter") then
			local TargetSequence = NumberSequence.new({ 
				NumberSequenceKeypoint.new(0, 0), 
				NumberSequenceKeypoint.new(0.5,0), 
				NumberSequenceKeypoint.new(1, 0)
			})

			local Tween = SuperTween.new(v, TargetSequence, Info, "Size")
			Tween:Play()			
		end
	end
	
	for i, CurrentChain in pairs(Chains) do
		local Model = CurrentChain.Model
		local centerPos = SPOS + Vector3.new(0,5,0)

		local initialRadius = (Model.PrimaryPart.Position - centerPos).Magnitude
		local radius = initialRadius

		local angleSpeed = math.rad(10) 
		local angle = math.atan2(Model.PrimaryPart.Position.Z - centerPos.Z, Model.PrimaryPart.Position.X - centerPos.X) 
		
		CurrentChain.Part.trail.shoot_trail.Enabled = true;
		CurrentChain.Part.trail.drag_trail.Enabled = true;
		
		TweenService:Create(CurrentChain.Part,TweenInfo.new(4),{
			Position = Floor2.Position
		}):Play()
		
		TweenService:Create(CurrentChain.Part.Beams["CHAIN"],TweenInfo.new(4),{
			Brightness = 1;
			LightEmission = 0;
			Width1 = 0;
			Width0 = 0;
		}):Play()
		TweenService:Create(CurrentChain.Part.Beams["Beam1"],TweenInfo.new(4),{
			Brightness = 1;
			LightEmission = 0;
			Width1 = 0;
			Width0 = 0;
		}):Play()
		TweenService:Create(CurrentChain.Part.Beams["Beam126"],TweenInfo.new(7),{
			Width1 = 0;
			Width0 = 35;
		}):Play()
		
		task.spawn(function()
			while radius > 0 do
				if not Model or not Model.PrimaryPart then break end
				angle += angleSpeed

				local x = centerPos.X + math.cos(angle) * radius
				local z = centerPos.Z + math.sin(angle) * radius
				local y = centerPos.Y + 1 

				Model.PrimaryPart.CFrame = CFrame.new(Vector3.new(x, y, z)) 
				
				radius = math.max(radius - 3, 0) 

				task.wait(0.04) 
			end
		end)
	end
	
	
	task.wait(3)
	
	for _,v in pairs(Chains) do
		v:Destroy()
	end
	
	local NewEnkidu = Folder.FINAL_ENKIDU:Clone()
	NewEnkidu.Parent = workspace.Visuals
	NewEnkidu:PivotTo(CFrame.new(SPOS + Vector3.new(0,300,0)) * CFrame.Angles(math.rad(180),0,0))
	
	local Final_Splash = Folder.STARTO_SPLASHO:Clone()
	Final_Splash.Position = NewEnkidu.Model.PrimaryPart.Position
	Final_Splash.Parent = workspace.Visuals
	Emit(Final_Splash)
	task.delay(5,Final_Splash.Destroy,Final_Splash)

	CameraShaker:ShakeOnce(2,50,0.1,0.1)
	Flash()
	
	CameraShaker:ShakeOnce(2,50,1,4)

	task.wait(4)

	TweenService:Create(NewEnkidu.Model.PrimaryPart,TweenInfo.new(1),{
		Position = NewEnkidu.Model.PrimaryPart.Position + Vector3.new(0,-240,0) --//200
	}):Play()
	
	CameraShaker:ShakeOnce(10,150,0.1,1)

	task.wait(0.9)
	
	CameraShaker:ShakeOnce(25,250,0.5,1.5)
	Flash()
	
	local Final_Big_Splash_2 = Folder.Emit_Final:Clone()
	Final_Big_Splash_2.Position = NewEnkidu.Model.PrimaryPart.Position
	Final_Big_Splash_2.Parent = workspace.Visuals
	Emit(Final_Big_Splash_2)
	
	local function freeze(Part)
		for _,v in pairs(Part:GetDescendants()) do
			if v:IsA("ParticleEmitter") then
				TweenService:Create(v,TweenInfo.new(0.75),{
					TimeScale = 0
				}):Play()
			elseif v:IsA("Beam") then
				TweenService:Create(v,TweenInfo.new(0.75),{
					TextureSpeed = 0
				}):Play()
			end
		end
	end
	
	
	freeze(Floor)
	freeze(Floor2)
	freeze(Wind_Cresents)
	freeze(Final_Big_Splash_2)
	freeze(NewEnkidu)
	freeze(Enkidu2)

	newLighting.Saturation = -1
	
	task.wait(3)
	
	Flash()
	
	Floor:Destroy()
	Floor2:Destroy()
	Wind_Cresents:Destroy()
	Final_Big_Splash_2:Destroy()
	NewEnkidu:Destroy()
	Enkidu2:Destroy()
	
	CameraShaker:ShakeOnce(25,250,0.5,6)
	
	local Grand_Finale = Folder.GRAND_FINALE:Clone()
	Grand_Finale.Position = SPOS
	Grand_Finale.Parent = workspace.Visuals

	local Final_Final_Final_Explosion = Folder.Emit_Final_final:Clone()
	Final_Final_Final_Explosion.Position = SPOS
	Final_Final_Final_Explosion.Parent = workspace.Visuals
	Emit(Final_Final_Final_Explosion)
	
	task.delay(10,Final_Final_Final_Explosion.Destroy,Final_Big_Splash_2)
	
	Flash()
	newLighting.Contrast = 2
	newLighting.Saturation = -0.5
	newLighting.Brightness = 0.2
	newLighting.TintColor = Color3.fromRGB(255, 233, 167)

	task.wait(5)

	TweenService:Create(newLighting,TweenInfo.new(3),{
		Contrast = 0;
		Saturation = 0;
		Brightness = 0;
		TintColor = Color3.fromRGB(255,255,255)
	}):Play()
	
	for _,v in pairs(Grand_Finale:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			v.Enabled = false
		elseif v:IsA("Beam") then
			TweenService:Create(v,TweenInfo.new(0.25),{
				Width0 = 0;
				Width1 = 0;
			}):Play()
		end
	end

	
	task.wait(3)

	TweenService:Create(Lighting,TweenInfo.new(1),{
		ClockTime = 12;
	}):Play()
	
	Grand_Finale:Destroy()
	newLighting:Destroy()
end


return EnkiduEffectsModule