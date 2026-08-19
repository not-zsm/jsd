local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )
local AenoirMesh = require( script.Parent.AenoirMesh )

local Rnd = Random.new();

local EmitStack = {};

function EmitStack.Increment(self)
	self.Items += 1;
end

function EmitStack.Decrement(self)
	self.Items -= 1;

	if self.Items <= 0 then
		self.Job:Destroy();

		if self.Finished then
			self.Finished()
		end;
	end
end

local function EvaluateNumberSequence(Sequence: NumberSequence, Time: number): number
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

local function EmitSingle(Effect: Instance, Adornee: Instance, Waiting: any)
	Effect.Archivable = false;
	
	local Info = Effect:GetAttributes();
	local EmitDelay = Info.EmitDelay or 0;
	
	if EmitDelay ~= 0 then
		task.wait(EmitDelay)
	end
	
	if Effect:IsA("ParticleEmitter") then
		Effect.Parent = Adornee;
		
		local Count = Info.EmitCount
		local Uptime = Info.EmitUptime
		
		EmitStack.Increment(Waiting);
		task.delay(Effect.Lifetime.Max + (Uptime or 0), function()
			EmitStack.Decrement(Waiting);
			Effect:Destroy();
		end)
		
		if Count then
			Effect:Emit( Count )
		end;

		if Uptime then
			Effect.Enabled = true;

			task.delay(Uptime, function()
				Effect.Enabled = false;
			end)
		end

	elseif Effect:IsA("Sound") then
		Effect.Parent = Adornee;
		
		if not Effect.IsLoaded then
			Effect.Loaded:Wait();
		end;
		
		Effect:Play();
		
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
		
		local Max = if Info.FadeOut then Info.FadeOut.Max else Effect.TimeLength;
		
		EmitStack.Increment(Waiting);
		task.delay(Max, function()
			EmitStack.Decrement(Waiting);
			Effect:Destroy();
		end)
		
	elseif Effect:IsA("Light") then
		Effect.Parent = Adornee;

		local Lifetime, Multiplier = 1, Effect.Brightness;
		
		if Info.Lifetime then
			Lifetime = Rnd:NextNumber(Info.Lifetime.Min, Info.Lifetime.Max)
		end;

		if Info.Brightness then
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
		end

		Effect.Enabled = true;
		
		EmitStack.Increment(Waiting);
		task.delay(Lifetime, function()
			EmitStack.Decrement(Waiting);
			Effect:Destroy();
		end)
		
	elseif Effect:IsA("Folder") then
		local Instances = Effect:GetChildren();
		local Particle = Instances[math.random(#Instances)];
		
		if Particle then
			EmitSingle(Particle, Adornee, Waiting);
		end
		
	elseif Effect:IsA("Model") then
		AenoirMesh.new(Effect):emit(Adornee);
		
	else
		for _, Single in Effect:GetChildren() do
			EmitSingle(Single, Adornee, Waiting);
		end
	end
end

local function Emit(Folder: Folder, Target: Instance | CFrame, Finished)
	local Waiting = {Items = 0, Job = Job.new(), Finished = Finished}
	local Adornee;

	if typeof(Target) == "CFrame" then
		local Coordinate: CFrame = Target;

		Adornee = Instance.new("Attachment");
		Adornee.CFrame = Coordinate;
		Adornee.Parent = workspace.Terrain;

		Waiting.Job:Task(Adornee);
	else
		Adornee = Target;
	end
	
	Waiting.Job:Task(task.delay(15, Waiting.Job.Destroy, Waiting.Job))
	
	for _, Particle in Folder:Clone():GetChildren() do
		task.spawn(EmitSingle, Particle, Adornee, Waiting);
	end
end

return Emit;