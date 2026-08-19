local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local BubbleHandler = require( script.BubbleHandler )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local AenoirEmit = EffectUtility.AenoirEmit

local Assets = script;
local EffectsFolder = workspace.Visuals;

local function ScreenEffect(Position : Vector3, ShakeIntensity : number, ShakeSpeed : number, ShakeFadeOut : number)
	if Players.LocalPlayer:DistanceFromCharacter(Position) <= 30 then
		CameraShake(ShakeIntensity or 4.5, ShakeSpeed or 22, 0.01, ShakeFadeOut or 0.65, Vector3.one * 0.8, Vector3.one * 0.15)
		Vignette(Color3.fromRGB(255, 255, 255), 0.75, 0.15)
	end
end

local function TheLastOil(Coordinate: CFrame)
	local DomainSize = 50;
	
	local RayResult = workspace:Raycast(Coordinate.Position, -Vector3.yAxis * 15, Utility.VisualParams);
	local GroundCoordinate = Coordinate - Vector3.yAxis * 4;
	
	if RayResult then
		GroundCoordinate = CFrame.lookAlong(RayResult.Position, RayResult.Normal) + RayResult.Normal * 0.1;
	end
	
	local Rnd = Random.new();
	
	for Count = 1, math.random(12, 16) do
		local BubbleCoordinate = GroundCoordinate.Position + Vector3.new(
			Rnd:NextNumber(-DomainSize / 2, DomainSize / 2), 
			Rnd:NextNumber(0, DomainSize / 2) + 1, 
			Rnd:NextNumber(-DomainSize / 2, DomainSize / 2)
		)
		BubbleHandler:create(CFrame.new(BubbleCoordinate), math.random(2, 4), Rnd:NextNumber(1, 4));
	end
	
	do
		local DiscoBall = Assets.DiscoBall:Clone();
		DiscoBall.CFrame = Coordinate;
		DiscoBall.Parent = EffectsFolder
		
		local DiscoOutInfo = TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out);
		
		local DiscoOutTween = TweenService:Create(DiscoBall, DiscoOutInfo, {
			CFrame = Coordinate + Vector3.yAxis * 15;
		})
		
		DiscoOutTween:Play();
		DiscoOutTween.Completed:Once(function()
			local DiscoSpinInfo = TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut);
			
			local DiscoSpinTween = TweenService:Create(DiscoBall, DiscoSpinInfo, {
				CFrame = DiscoBall.CFrame * CFrame.Angles(0, math.rad(179), 0);
			})
			DiscoSpinTween:Play()
			DiscoSpinTween.Completed:Wait();
			
			local DiscoInInfo = TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.In);
			
			local DiscoInTween = TweenService:Create(DiscoBall, DiscoInInfo, {
				CFrame = Coordinate - Vector3.yAxis * 20;
			})
			DiscoInTween:Play();
			DiscoInTween.Completed:Wait()
			DiscoBall:Destroy();
		end)
	end;
	
	do
		local Bubble = Assets.Bubble:Clone();
		Bubble.Size = Vector3.zero;
		Bubble.CFrame = GroundCoordinate;
		Bubble.Parent = EffectsFolder;
		
		local BubbleOutInfo = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out);
		
		local BubbleOutTween = TweenService:Create(Bubble, BubbleOutInfo, {
			Size = Vector3.one * DomainSize;
		})
		BubbleOutTween:Play();
		
		local BubbleFadeInfo = TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out);
		
		local BubbleFadeTween = TweenService:Create(Bubble, BubbleFadeInfo, {
			Transparency = 1;
		})
		BubbleFadeTween:Play();
		BubbleFadeTween.Completed:Once(function()
			task.delay(5, Bubble.Destroy, Bubble);
		end)
		
		AenoirEmit(Assets.BubbleExplode, Bubble.Effects)
	end;
	
	ScreenEffect(Coordinate.Position)
end

function VFX.LastOil(RootPart : BasePart)
	task.wait(0.1);
	TheLastOil( RootPart.CFrame + Vector3.yAxis * 5 )
end

function VFX.BottleStretchStart(Bottle : Model, RootPart : BasePart)
	ScreenEffect(RootPart.Position, 1.25, 15, 0.15)
	
	Bottle.Cap.SoapBeam.Enabled = true;
	AenoirEmit(Assets.BottleStretchStart, RootPart)
end

function VFX.BottleStretchEnd(Bottle : Model)
	Bottle.Cap.SoapBeam.Enabled = false;
end

function VFX.Cusp(RootPart : BasePart)
	ScreenEffect(RootPart.Position, 0.75, 20, 0.1)
	AenoirEmit(Assets.Cusp, RootPart);
end

function VFX.Clap(RootPart : BasePart)
	ScreenEffect(RootPart.Position, 0.75, 20, 0.1)
	VFX.Cusp(RootPart)
end

function VFX.BottleOpen(Bottle : Model)
	AenoirEmit(Assets.BottleOpen, Bottle.BallCap.Attachment1);
end

return VFX