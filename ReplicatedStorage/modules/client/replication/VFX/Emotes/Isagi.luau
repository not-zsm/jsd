local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

---------------------------------------------------------------------------------

local EffectUtility = require( ReplicatedStorage.modules.client.replication.EffectUtility )
local Yuki_FOV = require( ReplicatedStorage.modules.client.replication.Global.Yuki_FOV )

local AttributeListener = require( ReplicatedStorage.modules.client.replication.Global.AttributeListener )
local RunCameraRig = require( ReplicatedStorage.modules.client.replication.Global.RunCameraRig )

---------------------------------------------------------------------------------

local AnimationRetriever = require( ReplicatedStorage.modules.client.replication.VFX.AnimationRetriever )

---------------------------------------------------------------------------------

local Holder = script.Holder
local LocalPlayer = Players.LocalPlayer

local ImpactFrames = LocalPlayer.PlayerGui.ImpactFrames.Isagi

local AuraTable = {}

return {
	OnStart = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, ReplicatedStorage.Animations.Emotes.Isagi.Start)

		if (Retrieved == nil) then return end
		
		local Animation, NewJob = Retrieved.Animation, Retrieved.Job
		local RootPart = Retrieved.RootPart

		local Player = Players:GetPlayerFromCharacter(Model)

		local Head = RootPart.Parent.Head

		local EyeFX = NewJob:Task(Holder["1"]:Clone())
		local EyeParticle = NewJob:Task(Holder["2"]:Clone())
		local StartParticle = NewJob:Task(Holder["3"]:Clone())
		local Box = NewJob:Task(script.IsagiBox:Clone())
		
		local WorkspaceHighlight = NewJob:Task(Instance.new("Highlight"))
		WorkspaceHighlight.Name = "WorkspaceHighlight"
		WorkspaceHighlight.DepthMode = Enum.HighlightDepthMode.Occluded
		WorkspaceHighlight.FillColor = Color3.new()
		WorkspaceHighlight.FillTransparency = 0
		WorkspaceHighlight.OutlineTransparency = 1
		WorkspaceHighlight.OutlineColor = Color3.new(1, 1, 1)
		
		local BoxHighlight = NewJob:Task(Instance.new("Highlight"))
		BoxHighlight.Name = "Highlight"
		BoxHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		BoxHighlight.FillColor = Color3.new(1)
		BoxHighlight.FillTransparency = 1
		BoxHighlight.OutlineTransparency = 1
		BoxHighlight.OutlineColor = Color3.new(1, 1, 1)

		if LocalPlayer == Player then
			local CameraOffset = CFrame.new(0, 1.85, 0)

			local Camera = NewJob:Task(script.CameraRig:Clone())
			Camera.RootPart.CFrame = RootPart.CFrame * CameraOffset
			Camera.Parent = workspace.Visuals

			local CameraAnimation = Camera.AnimationController.Animator:LoadAnimation(ReplicatedStorage.Animations.Emotes["Isagi"].Camera)
			CameraAnimation:Play(0)

			NewJob:Task(RunCameraRig(RootPart, Camera, CameraOffset, {
				DontDoTransition = true,
				DontSupportCutsceneSetting = true
			}))

			EffectUtility.ToggleImpactFrames(ImpactFrames, true)

			NewJob:Task(function()
				EffectUtility.ToggleImpactFrames(ImpactFrames, false)
			end)
		end
		
		local Sound = NewJob:Task(script.SFX:Clone())
		Sound.Parent = RootPart
		Sound:Play()
		
		if (AuraTable[Model] == nil) then
			local Music : Sound = script.Music:Clone()
			Music.Parent = RootPart
			Music:Play()
			
			NewJob:Task(function()
				if (AuraTable[Model] == nil) then
					Music:Destroy()
				end
			end)

			Music.Ended:Once(function()
				Music:Destroy()

				if (AuraTable[Model] ~= nil) then
					for _, Item in AuraTable[Model] do
						if Item:IsA("ParticleEmitter") then
							Item.Enabled = false
						else
							EffectUtility.Toggle(Item, false)
						end

						task.delay(2, Item.Destroy, Item)
					end

					table.clear(AuraTable[Model])
					AuraTable[Model] = nil
				end
			end)
		end
		
		local function End()
			EffectUtility.Toggle(EyeParticle, false)
			EffectUtility.Toggle(StartParticle, false)
			
			if LocalPlayer == Player then
				Yuki_FOV.Tween(70, {0.5})
			end

			task.delay(1.5, function()
				EyeParticle:Destroy()
				StartParticle:Destroy()
			end)
		end 

		local function CreateAura()
			if (AuraTable[Model] ~= nil) then return end
			
			AuraTable[Model] = {}

			for _, Item in ipairs(Model:GetChildren()) do
				if Item:IsA("BasePart") and Item.Name ~= "HumanoidRootPart" then
					for _, Aura in ipairs(script.Aura.Holder:GetChildren()) do
						local NewAura = Aura:Clone()
						NewAura.Parent = Item

						table.insert(AuraTable[Model], NewAura)
					end
				end

				if Item:IsA("BasePart") and Item.Name == "Torso" then
					for _, Aura in ipairs(script.Aura.Torso:GetChildren()) do
						local NewAura = Aura:Clone()
						NewAura.Enabled = true
						NewAura.Parent = Item

						table.insert(AuraTable[Model], NewAura)
					end
				end
			end
		end

		NewJob:Task(Animation:GetMarkerReachedSignal("vfx"):Connect(function(Parameter : string)
			if Parameter == "1" then -- start
				if LocalPlayer == Player then
					WorkspaceHighlight.Enabled = true
					BoxHighlight.Enabled = true
					BoxHighlight.Parent = Box

					EffectUtility.Weld(Box, RootPart, CFrame.new(0,2.5,0))
					
					WorkspaceHighlight.Parent = workspace.Map
					Box.Parent = workspace.Visuals
				
					Yuki_FOV.Set(35)
					
					NewJob:Task(task.delay(6, function()
						EffectUtility.EmitImpactFrames(ImpactFrames, 18)
					end))
				end

				StartParticle.Parent = Head
				EffectUtility.Toggle(StartParticle, true)
				
			elseif Parameter == "2" then
				EyeFX.Parent = Head

				EffectUtility.Toggle(StartParticle, false)
				EffectUtility.EmitAttachment(EyeFX)
				
			elseif Parameter == "3" then
				if LocalPlayer == Player then
					WorkspaceHighlight.FillColor = Color3.new(1,1,1)
					Box.Color = Color3.fromRGB(155, 155, 155)

					Yuki_FOV.Tween(29, {0.1})
				end
				
				local VFX = NewJob:Task(Holder.Crack:Clone())
				VFX.Parent = RootPart
				EffectUtility.Emit(VFX)
				
			elseif Parameter == "4" then
				EyeParticle.Parent = Head
				
				EffectUtility.Emit(EyeParticle, true)
				EffectUtility.Toggle(EyeParticle, true)
				
			elseif Parameter == "5" then
				NewJob:Task(task.delay(1, function()
					task.spawn(CreateAura)
					End()
				end))
			end
		end))

		NewJob:Task(End)
	end,
}