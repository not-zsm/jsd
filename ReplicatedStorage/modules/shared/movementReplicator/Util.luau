local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local MovementUtil = {};

MovementUtil.limb_names = {
	["Right Arm"] = true;
	["Left Arm"] = true;
	["Right Leg"] = true;
	["Left Leg"] = true;
	["Torso"] = true;
	["Head"] = true;
};

function MovementUtil.frequency_loop(delay: number, callback: (dt: number) -> ()): thread
	
	return task.spawn(function()
		while true do
			callback( task.wait(delay) );
		end;
	end);
end

function MovementUtil.create_debug_part(color: Color3, title: string, subtitle: string)
	local part = script.DebugPart:Clone();
	
	part.Archivable = false
	part.SelectionBox.Color3 = color;
	part.SelectionBox.SurfaceColor3 = color;
	
	part.UI.Title.TextColor3 = color;
	part.UI.Title.Text = title or "";
	part.UI.SubTitle.Text = subtitle or "";
	
	return part;
end

function MovementUtil.tween_number(start, goal, info, callback)
	
	local last_value = start;
	local number_value = Instance.new("NumberValue");
	number_value.Value = start;
	
	local connection = RunService.Heartbeat:Connect(function(dt)
		callback(number_value.Value, last_value)
		last_value = number_value.Value;
	end)
	
	local tween = TweenService:Create(number_value, info, {Value = goal})
	tween.Completed:Once(function()
		connection:Disconnect();
	end)
	tween:Play();
end

return MovementUtil;