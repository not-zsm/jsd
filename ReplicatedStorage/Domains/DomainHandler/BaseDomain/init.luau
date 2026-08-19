local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer;

local AenoirUtil = require( ReplicatedStorage.Modules.Shared.Utilities.Utility.AenoirUtil )
local AenoirEmit = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility.AenoirEmit )

local Maid = require( ReplicatedStorage.Packages.Maid )
local DomainWorld = require( ReplicatedStorage.Domains.DomainWorld );

local ViewportEffect = require("./ViewportEffect");

local Assets = script.Parent.Parent.Assets;
local Rnd = Random.new();

local BaseDomain = {};
BaseDomain.__index = BaseDomain;
BaseDomain.resources = Assets;
BaseDomain.size = 70;
BaseDomain.world_size = 256;
BaseDomain.plane_transition = {
	fog_color = Color3.fromRGB(22, 30, 34);
	duration = 1.5;
	pretime = 1.8;
};
BaseDomain.ambient_reverb = Enum.ReverbType.Cave;
BaseDomain.darkness_value = -1;

function BaseDomain.new(DomainHandler, info)
	local maid = Maid.new();
	
	local self = setmetatable(
		{
			maid = maid;
			domain_handler = DomainHandler;
			model = info.model;
			origin = info.origin;
			owned = info.owner == Player;
			owner = info.owner;
			is_npc = not info.owner:IsA("Player"),
			other_world = info.model.TransitionWorld;
			world = DomainWorld.new(info.model, info.model.CollisionSphere.Position);
			assets = {};
			
			inside = false;
			bubble_ready = false;
		}, 
		BaseDomain);
	
	maid:add(info.model.AncestryChanged:Connect(function()
		self:destroy();
	end));
	
	return self;
end;

function BaseDomain:initialise()
	self.world.size = self.size;
	self.world:set_world_size(self.world_size);
	
	for _, asset in Assets:GetChildren() do
		self.assets[asset.Name] = asset;
	end;
	
	for _, asset in self.resources:GetChildren() do
		self.assets[asset.Name] = asset;
	end;
end;

function BaseDomain:destroy()
	AenoirEmit(Assets.DomainShatter, self.model:GetPivot());
	
	self:leave();
	self.domain_handler:remove(self);
	
	if self.screen then
		self.screen:Destroy();
	end;
	
	if self.model then
		self.model = nil;
	end
	
	self.maid:destroy();
	
	--table.clear(self);
end;

function BaseDomain:get_character()
	return if self.is_npc then self.owner else self.owner.Character;
end;

function BaseDomain:leave()
	if self.inside then
		self.inside = false;
		self.domain_handler:show_lighting();
		
		SoundService.AmbientReverb = Enum.ReverbType.NoReverb;
	
		self.world:teleport_world(
			self.enter_character, 
			self.world:get_position(true), 
			self.world:get_position(false), -- lol
			"Out"
		);
	end;
end

function BaseDomain:enter()
	self.inside = true;
	
	local plane = self.model.World.Plane;
	local character = Player.Character;
	
	self.enter_character = character;
	
	self:hide_screen(); -- Domain screen might be shown so we hide it
	self:create_darkness(2, 0.25);
	self:create_world();
	
	if workspace.StreamingEnabled then
		task.spawn(Player.RequestStreamAroundAsync, Player, plane.Position);
	end;
	
	task.wait(self.plane_transition.pretime);
	
	if not self.maid.destroyed then
		self:transition();
		
		if not self.maid.destroyed then
			self.world:teleport_world(
				self.enter_character, 
				self.world:get_position(self.other_world), 
				self.world:get_position(true),
				"None"
			);
			
			SoundService.AmbientReverb = self.ambient_reverb;
		end
	end;
end;

function BaseDomain:play_popup()
	local effect = ViewportEffect.new({
		
	});
	effect:play()

	task.wait(2);
	effect:stop();
end;

function BaseDomain:spawn_wave()
	local wave = self.assets.WorldSphere:Clone();
	wave.Material = Enum.Material.ForceField;
	wave.Transparency = 0.5;
	wave.Color = Color3.fromRGB(255, 255, 255);
	wave.Size = Vector3.zero;
	wave.CFrame = self.origin;
	wave.Parent = workspace.Visuals;
	
	task.delay(1, wave.Destroy, wave);
	
	local tween = TweenService:Create(wave, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.one * 120});
	tween:Play()
	
	local tween = TweenService:Create(wave, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1});
	tween:Play()
	
	AenoirEmit(self.assets.DomainWave, self.origin);
end;

function BaseDomain:create_world()
	print("bruh")
end

