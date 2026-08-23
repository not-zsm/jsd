local Util = {};

local replicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Utility = require( script.Parent )

function Util.get_asset_id(asset: string): number?
	asset = asset:lower() -- Makes the match case-insensitive by lowercasing everything

	local id = asset:match("^(%d+)$") or -- DECAL_ID
		asset:match("^rbxassetid://(%d+)$") or -- rbxassetid://DECAL_ID
		asset:match("^http://www%.roblox%.com/asset/%?id=(%d+)$") or -- http://www.roblox.com/asset/?id=DECAL_ID
		asset:match("^https://www%.roblox%.com/library/(%d+)") or -- https://www.roblox.com/library/DECAL_ID
		asset:match("^https://create%.roblox%.com/marketplace/asset/(%d+)") -- https://create.roblox.com/marketplace/asset/DECAL_ID

	if id then
		return tonumber(id)
	end;

	return nil;
end

function Util.GetAnimationId(AnimationId: string): number?
	return tonumber(string.match(AnimationId, "(%d+)$"));
end

function Util.WaitForAnimation(Animator: Animator, Id: any, Timeout: number?): AnimationTrack?
	if typeof(Id) == "string" then
		Id = Util.GetAnimationId(Id) :: any;
	end;

	local Animation = Util.GetAnimationFromId(Animator, Id);

	if not Animation then
		local Running, Alive = coroutine.running(), true;
		local TimeoutThread: thread?, Connection: RBXScriptConnection?;

		local function WorkDone()
			if Connection and Connection.Connected then
				Connection:Disconnect();
			end;

			if TimeoutThread and coroutine.status(TimeoutThread) == "suspended" then
				task.cancel(TimeoutThread);
				TimeoutThread = nil;
			end
		end

		local function Resume(Track: AnimationTrack?): ()
			WorkDone();

			if Alive then
				Alive = not Alive;
				coroutine.resume(Running, Track);
			end;
		end
		
		Connection = Animator.AnimationPlayed:Connect(function(Track)
			if Track.Animation and Util.GetAnimationId(Track.Animation.AnimationId) == Id then
				Resume(Track)
			end
		end)

		TimeoutThread = task.delay(Timeout or 15, Resume);
		Animation = coroutine.yield();
		WorkDone();
	end;

	return Animation;
end;

function Util.EventFrequency(Event: RBXScriptSignal, Frequency: number, Callback): RBXScriptConnection
	local Elapsed = 0;
	
	return Event:Connect(function(dt)
		Elapsed += dt;
		
		if Elapsed > Frequency then
			Elapsed -= Frequency;
			Callback(dt);
		end;
	end);
end;

function Util.WaitForAnimationLoaded(AnimationTrack: AnimationTrack, Timeout: number?): ()
	local Elapsed = 0;
	local Timeout = Timeout or 5;
	
	repeat 
		Elapsed += task.wait() ;
		
	until AnimationTrack.Length ~= 0 and Elapsed < Timeout;
end

function Util.GetAnimationFromId(Animator: Animator, Id: number): AnimationTrack?
	for _, Track: AnimationTrack in Animator:GetPlayingAnimationTracks() do
		if Track.Animation and Track.IsPlaying and Util.GetAnimationId(Track.Animation.AnimationId) == Id then
			return Track;
		end
	end

	return nil;
end

function Util.StopEffects(Object: Instance): ()
	for _, Particle in Object:GetDescendants() do
		if Particle:IsA("ParticleEmitter") or Particle:IsA("Beam") or Particle:IsA("Light") then
			Particle.Enabled = false;

		elseif Particle:IsA("Sound") then
			Particle:Stop();
		end;
	end;
end;

function Util.Unit(Vector: Vector3, Default: Vector3): Vector3
	return if Vector.Magnitude < 1e-7 then (Default or Vector3.zero) else Vector.Unit;
end

function Util.CreateAttachment(Coordinate: CFrame, Parent: Instance?): Attachment
	local Attachment = Instance.new("Attachment");
	Attachment.CFrame = Coordinate;
	Attachment.Parent = Parent;

	return Attachment;
end

function Util.CreatePsuedoAttachment(Attachment: Attachment): Attachment
	local CloneAttachment = Instance.new("Attachment");
	CloneAttachment.WorldCFrame = Attachment.WorldCFrame;
	CloneAttachment.Parent = workspace.Terrain;

	local Connection = RunService.PreRender:Connect(function(Delta)
		CloneAttachment.WorldCFrame = Attachment.WorldCFrame;
	end)

	CloneAttachment.Destroying:Once(function()
		Connection:Disconnect();
	end)

	return CloneAttachment;
