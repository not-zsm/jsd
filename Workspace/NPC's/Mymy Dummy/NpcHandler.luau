--return function(LuaPlayer)

--	task.wait()

--	local LuaCharacter = LuaPlayer.Character
--	local Combat = LuaCharacter.Combat

--	LuaCharacter.Emotes:PlayRandomEmote()

--	LuaCharacter.HumanoidJob:Task(Combat.OnStateChanged:Connect(function(State, Value)
--		if (State == "Stunned" or State == "Ragdolled") and not Value then
--			LuaCharacter.Emotes:PlayRandomEmote()
--		end
--	end))

--	return function()

--	end
--end

--return function(LuaPlayer)

--	task.wait()
-- local EmoteName = "Golden"

--	local LuaCharacter = LuaPlayer.Character
--	local Combat = LuaCharacter.Combat

--	LuaCharacter.Emotes:PlayEmote(EmoteName)

--	LuaCharacter.HumanoidJob:Task(Combat.OnStateChanged:Connect(function(State, Value)
--		if (State == "Stunned" or State == "Ragdolled") and not Value then
--			LuaCharacter.Emotes:PlayEmote(EmoteName)
--		end
--	end))

--	return function()

--	end
--end

local Chat = game:GetService("Chat")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local IsStudio = RunService:IsStudio()

local LuaPlayerList = require(ServerScriptService.Modules.LuaPlayerList)
local JobHandler = require(ReplicatedStorage.Shared.Utilities.Job)

local TextForPeople = {
	[7207821215] = {
		"swrerm...",
	},
	
	[2603403653] = {
		"Bugo? Pugo? I'm a big fan. but that hurt.",
		"Ooowwieeeee... Steooppp...."
	},
	
	[141123572] = {
		"Jimpee, you may be the owner of MY game, but hitting me will not solve anything.",
		"Jimpee, mlgxpro will come get you next.",
		"hi jimpee my goat."
	},

	
	[341579096] = {
		"bro tough get off me you faker",
		"YOU BETRAYED US TOUGH. YOU LOSER.",
		"How about you go climb a tree instead of hitting me tough. "
	},
	
	[265094988] = {
		"GET YO HANDS OFF ME THUNDER."
	},
}

local RandomText = {
	"I'll tell jimpee on you if you don't stop hitting me.",
	"That's it, the update is delayed by another month.",
	".... . / .. ... / .- .-.. .. ...- . --..-- / .... . / .. ... / .- .-- .- -.- .",
	"I am always watching."
}

return function(LuaPlayer)
	
	task.wait()

	local LuaCharacter = LuaPlayer.Character
	local Combat = LuaCharacter.Combat

	local HitCount = 0
	
	local OnCooldown = false
	
	local function Counter()
		if OnCooldown then return end

		OnCooldown = true

		task.delay(3, function()
			OnCooldown = false
		end)

		local Job = JobHandler.Extend(LuaPlayer.Job)

		local VictimLuaPlayer = LuaPlayerList.Get(Combat.LastHitBy)
		local VictimLuaCharacter = VictimLuaPlayer.Character

		local VictimCombat = VictimLuaCharacter.Combat

		local UserAnimation : AnimationTrack = LuaCharacter.Animator:LoadAnimation(ReplicatedStorage.Assets.Animations.Attacks.Universal.DummyCounter.User)
		local VictimAnimation : AnimationTrack = VictimLuaCharacter.Animator:LoadAnimation(ReplicatedStorage.Assets.Animations.Attacks.Universal.DummyCounter.Victim)

		UserAnimation:Play()
		VictimAnimation:Play()

		Job:Task(Combat:CreateMoveSFX("Universal", "Dummy Counter"))

		LuaCharacter:Anchor(true)

		local GrabObject = Combat:GrabVictim(VictimLuaPlayer, LuaCharacter.RootPart, CFrame.new(0, 0, -3) * CFrame.Angles(0, math.pi, 0))

		Combat:HideUI(true)
		VictimCombat:HideUI(true)

		Job:Task(LuaCharacter:StopAutoRotate())

		Combat:StackState("HitboxImmunity", true)
		VictimCombat:StackState("HitboxImmunity", true)

		Job:Task(UserAnimation:GetMarkerReachedSignal("finalstab"):Once(function()
			VictimAnimation:Stop(0)

			Combat:Afflict(VictimLuaPlayer, {
				ExcludeAttempts = true,
				FinisherKill = true,
			})

			GrabObject.Destroy(0)
			VictimCombat:Unstun()

			task.wait(1)

			Job:Clean()
		end))

		Job:Task(function()
			LuaCharacter:Anchor(false)

			if GrabObject and not GrabObject.Destroyed then
				GrabObject.Destroy(0)
				VictimCombat:Unstun()
			end

			Combat:HideUI(false)
			VictimCombat:HideUI(false)

			Combat:StackState("HitboxImmunity", false)
			VictimCombat:StackState("HitboxImmunity", false)
		end)

		LuaPlayer.Replication:FireReliableVFX("Universal/Dummy Counter", "Start", LuaCharacter.Model, VictimLuaCharacter.Model)
	end
	
	LuaCharacter.HumanoidJob:Task(Combat.OnStateUpdated:Connect(function(State, Value)
		if (State == "Stunned") and Value then
			HitCount += 1

			if HitCount >= math.random(10, 25) then
				if Combat.LastHitBy and Combat.LastHitBy.UserId and TextForPeople[Combat.LastHitBy.UserId] then
					local TextTable = TextForPeople[Combat.LastHitBy.UserId]
					Chat:Chat(LuaCharacter.Head, TextTable[math.random(1, #TextTable)])
				else
					Chat:Chat(LuaCharacter.Head, RandomText[math.random(1, #RandomText)])
				end
				
				HitCount = 0
			end
			
			if (LuaCharacter.HumanoidAlive and math.random(1, 500) == 1) then
				Counter()
			end
		end
	end))

	return function()

	end
end