function BaseDomain:create_bubble(origin: CFrame): ()
	AenoirEmit(self.assets.DomainSummon, origin);
	
	local domain = self.assets.DomainEffects:Clone();
	local origin_pos = CFrame.new(origin.Position);
	domain:PivotTo(origin_pos);
	
	local size = Vector3.one * self.size;

	domain.Floor.Size = Vector3.new(size.X - 5, 0.1, size.Z - 5);
	domain.Dome.Size = size;

	domain.Floor.Ink.Enabled = true;
	domain.Dome.Ink.Enabled = true;
	domain.Dome.Ink.Rate = 15 * self.size;
	domain.Dome.Ink.Size = AenoirUtil.ScaleNumberSequence(domain.Dome.Ink.Size, 0.5 + self.size / 50);
	domain.Floor.Ink.Size = AenoirUtil.ScaleNumberSequence(domain.Floor.Ink.Size, 0.5 + self.size / 100);
	domain.Floor.Ink.Rate = 20;
	
	domain.Parent = self.model;

	local TweenFloor = TweenService:Create(domain.Floor.Ink, TweenInfo.new(2), {ShapePartial = 1})
	TweenFloor:Play();
	TweenFloor.Completed:Once(function(status)
		if status ~= Enum.PlaybackState.Completed then return end;
		
		local Highlight = Instance.new("Highlight");
		Highlight.OutlineTransparency = 1;
		Highlight.FillColor = Color3.new(0, 0, 0);
		Highlight.FillTransparency = 1;
		Highlight.DepthMode = Enum.HighlightDepthMode.Occluded;
		Highlight.Parent = domain.Dome;
		
		local TweenDomeTransparency = TweenService:Create(Highlight, TweenInfo.new(0.5), {FillTransparency = 0})
		TweenDomeTransparency:Play();
		
		local TweenDomeTransparency = TweenService:Create(domain.Dome, TweenInfo.new(0.5), {Transparency = 0})
		TweenDomeTransparency:Play();
		
		domain.Dome.Ink.Rate = 15;
		domain.Floor.Ink.Rate = 12 * self.size * 0.5;
		
		self.bubble_ready = true;
	end)

	local TweenFloorRate = TweenService:Create(domain.Floor.Ink, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Rate = 12 * self.size, TimeScale = 0.5})
	TweenFloorRate:Play();

	local TweenDome = TweenService:Create(domain.Dome.Ink, TweenInfo.new(1.5), {ShapePartial = 1, TimeScale = 0.5})
	TweenDome:Play();
	
	self.maid:add(domain);
	
	return domain;
end

local function stop_audio(sound: Sound): ()
	local tween = TweenService:Create(sound, TweenInfo.new(0.5), {Volume = 0})
	tween.Completed:Once(function(status)
		if status == Enum.PlaybackState.Completed then
			sound:Stop();
		end
	end)
	tween:Play();
end

local function play_audio(sound: Sound): ()
	sound.Volume = 0.5;
	sound:Play();
end;

function BaseDomain:can_show_screen(): boolean
	return not (self.is_screen_shown or self.inside) and self.bubble_ready;
end

function BaseDomain:hide_screen(): ()
	if not self.screen or not self.is_screen_shown then return end;
	
	self.is_screen_shown = false;
	
	play_audio(Assets.DomainCameraLeave);
	stop_audio(Assets.DomainCameraEnter);
	
	local TweenDarkness = TweenService:Create(self.screen, TweenInfo.new(0.2), {Brightness = 0});
	
	TweenDarkness.Completed:Once(function(status)
		if status == Enum.PlaybackState.Completed then
			self.screen:Destroy();
			self.screen = nil;
		end;
	end);
	
	TweenDarkness:Play();
end

function BaseDomain:show_screen(): ()
	if not self:can_show_screen() then return end;
	
	play_audio(Assets.DomainCameraEnter);
	stop_audio(Assets.DomainCameraLeave);
	
	if not self.screen then
		self.screen = Instance.new("ColorCorrectionEffect");
		self.screen.Name = "DomainDarkness";
		self.screen.Parent = Lighting;
	end;
	
	self.is_screen_shown = true;
	
	local tween = TweenService:Create(self.screen, TweenInfo.new(0.2), {Brightness = -1})
	tween:Play();
end

function BaseDomain:create_transition_wisps(coordinate_origin: CFrame, duration: number)
	local target_offset = CFrame.new(-500, 0, 0);
	local origin_offset = target_offset:Inverse();
	local rnd = Random.new();
	
	local function spawn_wisp()
		local origin = coordinate_origin * origin_offset; 
		local target =  coordinate_origin * target_offset;

		local wisp = self.assets.Attachments.Transition:Clone();
		local seed = math.random();
		local unit = rnd:NextUnitVector();
		local elapsed = 0;
		local connection: RBXScriptConnection;
		
		local att_offset = wisp.Attachment1.CFrame;
		local attachment_offset = CFrame.new(-att_offset.X * 0.5, -att_offset.Y * 0.5, -att_offset.Z * 0.5);
		
		local function update(dt: number)
			elapsed += dt * 4;

			if elapsed > 1 then
				connection:Disconnect();
				elapsed = 1;
				Debris:AddItem(wisp, 5);
			end;

			local pre_rotation = CFrame.lookAlong(Vector3.zero, unit);
			local post_offset = CFrame.new(120, 20, 0);
			local full_offset = (CFrame.Angles(math.random() * 0.01, 0, math.rad(90)) * pre_rotation * post_offset).Position;
			
			wisp.CFrame = (origin + full_offset):Lerp(target + full_offset, elapsed) * attachment_offset;
		end

		connection = RunService.PreSimulation:Connect(update);
		update(0);

		wisp.Parent = workspace.Terrain;
	end
	
	task.spawn(function()
		local elapsed = 0;

		while elapsed < duration do
			for count = 1, 2 do
				task.spawn(spawn_wisp);
			end;
			
			elapsed += task.wait(1 / 60);
		end;
	end);
