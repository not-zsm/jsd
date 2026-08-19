local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local Player = Players.LocalPlayer;

local Assets = script.Assets;

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local AenoirEmit = EffectUtility.AenoirEmit

type Steak = BasePart;

local VFX = {};

local function TweenModelTransparency(Decals, Info, Value)
	local Goal = {Transparency = Value};
	
	for _, Part in Decals do
		TweenService:Create(Part, Info, Goal):Play();
	end;
end

local function CreateAttachment(Coordinate: CFrame, Parent: Instance?)
	local Attachment = Instance.new("Attachment");
	Attachment.CFrame = Coordinate;
	Attachment.Parent = Parent;

	return Attachment;
end

function VFX.SteakLaugh(Steak: Steak)
	AenoirEmit(Assets.SteakLaugh, Steak);
end

function VFX.SteakEat(Attachment: Attachment, EffectProperties)
	AenoirEmit(Assets.Munch, Attachment, nil, EffectProperties);
	
	if Player:DistanceFromCharacter(Attachment.WorldPosition) <= 25 then
		CameraShake(1.5, 25, 0.01, 0.15, Vector3.one * 0.8)
		Vignette(Color3.fromRGB(255, 0, 0), 0.65, 0.15)
	end
end

function VFX.Beep(Steak: Steak)
	AenoirEmit(Assets.Beep, Steak);
	AenoirEmit(Assets.Flash, Steak);
end

function VFX.Catch(Attachment: Attachment)
	AenoirEmit(Assets.Catch, Attachment);
end

function VFX.Jump(RootPart: BasePart)
	AenoirEmit(Assets.Jump, RootPart.RootAttachment);
	
	local Player = Players:GetPlayerFromCharacter(RootPart.Parent);
	
	if Player == Players.LocalPlayer then
		local Humanoid = Player.Character.Humanoid :: Humanoid;
		local RootPart = Humanoid.RootPart;
		
		local Velocity = Instance.new("LinearVelocity")
		Velocity.Attachment0 = RootPart.RootAttachment;
		Velocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis;
		Velocity.MaxAxesForce = Vector3.new(0, 25_000, 0);
		Velocity.VectorVelocity = Vector3.new(0, 50, 0);
		Velocity.Parent = RootPart;

		local LandedConnection; LandedConnection = Humanoid.StateChanged:Connect(function(_, state)
			if (state == Enum.HumanoidStateType.Landed) then
				local Attachment = CreateAttachment(CFrame.new(0, -2.5, 0), RootPart);
				
				if Player:DistanceFromCharacter(RootPart.Position) <= 30 then
					CameraShake(1, 22.5, 0.01, 0.2, Vector3.one * 0.8, Vector3.one * 0.25)
				end
				
				AenoirEmit(Assets.Land, Attachment, function()
					Attachment:Destroy();
				end)
			end
		end)

		task.wait(0.2)
		Velocity:Destroy();
		task.wait(5);
		
		if LandedConnection.Connected then
			LandedConnection:Disconnect();
		end
	end;
end


function VFX.LaserShoot(Steak, Target: Attachment, EffectProperties)
	local RightEye = Steak.Torso.RightEye;
	local LeftEye = Steak.Torso.LeftEye;

	AenoirEmit(Assets.LaserEye, RightEye, nil, EffectProperties);
	AenoirEmit(Assets.LaserEye, LeftEye, nil, EffectProperties);

	--local Speed = 600;

	--task.delay(0.75, function()
	--	for _, Eye: Attachment in {RightEye, LeftEye} do
	--		local Laser = Assets.LaserTrail:Clone();
	--		Laser.CFrame = Eye.WorldCFrame;

	--		local Direction = (Target.WorldPosition - Eye.WorldPosition)
	--		local Result = workspace:Raycast(Eye.WorldPosition, Direction.Unit * 1000, Utility.VisualParams);
	--		local CFrameHit = CFrame.lookAlong(Target.WorldPosition, Vector3.yAxis);

	--		if Result then
	--			CFrameHit = CFrame.lookAlong(Result.Position, Result.Normal);
	--		end;

	--		local DirectionHit = (Eye.WorldPosition - CFrameHit.Position);

	--		local Tween = TweenService:Create(Laser, TweenInfo.new(DirectionHit.Magnitude / Speed, Enum.EasingStyle.Linear), {
	--			Position = CFrameHit.Position;
	--		});

	--		Tween.Completed:Once(function()
	--			Laser.WorldCFrame = CFrameHit;

	--			AenoirEmit(Assets.LaserBlast, Laser, function()
	--				Laser:Destroy();
	--			end)
	--		end)

	--		AenoirEmit(Assets.LaserShoot, Eye);

	--		Laser.Parent = workspace.Terrain;
	--		task.wait();
	--		Tween:Play();
	--	end;
	--end)
end

