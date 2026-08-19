local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Effects = ReplicatedStorage.Effects
local CharacterEffects = Effects.Characters

local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local BugoVFX = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility.Bugo )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local AnimationRetriever = require(ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever)

local AnubisM1Anims = ReplicatedStorage.Animations.Attacks.Global.M1.Anubis

local TimeUntilMoriVFX = {
	[1] = 0.075,
	[2] = 0.08,
	[3] = 0.175,
	[4] = 0.3,
}

local TimeUntilAnubisVFX = {
	[1] = 19/60,
	[2] = 23/60,
	[3] = 20/60,
	[3.5] = 31/60,
	[4] = 12/60,
	[4.5] = 26/30,
}

return {
	["Edgerunner"] = function(RootPart : BasePart, Count : number, Distance : number)
		EffectUtility.EmitEffects(script.Edgerunner.Sounds[Count], RootPart)

		if (Count == 4) then
			task.wait(0.2)
			
			if Distance < 100 then
				EffectUtility.Arc.CloneAndEmit(script.Edgerunner.Visuals["4"], RootPart)
			end
			
			if (Distance < 15) then
				CameraShake(1.25, 12.5, 0.01, 0.3, Vector3.one * 0.8)
				Vignette(Color3.fromRGB(255, 103, 15), 0.5, 0.3)
			end
		end
	end,
	
	["Mori"] = function(RootPart : BasePart, Count : number, Distance : number)
		EffectUtility.EmitEffects(script.Mori.Sounds:FindFirstChild(`{Count}`), RootPart)
		
		local Time = TimeUntilMoriVFX[Count]
		
		require(CharacterEffects.Mori.M1_Trail)(RootPart, Time)
		
		task.wait(Time)
		
		if (Distance < 50) then
			BugoVFX(script.Mori.Visuals[Count], RootPart)
		end
	end,
	
	["Gebura Red Mist"] = function(RootPart : BasePart, Count : number, Distance : number)
		EffectUtility.EmitEffects(script.RedMist:FindFirstChild(`{Count}`), RootPart)
		
		local Sword : Model = RootPart.Parent:FindFirstChild("Mimicry")
		if (Sword == nil) then return end
		
		if Count == 3 then
			return
		end

		Sword.Blade.Attachment1.Trail.Enabled = true

		task.delay(0.5, function()
			Sword.Blade.Attachment1.Trail.Enabled = false
		end)

		EffectUtility.CloneAndEmit(CharacterEffects.RedMist.Swings[Count], RootPart)
	end,

	["Kratos"] = function(RootPart : BasePart, Count : number, Distance : number, CurrentlyUsing : string)
		if script.Kratos:FindFirstChild(CurrentlyUsing) then
			EffectUtility.EmitEffects(script.Kratos[CurrentlyUsing][Count], RootPart)
		else
			EffectUtility.Emit(script.Kratos.Fists[Count], RootPart)
		end
	end,

	["Chara"] = function(RootPart : BasePart, Count : number, Distance : number)
		if Count == 2 or Count == 4 then
			local Knife : Model = RootPart.Parent:FindFirstChild("Knife")
			if (Knife == nil) then return end

			EffectUtility.EmitEffects(CharacterEffects.Chara.Swing, RootPart)
			Knife.Handle.BladeAttachment.Trail.Enabled = true

			task.delay(0.05, function()
				if Count == 2 then
					local Effect = CharacterEffects.Chara.Assets.slash:Clone()
					Effect.Parent = RootPart
					EffectUtility.Emit(Effect)

				elseif Count == 4 then
					local Effect = CharacterEffects.Chara.Assets.finalm1swing:Clone()
					Effect.Parent = RootPart
					EffectUtility.Emit(Effect)
				end
			end)

			task.delay(0.3, function()
				Knife.Handle.BladeAttachment.Trail.Enabled = false
			end)
		end
	end,
	
	["Anubis"] = function(RootPart : BasePart, Count : number, Distance : number)
		--EffectUtility.EmitEffects(script.Mori.Sounds:FindFirstChild(`{Count}`), RootPart)
		local Retrieved = AnimationRetriever.new(RootPart.Parent, AnubisM1Anims:FindFirstChild(`{Count}`))
		
		if (Retrieved == nil) then
			return
		end
		
		local Time = TimeUntilAnubisVFX[Count]
		
		--require(CharacterEffects.Mori.M1_Trail)(RootPart, Time)
		
		local Start = os.clock()
		
		while (Retrieved.Animation.IsPlaying) and (Retrieved.Animation.TimePosition < Time) and (os.clock() - Start < 1) do
			task.wait()
		end
		
		if not Retrieved.Animation.IsPlaying then
			return
		end
		
		if (Distance < 50) then
			BugoVFX(script.Anubis.Visuals[Count], RootPart)
		end
		
		if (Distance < 100) then
			EffectUtility.EmitEffects(script.Anubis.Sounds.Swing[Count], RootPart)
		end
		
		if not table.find({3, --[[4]]}, Count) then
			return
		end
		
		local Time = TimeUntilAnubisVFX[Count + 0.5]
		
		local Start = os.clock()

		while (Retrieved.Animation.IsPlaying) and (Retrieved.Animation.TimePosition < Time) and (os.clock() - Start < 1) do
			task.wait()
		end

		if not Retrieved.Animation.IsPlaying then
			return
		end
		
		if (Distance < 50) then
			BugoVFX(script.Anubis.Visuals[Count + 0.5], RootPart)
		end
	end,
	
	["Hornet"] = function(RootPart : BasePart, Count : number, Distance : number)
		if Count ~= 3 then
			EffectUtility.CloneAndEmit(script.Hornet[Count].Slash.SlashVFX, RootPart)
			local GroundVFX = script.Hornet.Ground:Clone()
			GroundVFX.CFrame = RootPart.CFrame * CFrame.new(0.059, -2.644, -0.145) * CFrame.Angles(0, math.rad(90), 0)
			GroundVFX.Parent = workspace.Terrain
			EffectUtility.Emit(GroundVFX)
			task.delay(4, GroundVFX.Destroy, GroundVFX)
		end
	end,
}
