local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local RockHandler = {}

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local EventService = require( ReplicatedStorage.Modules.Shared.Utilities.EventService )

local Rnd = Random.new();
local Assets = script.Assets;
local Presets = require(script.Presets)

local IgnorePartNames = {
	Barrier = true;
}

local DefaultCraterInfo = {
	Amount = 6, -- Amount of rocks

	Timing = {
		In = { -- Time it takes for the rocks to fade in
			Min = 0.1,
			Max = 0.2
		},

		Idle = { -- Time where the rocks stay idle
			Min = 4.7,
			Max = 5.1
		},

		Out = { -- Time it takes for the rocks to fade out
			Min = 1.6,
			Max = 2.2
		},
	},

	Distance = 3,

	Exposure = {
		Min = 0.6,
		Max = 0.8
	},

	Angle = { -- Adds randomness so the rocks dont form a perfect circle
		Min = -30,
		Max = 30
	},

	LookAt = { -- Where the rocks face towards (y axis)
		Min = -3,
		Max = 3
	},
	
	Burn = {
		Enabled = false,
	},

	BaseX = 3,
	BaseY = 1.5,
	BaseZ = 2.1,

	SizeMultiplier = 1,
	
	CastShadow = true,
	CraterSmoke = true,
	CanCollide = true,

	Rotation = { -- Rotation of the rocks
		Min = {X = math.rad(-12), Y = math.rad(-12), Z = math.rad(-12)},
		Max = {X = math.rad(12), Y = math.rad(12), Z = math.rad(12)}
	},
}

DefaultCraterInfo.__index = DefaultCraterInfo

export type CraterInfo = any --typeof(DefaultCraterInfo);
type Adornee = BasePart | CFrame | Vector3

function RockHandler.GetAdorneeCFrame(Adornee : Adornee): CFrame
	if typeof(Adornee) == "CFrame" then
		return Adornee;

	elseif typeof(Adornee) == "Instance" then
		return Adornee.CFrame;
		
	elseif typeof(Adornee) == "Vector3" then
		return CFrame.new(Adornee)
	end;
	
	error("Could not get CFrame from Adornee");
end

function RockHandler.SlightlyBrightenColor(Color : Color3)
	--return Color3.new(
	--	math.clamp(Color.R * 1.1, 0, 1),
	--	math.clamp(Color.G * 1.1, 0, 1),
	--	math.clamp(Color.B * 1.1, 0, 1)
	--)
	
	return Color
end

function RockHandler.GenerateRandomOrientation(ReturnAngles: boolean?): (CFrame | Vector3)
	local Orientation = Rnd:NextUnitVector() * 360;

	if ReturnAngles then
		return CFrame.Angles(Orientation.X, Orientation.Y, Orientation.Z)
	end

	return Orientation
end

function RockHandler.MatchWithRay(Rock: typeof(Assets.Debree), Result: RaycastResult)
	local ResultInstance : BasePart = Result.Instance
	
	if not ResultInstance:GetAttribute("RockIgnoreTransparency") then
		Rock.Transparency = ResultInstance.Transparency
	end
	
	Rock.Reflectance = ResultInstance.Reflectance
	Rock.Color = RockHandler.SlightlyBrightenColor(ResultInstance.Color)
	Rock.Material = ResultInstance.Material
	Rock.MaterialVariant = ResultInstance.MaterialVariant
end

function RockHandler.Rocks(PresetName : string, Adornee: Adornee) -- made by swrerm
	local Preset = Presets[PresetName]
	if not Preset then return end
	
	local Coordinate = RockHandler.GetAdorneeCFrame(Adornee);
	
	for Index = -1, 1, 2 do
		local Origin

		if Preset.Messy then
			Origin = Coordinate * CFrame.new(
				Rnd:NextNumber(-Preset.Spacing, Preset.Spacing), 0, 
				Rnd:NextNumber(-Preset.Spacing, Preset.Spacing)
			)
		else
			Origin = Coordinate * CFrame.new(Preset.Spacing * Index, 0, 0)
		end

		local Raycast = workspace:Raycast(Origin.Position + Vector3.yAxis * 2, -Vector3.yAxis * (Preset.RaycastDistance + 2), Utility.VisualParams)

		if Raycast then
			local Rock = Assets.Debree:Clone()
			Rock.CanCollide = false
			RockHandler.MatchWithRay(Rock, Raycast);

			if Preset.Size then
				Rock.Size = Vector3.one * Preset.Size
			end
			
			local NewPosition = Raycast.Position
			local InGround = NewPosition - Vector3.yAxis * Rock.Size.Y

			Rock.Position = InGround
			Rock.Orientation = RockHandler.GenerateRandomOrientation()
			Rock.Parent = workspace.Visuals
			
			local FadeInInfo = TweenInfo.new(Preset.FadeInTime or Rnd:NextNumber(0.25, 0.4));
			
			local FadeInTween = TweenService:Create(Rock, FadeInInfo, {
				Position = NewPosition
			})
			FadeInTween:Play()
			
			task.delay(3 + Rnd:NextNumber(-0.5, 0.5), function()
				local FadeOutInfo = TweenInfo.new(Rnd:NextNumber(1, 2));
				
				local FadeOutTween = TweenService:Create(Rock, FadeOutInfo, {
					Position = InGround
				})
				FadeOutTween:Play()
				FadeOutTween.Completed:Wait();
				
				Rock:Destroy();
			end)
		end
	end
