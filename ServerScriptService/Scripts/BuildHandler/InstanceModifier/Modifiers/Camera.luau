local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

local Unpacker = require( "../../Unpacker" );
local Type = require( Unpacker.Packages.Type );

local BufferUtil = require( ReplicatedStorage.Packages.BufferUtil )
local AdornCamera = Unpacker.Remotes.Effects.AdornCamera;
local UnadornCamera = Unpacker.Remotes.Effects.UnadornCamera;

local InstanceModifier = require( script.Parent.Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Adorn the player's camera";
TagModifier.icon = 16060788318;
TagModifier.color = Color3.fromRGB(49, 142, 255)
TagModifier.section = 3;
TagModifier.use_prompt = false;
TagModifier.properties = {
	FieldOfView = {
		Default = 70
	};
	Adornee = {
		Default = nil;
		Type = Type.Instance();
	};
	EasingStyle = {
		Default = Enum.EasingStyle.Linear;
	};
	EasingDirection = {
		Default = Enum.EasingDirection.Out;
	};
	EasingTime = {
		Default = 0;
	};
	UnlockRotation = {
		Default = false;
	};
	UnlockPan = {
		Default = false;
	};
};

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	self.short_powered = true;
	self.camera_adorned = {};
	
	return self;
end

function TagModifier:on_powered_changed()
	local data = self.attributes:all();
	
	if self.powered then
		local output = data.Adornee or self.part;
		local tween_info = TweenInfo.new(data.EasingTime, data.EasingStyle, data.EasingDirection);

		local packet = BufferUtil.create(BufferUtil.tween_info.size + BufferUtil.f32.size);
		BufferUtil.write_tween_info(packet, tween_info);
		BufferUtil.write_f32(packet, data.FieldOfView);
		BufferUtil.truncate(packet);
		
		local signal = self:create_target_pulse();
		
		for _, combat in signal:get_combats() do
			local player = combat:get_player();

			if player then
				self.camera_adorned[player] = true;
				
				AdornCamera:FireClient(player, output, self.modifier, data.UnlockRotation, data.UnlockPan, packet.buffer);
			end;
		end;
	else
		for player in self.camera_adorned do
			UnadornCamera:FireClient(player, self.modifier);
		end;
		
		table.clear(self.camera_adorned);
	end
end

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;