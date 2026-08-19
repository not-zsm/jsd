local CollectionService = game:GetService("CollectionService")

local DefaultId = 94128997647163

--------------------------------

local function HandleNPC(NPC : Model)
	task.spawn(function()
		
		if NPC:GetAttribute("HasIdleModule") then
			local Module = NPC:WaitForChild("Idle", 25)
			require(Module)()
		else
			local IdleId = NPC:GetAttribute("IdleID") or DefaultId
			local Character = NPC

			local Animation = Instance.new("Animation")
			Animation.AnimationId = "rbxassetid://"..IdleId

			local Idle : AnimationTrack = Character.Humanoid.Animator:LoadAnimation(Animation)
			Idle:Play(0)
		end
	end)
end

for _, NPC in pairs(CollectionService:GetTagged("NPC Idle")) do
	HandleNPC(NPC)
end

CollectionService:GetInstanceAddedSignal("NPC Idle"):Connect(HandleNPC)