end

function RockHandler.RocksWithoutPreset(Data : {}, Adornee: Adornee) -- made by swrerm
	local Coordinate = RockHandler.GetAdorneeCFrame(Adornee);

	for Index = -1, 1, 2 do
		local Origin

		if Data.Messy then
			Origin = Coordinate * CFrame.new(
				Rnd:NextNumber(-Data.Spacing, Data.Spacing), 0, 
				Rnd:NextNumber(-Data.Spacing, Data.Spacing)
			)
		else
			Origin = Coordinate * CFrame.new(Data.Spacing * Index, 0, 0)
		end

		local Raycast = workspace:Raycast(Origin.Position + Vector3.yAxis * 2, -Vector3.yAxis * (Data.RaycastDistance + 2), Utility.VisualParams)

		if Raycast then
			local Rock = Assets.Debree:Clone()
			Rock.CanCollide = false
			RockHandler.MatchWithRay(Rock, Raycast);

			if Data.Size then
				Rock.Size = Vector3.one * Data.Size
			end

			local NewPosition = Raycast.Position
			local InGround = NewPosition - Vector3.yAxis * Rock.Size.Y

			Rock.Position = InGround
			Rock.Orientation = RockHandler.GenerateRandomOrientation()
			Rock.Parent = workspace.Visuals

			local FadeInInfo = TweenInfo.new(Data.FadeInTime or Rnd:NextNumber(0.25, 0.4));

			local FadeInTween = TweenService:Create(Rock, FadeInInfo, {
				Position = NewPosition
			})
			FadeInTween:Play()

			task.delay(3 + Rnd:NextNumber(-0.5, 0.5), function()
				local FadeOutInfo = TweenInfo.new(Rnd:NextNumber(1, 2));

				local FadeOutTween = TweenService:Create(Rock, FadeOutInfo, {
					Position = InGround
				})
				FadeOutTween:Play()
				FadeOutTween.Completed:Wait();

				Rock:Destroy();
			end)
		end
	end
end

function RockHandler.Rockst(Position : Vector3, Direction : Vector3, Params) -- made by ery
	local Raycast = workspace:Raycast(Position - (Direction / 2), Direction, Utility.VisualParams) 

	if (Raycast ~= nil) then
		local RockCount : number = Params.Count or 5

		local XZVelocity = Params.XZVelocity or NumberRange.new(0.75, 1)
		local YVelocity = Params.YVelocity or NumberRange.new(0.75, 1.25)

		for Index = 1, RockCount do
			local Rock = Assets.FlyingDebree:Clone()
			RockHandler.MatchWithRay(Rock, Raycast);
			
			Rock.Size = Vector3.one * Rnd:NextNumber(table.unpack(Params.Size)) 
			Rock.CFrame = CFrame.lookAt(Raycast.Position, Raycast.Position - Raycast.Normal) + Vector3.yAxis * 1.5 + Vector3.new(Rnd:NextNumber(-1, 1), 0, Rnd:NextNumber(-1, 1)) * (Params.SpawnVariance or 5)
			
			Params.Velocity = Params.Velocity * Rnd:NextNumber(0.75, 1)
			
			local Mass = math.max(1, Rock:GetMass());
			--local Mass = Rock:GetMass();
			local VelocityDirection = (Rnd:NextUnitVector() + Vector3.yAxis).Unit
			
			Rock.AssemblyLinearVelocity = (Mass * Vector3.new(
				VelocityDirection.X * Rnd:NextNumber(XZVelocity.Min, XZVelocity.Max) * Params.Velocity,
				VelocityDirection.Y * Rnd:NextNumber(YVelocity.Min, YVelocity.Max) * Params.Velocity,
				VelocityDirection.Z * Rnd:NextNumber(XZVelocity.Min, XZVelocity.Max) * Params.Velocity
			))
			
			Rock.AssemblyAngularVelocity = (Mass * Vector3.new(
				Rnd:NextNumber(-5, 5), 
				Rnd:NextNumber(-5, 5), 
				Rnd:NextNumber(-5, 5)
			))
			
			Rock.Parent = workspace.Visuals
			
			task.delay( (Params.Lifetime or 3) + Rnd:NextNumber(-0.5, 0.5), function()
				local FadeOutInfo = TweenInfo.new(Rnd:NextNumber(1, 2))
				
				local FadeOutTween = TweenService:Create(Rock, FadeOutInfo, {
					Size = Vector3.zero
				})
				FadeOutTween:Play()
				FadeOutTween.Completed:Wait();
				
				Rock:Destroy();
			end)
		end
	end
