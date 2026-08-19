local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Effects = ReplicatedStorage.Effects
local CharacterEffects = Effects.Characters

local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )

local ScreenPulse = require( ReplicatedStorage.Modules.Player.Replication.Global.ScreenPulse )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local BugoVFX = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility.Bugo )

local TimeUntilMoriVFX = {
	["Up"] = 0.35,
	["Down"] = 0.25,
}

return {
	["Edgerunner"] = function(RootPart : BasePart, Type : string, Distance : number)
		task.wait(0.15)
		
		EffectUtility.EmitEffects(script.Edgerunner.Sounds[Type], RootPart)
		
		--if (Type == "Up") then
			task.wait(0.2)
			--EffectUtility.Arc.CloneAndEmit(script.Edgerunner.Visuals.Up, RootPart)
			
			BugoVFX(script.Edgerunner.Visuals[Type], RootPart)
			
			--local test_mori = script.Mori.Up.Emit.Root:Clone()
			--test_mori.Anchored = true
			--test_mori.CFrame = RootPart.CFrame
			--test_mori.Parent = workspace.Visuals
			--EffectUtility.ToggleForTime(test_mori, 0.5)
			--task.delay(3, test_mori.Destroy, test_mori)
		--end
	end,
	
	["Mori"] = function(RootPart : BasePart, Type : string, Distance : number)
		if Type == "Up" then
			EffectUtility.EmitEffects(CharacterEffects.Mori.Swings.Uppercut, RootPart)
			
		elseif Type == "Down" then
			EffectUtility.EmitEffects(CharacterEffects.Mori.Swings.Downslam, RootPart)
		end
		
		local Time = TimeUntilMoriVFX[Type]
		
		require(CharacterEffects.Mori.M1_Trail)(RootPart, (Time * 1.3))

		task.wait(Time)
		
		if (Distance < 50) then
			BugoVFX(script.Mori[Type], RootPart)
		end
	end,
	
	["Gebura Red Mist"] = function(RootPart : BasePart, Type : string, Distance : number)
		local SoundEffect = script.RedMist:FindFirstChild(Type)

		if SoundEffect then
			EffectUtility.EmitEffects(SoundEffect, RootPart)
		end
		
		local Sword : Model = RootPart.Parent:FindFirstChild("Mimicry")
		if (Sword == nil) then return end
		
		Sword.Blade.Attachment1.Trail.Enabled = true
		
		task.delay(0.6, function()
			Sword.Blade.Attachment1.Trail.Enabled = false
		end)
		
		task.delay(0.3, function()
			if Distance < 20 then
				CameraShake(1.5, 12.5, 0.05, 0.35)
				ScreenPulse("Black Flash")
			end

			if Type == "Down" then
				local Raycast = workspace:Raycast(RootPart.Position, Vector3.yAxis * -15, Utility.VisualParams)
				local Attachment : Attachment = CharacterEffects.RedMist.Assets.Downslam:Clone()
				local AngleOffset : CFrame = CFrame.Angles(0, -math.rad(180), -math.rad(180))

				if Raycast then
					Attachment.WorldCFrame = RootPart.CFrame * CFrame.new(0.1, -Raycast.Distance, -5.15) *AngleOffset
				else
					Attachment.WorldCFrame = RootPart.CFrame * CFrame.new(0.1, -2.95, -5.15) * AngleOffset
				end

				Attachment.Parent = workspace.Terrain
				EffectUtility.Emit(Attachment)
			end
		end)
	end,
	
	["Chara"] = function(RootPart : BasePart, Type : string)
		local Knife : Model = RootPart.Parent:FindFirstChild("Knife")
		if (Knife == nil) then return end
		
		if Type == "Up" then
			Knife.Handle.BladeAttachment.Trail.Enabled = true

			task.delay(10 / 60, function()
				EffectUtility.EmitEffects(CharacterEffects.Chara.Swing, RootPart)
			end)
				
			task.delay(20 / 60, function()
				local Effect = CharacterEffects.Chara.Assets.uppercutslash:Clone()
				Effect.Parent = RootPart
				EffectUtility.Emit(Effect)
			end)

			task.delay(1, function()
				Knife.Handle.BladeAttachment.Trail.Enabled = false
			end)
		end
	end,
}