function VFX.LaserFire(Steak, Coordinate : CFrame, EffectProperties)
	local RightEye = Steak.Torso.RightEye;
	local LeftEye = Steak.Torso.LeftEye;
	
	local Speed = 600;

	for _, Eye: Attachment in {RightEye, LeftEye} do
		local Laser = Assets.LaserTrail:Clone();
		Laser.CFrame = Eye.WorldCFrame;

		if EffectProperties and EffectProperties.Tint then
			Laser.Trail.Color = AenoirEmit.Recolor(Laser.Trail.Color, EffectProperties.Tint);
			Laser.Trail2.Color = AenoirEmit.Recolor(Laser.Trail2.Color, EffectProperties.Tint);
		end;
		
		local DirectionHit = (Eye.WorldPosition - Coordinate.Position);

		local Tween = TweenService:Create(Laser, TweenInfo.new(DirectionHit.Magnitude / Speed, Enum.EasingStyle.Linear), {
			Position = Coordinate.Position;
		});

		Tween.Completed:Once(function()
			Laser.WorldCFrame = Coordinate;

			if Player:DistanceFromCharacter(Coordinate.Position) <= 25 then
				CameraShake(1.8, 30, 0.01, 0.2, Vector3.one * 0.8)
				Vignette(Color3.fromRGB(255, 0, 0), 0.65, 0.15)
			end

			AenoirEmit(Assets.LaserBlast, Laser, function()
				Laser:Destroy();
			end, EffectProperties)
		end)

		AenoirEmit.Emit(Assets.LaserShoot, Eye, EffectProperties);

		Laser.Parent = workspace.Terrain;
		task.wait();
		Tween:Play();
	end;
end

function VFX.SummoningLink(Origin: CFrame, Enemy)
	local Attachment = CreateAttachment(Origin * CFrame.new(0, -2, 0), workspace.Terrain);

	local Beam = Assets.Chain:Clone();
	Beam.Attachment0 = Attachment;
	Beam.Attachment1 = Enemy.HumanoidRootPart.RootAttachment;
	Beam.Parent = Attachment;

	local TransparencyValue = Instance.new("NumberValue")

	TransparencyValue.Changed:Connect(function(Value)
		Beam.Transparency = NumberSequence.new(Value)
	end)

	local Tween = TweenService:Create(TransparencyValue, TweenInfo.new(3.5, Enum.EasingStyle.Circular, Enum.EasingDirection.In), {
		Value = 1;
	})

	Tween.Completed:Once(function()
		Attachment:Destroy();
		Beam:Destroy();
		TransparencyValue:Destroy();
	end)

	Tween:Play();
end

function VFX.Summoning(Coordinate: CFrame, Steak: Steak)
	VFX.Beep(Steak);
	
	if Player:DistanceFromCharacter(Coordinate.Position) < 200 then
		local Color = Instance.new("ColorCorrectionEffect")
		local ColorTween = TweenService:Create(Color, TweenInfo.new(0.15), {
			Contrast = 0.1;
			TintColor = Color3.fromRGB(255, 172, 172)
		})
		ColorTween.Completed:Once(function()
			local ColorTween = TweenService:Create(Color, TweenInfo.new(1.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out, 0, false, 1), {
				Contrast = 0;
				TintColor = Color3.fromRGB(255, 255, 255);
			})
			ColorTween:Play();
			ColorTween.Completed:Wait()
			Color:Destroy();
		end)
		Color.Parent = Lighting;
		ColorTween:Play();
		
		local Camera = workspace.CurrentCamera
		local CameraTween = TweenService:Create(Camera, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {FieldOfView = 90})
		CameraTween.Completed:Once(function()
			local CameraTween = TweenService:Create(Camera, TweenInfo.new(5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out, 0, false, 0), {
				FieldOfView = 70
			})
			CameraTween:Play();
		end)
		CameraTween:Play();
	end;
	
	local Attachment = CreateAttachment(Coordinate, workspace.Terrain);

	local Gui = Assets.TitleGui:Clone();
	Gui.Body.GroupTransparency = 1;
	Gui.Parent = Attachment;
	
	local Tween = TweenService:Create(Gui.Body, TweenInfo.new(1), {GroupTransparency = 0})
	Tween:Play();
	
	AenoirEmit(Assets.Michael, Attachment)

	task.delay(3, function()
		local Tween = TweenService:Create(Gui.Body, TweenInfo.new(1), {GroupTransparency = 1})
		Tween:Play();
		Tween.Completed:Wait();
		Attachment:Destroy();
	end)
	
	local Result = workspace:Raycast(Coordinate.Position, -Vector3.yAxis * 200, Utility.VisualParams)

	if Result then
		local GroundAttachment = CreateAttachment(CFrame.lookAlong(Result.Position, Result.Normal), workspace.Terrain)

		AenoirEmit(Assets.MichaelGround, GroundAttachment, function()
			GroundAttachment:Destroy();
		end)
	end;
end

return VFX;