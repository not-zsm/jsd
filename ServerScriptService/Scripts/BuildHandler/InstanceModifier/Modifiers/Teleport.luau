local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Unpacker = require( "../../Unpacker" );
local Type = require( Unpacker.Packages.Type );

local InstanceModifier = require( script.Parent .Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Teleport to another location";
TagModifier.icon = 6723742952;
TagModifier.color = Color3.fromRGB(255, 135, 189)
TagModifier.section = 3;
TagModifier.use_prompt = true;
TagModifier.properties = {
	Debounce = {
		Default = 1;
	};
	ToPosition = {
		Default = Vector3.zero;
	};
	ToPart = {
		Default = nil;
		Type = Type.Instance();
	};
	Prompt = {
		Default = true;
	};
	Effects = {
		Default = true;
	};
	Local = {
		Default = false;
	};
};

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	self.short_powered = true;
	
	return self;
end

function TagModifier:prompt_set()
	self.prompt.Enabled = self.attributes:get("Prompt");
	self.prompt.ActionText = "Teleport";
	self.prompt.ObjectText = `To {self.attributes:get("ToPart") or self.attributes:get("ToPosition")}`
end

function TagModifier:pulse(signal)
	local data = self.attributes:all();
	local base: BasePart = self.part;
	
	for _, combat in signal:get_combats() do
		local character = combat:get_character();
		local pivot = character:GetPivot();
		local coordinate = CFrame.new(data.ToPosition) * pivot.Rotation;
		
		if not data.ToPart then
			if data.Local then
				character:PivotTo( base.CFrame * coordinate);
			else
				character:PivotTo( coordinate );
			end
		else
			if data.ToPart:IsA("BasePart") then
				coordinate = data.ToPart.CFrame;
				
			elseif data.ToPart:IsA("Attachment") then
				coordinate = data.ToPart.WorldCFrame;
			end
			
			character:PivotTo( coordinate )
		end
		
		if data.Effects then
			combat:spawn_effects_by_builder("Teleport")
		end;
	end;
end

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;