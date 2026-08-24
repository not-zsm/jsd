local replicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local Math = require( "../../Math" )
local Table = require( "../../Table" )
local Maid = require( "../../Maid" )
local Signal = require( "../../Signal" )
local Asset = require( "../../Asset" );
local StylusBase = require( script.Parent );

local ButtonMusicbox = script:WaitForChild("Musicbox");
local MusicboxFolder = SoundService:FindFirstChild("MusicboxAudio");

if not MusicboxFolder then
	MusicboxFolder = Instance.new("Folder");
	MusicboxFolder.Name = "MusicboxAudio";
	MusicboxFolder.Parent = SoundService;
end;

local MusicboxSoundName = "MusicboxSound";

-----------------------------------------------------------------------

export type Defaults = {
	text: string;
	text_scaled: boolean?;
	tooltip: string?;
	ui_ratio: number?;
	padding: {[string]: UDim}?;
	ratio: number;
	parent: Instance?;
};

export type ClassMusicbox = {
	__index: ClassMusicbox;

	new: (stylus: any, defaults: Defaults) -> Musicbox;
	init: (self: Musicbox) -> ();
	set_label: (self: Musicbox, label: string) -> ();
	get_raw_alpha: (self: Musicbox) -> number;
	set_alpha: (self: Musicbox, alpha: number) -> ();
	update_alpha: (self: Musicbox, input: Vector2) -> ();
	get_value_from_alpha: (self: Musicbox) -> number;
	get_alpha_from_value: (self: Musicbox, value: number) -> number;
};

export type Musicbox = typeof(setmetatable({} :: {
	defaults: Defaults;
	instance: typeof(ButtonMusicbox);
	slider: typeof(ButtonMusicbox.Slider);
	ball: typeof(ButtonMusicbox.Slider.Ball);
	maid: Maid.Maid;
	alpha: number;
	value: number;

}, {} :: ClassMusicbox));

-----------------------------------------------------------------------

local Musicbox = setmetatable({} :: ClassMusicbox, StylusBase)
Musicbox.__index = Musicbox;
Musicbox.__type = "Musicbox";
Musicbox.defaults = {
	text = "Musicbox";
	text_scaled = false;
	ratio = 0.5;
	parent = nil;
}

function Musicbox.new(stylus, defaults)
	debug.profilebegin("Sliderbox");
	
	local self = setmetatable(StylusBase.new(stylus, defaults), Musicbox);
	
	self.defaults = Table.mirror(Musicbox.defaults, defaults or {})
	self:create_instance(ButtonMusicbox);
	
	self.layout.TextLabel.Size = UDim2.fromScale(self.defaults.ratio, 1);
	self.layout.TextLabel.TextScaled = self.defaults.text_scaled;
	self.instance.Visible = true;
	self.ball = self.value_frame.Slider.Ball;
	self.slider = self.value_frame.Slider;
	self.dragger = self.slider.UIDragDetector;
	self.on_played = self.maid:add(Signal.new());
	self.audio_maid = self.maid:limb();
	
	self:set_label(self.defaults.text)
	self:init();
	self:draw();
	
	if self.defaults.value then
		if typeof(self.defaults.value) == "Instance" then
			self:set_audio( self.defaults.value );
		else
			self:set_asset_id( self.defaults.value );
		end;
	end;

	debug.profileend();
	
	return self;
end;

function Musicbox:destroy()
	self:set_audio(nil);
	StylusBase.destroy(self);
end;

function Musicbox:set_label(label: string): ()
	self.layout.TextLabel.Text = tostring(label or "");
end;

function Musicbox:set_asset_id(asset_id: number): Sound
	local audio = Instance.new("Sound");
	audio.Name = MusicboxSoundName;
	audio.Volume = 1;
	audio.SoundId = Asset.get_rbx_asset(asset_id);
	audio.Parent = self.instance;
	
	self:set_audio(audio);
	
	return audio;
end;

local function get_property(instance: Instance, property: string): any
	return instance[property];
end

local function set_property(instance: Instance, property: string, value: any): ()
	instance[property] = value;
end;

local BadProperties = {Name = true, Parent = true, Playing = true, TimePosition = true};

function Musicbox:set_audio_referenced(sound: Sound?): ()
	if not sound then
		return self:set_audio(sound);
	end;
	
	local audio_copy = Instance.fromExisting(sound);
	audio_copy:Stop();
	audio_copy.TimePosition = 0;
	audio_copy.Archivable = false;
	audio_copy.Name = MusicboxSoundName;
	audio_copy.Parent = MusicboxFolder;
	
	self:set_audio(audio_copy);
	
	self.audio_maid:add(sound.Changed:Connect(function(property)
		if BadProperties[property] then
			return;
		end;
		
		local is_property, value = pcall(get_property, sound, property);
		
		if is_property then
			pcall(set_property, audio_copy, property, value);
		end;
	end));
end

