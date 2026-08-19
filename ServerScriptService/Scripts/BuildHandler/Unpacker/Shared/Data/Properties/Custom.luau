-- Add custom properties to instances of inherited class.

-- Makes the custom property a boolean that uses presence of tags.
local function TagBased(tag: string, default: boolean)
	return {
		Default = default,
		
		Get = function(instance: Instance)
			return instance:HasTag(tag);
		end,
		
		Set = function(instance: Instance, value: boolean)
			if value then
				instance:AddTag(tag);
			else
				instance:RemoveTag(tag);
			end;
		end,
	}
end

return {
	
	["Model"] = {
		["Locked"] = TagBased("ModelLocked", false),
		["CanVoxelize"] = TagBased("CanHavoc", false),
		
		["Scale"] = {
			Default = 1;
			Get = function(instance: Model) return instance:GetScale() end,
			Set = function(instance: Model, value: number) instance:ScaleTo(value) end,
		};
	};
	
	["Configuration"] = {
		["FruitSpawner"] = TagBased("BallSpawner", false),
	};
	
	["BasePart"] = {
		["Plantable"] = TagBased("FootPlantable", false),
		["Fruity"] = TagBased("JumpscareBall", false),
		["CanVoxelize"] = TagBased("CanHavoc", false),
	}
}