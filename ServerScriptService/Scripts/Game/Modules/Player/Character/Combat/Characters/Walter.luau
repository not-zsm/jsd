return {
	PrivateServerPlusOnly = true,
	DontSave = true,
	
	Stats = {
		M1 = {
			Speed = 1.3,
			EndlagAfterSwing = 0.125,
		},
	},
	
	--OnSpawn = function(LuaPlayer)
	--	if LuaPlayer.Character.Combat:IsOwner() then
	--		local attack = LuaPlayer.Character.Combat:CreateAttack("Turret", Enum.KeyCode.Five);
	--		attack.RemoveOnSpawn = true;
	--	end;
	--end,
	
	Ultimate = {
		Name = "FE-LI-NA",
		
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(155, 223, 234)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(234, 234, 234)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(155, 223, 234)),
		}),

		DontHeal = true,
		CanUseWhileDead = true,
		ManuallyFireStartRemote = true,

		OnStart = function(self)
			self.Combat:TimesSpeed(1.3)

			self.Combat.Attacks.Ultimate.OnUltimateEnded:Once(function()
				self.Combat:DivideSpeed(1.3)
			end)
		end,

		Function = function(self)
			self.LuaCharacter:Anchor(true, true)

			self.Thread.OnClosed:Connect(function()
				self.LuaCharacter:Anchor(false)
			end)

			local Animation : AnimationTrack = self.Animations[self.Combat.CurrentCharacter.Name].Start
			Animation:Play(0);
			
			local Friends = self.LuaPlayer:GetFriendsQuota(12, true);
			local FriendsList = {};

			for _, Friend in Friends do
				table.insert(FriendsList, tostring(Friend.Id));
			end;
			
			self:FireReliableVFX("Walter/Ultimate", "Start", self.LuaCharacter.Model, FriendsList)

			self.Thread.Job:Task(Animation.Stopped:Once(function()
				task.wait(0.5);
				self:Close()
			end))
			
			self.LuaCharacter:HealFull()
		end,
		
		Attacks = {
			["Candy Lab"] = Enum.KeyCode.One,
			["Pizza Throw"] = Enum.KeyCode.Two,
			["Last Chance To Look"] = Enum.KeyCode.Three,
			["Machine Gun"] = Enum.KeyCode.Four,
		},
	},

	Attacks = {
		["This, Is Candy."] = Enum.KeyCode.One,
		["Pizza Throw"] = Enum.KeyCode.Two,
		["Last Chance To Look"] = Enum.KeyCode.Three,
		["Machine Gun"] = Enum.KeyCode.Four,
	}
}
