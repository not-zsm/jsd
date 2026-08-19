local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer;

local Instances = require( ReplicatedStorage.Packages.Instances )
local Maid = require( ReplicatedStorage.Packages.Maid )

local FastTweenInfo = TweenInfo.new(0.1);

local CameraAdorn = {};
CameraAdorn.__index = CameraAdorn;

function CameraAdorn.new()
	local self = setmetatable(
		{
			items = {};
			active_maid = Maid.new();
			number = Instance.new("NumberValue");
		}, 
		CameraAdorn);
	
	return self;
end;

function CameraAdorn:hook_active_updater()
	self.active_maid:clean();

	self.active_maid:add(RunService.PreRender:Connect(function(dt)
		local peak = self.items[1];

		if peak then
			local current_camera = workspace.CurrentCamera;
			local origin = self.last_adorn_coordinate or current_camera.CFrame;
			local target = Instances.cframe(peak.adorn)
			
			if not peak.unlock_pan then
				if peak.unlock_rotation then 
					current_camera.CFrame = current_camera.CFrame.Rotation + origin.Position:Lerp(target.Position, self.number.Value);
				else
					current_camera.CFrame = origin:Lerp(target, self.number.Value);
				end;
			end;
		end;
	end));
end;

function CameraAdorn:remove(identifier: Instance?)
	if not identifier then return end;
	
	for index, queue in self.items do
		if queue.identifier == identifier then
			table.remove(self.items, index);
			return self:update();
		end;
	end;
end;

function CameraAdorn:add(identifier: Instance, adorn: Instance, tween_info: TweenInfo, field_of_view: number, unlock_rotation: boolean, unlock_pan): ()
	if not identifier or not adorn then return end;
	
	table.insert(self.items, 1, {
		adorn = adorn,
		identifier = identifier,
		tween_info = tween_info,
		field_of_view = field_of_view,
		unlock_rotation = unlock_rotation or unlock_pan,
		unlock_pan = unlock_pan;
	});

	self:update();
end;

function CameraAdorn:reset_subject()
	local character = Player.Character;

	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid");

		if humanoid then
			workspace.CurrentCamera.CameraSubject = humanoid;
		end
	end;
end

function CameraAdorn:update()
	local peak = self.items[1];
	local camera = workspace.CurrentCamera;

	if peak then
		if not self.is_adorned then
			self.is_adorned = true;
			self:hook_active_updater();
		end;
		
		self.number.Value = 0;
		self.last_adorn_coordinate = camera.CFrame;
		
		if peak.unlock_rotation then
			if peak.unlock_pan then
				camera.CameraType = Enum.CameraType.Custom;
			else
				camera.CameraType = Enum.CameraType.Fixed;
			end;
			
			camera.CameraSubject = peak.adorn;
		else
			camera.CameraType = Enum.CameraType.Scriptable;
		end
		
		local fov_tween = TweenService:Create(camera, peak.tween_info, {FieldOfView = peak.field_of_view})
		fov_tween:Play();

		local tween = TweenService:Create(self.number, peak.tween_info, {Value = 1})
		tween:Play();

	elseif self.is_adorned then
		self.is_adorned = false;
		self.active_maid:clean();
		
		local fov_tween = TweenService:Create(camera, FastTweenInfo, {FieldOfView = 70})
		fov_tween:Play();
		
		local tween = TweenService:Create(self.number, FastTweenInfo, {Value = 0})
		tween:Play();
		
		camera.FieldOfView = 70;
		camera.CameraType = Enum.CameraType.Custom;
		
		self:reset_subject();
	end
end

table.freeze(CameraAdorn);

return CameraAdorn;