end

function Util.CastOnGround(Position: Vector3, Distance: number): CFrame
	local Result = workspace:Raycast(Position, -Vector3.yAxis * Distance, Utility.VisualParams);

	if Result then
		return CFrame.lookAlong(Result.Position, Result.Normal) + Result.Normal * 0.1, Result;
	else
		return CFrame.lookAlong(Position, Vector3.yAxis), Result;
	end
end

function Util.GetModelParts(Object: Model)
	local Parts = {};
	for _, Part in Object:GetDescendants() do
		if (Part:IsA("BasePart")) then
			table.insert(Parts, Part);
		end;
	end;
	return Parts;
end

function Util.GetModelPartDecals(Object: Model)
	local Parts = {};
	for _, Part in Object:GetDescendants() do
		if Part.Name ~= "HumanoidRootPart" and (Part:IsA("BasePart") or Part:IsA("Decal")) then
			table.insert(Parts, Part);
		end;
	end;
	return Parts;
end

function Util.RemoveAllTagsOnInstance(Item : Instance)
	for _, Tag in Item:GetTags() do
		Item:RemoveTag(Tag);
	end;
end

function Util.CloneCharacter(Model : Model)
	Model.Archivable = true;

	local NewModel = Model:Clone();

	NewModel.Archivable = false;
	Model.Archivable = false;

	Util.CleanAfterimage(NewModel, 0);

	return NewModel
end

function Util.CleanAfterimage(Afterimage, Transparency : number?): ({BasePart}, {BasePart | Decal})
	local Parts = Util.GetModelParts(Afterimage);
	local DecalParts = Util.GetModelPartDecals(Afterimage);

	if (Transparency ~= nil) then
		for _, Part in DecalParts do
			if Part:GetAttribute("Transparent") then
				continue;
			end;
			
			Part.Transparency = Transparency;
		end;
	end;

	for _, Part in Afterimage:GetChildren() do
		if not (Part:IsA("Shirt") or Part:IsA("Pants") or Part:IsA("BodyColors") or Part:IsA("Part") or Part:IsA("Humanoid") or Part:IsA("Accessory")) then
			Part:Destroy();
		end
	end

	for _, Item in Afterimage:GetDescendants() do
		if Item:IsA("Constraint") or Item:IsA("BodyMover") or Item:IsA("ParticleEmitter") or Item:IsA("Sound") or Item:IsA("BillboardGui") or Item:IsA("BallSocketConstraint") or Item:IsA("LuaSourceContainer") then
			Item:Destroy();
		end;
	end;

	Afterimage.Humanoid.RootPart.AssemblyLinearVelocity = Vector3.zero;
	Afterimage.Humanoid.RootPart.AssemblyAngularVelocity = Vector3.zero;
	
	Afterimage.Humanoid.EvaluateStateMachine = false;
	Afterimage.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None;
	Afterimage.Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff;

	Util.RemoveAllTagsOnInstance(Afterimage.Humanoid);
	
	local function SetCanCollide()
		for _, Part in Parts do
			Part.AssemblyLinearVelocity = Vector3.zero;
			Part.AssemblyAngularVelocity = Vector3.zero;
			
			Util.RemoveAllTagsOnInstance(Part);
			
			Part.CollisionGroup = "NoCollision";
			Part.CanCollide = false;
			Part.CanQuery = false;
			Part.CanTouch = false;
		end
	end;

	SetCanCollide();
	Afterimage.AncestryChanged:Connect(SetCanCollide);

	return Parts, DecalParts;
end

local function Enlarge(Keypoint : (NumberSequenceKeypoint), ScaleFactor: number)
	return Keypoint.Time, Keypoint.Value * ScaleFactor, Keypoint.Envelope * ScaleFactor;
end

function Util.ScaleNumberSequence(Sequence: NumberSequence, ScaleFactor: number): NumberSequence
	return Util.TransformNumberSequence(Sequence, Enlarge, ScaleFactor);
end

function Util.TransformNumberSequence(Sequence: NumberSequence, Function, ...: any): NumberSequence
	local SequenceArray = {}

	for _, Keypoint in ipairs(Sequence.Keypoints) do
		table.insert(SequenceArray, NumberSequenceKeypoint.new(Function(Keypoint, ...)));
	end;

	return NumberSequence.new(SequenceArray);
end

return Util;