end;


function BaseDomain:transition()
	self.domain_handler:hide_lighting();
	
	local Sphere = Assets.WorldSphere:Clone();
	Sphere.Size = Vector3.one * 2048;
	Sphere.CFrame = self.model.World.Plane.CFrame;
	Sphere.Parent = self.model.World;
	
	if self.plane_transition then
		
		--local TweenFOV = TweenService:Create(workspace.CurrentCamera, TweenInfo.new(1, Enum.EasingStyle.Elastic), {FieldOfView = 45})
		--TweenFOV:Play();
		
		--task.delay(0.13, function()
			local TweenFOV = TweenService:Create(workspace.CurrentCamera, TweenInfo.new(4, Enum.EasingStyle.Exponential), {FieldOfView = 120})
			TweenFOV:Play();
		--end)
		
		Lighting.FogColor = self.plane_transition.fog_color;
		Lighting.FogStart = 0;
		Lighting.FogEnd = 25;
		
		local TweenFog = TweenService:Create(Lighting, TweenInfo.new(self.plane_transition.duration), {FogStart = 0, FogEnd = 500})
		TweenFog:Play();
		
		AenoirEmit(self.assets.Sounds.Transition, workspace.CurrentCamera)
		
		self:create_transition_wisps(self.other_world:GetPivot(), self.plane_transition.duration);
		
		self.world:teleport_world(
			self.enter_character, 
			self.world:get_position(false), 
			self.world:get_position(self.other_world),
			"In"
		);
		
		task.wait(self.plane_transition.duration);
		
		local TweenFOV = TweenService:Create(workspace.CurrentCamera, TweenInfo.new(2, Enum.EasingStyle.Back), {FieldOfView = 70})
		TweenFOV:Play();
		
		self:create_darkness(0.5, 1);
		
		task.wait(0.5);
		
		local TweenFog = TweenService:Create(Lighting, TweenInfo.new(5), {FogStart = 0, FogEnd = 100_000, FogColor = Color3.fromRGB(192, 192, 192)})
		TweenFog:Play();
	end;
	
	if self.music then
		local Music = self.music:Clone();
		Music.Volume = 0;
		Music.Parent = SoundService;
		Music:Play();

		local tween = TweenService:Create(Music, TweenInfo.new(0.5), {Volume = self.music.Volume});
		tween:Play();

		self.maid:add(function()
			local tween = TweenService:Create(Music, TweenInfo.new(1), {Volume = 0});
			tween:Play();
			tween.Completed:Wait();
			Music:Destroy();
		end)
	end;
end

function BaseDomain:create_darkness(fade_in: number, fade_out: number): ()
	local Darkness = Instance.new("ColorCorrectionEffect");
	Darkness.Name = "DomainDarkness";
	Darkness.Parent = Lighting;
	
	self.maid:add(Darkness);
	
	local ColorValue = 1 - (self.darkness_value + 1) // 2;
	
	local Highlight = Instance.new("Highlight");
	Highlight.FillColor = Color3.fromRGB(255 * ColorValue, 255 * ColorValue, 255 * ColorValue);
	Highlight.OutlineTransparency = 1;
	Highlight.FillTransparency = 1;
	Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop;
	Highlight.Name = "DomainHighlight";
	Highlight.Adornee = Player.Character;
	Highlight.Parent = Player.Character;
	
	self.maid:add(Highlight);
	
	local TweenHighlight = TweenService:Create(Highlight, TweenInfo.new(fade_in * 0.66), {FillTransparency = 0.6})
	TweenHighlight:Play();

	local TweenDarkness = TweenService:Create(Darkness, TweenInfo.new(fade_in), {Brightness = self.darkness_value})
	TweenDarkness:Play();

	task.delay(fade_in, function()
		local TweenHighlight = TweenService:Create(Highlight, TweenInfo.new(fade_out), {FillTransparency = 1})
		TweenHighlight:Play();

		local TweenDarkness = TweenService:Create(Darkness, TweenInfo.new(fade_out), {Brightness = 0})
		TweenDarkness:Play();
		
		task.wait(fade_out);
		
		self.maid:delete(Darkness);
		self.maid:delete(Highlight);
	end);
end;

table.freeze(BaseDomain);

export type BaseDomain = typeof(BaseDomain.new(...))

return BaseDomain;