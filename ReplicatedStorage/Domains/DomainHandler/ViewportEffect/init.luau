local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local ViewCharacter = require( script.ViewCharacter )
local Maid = require( ReplicatedStorage.Packages.Maid )

local BaseDomainView = script.DomainView;

local ViewportEffect = {};
ViewportEffect.__index = ViewportEffect;

function ViewportEffect.new(settings)
	local view = BaseDomainView:Clone();
	local maid = Maid.new();
	
	local self = setmetatable(
		{
			maid = maid;
			animation_maid = maid:limb();
			
			settings = settings or {},
			view = view;
			straight = view.Straight,
			outer_viewport = view.Straight.CharacterViewport;
			background = view.Straight.Background;
			top_path = view.Straight.TopPath.Path2D;
			bottom_path = view.Straight.BottomPath.Path2D;
		}, 
		ViewportEffect);
	
	self.viewport_camera = Instance.new("Camera")
	self.viewport_camera.CFrame = CFrame.Angles(math.rad(-6), math.rad(3), math.rad(-1)) * CFrame.lookAt(Vector3.new(0, -2.5, -5), Vector3.zero) * CFrame.new(0, 5.5, 4) + Vector3.new(0, 1.5, 0);
	self.viewport_camera.FieldOfView = 40;
	self.viewport_camera.Parent = view;
	
	self.outer_viewport.CurrentCamera = self.viewport_camera;
	self.viewport_character = ViewCharacter.new(self.outer_viewport);
	
	--self.bottom_path.Parent = self.view;
	--self.top_path.Parent = self.view;
	
	self:animate();
	
	return self;
end;

function ViewportEffect:animate()
	local Points = self.straight.Stroke;
	
	local function SetSinePath(Path: Path2D, vP0: Vector2, vP1: Vector2, Time: number, Frequency: number, Amplitude: number)
		local MaxPoints = 15;

		local ControlPoints = {};

		for Index = 0, MaxPoints do
			local t = Index / MaxPoints;
			local vP01 = (vP1 - vP0) * t;
			local nP01 = Vector2.new(-vP01.Y, vP01.X):Sign() * math.sin(Time + t * Frequency * math.pi) * Amplitude * 2.25;

			local LinePosition = UDim2.fromOffset( vP0.X + vP01.X + nP01.X, vP0.Y+ vP01.Y + nP01.Y);
			local Point = Path2DControlPoint.new(LinePosition)

			table.insert(ControlPoints, Point);
		end;

		Path:SetControlPoints(ControlPoints);
	end;
	
	local Elapsed = 0;
	
	local function PosOf(Frame)
		return Frame.AbsolutePosition - self.straight.AbsolutePosition + Vector2.new(0, 6);
	end
	
	local function UpdateSinePaths()
		SetSinePath(self.bottom_path, PosOf(Points.Point1), PosOf(Points.Point4), Elapsed, 3 + math.cos(Elapsed) * 0.1 + math.noise(0.02525, Elapsed * 0.25) * 0.4, 0.2 * self.bottom_path.Thickness)
		SetSinePath(self.top_path, PosOf(Points.Point2), PosOf(Points.Point3), Elapsed, -3.5 + math.sin(Elapsed) * 0.1 + math.noise(Elapsed * 0.21, 0.25835) * 0.4, 0.2 * self.top_path.Thickness);
	end
	
	UpdateSinePaths();
	
	self.maid:add(RunService.PreRender:Connect(function(dt)
		Elapsed += dt * self.top_path.Thickness * 0.4;
		UpdateSinePaths();
	end));
end

local function viewport_start_animation(self)
	local tween = TweenService:Create(self.viewport_camera, TweenInfo.new(1.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		FieldOfView = 15;
		CFrame = self.viewport_camera.CFrame * CFrame.new(0, -5.5, 6.5);
	})
	tween:Play();
	
	local tween = TweenService:Create(self.straight, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(1.25, 0.2);
	})
	tween:Play();

	local tween = TweenService:Create(self.top_path, TweenInfo.new(0.55, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
		Thickness = 30;
	})
	tween:Play();

	local tween = TweenService:Create(self.bottom_path, TweenInfo.new(0.55, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
		Thickness = 30;
	})
	tween:Play();
	tween.Completed:Wait();

	local tween = TweenService:Create(self.top_path, TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Thickness = 15;
	})
	tween:Play();

	local tween = TweenService:Create(self.bottom_path, TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Thickness = 15;
	})
	tween:Play();
end;

local function viewport_end_animation(self)
	for _, path in { self.top_path, self.bottom_path, self.background.TopPath, self.background.BottomPath } do
		local tween = TweenService:Create(path, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Thickness = 0;
		})
		tween:Play();
	end;
	
	local tween = TweenService:Create(self.straight, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(1.25, 0);
	})
	tween:Play();
end

function ViewportEffect:play()
	local Player = Players.LocalPlayer;
	local PlayerGui = Player:WaitForChild("PlayerGui") :: typeof(StarterGui);
	
	self.animation_maid:clean();
	
	if self.settings.character then
		self.viewport_character:create_character( self.settings.character );
	end;
	
	if self.settings.background_image then
		self.background.ImageLabel.Image = self.settings.background_image;
	end;

	self.straight.Size = UDim2.fromScale(1.25, 0);
	self.top_path.Thickness = 0;
	self.bottom_path.Thickness = 0;
	self.view.Parent = PlayerGui.DomainViewport.Main;
	
	if self.settings.viewport_animation then
		local track = self.viewport_character:load_animation( self.settings.viewport_animation )
		track:Play(0.1, 1, 0.1);

		task.delay(0.5, function()
			track:AdjustSpeed(1);
		end);

		track:GetMarkerReachedSignal("Pause"):Once(function()
			track:AdjustSpeed(0.1);
		end);
	end;
	
	self.animation_maid:add(task.spawn(viewport_start_animation, self))
end;

function ViewportEffect:stop()
	self.animation_maid:clean();
	
	task.spawn(viewport_end_animation, self);
	task.wait(1);
	
	self:destroy();
end

function ViewportEffect:destroy()
	self.maid:destroy();
	self.viewport_character:destroy();
	self.view:Destroy();
end

table.freeze(ViewportEffect);

return ViewportEffect;