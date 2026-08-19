local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------------------

local DialogueManager = require( ReplicatedStorage.Modules.Player.Character.Combat.UI.DialogueManager )
local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )

---------------------------------------------------------------------

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )


local RunCameraRig = require( ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

---------------------------------------------------------------------

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local VelocityUtil = require( ReplicatedStorage.Modules.Shared.Game.Velocity.VelocityUtil )
local Smoke = require( ReplicatedStorage.Modules.Player.Replication.Global.Smoke )
local Indicator = require ( ReplicatedStorage.Packages.Indicator )
local Signal = require(ReplicatedStorage.Modules.Shared.Utilities.EventService)

---------------------------------------------------------------------

local DeliveryIndicator = nil
local CrateIndicator = nil

local ChoseToMark = nil
-- local Ended = Signal.new()

return {
	SpawnCrate = function(Case : Part, SpawnCFrame : CFrame, TweenDuration : Number)
		if not Case then
			return
		end
		
		Case.Transparency = 1
		
		-- Create Falling Tween
		local CrateFallVisual = script.Assets.fallingcrate:Clone()
		local FallSFX = EffectUtility.AddSFX(script.Assets.FallLoop, CrateFallVisual, 0.5)
		task.delay(TweenDuration + 8, CrateFallVisual.Destroy, CrateFallVisual)
		CrateFallVisual.CFrame = SpawnCFrame * CFrame.new(0, 1000, 0)
		CrateFallVisual.Parent = workspace.Visuals

		local FallTweenParameters = TweenInfo.new(TweenDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local FallTween = TweenService:Create(CrateFallVisual, FallTweenParameters, {CFrame = SpawnCFrame})
		
		FallTween:Play()
		task.wait(TweenDuration)
		
		Case.Transparency = 0
		CrateFallVisual.Transparency = 1
		EffectUtility.Toggle(CrateFallVisual, false)
		
		local Explosion = script.Assets.Explosion:Clone()
		task.delay(8, Explosion.Destroy, Explosion)
		Explosion.Parent = workspace.Visuals
		Explosion:PivotTo(SpawnCFrame * CFrame.new(0, -0.75, 0))
		FallSFX:Destroy()
		local SFX : Sound = EffectUtility.AddSFX(script.Assets.Slam, Explosion.slam, 0.3)
		
		--print(SFX.Parent)
		
		--SFX.Destroying:Once(function()
		--	print("Destroyed")
		--end)
		
		EffectUtility.Emit(Explosion.slam)
		
		---------------------------------------------------------
		local DistanceFromCase = LocalPlayer:DistanceFromCharacter(Case.Position)
		if DistanceFromCase < 500 then
			CameraShake(((500 - DistanceFromCase) / 100), 30, 0.05, 1, Vector3.one * 0.9, Vector3.one * 0.4)
		end
		
		local Position = Case.Position
		local Direction = Vector3.yAxis * -10
		
		coroutine.wrap(RockHandler.Crater)(Position, Direction, { -- big middle rocks
			Amount = 6,
			Distance = {Min = 6, Max = 14},
			LookAt = { Min = 5, Max = 20 },
			Timing = {
				In = {Min = 0.075, Max = 0.2},
				Idle = {Min = 5.7, Max = 6.1},
				Out = {Min = 1.6, Max = 2.2},
			},
			Exposure = { Min = 1, Max = 2 },
			BaseZ = 2.5,
			SizeMultiplier = 2.2,
		})

		coroutine.wrap(RockHandler.Crater)(Position, Direction, { -- smaller outside rocks
			Amount = 45,
			Distance = {Min = 5, Max = 15},
			LookAt = { Min = -15, Max = 15 },
			Timing = {
				In = {Min = 0.05, Max = 0.35},
				Idle = {Min = 5.3, Max = 6.2},
				Out = {Min = 1.6, Max = 2.2},
			},
			Exposure = { Min = 0.75, Max = 1 },
			BaseZ = 1.2,
			SizeMultiplier = 1.5,
		})

		coroutine.wrap(RockHandler.Crater)(Position, Direction, {
			Size = {0.75, 1.5},
			Count = 6,
			Velocity = 15,
			SpawnVariance = 2;
		})
	end,
	
	EquipCrate = function(Equipped : Bolean, NPCAttachment : Attachment)
		
		if Equipped then
			if DeliveryIndicator then
				DeliveryIndicator:Show()
			else
				DeliveryIndicator = Indicator.new({
					Attachment = NPCAttachment,
					Color = Color3.new(0.356863, 0.321569, 0.278431),
					Icon = "rbxassetid://13868069708"
				})
			end
			
			if CrateIndicator then
				CrateIndicator:Hide()
			end
		else
			if DeliveryIndicator then
				DeliveryIndicator:Hide()
			end
			
			if CrateIndicator then
				if ChoseToMark then
					CrateIndicator:Show()
				end
			end
		end
	end,
	
	MarkCrate = function(Marked : Bolean, CrateAttachment : Attachment)
		if Marked == true then
			if CrateIndicator then
				if ChoseToMark then
					CrateIndicator:Show()
				end
			else
				local Bindable = Instance.new("BindableFunction")
				-- task.delay(11, ResponseFunction.Destroy, ResponseFunction)

				Bindable.OnInvoke = function(Selection : string)
					if Selection == "Yes" then
						CrateIndicator = Indicator.new({
							Attachment = CrateAttachment,
							Color = Color3.new(0.356863, 0.321569, 0.278431),
							Icon = "rbxassetid://13858381883",
							Visible = not (LocalPlayer:GetAttribute("HoldingCrate") or false)
						})

						ChoseToMark = true
					end
				end

				StarterGui:SetCore("SendNotification", {
					Title = "World Event",
					Text = "Would you like to track the weapons crate?",
					Icon = "rbxassetid://13858381883";
					Duration = 10,
					Callback = Bindable,
					Button1 = "Yes",
					Button2 = "No"
				})
			end
		else
			if CrateIndicator then
				CrateIndicator:Hide()
			end
		end
	end,
	
	End = function(Winner)
		if DeliveryIndicator then
			DeliveryIndicator:Destroy(false)
			DeliveryIndicator = nil
		end
		
		if CrateIndicator then
			CrateIndicator:Destroy(false)
			CrateIndicator = nil
		end
		
		ChoseToMark = nil
		
		if Winner == LocalPlayer then
			local Dialogue = DialogueManager.Get():StartConversation(workspace["NPC's"]["Black Market Dealer"], 4)
		end
	end,
}