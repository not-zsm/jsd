local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

return function(self, MoveName)
	--local Conditions = not self.Combat:GetState("Stunned") 
	--	and not self.Combat:GetState("Attacking") 
	--	and not self.Combat:GetState("Ragdolled") 
	--	and not self.Combat:GetState("Backdashing")
	--	and not self.Combat:GetState("Blocking") 
	
	--if not Conditions then return end
	local Attack = self.Combat:CreateAttack(MoveName)
	
	if Attack:ConditionToActivate(true) then
		Attack:Trigger(true)
	end
	
	self.Combat:RemoveAttack(MoveName, true)
end