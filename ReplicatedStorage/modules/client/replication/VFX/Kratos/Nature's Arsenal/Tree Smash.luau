local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------------------

local AnimationRetriever = require( replicatedStorage.modules.client.replication.VFX.AnimationRetriever )
local Animations = replicatedStorage.Animations.Attacks.Kratos["Nature's Arsenal"]

---------------------------------------------------------------------

local RockHandler = require( replicatedStorage.modules.client.replication.Global.RockHandler )
local CameraShake = require( replicatedStorage.modules.client.replication.Global.CameraShake )
local Blood = require( replicatedStorage.modules.client.replication.Global.Blood )

---------------------------------------------------------------------

local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )
local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )

local VFX = script.VFX

---------------------------------------------------------------------

return {
	Start = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Tree)
		if (Retrieved == nil) then return end
		
		local Job, MainAnimation = Retrieved.Job, Retrieved.Animation
		local RootPart = Retrieved.RootPart
		
		local Tree = script.Tree:Clone()
		Tree.Name = "Main" -- makes it animated
		Tree.Weld.Part0 = Model.Torso
		Tree.Parent = Model

		Job:Task(Tree)
		
		local function GetCF(Effect : BasePart)
			return RootPart.CFrame * Effect.CFrame
		end

		Job:Task(EffectUtility.AddSFX(script.TreeSFX, Model.Torso, 0.5))
		
		--local she_didnt_even_give_me_a_rim = script.TreeSFX:Clone()
		--she_didnt_even_give_me_a_rim.Parent = RootPart
		--she_didnt_even_give_me_a_rim:Play()

		--task.delay(4.1, she_didnt_even_give_me_a_rim.Destroy, she_didnt_even_give_me_a_rim)
		
		Job:Task(MainAnimation:GetMarkerReachedSignal("take"):Connect(function()
			if LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 50 then
				CameraShake(2, 20, 0.01, 1, Vector3.one * 0.8, Vector3.one * 0.3)
			end
			
			local DirtVFX = VFX.Dirt:Clone()
			local DirtEnableVFX = VFX.Enable:Clone()
			
			DirtVFX.CFrame = GetCF(DirtVFX)
			DirtEnableVFX.CFrame = GetCF(DirtEnableVFX)
			
			DirtVFX.Parent = workspace.Visuals
			DirtEnableVFX.Parent = workspace.Visuals

			EffectUtility.Emit(DirtVFX)

			EffectUtility.Toggle(Tree, true, true)
			EffectUtility.Toggle(Tree.TopLeaf, true, true)
			
			task.delay(0.5, EffectUtility.Toggle, Tree, false, true)
			
			EffectUtility.ToggleForTime(DirtEnableVFX, 0.5)
		end))
			
		Job:Task(MainAnimation:GetMarkerReachedSignal("hit"):Connect(function()
			local HitCF = RootPart.CFrame * CFrame.new(0, 0, -12)
			local Position = HitCF.Position
			local Direction = Vector3.yAxis * -10
			
			local i_kissed_jimpee_on_the_mouth = script.ThrownTree:Clone()
			i_kissed_jimpee_on_the_mouth.CFrame = Tree.CFrame + Vector3.new(0, 5, 0)
			i_kissed_jimpee_on_the_mouth.Parent = workspace.Visuals
			Tree:Destroy()
		

			for _, Item in ipairs(i_kissed_jimpee_on_the_mouth:GetChildren()) do
				if Item:IsA("BasePart") then
					local Weld = Item:FindFirstChildOfClass("ManualWeld")
					local C1 = Weld.C1
					
					if Weld then Weld:Destroy() end

					Item.CFrame = i_kissed_jimpee_on_the_mouth.CFrame * C1
					
					Item.AssemblyLinearVelocity = Vector3.new(Utility.Seed:NextNumber(-35, 35), Utility.Seed:NextNumber(60, 70), Utility.Seed:NextNumber(-35, 35))
					Item.AssemblyAngularVelocity = Vector3.new(Utility.Seed:NextNumber(-15, 15), Utility.Seed:NextNumber(-15, 15), Utility.Seed:NextNumber(-15, 15))
				end
			end

			i_kissed_jimpee_on_the_mouth.AssemblyLinearVelocity = 
				(RootPart.CFrame.LookVector * 50) + 
				(RootPart.CFrame.RightVector * 75) +
				(Vector3.yAxis * 5)
			
			i_kissed_jimpee_on_the_mouth.AssemblyAngularVelocity = (RootPart.CFrame.RightVector * 7.5)

			task.delay(2, function()
				local Info = TweenInfo.new(2, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
				TweenService:Create(i_kissed_jimpee_on_the_mouth, Info, {Transparency = 1}):Play()
				
				for _, Item in ipairs(i_kissed_jimpee_on_the_mouth:GetChildren()) do
					if Item:IsA("BasePart") then
						TweenService:Create(Item, Info, {Transparency = 1}):Play()
					end
				end
				
				task.delay(Info.Time, i_kissed_jimpee_on_the_mouth.Destroy, i_kissed_jimpee_on_the_mouth)
			end)
			
			task.spawn(RockHandler.Crater, Position, Direction, { -- big middle rocks
				Amount = 10,
				Distance = {Min = 6 * 1.5, Max = 14 * 1.5},
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

			task.spawn(RockHandler.Crater, Position, Direction, { -- smaller outside rocks
				Amount = 45,
				Distance = {Min = 5 * 1.2, Max = 15 * 1.2},
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
			
			local HitVFX = VFX.Hit:Clone()
			HitVFX.CFrame = HitCF
			HitVFX.Parent = workspace.Visuals
			EffectUtility.Emit(HitVFX)
			
			if LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 50 then
				CameraShake(6, 35, 0.01, 0.45, Vector3.one * 0.8, Vector3.one * 0.3)
			end
		end))
	end,
	
	Hit = function(Victim : Model)
		if (Victim and Victim.Parent) then
			EffectUtility.EmitEffects(replicatedStorage.Effects.Blood.SmallSplash, Victim.Head)
			
			Blood.BloodRaysWithoutPreset(Victim.Head, {
				Face = Enum.NormalId.Front,
				Amount = Vector2.new(3, 5),
				PoolSize = 1.5,
			})
			
			Blood.BloodRaysWithoutPreset(Victim.Head, {
				Face = Enum.NormalId.Back,
				Amount = Vector2.new(3, 5),
				PoolSize = 1.5,
			})
			
			Blood.BloodRaysWithoutPreset(Victim.Head, {
				Face = Enum.NormalId.Top,
				Amount = Vector2.new(2, 4),
				PoolSize = 1.5,
			})
		end
	end,
}