function Musicbox:set_audio(sound: Sound?): ()
	self:stop();
	
	if self.audio and self.audio.Name == MusicboxSoundName then
		self.audio:Destroy();
	end;
	
	self.audio_maid:clean();
	self.audio = sound;
	
	if self.audio_track_connection then
		self.audio_track_connection:Disconnect();
	end;
	
	if sound then
		local function update_playing()
			self:update_playing();
		end;
		
		self:update_graph();
		
		self.audio_maid:add(sound.Loaded:Connect(function()
			self:update_graph();
		end));
		
		self.audio_maid:add(sound.Played:Connect(update_playing));
		self.audio_maid:add(sound.Ended:Connect(update_playing));
		self.audio_maid:add(sound.Stopped:Connect(update_playing));
	end;
end;

function Musicbox:update_audio_stats()
	if self.audio then
		self.value_frame.Length.Text = `{Asset.pretty_time(self.audio.TimePosition)} / {Asset.pretty_time(self.audio.TimeLength)}`;
	else
		self.value_frame.Length.Text = "---";
	end
end

function Musicbox:update_playing()
	if self.audio_track_connection then
		self.audio_track_connection:Disconnect();
	end;
	
	if self.audio and self.audio.IsPlaying then
		self.value_frame.Play.BackgroundColor3 = Color3.fromRGB(127, 72, 72);
		self.value_frame.Play.Icon.Image = "rbxassetid://8517320975";
		
		self.audio_track_connection = RunService.PostSimulation:Connect(function(dt)
			self:update_graph();
		end);
	else
		self.value_frame.Play.BackgroundColor3 = Color3.fromRGB(81, 127, 74);
		self.value_frame.Play.Icon.Image = "rbxassetid://12099513379";
	end;
	
	self:update_graph();
end;

function Musicbox:play()
	if self.audio then
		self.audio:Play();
	end;
end;

function Musicbox:stop()
	if self.audio then
		self.audio:Stop();
	end;
end;

function Musicbox:get_raw_alpha(): number
	local ball_pos = self.ball.AbsolutePosition.X;
	local start_pos = self.slider.AbsolutePosition.X;
	local end_pos = start_pos + self.slider.AbsoluteSize.X;
	
	return Math.GetAlpha(start_pos, ball_pos, end_pos);
end

function Musicbox:get_value_from_alpha(alpha: number): number
	if not self.audio then 
		return 0; 
	end;
	
	return alpha * self.audio.TimeLength;
end

function Musicbox:get_alpha_from_value(value: number): number
	if not self.audio or self.audio.TimeLength == 0 then 
		return 0; 
	end;
	
	return value / self.audio.TimeLength;
end;

function Musicbox:update_graph()
	local alpha = self:get_alpha();
	
	self.ball.Position = UDim2.fromScale(math.clamp(alpha, 0.02, 0.98), 0.5);
	self.slider.Backdrop.Size = UDim2.fromScale(math.clamp(alpha, 0, 1), 0.3);
	
	self:update_audio_stats();
end

function Musicbox:get_alpha(): number
	if not self.audio or self.audio.TimeLength == 0 then
		return 0;
	end;
	
	return self.audio.TimePosition / self.audio.TimeLength;
end

function Musicbox:set_alpha(alpha: number): ()
	self:set_value( self:get_value_from_alpha(alpha) );
end;

function Musicbox:get_value(): number
	if not self.audio then
		return 0;
	end;
	
	return self.audio.TimePosition;
end

function Musicbox:update_alpha(input: Vector2): ()
	local start, finish = self.slider.AbsolutePosition.X, self.slider.AbsolutePosition.X + self.slider.AbsoluteSize.X;
	local alpha = math.clamp( Math.GetAlpha(start, input.X, finish), 0, 1 );
	
	self:set_alpha(alpha);
end

function Musicbox:init()
	self.maid:add(self.value_frame.Play.MouseButton1Click:Connect(function()
		if not self.audio or not self.audio.IsPlaying then
			self.on_played:Fire();
		end;
		
		if self.audio then
			if self.audio.IsPlaying then
				self.audio:Stop();
			else
				self.audio:Play();
			end;
		end;
	end));
	
	self.maid:add(self.stylus.bind_to_resize(self.value_frame.Length, function(size)
		self.value_frame.Length.TextSize = size.Y * (self.defaults.text_scale or 0.85);
	end));
	
	self.maid:add(self.slider.UIDragDetector.DragContinue:Connect(function(input)
		self:update_alpha(input);
	end))
	
	self.maid:add(self.slider.UIDragDetector.DragStart:Connect(function(input)
		self:update_alpha(input);
		
		if self.audio and not self.audio.IsPaused then
			self.audio:Pause();
		end;
	end))
	
	self.maid:add(self.slider.UIDragDetector.DragEnd:Connect(function()
		self.interacted:Fire( self:get_value() );
		
		if self.audio and self.audio.IsPaused then
			self.audio:Resume();
		end;
	end))
end;

function Musicbox:set_value(value: number)
	if self.audio then
		self.audio.TimePosition = value;
	end;
	
	self:update_graph();
end

table.freeze(Musicbox);

return Musicbox;