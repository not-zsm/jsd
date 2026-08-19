local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer;
local CurrentCamera = workspace.CurrentCamera;

local AimAssist = {};

function AimAssist.get(radius: number, maxdistance : number, humanoid_pool: {Humanoid})
	local humanoid_best: Humanoid?;
	local distance_best = math.huge;

	local mouse = UserInputService:GetMouseLocation();
	local ray = CurrentCamera:ViewportPointToRay(mouse.X, mouse.Y, 1024);

	for _, humanoid in humanoid_pool do
		if humanoid.Parent == Player.Character then
			continue;
		end
		
		if not humanoid.RootPart then
			continue 
		end

		local point = ray.Unit.Direction;
		local direction = CurrentCamera.CFrame.Position - humanoid.RootPart.Position;
		
		if direction.Unit:Dot(point) < 0 and direction.Magnitude < maxdistance then
			local magnitude = ray.Unit.Direction:Cross(direction).Magnitude;

			if (magnitude < distance_best and magnitude < radius) then
				distance_best = magnitude;
				humanoid_best = humanoid;
			end;
		end;
	end;

	return humanoid_best;
end

return AimAssist;