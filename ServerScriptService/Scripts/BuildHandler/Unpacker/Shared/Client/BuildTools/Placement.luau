local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local Sounds = script.Parent.Sounds;

local Table = require( ReplicatedStorage.Packages.Table )

local Placement = {};
Placement.__index = Placement;

function Placement.new(build_tools)
	local self = setmetatable(
		{
			build_tools = build_tools;
			model = nil;
			slot = nil;
		}, 
		Placement);
	
	return self;
end;

function Placement:destroy()
	self:deselect();
	Table.dispose(self);
end

function Placement:is_active()
	return self.slot ~= nil;
end

function Placement:place_at_cursor()
	SoundService:PlayLocalSound(Sounds.Place);
	self.build_tools.actions:load_from_hotbar(self.slot.index, self.model:GetPivot());
end

function Placement:deselect()
	if self.slot then
		self.slot = nil;
	end
	
	if self.model then
		self.model:Destroy();
		self.model = nil;
	end;
	
	self.build_tools.selection:deselect();
end

function Placement:create_model_for(slot)
	local model = slot.info.model:Clone();
	model:AddTag("Placement")

	local highlight = Instance.new("Highlight");
	highlight.Name = "PlacementHighlight";
	highlight.FillColor = Color3.fromRGB(29, 97, 255);
	highlight.OutlineTransparency = 1;
	highlight.Parent = model;
	
	local all_instances = model:GetDescendants();
	table.insert(all_instances, model);

	for _, instance in all_instances do
		instance.Archivable = false;

		if instance:IsA("BasePart") then
			instance.Anchored = true;
			instance.CanCollide = false;
			instance.CanQuery = false;
			instance.CanTouch = false;
			instance.Locked = true;
			
		elseif instance:IsA("Sound") then
			instance.Playing = false;
		end;
	end;
	
	return model;
end

function Placement:select(slot)
	if self.slot ~= slot then
		self:deselect();
		
		self.slot = slot;
		
		self.model = self:create_model_for(slot);
		self.model.Parent = workspace.CurrentCamera;
		
		-- i know this is stupid but it must stay
		self.build_tools.selection.pivot_items[self.model] = true;
		self.build_tools.selection:select_instance(self.model);
		self.build_tools.selection.dragger.Enabled = false;
		
		self.build_tools.selection:move_to_cursor();
	else
		self:deselect();
	end;
end

table.freeze(Placement);

return Placement;