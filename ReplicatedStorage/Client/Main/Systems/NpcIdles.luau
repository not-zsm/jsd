--!strict
-- Was StarterPlayerScripts/Game/NPC Idles.client.luau
local CollectionService = game:GetService("CollectionService")

local DEFAULT_IDLE = 94128997647163

--[[
	Plays an idle on anything tagged "NPC Idle".

	An NPC with `HasIdleModule` supplies its own Idle module; otherwise it gets
	the animation named by its `IdleID` attribute, or the default.
--]]
local function Handle(NPC: Model)
	task.spawn(function()
		if NPC:GetAttribute("HasIdleModule") then
			local Module = NPC:WaitForChild("Idle", 25)

			if not Module then
				return warn(`[NpcIdles] {NPC.Name} declares HasIdleModule but has no Idle`)
			end

			require(Module :: any)()
			return
		end

		local Animation = Instance.new("Animation")
		Animation.AnimationId = `rbxassetid://{NPC:GetAttribute("IdleID") or DEFAULT_IDLE}`

		local Humanoid = NPC:FindFirstChildOfClass("Humanoid")
		local Animator = Humanoid and Humanoid:FindFirstChildOfClass("Animator")

		if not Animator then
			return warn(`[NpcIdles] {NPC.Name} has no Animator`)
		end

		Animator:LoadAnimation(Animation):Play(0)
	end)
end

return {
	Name = "NpcIdles",
	Priority = 80,

	Start = function(_self, _Client, Cleanup)
		Cleanup:Task(CollectionService:GetInstanceAddedSignal("NPC Idle"):Connect(Handle))

		for _, NPC in CollectionService:GetTagged("NPC Idle") do
			Handle(NPC :: Model)
		end
	end,
}
