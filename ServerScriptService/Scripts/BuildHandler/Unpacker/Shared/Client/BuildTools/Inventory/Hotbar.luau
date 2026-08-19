local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer;
local PlayerGui = Player:WaitForChild("PlayerGui") :: typeof(StarterGui);

local BuildPersistent = ReplicatedStorage:WaitForChild("BuildTools");
local BuildShared = BuildPersistent:WaitForChild("Shared");
local Remotes = BuildPersistent:WaitForChild("Remotes");
local BuildAssets = BuildShared:WaitForChild("Assets");

local Products = require( BuildShared.Data.Products );
local NotificationStatus = require( BuildShared.Data.NotificationStatus );
local Table = require( ReplicatedStorage.Packages.Table )
local Maid = require( ReplicatedStorage.Packages.Maid )
local Item = require( script.Parent.Item )

local Hotbar = {};
Hotbar.__index = Hotbar;
Hotbar.inputs = {
	Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, 
	Enum.KeyCode.V, Enum.KeyCode.F, Enum.KeyCode.G, 
	Enum.KeyCode.H, Enum.KeyCode.J, Enum.KeyCode.L,
};

--for enum_value = 257, 265 do
--	table.insert(Hotbar.inputs, Enum.KeyCode:FromValue(enum_value));
--end;

function Hotbar.new(inventory)
	local self = setmetatable(
		{
			inventory = inventory;
			build_tools = inventory.build_tools;
			slots = {};
			equipped = nil;
			gpad_last_equipped = nil;
			equip_maid = Maid.light();
			
			hotbar_frame = inventory.build_tools.elements.InventoryFrame.Hotbar;
		}, 
		Hotbar);
	
	self.build_tools.maid:add(UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not self.build_tools.enabled then return end;
		
		local slot = table.find(Hotbar.inputs, input.KeyCode);
		
		if slot and not self.build_tools:is_control_down() then
			self:select(slot);
		end
	end))
	
	return self;
end;

function Hotbar:destroy()
	self:deselect();
	
	for _, slot in self.slots do
		slot:destroy();
	end;
	
	table.clear(self.slots);
	Table.dispose(self);
end

function Hotbar:unequip_slot(slot: number)
	if self.slots[slot] then
		self:deselect();
		
		local maxn = #self.slots;
		
		self.slots[slot]:destroy();
		self.slots[slot] = nil;
		
		for current_slot = slot + 1, maxn do
			local slot_item = self.slots[current_slot];
			
			if not slot_item then
				break;
			end;
			
			slot_item:set_index( self.slots[current_slot].index - 1 );
			
			self.slots[current_slot] = nil;
			self.slots[current_slot - 1] = slot_item;
		end;
		
		self.build_tools.actions:save_to_hotbar(slot, nil);
	end;
end

local function equip_slot(self, slot: number, info): ()
	if not info.model and info.reference then
		info.model = info.reference:Clone();
	end;

	self:unequip_slot(slot);

	self.slots[slot] = Item.new(self.inventory, slot, info);
	self.slots[slot]:initialise_as_slot();
	self.slots[slot]:set_viewport_enabled(true);
	self.slots[slot].frame.Parent = self.hotbar_frame.Items;

	self.build_tools.actions:save_to_hotbar(slot, info.reference);
end

function Hotbar:equip_slot(slot: number, info)
	if not self.build_tools.marketplace:has_gamepass( "PrivateServerPlus" ) then
		return;
	end;
	
	if not (slot >= 1 and slot <= 9) then
		return self.build_tools:notify(NotificationStatus.info, "You cannot have more than 9 items in your hotbar.", 5);
	end
	
	equip_slot(self, slot, info);
end

function Hotbar:force_equip_slot(slot: number, info): ()
	equip_slot(self, slot, info);
end

function Hotbar:next(): number
	return #self.slots + 1;
end

function Hotbar:is_active(): boolean
	return self.equipped ~= nil;
end

function Hotbar:deselect()
	if self.equipped then
		local slot_item = self.slots[self.equipped];
		
		self.build_tools.placement:deselect();
		
		self.equip_maid:clean();
		self.equipped = nil;
		
		if slot_item then
			slot_item:update_equipped();
		end;
	end;
end

function Hotbar:select(slot: number)
	if self.equipped ~= slot then
		if self.equipped then
			self:deselect();
		end
		
		task.wait()
		local slot_item = self.slots[slot];
		
		if slot_item then
			self.equipped = slot;
			self.gpad_last_equipped = slot;
			self.build_tools.placement:select(self.slots[self.equipped]);
			
			self.equip_maid:add(self.build_tools.selection.on_selection_changed:Connect(function()
				self:deselect();
			end))
			
			slot_item:update_equipped();
		end;
	else
		self:deselect();
	end;
end

function Hotbar:cycle_slot(value: number): ()
	if self.equipped then
		self:select( math.clamp(self.equipped + value, 1, 9) );
	else
		self:select( self.gpad_last_equipped or 1 );
	end
end

table.freeze(Hotbar);

return Hotbar;