local replicatedStorage = game:GetService("ReplicatedStorage")

local NumberStack = require( replicatedStorage.modules.shared.Utilities.NumberStack )

--[[
	Drives a hotbar slot that renames itself while a condition holds.

	The move declares what it wants -- Properties.Variant, which rides along
	with createAttack -- and this only knows how to watch the conditions a
	variant is allowed to name.
--]]

local Watchers = {}

function Watchers.HoldingSpace(Combat, Job, Set)
	Job:Task(Combat.OnSpaceChanged:Connect(Set))
end

function Watchers.HoldingSpaceOrFalling(Combat, Job, Set)
	local Stack = Job:Task(NumberStack.new())

	Stack.OnChanged:Connect(function()
		Set(not Stack:IsFalse())
	end)

	Job:Task(Combat.OnSpaceChanged:Connect(function(Value : boolean)
		if Value then
			Stack:Add()
		else
			Stack:Subtract()
		end
	end))

	Job:Task(Combat.OnFreeFalling:Connect(function()
		Stack:Add()
	end))

	Job:Task(Combat.OnLanded:Connect(function()
		Stack:Reset()
	end))
end

function Watchers.AirLockedOrUpTilted(Combat, Job, Set)
	local Attributes = Combat.LuaPlayer.Replication.Attributes

	local function Update()
		Set((Attributes:GetAttribute("AirLocked") or 0) > 0
			or (Attributes:GetAttribute("UpTilted") or 0) > 0)
	end

	for _, Name in {"AirLocked", "UpTilted"} do
		Job:Task(Attributes:GetAttributeChangedSignal(Name):Connect(Update))
	end

	Update()
end

return function(Combat, Name : string, Job)
	local Attack = Combat.Attacks[Name]
	local Variant = Attack and Attack.Properties and Attack.Properties.Variant

	if not Variant then return end

	local Watch = Watchers[Variant.When]

	if not Watch then
		return warn(`{Name} declares an unknown variant condition: {tostring(Variant.When)}`)
	end

	Watch(Combat, Job, function(Active : boolean)
		Combat.UI:ChangeHotbarDisplay(Name, Active and Variant.Name or Name, nil, Variant.Colour)
	end)
end
