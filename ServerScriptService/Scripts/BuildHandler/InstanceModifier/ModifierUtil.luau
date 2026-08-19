local Alive = workspace.Models;

local Players = game:GetService("Players")

local Util = {};

function Util.normal_range(range: NumberRange): NumberRange
	if range.Min == range.Max then
		return NumberRange.new(0, range.Max);
	end;
	
	return range;
end

function Util.get_nearest(position: Vector3, humanoids: {Humanoid}): Humanoid?
	local nearest: Humanoid?;
	local nearest_distance = math.huge;
	
	for _, humanoid in humanoids do
		local distance = (humanoid.RootPart.Position - position).Magnitude;
		
		if distance < nearest_distance then
			nearest = humanoid;
			nearest_distance = distance;
		end;
	end;
	
	return nearest;
end

function Util.get_player_humanoids(position: Vector3, range: NumberRange): {Humanoid}
	local humanoids = {};
	
	for _, player in Players:GetPlayers() do
		if player.Character then
			local distance = player:DistanceFromCharacter(position);
			
			if (distance > range.Min and distance < range.Max) then
				local humanoid = player.Character:FindFirstChildOfClass("Humanoid");

				if humanoid and humanoid.RootPart and humanoid.Health > 0 then
					table.insert(humanoids, humanoid);
				end;
			end;
		end;
	end;
	
	return humanoids;
end;

function Util.get_humanoids(position: Vector3, range: NumberRange): {Humanoid}
	local humanoids = {};
	local search_list = Alive:GetChildren();
	
	for _,  model in search_list do
		if model:IsA("Folder") then
			local instances = model:GetChildren();
			table.move(instances, 1, #instances, #search_list + 1, search_list);
			continue;
		end;
		
		if model:IsA("Model") then
			local distance = (model:GetPivot().Position - position).Magnitude;
			
			if (distance > range.Min and distance < range.Max) then
				local humanoid = model:FindFirstChildOfClass("Humanoid");
				
				if humanoid and humanoid.RootPart and humanoid.Health > 0 then
					table.insert(humanoids, humanoid);
				end;
			end;
		end;
	end;

	return humanoids;
end

return Util;