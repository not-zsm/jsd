local Shikigami = require(script.shikigami)

----------------------------------------------------------------------------------

local tenShadows = {}
tenShadows.__index = tenShadows

local Names = { "divineDogs", "nue", "bunny", "toad", "serpent", "elephant" }

function tenShadows.new(user)
	local self = setmetatable({}, tenShadows)

	self.megumiChan = user
	self.summons = {}

	return self
end

----------------------------------------------------------------------------------

function tenShadows:get(name : string)
	return self.summons[name]
end

function tenShadows:isOut(name : string) : boolean
	return self.summons[name] ~= nil
end

function tenShadows:summon(thingToSummon : string)
	if not thingToSummon then return end
	if self.summons[thingToSummon] then return end

	local spec = Shikigami.Spec(thingToSummon)
	local rig = script:FindFirstChild(thingToSummon)

	if not (spec and rig) then
		return warn(`tenShadows: nothing to summon for {thingToSummon}`)
	end

	local user = self.megumiChan

	if not (user and user.HumanoidAlive and user.RootPart) then return end

	local model = rig:Clone()
	model.Name = `{user.Model.Name}'s {thingToSummon}`
	model:PivotTo(user.RootPart.CFrame * spec.Offset)
	model.Parent = workspace.chars

	local summon = Shikigami.new(thingToSummon, user, model)

	if (summon == nil) then
		model:Destroy()
		return
	end

	self.summons[thingToSummon] = summon

	return summon
end

function tenShadows:unsummon(thingToEviscerate : string)
	if not thingToEviscerate then return end

	local summon = self.summons[thingToEviscerate]

	if (summon == nil) then return end

	self.summons[thingToEviscerate] = nil
	summon:Destroy()
end

function tenShadows:unsummonAll()
	for _, name in Names do
		self:unsummon(name)
	end
end

tenShadows.Destroy = tenShadows.unsummonAll

----------------------------------------------------------------------------------

return tenShadows
