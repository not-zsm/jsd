--!native

local replicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Job = require( replicatedStorage.modules.shared.Utilities.Job )

local Utility = {}

Utility.Faces = {
	[Enum.NormalId.Front] = -Vector3.zAxis,
	[Enum.NormalId.Back] = Vector3.zAxis,
	[Enum.NormalId.Top] = Vector3.yAxis,
	[Enum.NormalId.Bottom] = -Vector3.yAxis,
	[Enum.NormalId.Left] = -Vector3.xAxis,
	[Enum.NormalId.Right] = Vector3.xAxis,
}

Utility.ControllerToKeyboardInputs = {
	[Enum.KeyCode.ButtonA] = Enum.KeyCode.Space,
	[Enum.KeyCode.ButtonY] = Enum.KeyCode.Q,
	[Enum.KeyCode.ButtonB] = Enum.UserInputType.MouseButton1,
	[Enum.KeyCode.ButtonX] = Enum.KeyCode.F,
	[Enum.KeyCode.ButtonL1] = Enum.KeyCode.One,
	[Enum.KeyCode.ButtonL2] = Enum.KeyCode.Two,
	[Enum.KeyCode.ButtonR1] = Enum.KeyCode.Three,
	[Enum.KeyCode.ButtonR2] = Enum.KeyCode.Four,
	[Enum.KeyCode.DPadUp] = Enum.KeyCode.Five,
	[Enum.KeyCode.DPadUp] = Enum.KeyCode.G,
	[Enum.KeyCode.DPadLeft] = Enum.KeyCode.R,
	[Enum.KeyCode.DPadRight] = Enum.KeyCode.T,
}

Utility.KeyboardToControllerInputs = {
	[Enum.KeyCode.Space] = Enum.KeyCode.ButtonA,
	[Enum.KeyCode.Q] = Enum.KeyCode.ButtonY,
	[Enum.UserInputType.MouseButton1] = Enum.KeyCode.ButtonB,
	[Enum.KeyCode.F] = Enum.KeyCode.ButtonX,
	[Enum.KeyCode.One] = Enum.KeyCode.ButtonL1,
	[Enum.KeyCode.Two] = Enum.KeyCode.ButtonL2,
	[Enum.KeyCode.Three] = Enum.KeyCode.ButtonR1,
	[Enum.KeyCode.Four] = Enum.KeyCode.ButtonR2,
	[Enum.KeyCode.Five] = Enum.KeyCode.DPadUp,
	[Enum.KeyCode.G] = Enum.KeyCode.DPadUp,
	[Enum.KeyCode.R] = Enum.KeyCode.DPadLeft,
	[Enum.KeyCode.T] = Enum.KeyCode.DPadRight,
}

Utility.Seed = Random.new()
Utility.FullCircle = (math.pi * 2)

Utility.ShiftlockRenderPriority = Enum.RenderPriority.Camera.Value + 1
Utility.CharacterRenderPriority = Enum.RenderPriority.Camera.Value + 2

Utility.GroundParams = RaycastParams.new()
Utility.GroundParams.FilterType = Enum.RaycastFilterType.Include

Utility.VisualParams = RaycastParams.new()
Utility.VisualParams.FilterType = Enum.RaycastFilterType.Include

Utility.VisualAndHitboxParams = RaycastParams.new()
Utility.VisualAndHitboxParams.FilterType = Enum.RaycastFilterType.Include

Utility.VisualOverlapParams = OverlapParams.new()
Utility.VisualOverlapParams.FilterType = Enum.RaycastFilterType.Include

Utility.DestructiblesParams = OverlapParams.new()
Utility.DestructiblesParams.FilterType = Enum.RaycastFilterType.Include

Utility.HitboxParams = OverlapParams.new()
Utility.HitboxParams.FilterType = Enum.RaycastFilterType.Include

task.spawn(function()
	local MovementReplicatorSettings = require( replicatedStorage.modules.shared.movementReplicator.Settings )

	if MovementReplicatorSettings.use_replicator then
		Utility.HitboxParams.CollisionGroup = "ResimulatedPart"
	end
end)

local Map = workspace:FindFirstChild("Map")
local Models = workspace:FindFirstChild("chars")
local Builds = workspace:FindFirstChild("Builds")
local Havoc = workspace:FindFirstChild("Havoc")
local HavocStatic = Havoc and Havoc:FindFirstChild("Static")

if Models then
	Utility.HitboxParams.FilterDescendantsInstances = {Models}
end

if Map then
	Utility.VisualOverlapParams.FilterDescendantsInstances = {Map}
	Utility.VisualParams.FilterDescendantsInstances = {Map}
	
	local MapModel = Map:FindFirstChild("Model")
	local Props = MapModel and MapModel:FindFirstChild("Props")

	if Props and Props:FindFirstChild('Trees') then --TODO: figure out what this is genuinely meant to do, and remove it as trees dont exist rn
		task.spawn(function()
			for _, Item in ipairs(Props.Trees:GetChildren()) do
				if Item.Name == "Tree" then continue end

				Utility.GroundParams:AddToFilter(Item);
			end
		end)
		
		Utility.DestructiblesParams.FilterDescendantsInstances = {Props}
	end