end

local function RandomSettingToAngles(Setting: {Min : Vector3, Max : Vector3})
	return CFrame.Angles(
		Rnd:NextNumber(Setting.Min.X, Setting.Max.X),
		Rnd:NextNumber(Setting.Min.Y, Setting.Max.Y),
		Rnd:NextNumber(Setting.Min.Z, Setting.Max.Z)
	)
end

local function RandomSetting(Setting : {Min : number, Max : number}) : number
	return if typeof(Setting) == "table" then Rnd:NextNumber(Setting.Min, Setting.Max) else Setting
end

local function NormalisedDirection(Direction: Vector3): Vector3
	return if Direction.Magnitude < 1e-7 then Vector3.zero else Direction.Unit;
end

local function GetDistanceMax(Distance: any): number
	return if typeof(Distance) == "table" then Distance.Max else Distance;
end

local function GetNumberSetting(Setting: any): number
	return if typeof(Setting) == "table" then RandomSetting(Setting) else Setting;
end

local function CanSpawnCraterOn(Result: RaycastResult?): boolean
	local IsADestructible = false
	
	if Result then
		IsADestructible = (Result.Instance:HasTag("DestructibleDescendant") or Result.Instance:HasTag("Destructible"))
	end

	return (Result ~= nil and Result.Instance.CanCollide and not IsADestructible and not IgnorePartNames[Result.Instance.Name])
end

