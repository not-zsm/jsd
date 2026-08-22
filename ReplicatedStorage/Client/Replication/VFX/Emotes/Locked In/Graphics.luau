local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Job = require( ReplicatedStorage.Shared.Utilities.Job )

local Player = Players.LocalPlayer;
local Animation = {};

function Animation.play(UI)
	local quality = UserSettings().GameSettings.SavedQualityLevel.Value;
	if quality == 0 then quality = 5; end;

	local job = Job.new();

	local self = {
		UI = UI;
		Path = script:WaitForChild("Path2D");
		Letter = script:WaitForChild("Letter");
		Spacer = script:WaitForChild("Spacer");
		
		Speech = UI.Body:WaitForChild("Speech");
		Graphic = UI.Body:WaitForChild("Graphic");

		job = job;
		sine = math.pi * 1.25;
		paths_list = {};
		max_paths = math.round( 72 * math.clamp(quality / 10 + 0.25, 0.25, 1) );
		max_letters = math.round( 80 * math.clamp(quality / 8, 0.25, 1) );
		path_center = Path2DControlPoint.new(UDim2.fromScale(0.5, 0.5));
		letter_tween_info = TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.In);
	};

	UI.Destroying:Once(function()
		Animation.destroy(self);
	end)

	Animation.begin(self);

	return self;
end

function Animation.create_flipbook_asset(self, icon: ImageLabel): ()
	local info = icon:GetAttributes();

	local sequence = 0;
	local elapsed = 0;
	local max_sequence = info.Size * info.Size;
	local interval = info.Resolution / info.Size;
	local framerate = 1 / info.Framerate;

	icon.ImageRectSize = Vector2.new(interval, interval);

	self.job:Task(RunService.RenderStepped:Connect(function(dt)
		elapsed += dt;

		while elapsed > framerate do
			elapsed -= framerate;
			sequence = (sequence + 1) % max_sequence;

			icon.ImageRectOffset = Vector2.new(sequence % info.Size, sequence // info.Size) * interval;
		end
	end))
end

function Animation.destroy(self)
	self.job:Destroy();
	Animation.destroy_paths(self);
end

function Animation.create_letter(self)
	local letter = self.Letter:Clone()
	local dimming = 1 - math.random() * 0.4;

	letter.Icon:SetAttribute("Framerate", 5 + math.random() * 5)
	letter.Icon.ImageColor3 = Color3.fromRGB(255 * dimming, 255 * dimming, 255 * dimming);
	letter.Icon.Position = UDim2.fromScale(0.5 + (0.3 - math.random() * 01.6), 0.5 - math.random() / 3)
	letter.Icon.Size = UDim2.fromScale(1 + math.random() * 2, 1);
	letter.Icon.UIScale.Scale = 0;
	letter.Parent = self.Speech;

	Animation.create_flipbook_asset(self, letter.Icon);

	local tween = TweenService:Create(letter.Icon.UIScale, self.letter_tween_info, {
		Scale = 1.75;
	});
	tween:Play();

	return letter;
end

function Animation.create_spacer(self)
	local spacer = self.Spacer:Clone();
	spacer.Parent = self.Speech;

	return spacer;
end

function Animation.begin_letter_animation(self, count: number, delay: number): ()
	for count = 1, count do
		local letter = Animation.create_letter(self);

		task.wait(delay);

		if count == 21 or count == 47 then
			Animation.create_spacer(self);
		end
	end
end

function Animation.begin_graphic_flyin(self)
	self.Graphic.Animate.Position = UDim2.fromScale(0.5, -0.6);

	local tween = TweenService:Create(self.Graphic.Animate, TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.5, 0.5);
	});
	tween:Play();
end

function Animation.curved_tangent(origin: Vector2, target: Vector2, scale: number): (UDim2, UDim2)
	local direction = origin - target;
	local left_tangent = origin:Lerp(target, 0.75) - origin + Vector2.new(-direction.Y, direction.X).Unit * scale / 2;

	return UDim2.fromScale(-left_tangent.X, -left_tangent.Y), UDim2.fromScale(left_tangent.X, left_tangent.Y);
end

function Animation.destroy_paths(self)
	for _, path in self.paths_list do
		path:Destroy();
	end;

	table.clear(self.paths_list);
