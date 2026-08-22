local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utility = require( ReplicatedStorage.Shared.Utilities.Utility )
local EffectUtility = require( ReplicatedStorage.Client.Replication.EffectUtility )

--local Ids = {
--	7207821215, 85042395, 150522417, 141123572
--}

local Whitelist = require( ReplicatedStorage.Shared.Game.Whitelist )

local Assets = ReplicatedStorage.Effects["Eye Of Rah"]

return function(self, Job)
	local OriginalFace = self.LuaCharacter.Head:FindFirstChildOfClass("Decal")

	if OriginalFace then
		OriginalFace.Parent = nil
	end

	local Smile = Assets["smile no eyes"]:Clone()
	Smile.Parent = self.LuaCharacter.Head

	for _, Item in ipairs(self.LuaCharacter.Model:GetDescendants()) do
		if Item:IsA("Accessory") then
			Item.Handle.Transparency = 1
		end
	end

	local Eye = Assets.Part1:Clone()
	Eye.Weld.Part1 = self.LuaCharacter.Head
	Eye.Parent = self.LuaCharacter.Head

	local Hair = Assets.Part2:Clone()
	Hair.Weld.Part1 = self.LuaCharacter.Head
	Hair.Parent = self.LuaCharacter.Head

	local Effects = Eye.effect
	local Flames = Effects.Flames

	local HasProduct = not self.LuaPlayer.IsNPC and Whitelist.is_permitted(self.LuaPlayer.UserId, "Big Rah") --table.find(Ids, self.LuaPlayer.Player.UserId)

	if HasProduct then
		Effects.Sound.RollOffMaxDistance = 10000
		Effects.Sound.Volume = 10

		local new_sequence = {};
		local size_factor = 10

		for _, keypoint in Flames.Size.Keypoints do
			table.insert(new_sequence, NumberSequenceKeypoint.new(keypoint.Time, keypoint.Value * size_factor, keypoint.Envelope))
		end

		Flames.Size = NumberSequence.new(new_sequence)
	end

	Job:Task(task.defer(function()
		while task.wait(Utility.Seed:NextNumber(0.15, 0.75)) do
			Flames.Parent = nil

			if Eye.effect.Sound.IsPlaying then
				Eye.effect.Sound:Stop()
			end

			task.delay(1 / 60, function()
				if (Eye.Parent == nil) then return end

				Flames.Parent = Eye.effect
				Flames:Emit(5)

				Eye.effect.Sound:Play()
				self.LuaPlayer.Replication:FireReliableVFXToSelf("Emotes/EyeOfRah", "Rah")

				if HasProduct then
					local Hitbox = self.Hitbox:Create(true)
					Hitbox.Params.Offset = CFrame.identity
					Hitbox.Params.Size = 35
					
					self.Hitbox:SphereDestruction(self.LuaCharacter.RootPart.Position, 25, 10)

					Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
						local VictimLuaCharacter = VictimLuaPlayer.Character
						local VictimCombat = VictimLuaCharacter.Combat

						local Validated = self:Afflict(VictimLuaPlayer, {
							DontBypassIFrames = {},
							BreakBlock = true,
							Damage = 0.1,
						})

						if Validated then
							if VictimCombat:GetState("Grabbed") then
								VictimCombat:CancelAllAttacks()
							end

							if math.random(1, 10) == 1 or VictimLuaCharacter.Humanoid.Health <= 20 then -- so sorry for your brother, heres 5 big booms. boom! boom! boom! boom! boom!
								self:Afflict(VictimLuaPlayer, {
									ExcludeAttempts = true,
									FinisherKill = true,
								})

								EffectUtility.EmitEffects(Assets.finisher, VictimLuaCharacter.RootPart)

								VictimCombat.Ragdoll:Toggle(true)
								
								local VelocityObject = self:VelocityOn(VictimCombat)
								VelocityObject.Settings.RemoveTime = 0.1
								VelocityObject.Settings.Velocity = self:CalculateUnitDifference(VictimLuaPlayer) * 300 + Vector3.yAxis * 200
								VelocityObject:Fire()
								
								VictimCombat:ImpactOnGroundHit()
								
								return
							end

							if math.random(1, 5) == 1 then
								self:Afflict(VictimLuaPlayer, {
									ExcludeAttempts = true;
									Ragdoll = 1.25;
								})
								--VictimCombat.Ragdoll:Toggle(true, 1.25)
								
								local VelocityObject = self:VelocityOn(VictimCombat)
								VelocityObject.Settings.RemoveTime = 0.1
								VelocityObject.Settings.Velocity = -VictimLuaCharacter.RootPart.CFrame.LookVector * 20
								VelocityObject:Fire()
							else
								VictimCombat:PlayRandomHitReaction()
							end
						end
					end)

					Hitbox:Detect()
					Hitbox:Destroy()
				end
			end)
		end
	end))

	Job:Task(function()
		Eye:Destroy()
		Hair:Destroy()
		Smile:Destroy()

		for _, Item in ipairs(self.LuaCharacter.Model:GetDescendants()) do
			if Item:IsA("Accessory") then
				Item.Handle.Transparency = 0
			end
		end

		if OriginalFace then
			OriginalFace.Parent = self.LuaCharacter.Head
		end
	end)
end