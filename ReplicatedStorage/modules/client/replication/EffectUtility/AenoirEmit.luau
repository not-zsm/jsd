local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

------------------------------------------------------------------------------------------

local Maid = require( replicatedStorage.packages.Maid )

------------------------------------------------------------------------------------------

local Rnd = Random.new();
local DefaultParameters = { Scale = 1, Volume = 1, Density = 1, Offset = CFrame.identity };
local MetaParameters = { __index = DefaultParameters };

------------------------------------------------------------------------------------------

export type EmitParameters = {
	Folder: Instance?,
	Target: (Instance | CFrame)?,
	Finished: ( () -> () )?,
	Scale: number?,
	Volume: number?,
	Offset: CFrame?,
	Density: number?,
	Tint: Color3?,
};

export type ClassEmitStruct = {
	__index: ClassEmitStruct;

	Increment: (self: EmitStruct) -> ();
	Decrement: (self: EmitStruct) -> ();
	Destroy: (self: EmitStruct) -> ();
};

export type EmitStruct = typeof(setmetatable({} :: {

	Items: number,
	Destroyed: boolean,
	Maid: Maid.Maid,
	Finished: ( () -> () )?,
	Scale: number,
	Volume: number,
	Tint: Color3?,
	Density: number,

}, {} :: ClassEmitStruct));

------------------------------------------------------------------------------------------

export type ClassMain = {
	__index: ClassMain;
	__call: (Folder: Folder, Target: Instance | CFrame, Finished: (() -> ())?, Parameters: EmitParameters?) -> EmitStruct,

	EvaluateNumberSequence: (Sequence: NumberSequence, Time: number) -> number;
	ScaleNumberSequence: (Sequence: NumberSequence, ScaleFactor: number) -> NumberSequence;
	LerpNumberSequence: (Sequence: NumberSequence, Value: number, Alpha: number) -> NumberSequence;

	FromParameters: (Parameters: EmitParameters) -> EmitStruct;
	Emit: (Folder: Folder, Target: Instance | CFrame, Parameters: EmitParameters?) -> EmitStruct;
	Recolor: (Color: ColorSequence, Tint: Color3) -> ColorSequence,
};

export type Main = typeof(setmetatable({} :: {}, {} :: ClassMain));

------------------------------------------------------------------------------------------

local Main = {}:: ClassMain;
Main.__index = Main;

local EmitStruct = {} :: ClassEmitStruct;
EmitStruct.__index = EmitStruct;

------------------------------------------------------------------------------------------

