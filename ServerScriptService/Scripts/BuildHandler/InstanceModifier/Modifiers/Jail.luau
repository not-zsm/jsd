local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Unpacker = require( "../../Unpacker" );
local Type = require( Unpacker.Packages.Type );

local overlap = RaycastParams.new()
overlap.FilterDescendantsInstances = {workspace.Map, workspace.Builds, workspace.Terrain};
overlap.FilterType = Enum.RaycastFilterType.Include;

local InstanceModifier = require( script.Parent .Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Locks up a player for a specified amount of time";
TagModifier.needs_gamepass = "TrapsPack1";
TagModifier.icon = 17169180878;
TagModifier.color = Color3.fromRGB(103, 103, 103)
TagModifier.section = 5;
TagModifier.properties = {
	Duration = {
		Default = 10;
	};
	ShowCountdown = {
		Default = true;
	};
	Unjails = {
		Default = false;
	};
};

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	self.short_powered = true;
	
	return self;
end

local function unjail(self, character: Model)
	local is_jailed = character:GetAttribute("Jailed");
	if not is_jailed then return end;
	
	character:SetAttribute("Jailed", false);
	
	local cage = character:FindFirstChild("Cage");
	
	if cage then
		cage:Destroy();
	end
end

local function jail(self, character: Model)
	local is_jailed = character:GetAttribute("Jailed");
	if is_jailed then return end;
	
	local root_part = character.HumanoidRootPart :: BasePart;
	
	local origin = character:GetPivot();
	local result = workspace:Raycast(origin.Position, -Vector3.yAxis * 15, overlap);
	
	local coordinate = if result then origin.Rotation + result.Position else origin;
	local cage = script.Cage:Clone();
	local countdown_title = cage.Top.Countdown.Title;
	
	cage:PivotTo(coordinate);
	
	local duration = self.attributes:get("Duration");
	local has_countdown = self.attributes:get("ShowCountdown");
	
	if duration > 0 and duration < 1800 then
		local debmaid = self.maid:limb();
		
		debmaid:add(cage.AncestryChanged:Connect(function(_, parent)
			if parent then return end;
			debmaid:destroy();
		end));
		
		if has_countdown then
			debmaid:add(task.spawn(function()
				local time_end = duration;
				
				repeat
					countdown_title.Text = math.round(time_end);
					time_end -= 1;
					task.wait(1);
					
				until time_end <= 0;
			end));
		end;
		
		debmaid:add(function()
			unjail(self, character);
		end)
		
		debmaid:add(task.delay(duration, function()
			debmaid:destroy();
		end))
	else
		countdown_title.Text = "...";
	end
	
	if not has_countdown then
		cage.Top.Countdown:Destroy();
	end;
	
	character:PivotTo(coordinate * CFrame.new(0, 0.1, 0));
	cage.Parent = character;
	
	character:SetAttribute("Jailed", true);
	
	task.defer(function()
		self.build_handler:spawn_effects("Jailed", root_part.RootAttachment)
	end);
end

function TagModifier:pulse(signal)
	local data = self.attributes:all();
	
	for _, combat in signal:get_combats() do
		local player = combat:get_player();
		
		if player and player.Character then
			if data.Unjails then
				unjail(self, player.Character);
			else
				jail(self, player.Character);
			end
		end
	end;
end

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;