end

function Animation.generate_paths(self)
	Animation.destroy_paths(self);

	for count = 1, self.max_paths do
		local path = self.Path:Clone();
		path.Parent = self.Graphic.Animate;

		self.paths_list[count] = path;
	end
end

function Animation.update_path_render(self, dt: number): ()
	self.sine += dt * 0.4;

	local cam_dist = (workspace.CurrentCamera.CFrame.Position - self.UI.Parent.CFrame.Position + self.UI.ExtentsOffsetWorldSpace).Magnitude ^ 3;
	local now = self.sine + math.cos(self.sine * 4) * 0.1
	local max_size = TweenService:GetValue(math.clamp(self.sine * 1 - math.pi * 1.25, 0, 1), Enum.EasingStyle.Cubic, Enum.EasingDirection.Out);
	local size2 = math.sin(now * 5) * 0.2 * max_size;

	for count, path in self.paths_list do
		local arc = now + count * math.pi * 2 / self.max_paths;
		local size_no_max = (0.75 + (math.cos(now + arc * 6)) * 0.25)
		local size = size_no_max * max_size;
		local x, y = 0.5 - math.cos(arc) / 2 * size, 0.5 - math.sin(arc) / 2 * size;
		local x2, y2 = 0.5 - math.cos(arc + now) / 2 * size, 0.5 - math.sin(arc + now) / 2 * size;

		path.Color3 = Color3.fromRGB(148 + math.clamp(math.sin(arc - now) * 127, 0, 127), math.clamp(50 + 150 * size_no_max, 0, 255), math.clamp(255 * size_no_max, 0, 255))
		path.Thickness = (0.25 + math.abs(math.sin(arc) * 2)) / cam_dist * 4;

		path:SetControlPoints({self.path_center,
			Path2DControlPoint.new(UDim2.fromScale(x2, y2), Animation.curved_tangent(Vector2.new(0.5, 0.5), Vector2.new(x2, y2), size2 / 12)),
			Path2DControlPoint.new(UDim2.fromScale(x, y), Animation.curved_tangent(Vector2.new(x, y), Vector2.new(0.5, 0.5), size2 / 2 * 5))
		})
	end
	
	--local now = self.sine + math.cos(self.sine * 4) * 0.1
	--local max_size = TweenService:GetValue(math.clamp(self.sine * 1 - math.pi, 0, 1), Enum.EasingStyle.Cubic, Enum.EasingDirection.Out);
	--local size2 = math.sin(now * 5) * 0.2 * max_size;

	--for count, path in self.paths_list do
	--	local arc = now + count * math.pi * 2 / self.max_paths;
	--	local size_no_max = (0.75 + (math.cos(now + arc * 6)) * 0.25)
	--	local size = size_no_max * max_size;
	--	local x, y = 0.5 - math.cos(arc) / 2 * size, 0.5 - math.sin(arc) / 2 * size;
	--	local x2, y2 = 0.5 - math.cos(arc + now) / 2 * size, 0.5 - math.sin(arc + now) / 2 * size;

	--	path.Color3 = Color3.fromRGB(148 + math.clamp(math.sin(arc - now) * 127, 0, 127), math.clamp(50 + 150 * size_no_max, 0, 255), math.clamp(255 * size_no_max, 0, 255))
	--	path.Thickness = 0.25 + math.abs(math.sin(arc) * 2);

	--	path:SetControlPoints({self.path_center,
	--		Path2DControlPoint.new(UDim2.fromScale(x2, y2), Animation.curved_tangent(Vector2.new(0.5, 0.5), Vector2.new(x2, y2), size2 / 12)),
	--		Path2DControlPoint.new(UDim2.fromScale(x, y), Animation.curved_tangent(Vector2.new(x, y), Vector2.new(0.5, 0.5), size2 / 2 * 5))
	--	})
	--end
end

function Animation.begin(self): ()
	Animation.generate_paths(self);
	Animation.begin_graphic_flyin(self);

	self.job:Task(task.spawn(Animation.begin_letter_animation, self, self.max_letters, 0.1));

	self.job:Task(RunService.PreRender:Connect(function(dt)
		Animation.update_path_render(self, dt);
	end))
end

return Animation;