local function EvaluateNumberSequence(Sequence: NumberSequence, Time: number): number
	if typeof(Sequence) == "number" then return Sequence end;
	
	local Keypoints = Sequence.Keypoints;

	if Time <= 0 then
		return Keypoints[1].Value;

	elseif Time >= 1 then
		return Keypoints[#Keypoints].Value;
	end

	for Index = 1, #Keypoints - 1 do
		local Keypoint, NextKeypoint = Keypoints[Index], Keypoints[Index + 1]

		if Keypoint.Time <= Time and NextKeypoint.Time >= Time then
			return math.lerp(Keypoint.Value, NextKeypoint.Value, (Time - Keypoint.Time) / (NextKeypoint.Time - Keypoint.Time));
		end
	end;

	error("NumberSequence could not return a value");
end;

local function LerpNumberSequence(Sequence: NumberSequence, Value: number, Alpha: number): NumberSequence
	local SequenceArray: {NumberSequenceKeypoint} = {}

	for _, Keypoint in ipairs(Sequence.Keypoints) do
		table.insert(SequenceArray, NumberSequenceKeypoint.new(Keypoint.Time, math.lerp(Keypoint.Value, Value, Alpha), math.lerp(Keypoint.Envelope, Value, Alpha)));
	end;

	return NumberSequence.new(SequenceArray);
end

local function ScaleNumberSequence(Sequence: NumberSequence, ScaleFactor: number): NumberSequence
	if ScaleFactor == 1 then
		return Sequence;
	end;

	local SequenceArray: {NumberSequenceKeypoint} = {}

	for _, Keypoint in ipairs(Sequence.Keypoints) do
		table.insert(SequenceArray, NumberSequenceKeypoint.new(Keypoint.Time, Keypoint.Value * ScaleFactor, Keypoint.Envelope * ScaleFactor));
	end;

	return NumberSequence.new(SequenceArray);
end;

local function ScaleLightRange(Light: any, Scale: number): ()
	Light.Range = Light.Range * Scale;
end

------------------------------------------------------------------------------------------

local function EmitSingle(Effect: Instance, Adornee: Instance, Struct: EmitStruct)

	local Info = Effect:GetAttributes();
	
	local Count: number = Info.EmitCount or 0;
	local EmitDelay: number = Info.EmitDelay or 0;
	local Uptime: number? = Info.EmitUptime or Info.EmitDuration or Info.EnableDuration;
	
	Effect.Archivable = false;

	if EmitDelay ~= 0 then
		task.wait(EmitDelay)
	end

	if Effect:IsA("ParticleEmitter") then
		Effect.Size = ScaleNumberSequence(Effect.Size, Struct.Scale);
		Effect.Speed = NumberRange.new( Effect.Speed.Min * Struct.Scale, Effect.Speed.Max * Struct.Scale );
		Effect.Acceleration *= Struct.Scale;
		Effect.Enabled = false;

		if Struct.Tint then
			Effect.Color = Main.Recolor(Effect.Color, Struct.Tint);
		end;

		Effect.Parent = Adornee;

		Struct:Increment();

		task.delay(Effect.Lifetime.Max / Effect.TimeScale + (Uptime or 0), function()
			Struct:Decrement();
			Effect:Destroy();
		end)
		
		if Count > 0 then
			Effect:Emit( Count * Struct.Density )
		end;
		
		if Uptime then
			Effect.Enabled = true;

			task.delay(Uptime, function()
				Effect.Enabled = false;
			end)
		end

	elseif Effect:IsA("Sound") then
		Effect.Volume *= Struct.Volume
		Effect.Playing = false;
		Effect.Parent = Adornee;

		if Struct.Volume > 0 then
			if not Effect.IsLoaded then
				Effect.Loaded:Wait();
			end;

			Effect:Play();
		end;

		if Info.Pitch then
			Effect.PlaybackSpeed = Info.Pitch.Min + math.random() * (Info.Pitch.Max - Info.Pitch.Min)
		end

		if Info.FadeIn then
			local TargetVolume = Effect.Volume;
			Effect.Volume = 0;

			task.delay(Info.FadeIn.Min, function()
				local Tween = TweenService:Create(Effect, TweenInfo.new(Info.FadeIn.Max - Info.FadeIn.Min), {
					Volume = TargetVolume;
				})
				Tween:Play();
			end)
		end

		if Info.FadeOut then
			task.delay(Info.FadeOut.Min, function()
				local Tween = TweenService:Create(Effect, TweenInfo.new(Info.FadeOut.Max - Info.FadeOut.Min), {
					Volume = 0;
				})
				Tween:Play();
			end)
		end

		local Max = (if Info.FadeOut then Info.FadeOut.Max else Effect.TimeLength) * Effect.PlaybackSpeed;

		Struct:Increment();

		task.delay(Max, function()
			Struct:Decrement();
			Effect:Destroy();
		end)

	elseif Effect:IsA("Light") then
		pcall(ScaleLightRange, Effect, Struct.Scale);
		Effect.Parent = Adornee;

		local Brightness = Effect.Brightness;
		
		local Lifetime, Multiplier = 1, Brightness;
		local StartFade: number = Info.StartFade or 0;
		local EndFade: number = Info.EndFade or 0;

		local StartFadeStyle: string = Info.StartFadeStyle or "Cubic"
		local EndFadeStyle: string = Info.EndFadeStyle or "Cubic"
		
		if Info.Lifetime then
			if typeof(Info.Lifetime) == "NumberRange" then
				Lifetime = Rnd:NextNumber(Info.Lifetime.Min, Info.Lifetime.Max);
			else
				Lifetime = Info.Lifetime;
			end;
			
		elseif Info.EnableDuration then
			Lifetime = Info.EnableDuration + EndFade;
			
			task.delay(Info.EnableDuration, function()
				if EndFade > 0 then
					TweenService:Create(Effect, TweenInfo.new(EndFade, Enum.EasingStyle[EndFadeStyle], Enum.EasingDirection.Out), {Brightness = 0}):Play();
				else
					Effect.Enabled = false;
				end;
			end);
		end;
		
		if Info.Brightness then
			if typeof(Info.Brightness) == "NumberSequence" then
				local Elapsed = 0;
				local Connection: RBXScriptConnection;

				local function EffectStep(Delta: number)
					Elapsed += Delta;

					if Elapsed > Lifetime then
						Connection:Disconnect();
					end

					Effect.Brightness = EvaluateNumberSequence(Info.Brightness, Elapsed / Lifetime) * Multiplier
				end

				EffectStep(0);
				Connection = RunService.PostSimulation:Connect(EffectStep)
			else
				Brightness = Info.Brightness;
				
				if StartFade > 0 then
					Effect.Brightness = 0;
					TweenService:Create(Effect, TweenInfo.new(StartFade, Enum.EasingStyle[StartFadeStyle], Enum.EasingDirection.Out), {Brightness = Brightness}):Play()
				else
					Effect.Brightness = Brightness;
				end;
			end;
		end;

		Effect.Enabled = true;
		Struct:Increment();

		task.delay(Lifetime, function()
			Struct:Decrement();
			Effect:Destroy();
		end);

	elseif Effect:IsA("Folder") then
		local Instances = Effect:GetChildren();
		local Particle = Instances[math.random(#Instances)];

		if Particle then
			EmitSingle(Particle, Adornee, Struct);
		end;
		
	elseif Effect:IsA("Attachment") then
		Effect.Parent = Adornee;
		
		local Instances = Effect:GetChildren();
		
		for _, Particle in Instances do
			EmitSingle(Particle, Effect, Struct);
		end;
	end;
end;

local function Emit(Folder: Folder, Target: Instance | CFrame, Finished: (() -> ())?, Parameters: any): EmitStruct
	if not Folder then
		return warn("Unable to emit: no effects were passed");
	end;
	
	if not Parameters then
		Parameters = DefaultParameters;
		
	elseif typeof(Parameters) == "Instance" then
		Parameters = setmetatable(Parameters:GetAttributes(), MetaParameters);
	else
		setmetatable(Parameters, MetaParameters);
	end

	local EmitStructure = setmetatable(
		{
			Items = 0, 
			ConfirmFinish = Parameters.ConfirmFinish or 3;
			Destroyed = false,
			Maid = Maid.light(), 
			Finished = Finished,
			Scale = Parameters.Scale,
			Volume = Parameters.Volume,
			Density = Parameters.Density,
			Tint = Parameters.Tint,
		},
		EmitStruct);
	
	local Adornee;

	if typeof(Target) == "Instance" and Parameters.Offset ~= CFrame.identity then
		Adornee = Instance.new("Attachment");
		Adornee.CFrame = Parameters.Offset;
		Adornee.Parent = Target;

		EmitStructure.Maid:add(Adornee);

	elseif typeof(Target) == "Vector3" then
		Adornee = Instance.new("Attachment");
		Adornee.Position = Parameters.Offset.Position + Target;
		Adornee.Parent = workspace.Terrain;
		
		EmitStructure.Maid:add(Adornee);
		
	elseif typeof(Target) == "CFrame" then
		Adornee = Instance.new("Attachment");
		Adornee.CFrame = Target * Parameters.Offset;
		Adornee.Parent = workspace.Terrain;

		EmitStructure.Maid:add(Adornee);
	else
		Adornee = Target;
	end;
	
	-- Timeout if for whatever reason they dont auto-destroy.
	EmitStructure.Maid:add(task.delay(30, EmitStruct.Destroy, EmitStruct))

	if Folder:IsA("Sound") or Folder:IsA("ParticleEmitter") then
		task.spawn(EmitSingle, Folder:Clone(), Adornee, EmitStructure);
	end;
	
	local Copy = Folder:Clone();
	
	for _, Particle in Copy:GetChildren() do
		task.defer(EmitSingle, Particle, Adornee, EmitStructure);
	end;
	
	if Copy:IsA("Sound") or Copy:IsA("ParticleEmitter") then
		task.spawn(EmitSingle, Copy, Adornee, EmitStructure);
	end;
	
	return EmitStructure;
end

------------------------------------------------------------------------------------------

function EmitStruct:Increment()
	self.Items += 1;
	
	if self.DestroyTimer and coroutine.status(self.DestroyTimer) == "suspended" then
		task.cancel(self.DestroyTimer);
		self.DestroyTimer = nil;
	end
end;

function EmitStruct:Decrement()
	self.Items -= 1;
	
	if self.Items <= 0 and not self.DestroyTimer then
		self.DestroyTimer = task.delay(self.ConfirmFinish, self.Destroy, self);
	end;
end;

function EmitStruct:Destroy()
	if self.Destroyed or not self.Maid then return end;
	
	self.Destroyed = true;
	self.Maid:destroy();
	
	if self.Finished then
		task.spawn(self.Finished);
		self.Finished = nil;
	end;
end;

------------------------------------------------------------------------------------------

Main.EvaluateNumberSequence = EvaluateNumberSequence;
Main.ScaleNumberSequence = ScaleNumberSequence;
Main.LerpNumberSequence = LerpNumberSequence;

function Main:__call(...)
	return Emit(...);
end;

function Main.FromParameters(Parameters)
	if not Parameters then Parameters = {}; end;
	
	return Emit(Parameters.Folder, Parameters.Target, Parameters.Finished, Parameters);
end;

function Main.Emit(Folder, Target, Parameters)
	if not Parameters then Parameters = {}; end;
	
	return Emit(Folder, Target, Parameters.Finished, Parameters);
end;

function Main.Recolor(Color: ColorSequence, Tint: Color3): ColorSequence
	local SequenceArray: {ColorSequenceKeypoint} = {};
	local TintHue, TintSaturation, TintValue = Tint:ToHSV();
	local TintStrength = 1;

	for _, Keypoint in ipairs(Color.Keypoints) do
		local Hue, Saturation, Value = Keypoint.Value:ToHSV();
		-- Darker colors remain dark
		local NewColor = Color3.fromHSV( math.lerp(Hue, TintHue, TintStrength), math.lerp(Hue, TintSaturation, TintStrength), Value );
		
		table.insert(SequenceArray, ColorSequenceKeypoint.new(Keypoint.Time, NewColor));
	end;

	return ColorSequence.new(SequenceArray);
end

------------------------------------------------------------------------------------------

-- Create Singleton
local MainEmit: Main = setmetatable({}, Main);

return MainEmit;