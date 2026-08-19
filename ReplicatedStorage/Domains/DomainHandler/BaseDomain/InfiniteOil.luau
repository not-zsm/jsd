local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local Player = Players.LocalPlayer;
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Animations = ReplicatedStorage.Animations.Attacks["Meaty Michael"]["Drake's Love"];

local ViewportEffect = require("../ViewportEffect");
local BaseDomain = require(script.Parent);

local InfiniteOil = setmetatable({}, BaseDomain);
InfiniteOil.__index = InfiniteOil;
InfiniteOil.resources = script;
InfiniteOil.size = 150;
InfiniteOil.music = script.Sounds.Music;
InfiniteOil.plane_transition = {
	fog_color = Color3.fromRGB(240, 240, 240);
	duration = 3;
};
InfiniteOil.darkness_value = 1;
InfiniteOil.ambient_reverb = Enum.ReverbType.NoReverb;

function InfiniteOil.new(...)
	local self = setmetatable(BaseDomain.new(...), InfiniteOil);
	
	return self;
end;

function InfiniteOil:transition()
	BaseDomain.transition(self);
	
end

function InfiniteOil:play_popup()
	local effect = ViewportEffect.new({
		viewport_animation = Animations.Windup,
		background_image = "rbxassetid://18725689134",
		character = self:get_character(),
	});
	effect:play();

	task.wait(2.5);
	effect:stop();
end;

function InfiniteOil:create_world()
	local world = self.assets.Domain:Clone();
	world:PivotTo(self.world.plane:GetPivot() * CFrame.new(0, 7, 0));
	world.Parent = self.model.World;
	
	
end;

function InfiniteOil:create_bubble(origin)
	BaseDomain.create_bubble(self, origin);
end

table.freeze(InfiniteOil);

return InfiniteOil;