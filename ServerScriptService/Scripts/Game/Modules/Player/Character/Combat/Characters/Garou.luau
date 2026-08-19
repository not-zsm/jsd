local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

return {
	OwnerOnly = true,

	Stats = {
		M1 = {
			LastM1KnocksUp = true,
			Speed = 1.05,
			EndlagAfterSwing = 0.215,
		}
	},

	Attacks = {
		["Flowing Water"] = Enum.KeyCode.One,
		["Lethal Whirlwind Stream"] = Enum.KeyCode.Two,
		["Hunter's Grasp"] = Enum.KeyCode.Three,
		["Prey's Peril"] = Enum.KeyCode.Four
	},
	
	WallCombo = {
		DistanceFromWall = 6,
		VictimDistanceFromAttacker = 6,

		Function = function(Attack, VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			local VictimModel = VictimLuaCharacter.Model

			local AttackerAnimation = Attack.Animations.WallCombo.Garou.User
			local VictimAnimation = VictimLuaCharacter.Humanoid:LoadAnimation(ReplicatedStorage.Animations.Attacks.Global.Dash.WallCombo.Garou.Victim) -- are we bringing back garou 💀

			Attack.Thread.OnClosed:Connect(function()
				AttackerAnimation:Stop()

				AttackerAnimation.Ended:Once(function()
					Attack.LuaCharacter.RootPart.Anchored = false
				end)
				
				Attack.Combat:StackState("GrabIFrames", false)
				VictimCombat:StackState("GrabIFrames", false)

				VictimAnimation:Stop()
				VictimAnimation = nil
			end)

			Attack.Thread.OnCancelled:Connect(function()
				Attack.LuaCharacter.RootPart.Anchored = false
			end)

			AttackerAnimation:Play()
			VictimAnimation:Play()
			
			for Index = 1, 5 do
				AttackerAnimation:GetMarkerReachedSignal("hit".. Index):Once(function()
					Attack.LuaPlayer.Replication:FireReliableVFX("Garou/Wall Combo", "Hit", VictimLuaCharacter.Torso, Index)
				end)
			end
			
			AttackerAnimation:GetMarkerReachedSignal("hit6"):Wait()

			if VictimModel == VictimLuaCharacter.Model then
				Attack.LuaPlayer.Replication:FireReliableVFX("Garou/Wall Combo", "Hit", VictimLuaCharacter.Torso)
				VictimAnimation:Stop(0)

				VictimLuaCharacter:SetCollisionGroup("NoPlayerCollision")
				VictimCombat.Ragdoll:SetCollisionGroupOfColliders("NoPlayerCollision")

				task.delay(0.3 + (not VictimLuaPlayer.IsNPC and VictimLuaPlayer.Player:GetNetworkPing() or 0), function()
					if not VictimCombat:GetState("Grabbed") then
						VictimLuaCharacter:SetCollisionGroup("Player")
					end

					VictimCombat.Ragdoll:SetCollisionGroupOfColliders("Default")
				end)

				Attack.Combat:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = 5,
					Ragdoll = 2.25;
				})

				VictimLuaCharacter.RootPart.Anchored = false

				--VictimCombat.Ragdoll:Toggle(true, 2.25)
				VictimCombat:Velocity((VictimLuaCharacter.RootPart.Position - Attack.LuaCharacter.RootPart.Position).Unit * -45 + Vector3.yAxis * 30, 0.1)
				VictimCombat:Unstun()
			end
			
			AttackerAnimation:GetMarkerReachedSignal("end"):Wait()
			Attack:Close()
		end,
	},

	OnRespawn = function(LuaPlayer)
		local Animation : AnimationTrack = LuaPlayer.Character.Animator:LoadAnimation(ReplicatedStorage.Animations.CharacterSpawnAnimations.Garou.Spawn)
		Animation:Play()
		
		LuaPlayer.Replication:FireVFX("Garou/Flowing Water", "DualHandWaterStream", LuaPlayer.Character.Model, 1.25)

		return Animation
	end,
	
	Ultimate = {
		Name = "RAMPAGE"
	}
}