function RockHandler.Crater(Position : Vector3, Direction: Vector3, Info: CraterInfo?) -- made by bugo and swrerm
	local Info = setmetatable(Info or {}, DefaultCraterInfo)
	local InitialCast = workspace:Raycast(Position - (Direction / 2), Direction, Utility.VisualParams)
	
	if not CanSpawnCraterOn(InitialCast) then return end
	
	local UnitDirection = NormalisedDirection(Direction);
	local Velocity = UnitDirection * (GetDistanceMax(Info.Distance) + Direction.Magnitude - InitialCast.Distance)

	local RockParent = workspace.Visuals
	local OnAllRockGone = EventService.new()
	
	if Info.Burn and Info.Burn.Enabled then
		local CraterHolder = Instance.new("Model")
		CraterHolder.Name = "CraterHolder"
		CraterHolder.Parent = workspace.Visuals
		
		local Highlight = Instance.new("Highlight")
		Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		Highlight.FillColor = Info.Burn.Color
		Highlight.FillTransparency = Info.Burn.Transparency
		Highlight.OutlineTransparency = 1
		Highlight.Parent = CraterHolder
		
		TweenService:Create(Highlight, TweenInfo.new(RandomSetting(Info.Burn.Time)), {FillTransparency = 1}):Play()

		OnAllRockGone:Connect(function()
			OnAllRockGone:Destroy()
			CraterHolder:Destroy()
		end)

		RockParent = CraterHolder
	end
	
	for CurrentAmount = 1, Info.Amount do
		local Distance : Vector3 = InitialCast.Normal * GetNumberSetting(Info.Distance);
		local StartPosition: Vector3 = InitialCast.Position + Distance

		local EndCoordinate =
			CFrame.lookAt(StartPosition, StartPosition - Distance) * 
			CFrame.Angles(math.rad(90), math.rad(CurrentAmount * (360 / Info.Amount) + RandomSetting(Info.Angle)), 0) * 
			CFrame.new(0, (-Distance.Magnitude - Direction.Magnitude), (Distance.Magnitude + Direction.Magnitude))

		local Raycast = workspace:Raycast(StartPosition, (EndCoordinate.Position - StartPosition), Utility.VisualParams)

		if CanSpawnCraterOn(Raycast) then
			local BaseSize : Vector3 = Vector3.new(Info.BaseX, Info.BaseY, Info.BaseZ) * Info.SizeMultiplier
			local Rotation = RandomSettingToAngles(Info.Rotation)

			local At = Raycast.Position - Raycast.Normal * GetNumberSetting(Info.Exposure)
			local LookAt = InitialCast.Position - Raycast.Normal * RandomSetting(Info.LookAt)

			local OutGroundCFrame = CFrame.lookAt(At, LookAt, Raycast.Normal)
			local InGroundCFrame = OutGroundCFrame - Raycast.Normal * BaseSize

			local DoOutGroundTween = (Info.Timing.In ~= 0)
			
			local Rock = Assets.Debree:Clone()
			RockHandler.MatchWithRay(Rock, Raycast)
			
			Rock.CFrame = DoOutGroundTween and InGroundCFrame or OutGroundCFrame
			Rock.Size = BaseSize
			Rock.CanCollide = Info.CanCollide
			Rock.CastShadow = Info.CastShadow
			
			if Info.CraterSmoke then
				local SmokeSize = (BaseSize.X + BaseSize.Y + BaseSize.Z)

				local Smoke = Assets.Smoke:Clone()
				Smoke.Size = NumberSequence.new(SmokeSize)
				Smoke.Speed = NumberRange.new((SmokeSize * 10))
				Smoke.Color = ColorSequence.new(Rock.Color);

				Smoke.Parent = Rock

				Smoke:Emit(math.clamp(math.round(SmokeSize) - 1, 1, 10))
			end
			
			task.delay(RandomSetting(Info.Timing.Idle), function()
				local FadeOutTween = TweenService:Create(Rock, TweenInfo.new(RandomSetting(Info.Timing.Out)), 
					{CFrame = InGroundCFrame, Size = Vector3.zero}
				)

				FadeOutTween:Play()

				FadeOutTween.Completed:Once(function()
					Rock:Destroy();
					
					if (CurrentAmount == Info.Amount) then
						OnAllRockGone:Fire()
					end
				end)
			end)
			
			Rock.Parent = RockParent
	
			if DoOutGroundTween then
				TweenService:Create(Rock, TweenInfo.new(RandomSetting(Info.Timing.In)), 
					{CFrame = OutGroundCFrame}
				):Play()
			end
		end
	end
end

local RockLineParams = {
	Amount = 15,
	Spacing = 1.5,
	Angle = math.rad(110),
	Size = 1,
	SizeIndex = 0.2,
	RandomJitter = 1.25,
	ExposeLevel = -0.5,
};
RockLineParams.__index = RockLineParams;

local function CreateRockLine(Params, Coordinate: CFrame, Index: number, AmountIndex: number)
	local Origin = Coordinate * CFrame.Angles(0, Params.Angle * Index / 2, 0) * CFrame.new(Rnd:NextNumber(-Params.RandomJitter, Params.RandomJitter), 0, -Params.Spacing * AmountIndex)
	local Raycast = workspace:Raycast(Origin.Position + (Vector3.yAxis * 2), Vector3.yAxis * -25, Utility.VisualParams)

	if Raycast then
		local Rock = Assets.RockLine:Clone();
		RockHandler.MatchWithRay(Rock, Raycast);
		Rock.Position = Raycast.Position - (Vector3.yAxis * -Params.ExposeLevel)
		Rock.Orientation = RockHandler.GenerateRandomOrientation()
		
		local FinalSize = Vector3.one * (Params.Size + (AmountIndex * Params.SizeIndex))

		if Params.NoTween then
			Rock.Size = FinalSize
		else
			local FadeInTween = TweenService:Create(Rock, TweenInfo.new(0.3), {Size = FinalSize})
			FadeInTween:Play();
		end

		if not Params.NoSmoke then
			local Smoke = Assets.Smoke:Clone()
			Smoke.Color = ColorSequence.new(Rock.Color)
			Smoke.Parent = Rock
			Smoke:Emit((FinalSize.X * FinalSize.Y * FinalSize.Z) / 4)
		end
		
		Rock.Parent = workspace.Visuals;
		
		task.delay(2, function()
			local FadeOutTween = TweenService:Create(Rock, TweenInfo.new(3), {Size = Vector3.zero})
			FadeOutTween:Play();
			FadeOutTween.Completed:Wait();

			Rock:Destroy();
		end)
	end