end

if HavocStatic then
	Utility.VisualParams:AddToFilter(HavocStatic)
end

if Builds then
	Utility.VisualOverlapParams:AddToFilter(Builds)
	Utility.VisualAndHitboxParams:AddToFilter(Builds)
	Utility.VisualParams:AddToFilter(Builds)
end

if Models then
	Utility.VisualAndHitboxParams:AddToFilter(Models)
end

if Map then
	Utility.VisualAndHitboxParams:AddToFilter(Map)
end

Utility.DestructionRespawnTime = 20

if RunService:IsClient() then
	local UserGameSettings : UserGameSettings = UserSettings():GetService("UserGameSettings")
	local Quality = 10

	local function Upd()
		local SavedQuality = UserGameSettings.SavedQualityLevel
		Quality = SavedQuality == Enum.SavedQualitySetting.Automatic and (Quality / 2) or SavedQuality.Value
	end

	UserGameSettings:GetPropertyChangedSignal("SavedQualityLevel"):Connect(Upd)
	Upd()

	function Utility.GetQuality()
		return Quality
	end
end

function Utility.CloseThreadSafe(thread : thread)
	if (thread ~= nil and coroutine.status(thread) == "suspended") then
		task.cancel(thread)
	end
end

function Utility.biDirRandom(Value : number)
	return Value - math.random() * Value * 2
end

function Utility.QuadBezier(Time : number, Start : Vector3, Middle : Vector3, End : Vector3) : Vector3
	local T = (1 - Time)

	return (T ^ 2 * Start + 2 * T * Time * Middle + Time ^ 2 * End)
end

function Utility.WithinTime(Time : number, Value : number)
	return (Time == -1) or time() - Time < Value
end

function Utility.BeyondTime(Time : number, Value : number) : boolean
	return (Time == -1) or time() - Time > Value
end

function Utility.NumberRangeRandom(Range : NumberRange)
	return Utility.Seed:NextNumber(Range.Min, Range.Max)
end

function Utility.BetweenNumberRange(Range : NumberRange, Value : number) : boolean
	return not (Value < Range.Min or Value > Range.Max)
end

function Utility.XOR(A : boolean, B : boolean) : boolean
	return (not A and B) or (A and not B)
end

function Utility.DecimalRound(Value : number, Degree : number?) : number
	local Places = 10 ^ (Degree or 1)

	return math.round(Value * Places) / Places
end

function Utility.GetTotalWeight(WeightedObjects : {Instance}) : number
	local TotalWeight = 0

	for _, Object in ipairs(WeightedObjects) do
		TotalWeight += Object:GetAttribute("Weight")::number
	end

	return TotalWeight
end

function Utility.GetRandomByWeight(WeightedObjects : {Instance}) : (Instance?)
	local TotalWeight = Utility.GetTotalWeight(WeightedObjects)
	local Chosen = math.random(0, TotalWeight)

	for _, Object in ipairs(WeightedObjects) do
		TotalWeight -= Object:GetAttribute("Weight")

		if (TotalWeight <= Chosen) then
			return Object
		end
	end

	return nil
end

function Utility.AlphaClamp(Value : number)
	return math.clamp(Value, 0, 1)
end

