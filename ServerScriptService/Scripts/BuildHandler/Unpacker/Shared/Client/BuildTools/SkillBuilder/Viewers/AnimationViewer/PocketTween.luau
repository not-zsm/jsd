local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local TweenTypes = { ["number"] = "NumberValue", ["Vector3"] = "Vector3Value" };

local PocketTween = {};
PocketTween.__index = PocketTween;

function PocketTween.new(values)
	local self = setmetatable(
		{
			values = values,
			objects = {};
			active = {};
		}, 
		PocketTween);
	
	for name, value in values do
		local tween_type = TweenTypes[typeof(value)];
		
		if tween_type then
			self.objects[name] = Instance.new(tween_type);
			self.objects[name].Value = value;
		end;
	end;
	
	return self;
end;

function PocketTween:destroy()
	for _, object in self.objects do
		object:Destroy();
	end;
	
	table.clear(self.values);
	table.clear(self.objects);
	table.clear(self.active);
	
	self:update_active(nil, nil);
end

function PocketTween.on_step(dt: number, values)
	return;
end

function PocketTween:update_active(name, value)
	self.active[name] = value;
	
	local is_empty = next(self.active) == nil;
	
	if is_empty and self.connection then
		self.connection:Disconnect();
		self.connection = nil;
		
	elseif not is_empty and not self.connection then
		local values = {};
		
		local function update_step(dt: number)
			for name, value_base in self.objects do
				values[name] = value_base.Value;
			end;

			self.on_step(dt, values);
		end
		
		self.connection = RunService.PostSimulation:Connect(update_step);
		update_step(0);
	end;
end;

function PocketTween:tween_values(info: TweenInfo, values: {[string]: any})
	for name, value in values do
		self:tween(name, info, value);
	end;
end

function PocketTween:tween(name: string, info: TweenInfo, value: any)
	local tween = TweenService:Create(self.objects[name], info, {Value = value});
	
	tween.Completed:Once(function(status)
		if status == Enum.PlaybackState.Completed then
			self:update_active(name, nil);
		end;
	end);
	
	tween:Play();
	self:update_active(name, true);
end

table.freeze(PocketTween);

return PocketTween;