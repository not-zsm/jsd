-- Contains exactly what can be edited, transformed, removed, or copied.

---------------------------------------------------------------

local Lighting = game:GetService("Lighting");
local Teams = game:GetService("Teams");

local Terrain = workspace.Terrain;
local Builds = workspace.Builds;
local Shared = script.Parent.Parent;
local InstanceBuild = Shared.Assets.Build;
local InstanceAssets = InstanceBuild.Insert;
local InstanceInventory = InstanceBuild.Inventory;

---------------------------------------------------------------

export type QueryTable = {
	Instances: {[Instance]: boolean};
	Descendants: {[Instance]: boolean};
};

---------------------------------------------------------------

local InstanceAllowed = {}

InstanceAllowed.Modify = {
	Instances = {
		[Lighting] = true;
		[Teams] = true;
		[Terrain] = true;
	};
	Descendants = {
		[Lighting] = true;
		[Builds] = true;
		[Teams] = true;
		[Terrain] = true;
	};
};

InstanceAllowed.Remove = {
	Instances = {};
	Descendants = {
		[Lighting] = true;
		[Builds] = true;
		[Teams] = true;
		[Terrain] = true;
	};
};

InstanceAllowed.Copy = {
	Instances = {};
	Descendants = {
		[Builds] = true;
		[InstanceInventory] = true;
		[InstanceAssets] = true;
	};
};

---------------------------------------------------------------

@native local function can_do_something(query_table: QueryTable, instance: Instance): boolean
	if query_table.Instances[instance] then
		return true;
	end;
	for object in query_table.Descendants do
		if instance:IsDescendantOf(object) then
			return true;
		end;
	end;
	return false;
end

---------------------------------------------------------------

function InstanceAllowed.can_modify(instance: Instance): boolean
	return can_do_something(InstanceAllowed.Modify, instance);
end;

function InstanceAllowed.can_remove(instance: Instance): boolean
	return can_do_something(InstanceAllowed.Remove, instance);
end;

function InstanceAllowed.can_copy(instance: Instance): boolean
	return can_do_something(InstanceAllowed.Copy, instance);
end;

---------------------------------------------------------------

table.freeze(InstanceAllowed);

return InstanceAllowed;