function Utility.InterpolateNumberSequenceValues(Sequence : NumberSequence, Alpha: number, Goal : number)
	local NewSequence = table.create(#Sequence.Keypoints)

	for Index, Keypoint in ipairs(Sequence.Keypoints) do
		NewSequence[Index] = NumberSequenceKeypoint.new(
			Keypoint.Time,
			Keypoint.Value + (Goal - Keypoint.Value) * Alpha,
			Keypoint.Envelope
		)
	end

	return NumberSequence.new(NewSequence)
end

function Utility.VectorToRotation(Vector : Vector3) : CFrame
	return CFrame.lookAt(Vector3.zero, Vector)
end

function Utility.RaycastWithDebug(Origin : Vector3, Direction : Vector3, Params : RaycastParams) : RaycastResult
	local Raycast = workspace:Raycast(Origin, Direction, Params)

	local Cone = Instance.new("ConeHandleAdornment")
	Cone.CFrame = CFrame.lookAlong(Origin, Direction)
	Cone.Height = Direction.Magnitude
	Cone.Radius = 0.25
	Cone.Transparency = 0.5
	Cone.Color3 = Color3.new()
	Cone.Adornee = workspace.Terrain
	Cone.Parent = workspace.Terrain

	task.delay(12, Cone.Destroy, Cone)

	return Raycast
end

function Utility.CaseSplit(Text : (string), Seperator : (string), Capture : (string)) : {string?}
	local LastSplit = 0;

	local Stack = {};
	local Split = {};
	local Stacky = 1;

	for n = 1, #Text do
		local Char = string.sub(Text, n, n);

		if (Capture == Char) then
			if #Stack == 0 then
				table.insert(Stack, Char);
				Stacky = 2
			else
				table.remove(Stack, #Stack);
			end
		end

		if (#Stack == 0 and Char == Seperator) then
			table.insert(Split, string.sub(Text, LastSplit + Stacky, n - Stacky));

			Stacky = 1;
			LastSplit = n;
		end
	end

	table.insert(Split, string.sub(Text, LastSplit + Stacky, -Stacky));

	return Split;
end

function Utility.PickRandom(Table, Conditional : (any) -> ())
	local Value;
	local Moved = -1;
	local Index = math.random(1, #Table)

	while Moved <= #Table do
		Moved += 1;
		Value = Table[(Index + Moved) % #Table + 1];

		if Conditional(Value) then
			break;
		end;
	end;

	if Moved <= #Table then
		return Value;
	end

	return nil;
end

function Utility.TableCount(Table)
	local Count = 0;

	for _ in pairs(Table) do
		Count += 1;
	end;

	return Count;
end

function Utility.DeepCopy<T>(Table : T): T
	assert(typeof(Table) == "table", "t is not a table");

	local clone = {};

	for i, v: any in Table do
		if typeof(v) == "table" then
			clone[i] = Utility.DeepCopy(v);
		else
			clone[i] = v;
		end;
	end;

	return clone :: any;
end

function Utility.StopAutoRotate(Humanoid: Humanoid, Tag : string?): Configuration
	local Configuration = Instance.new("Configuration");
	Configuration.Name = "StopAutoRotate";

	if Tag then
		Configuration:AddTag(Tag)
	end

	Configuration.Parent = Humanoid;

	return Configuration;
end

function Utility.BindSignalDisconnectToInstanceDestroying(Signal : RbxScriptSignal, Ins : Instance, Callback : () -> ()) : Job.object
	local NewJob = Job.new()

	local function DeleteWhen()
		if (Ins.Parent == nil) then 
			NewJob:Destroy()
		end
	end

	task.defer(DeleteWhen)
	NewJob:Task(Ins:GetPropertyChangedSignal("Parent"):Connect(DeleteWhen))
	NewJob:Task(Signal:Connect(Callback))

	return NewJob
end

function Utility.IsNumberKey(Code : (Enum.KeyCode | Enum.UserInputType))
	return (Code.Value >= 48 and Code.Value <= 57)
end

function Utility.GetNumberKeyFromNumber(Number : number)
	local Code = Enum.KeyCode:FromValue(48 + Number)

	if (Code == nil or not Utility.IsNumberKey(Code)) then
		return nil
	end

	return Code
end

function Utility.TranslateInput(Input : InputObject)
	return (Input.UserInputType == Enum.UserInputType.Keyboard or Input.UserInputType == Enum.UserInputType.Gamepad1) and Input.KeyCode or Input.UserInputType
end

function Utility.GetNumberFromNumberKey(Key : (Enum.KeyCode | Enum.UserInputType))
	if (not Utility.IsNumberKey(Key)) then
		return nil
	end

	local Number = (Key.Value - 48)
	return Number
end

function Utility.GetTrackById(AnimationId : string, Animator : Animator)
	if (AnimationId == nil or typeof(AnimationId) ~= "string") then
		return error("you did not pass an animation id or its not a string")
	end

	local ReturnTrack

	for _, Track : AnimationTrack in ipairs(Animator:GetPlayingAnimationTracks()) do
		if Track.Animation.AnimationId == AnimationId and Track.IsPlaying then
			ReturnTrack = Track
			break
		end
	end

	return ReturnTrack
end

function Utility.ConvertStringAttributeFriendly(String : string)
	return string.gsub(String, "[%c%%%.,'!? %-]", "")
end

function Utility.SafeCall(Function : () -> ())
	local Success, Result = pcall(Function)

	if not Success then
		warn(Result)
	end

	return Result
end

function Utility.cmap(value : number, inmin : number, inmax : number, outmin : number, outmax : number)
	return math.clamp(math.map(value, inmin, inmax, outmin, outmax), outmin, outmax)
end

function Utility.IsFacingOnAWall(Part : BasePart, Params : RaycastParams?)
	local Raycast = workspace:Raycast(Part.Position, Part.CFrame.LookVector * 2.5, Params or Utility.VisualParams)
	
	return (Raycast ~= nil and Raycast.Instance.CanCollide)
end

local function FormatInt(Int : string)
	return string.format("%02i", Int)
end

function Utility.ConvertToHMS(Seconds)
	local Minutes = (Seconds - Seconds % 60) / 60
	Seconds = Seconds - Minutes * 60
	local Hours = (Minutes - Minutes % 60) / 60
	Minutes = Minutes - Hours * 60
	return FormatInt(Hours) .. ":" .. FormatInt(Minutes) .. ":" .. FormatInt(Seconds)
end

return Utility