end

function RockHandler.RockLines(Coordinate: CFrame, Params) -- made by swrerm this isnt my proudest work
	setmetatable(Params, RockLineParams);
	
	for AmountIndex = 1, Params.Amount do
		for Index = -1, 1, 2 do
			CreateRockLine(Params, Coordinate, Index, AmountIndex);
		end

		if Params.TimeTilNextRock then
			task.wait((Params.TimeTilNextRock))
		end
	end
end

local RegularRockLineParams = {
	Amount = 15,
	Spacing = 3,
	Angle = math.rad(110),
	Size = 1,
	SizeIndex = 0.2,
	RandomJitter = 1.25,
	ExposeLevel = -0.5,
	SideSpacing = 8
};
RegularRockLineParams.__index = RegularRockLineParams;

function RockHandler.RegularRockLines(Coordinate: CFrame, Params) 
	setmetatable(Params, RegularRockLineParams);
	
	for AmountIndex = 1, Params.Amount do
		for Index = -1, 1, 2 do
			local Origin = Coordinate * CFrame.Angles(0, Params.Angle * Index / 2, 0) * CFrame.new((Params.SideSpacing * Index) + Rnd:NextNumber(-Params.RandomJitter, Params.RandomJitter), 0, -Params.Spacing * AmountIndex)
			local Raycast = workspace:Raycast(Origin.Position + (Vector3.yAxis * 2), Vector3.yAxis * -25, Utility.VisualParams)
			
			if Raycast then
				local Rock = Assets.RockLine:Clone();
				RockHandler.MatchWithRay(Rock, Raycast);
				Rock.Position = Raycast.Position - (Vector3.yAxis * -Params.ExposeLevel)
				Rock.Orientation = RockHandler.GenerateRandomOrientation()
				
				local FinalSize = Vector3.one * (Params.Size + (AmountIndex * Params.SizeIndex))
				
				if Params.NoTween then
					Rock.Size = FinalSize
				else
					local FadeInTween = TweenService:Create(Rock, TweenInfo.new(0.3), {Size = FinalSize})
					FadeInTween:Play();
				end
				
				if not Params.NoSmoke then
					local Smoke = Assets.Smoke:Clone()
					Smoke.Color = ColorSequence.new(Rock.Color)
					Smoke.Parent = Rock
					Smoke:Emit((FinalSize.X * FinalSize.Y * FinalSize.Z) / 4)
				end
				
				Rock.Parent = workspace.Visuals;
				
				task.delay(2, function()
					local FadeOutTween = TweenService:Create(Rock, TweenInfo.new(3), {Size = Vector3.zero})
					FadeOutTween:Play();
					FadeOutTween.Completed:Wait();
					
					Rock:Destroy();
				end)
			end
		end

		if Params.TimeTilNextRock then
			task.wait((Params.TimeTilNextRock))
		end
	end
end

local function FetchGround(Pos: Vector3, NegY: number?)
	local GroundRay = workspace:Raycast(Pos, Vector3.yAxis * -(NegY or 8), Utility.VisualParams);
	if not GroundRay then return end;

	return {
		Position = GroundRay.Position;
		Normal = GroundRay.Normal;
		Color = GroundRay.Instance.Color;
		Material = GroundRay.Instance.Material;
		Raw = GroundRay;
	};
end;

