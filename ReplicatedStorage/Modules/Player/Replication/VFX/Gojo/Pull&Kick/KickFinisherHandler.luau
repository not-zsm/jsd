local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )

return function(AttackerModel : Model, VictimModel : Model)
	local Retrieved = AnimationRetriever.new(AttackerModel,
		ReplicatedStorage.Animations.Attacks.Gojo["Lapse Pull"].KickFinisher.AnimationId
	)
	
	if (Retrieved == nil) then return end

	local Animation, NewJob = Retrieved.Animation, Retrieved.Job
	local RootPart = Retrieved.RootPart
	
	NewJob:Task(Animation:GetMarkerReachedSignal("pullwindup1"):Once(function()
		self:FireReliableVFX("Gojo/Pull&Kick", "KickFinisherPullWindup1", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)
	end))

	NewJob:Task(Animation:GetMarkerReachedSignal("kickfreeze1"):Once(function()
		self.LuaPlayer.Replication:FireReliableVFX("Gojo/Pull&Kick", "KickFinisherKickPause1", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)
	end))

	NewJob:Task(Animation:GetMarkerReachedSignal("kickresume1"):Once(function()
		self.LuaPlayer.Replication:FireReliableVFX("Gojo/Pull&Kick", "KickFinisherKickResume1", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)
	end))

	NewJob:Task(Animation:GetMarkerReachedSignal("pullwindup2"):Once(function()
		self.LuaPlayer.Replication:FireReliableVFX("Gojo/Pull&Kick", "KickFinisherPullWindup2", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)
	end))

	NewJob:Task(Animation:GetMarkerReachedSignal("kickfreeze2"):Once(function()
		self.LuaPlayer.Replication:FireReliableVFX("Gojo/Pull&Kick", "KickFinisherKickPause2", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)
	end))

	NewJob:Task(Animation:GetMarkerReachedSignal("kickresume2"):Once(function()
		self.LuaPlayer.Replication:FireReliableVFX("Gojo/Pull&Kick", "KickFinisherKickResume2", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)
	end))

	NewJob:Task(Animation:GetMarkerReachedSignal("punchfreeze"):Once(function()
		self.LuaPlayer.Replication:FireReliableVFX("Gojo/Pull&Kick", "KickFinisherPunchFreeze", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)
	end))
	
	🤞🤞🤞🤞🤞🤞🤞🤞
	
	local Distance = LocalPlayer:DistanceFromCharacter(VictimModel.Position)

	if (Distance < 10) then
		CameraShake(1.5, 15, 0.05, 0.25)
	end

	--SharmMeshVFX.Create(SharmMeshVFX.DefaultStorage.HitWind.MeshHit1, AttackerRootPart.CFrame, 4)
	--SharmMeshVFX.Create(SharmMeshVFX.DefaultStorage.HitWind.MeshHit2, AttackerRootPart.CFrame, 4)

	if (Distance < 75) then
		Blood.BloodRays("SpitOut", VictimRootPart.Parent.Head.MouthAttachment)
		EffectUtility.EmitEffects(script.KickHit, workspace.Terrain, CFrame.new(VictimRootPart.Position))
	end
end