function RockHandler.OldJSDRocks(Origin: CFrame | Vector3, Params) -- jimpee keeps complaining so im just using these
	Params = Params or {};

	local OriginPos = (typeof(Origin) == 'CFrame' and Origin.Position) or Origin;
	local Ground = FetchGround(OriginPos+Vector3.yAxis*2, 10);
	if not Ground then return end;

	local OriginCFr = (typeof(Origin) == 'CFrame' and (Origin - Origin.Position) + Ground.Position) or CFrame.new(Ground.Position, Ground.Position+Ground.Normal) * CFrame.Angles(math.rad(-90),0,0);

	local RockCount = Params.Rocks or 4; -- How many pieces of rocks are in the crater
	local Distance = Params.Distance or 3; -- Distance from center
	local SizeMagnitude = Params.SizeMagnitude or 1 -- Accepts Vector3 and number;
	local BaseDuration = Params.BaseDuration or 2; -- Base duration for each crater piece
	local ExposeLevel = Params.ExposeLevel or 0; -- Exposure level of the rocks to the surface
	local OpenSpace = Params.OpenSpaces or 0; -- Amount of open spaces in the crater, gaps will always appear in the same spot
	local Layers = Params.Layers or 1;

	local IsMagnitude = (typeof(SizeMagnitude) == 'number');

	local SizeMultipliers = {};
	if IsMagnitude then
		SizeMultipliers.X=SizeMagnitude;
		SizeMultipliers.Y=SizeMagnitude;
		SizeMultipliers.Z=SizeMagnitude;
	else
		SizeMultipliers.X=SizeMagnitude.X;
		SizeMultipliers.Y=SizeMagnitude.Y;
		SizeMultipliers.Z=SizeMagnitude.Z;
	end;

	--Variation range in crater piece distance
	local MinVariation = Params.VariationMin or 0.95;
	local MaxVariation = Params.VariationMax or 1.05;

	--Variation range in crater piece size
	local MinSizeVariation = Params.SizeVariationMin or 0.95;
	local MaxSizeVariation = Params.SizeVariationMax or 1.05;

	--Variation in angle
	local MinAngleVariation = Params.MinAngleVariation or -30;
	local MaxAngleVariation = Params.MaxAngleVariation or 30;

	--Axis bases
	local BaseX = Params.BaseX or 3;
	local BaseY = Params.BaseY or 1.5;
	local BaseZ = Params.BaseZ or 2.1;

	local BaseSize = Vector3.new(BaseX, BaseY, BaseZ);
	BaseSize *= Vector3.new(SizeMultipliers.X,SizeMultipliers.Y,SizeMultipliers.Z);

	--Fetch randomly generated variation in size
	local function FetchVariatedSize()
		return BaseSize*(Utility.Seed:NextNumber(MinSizeVariation, MaxSizeVariation));
	end;

	--Fetch randomly generated variation in distance
	local function GetDistanceVariation()
		return (Distance*(Utility.Seed:NextNumber(MinVariation, MaxVariation)));
	end;

	local RockSpace = (RockCount+OpenSpace);

	--Create crater piece
	local function CreatePiece(i: number)
		local Angle = (i*(math.pi * 2/RockSpace))+math.rad(Utility.Seed:NextNumber(-30,30));
		local X,Z = math.sin(Angle), math.cos(Angle);

		X*=GetDistanceVariation();
		Z*=GetDistanceVariation();

		local OffsetPos = OriginCFr.Position + Vector3.new(X,0,Z);
		local GroundRay = workspace:Raycast(OffsetPos+Vector3.yAxis*2, Vector3.yAxis*-7, Utility.VisualParams);

		if not GroundRay then return end;
		if GroundRay.Normal:Dot(Vector3.yAxis) < 1 then return end;

		for i = 1,Layers do
			task.spawn(function()
				local ScaleFactor = (i == 1 and 1) or 1+(i*.05);

				local NewPiece = script.Assets.Debree:Clone();
				NewPiece.Anchored, NewPiece.CanCollide = true, (Params.CanCollide == nil and true) or Params.CanCollide;
				NewPiece.Color, NewPiece.Material = GroundRay.Instance.Color, GroundRay.Instance.Material;
				NewPiece.Size = FetchVariatedSize()*ScaleFactor;

				local VarAngle = math.rad(Utility.Seed:NextNumber(40,45)*ScaleFactor);
				if Params.Inverted then
					VarAngle = -VarAngle;
				end;

				local BaseCFr = CFrame.new(OffsetPos, OriginCFr.Position) * CFrame.new(0,0,(i == 1 and 0) or ScaleFactor*Utility.Seed:NextNumber(1.2,1.7)) * CFrame.Angles(VarAngle,0,0);
				local EndCFr = BaseCFr * CFrame.new(0,NewPiece.Size.Y*.05+ExposeLevel,0);

				NewPiece.CFrame = EndCFr;
				NewPiece.Position -= Vector3.yAxis*4;

				NewPiece.Parent = workspace.Visuals;

				TweenService:Create(NewPiece, TweenInfo.new(Utility.Seed:NextNumber(.1,.15), Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = EndCFr}):Play();
				task.wait(BaseDuration*Utility.Seed:NextNumber(.9,1.1));
				TweenService:Create(NewPiece, TweenInfo.new(Utility.Seed:NextNumber(1.1,1.5), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = NewPiece.Position-Vector3.yAxis*NewPiece.Size.Y}):Play();
				task.delay(2, NewPiece.Destroy, NewPiece)
			end);
		end;
	end;

	--Create X crater pieces
	for i = 1,RockCount do
		task.spawn(CreatePiece, i);
	end;
end

return RockHandler