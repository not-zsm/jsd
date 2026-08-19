return {
	["duration"] = -1;
	["offset"] = CFrame.identity;
	["raycast_distance"] = 25;
	["fade_out_time"] = 10;
	["local_to_adornee"] = false;
	
	["if_water_effects"] = "Particles/WaterSplash";
	
	["rotation_angle"] = {
		NumberRange.new(0, 0);
		NumberRange.new(0, 0);
	};
	
	["cone"] = {
		["count"] = NumberRange.new(0);
		["angle"] = NumberRange.new(0);
		["distance"] = 16;
		["delay"] = 0;
		["size"] = Vector3.one;
		["tween"] = {
			NumberRange.new(0.1), 
			Enum.EasingStyle.Quad, 
			Enum.EasingDirection.Out, 0, false, 0
		};
		["variance"] = 0;
		["magnitude_variance"] = 0;
		["rate"] = 20;
		["duration"] = 0;
		["depth"] = 0;
		["accent"] = 0;
		["spawn_middle"] = false;
	};
	
	["rubble"] = {
		["size"] = Vector3.one;
		["tween"] = {
			NumberRange.new(0.1), 
			Enum.EasingStyle.Quad, 
			Enum.EasingDirection.Out, 0, false, 0
		};
		["variance"] = 0;
		["magnitude_variance"] = 0;
		["rate"] = 20;
		["duration"] = 0;
		["depth"] = 0;
		["accent"] = 0;
		["spawn_middle"] = false;
	};

	["crater"] = {
		["size"] = Vector3.new(4, 1, 2);
		["count"] = NumberRange.new(0);
		["angle_variance"] = NumberRange.new(0);
		["tween"] = {
			NumberRange.new(0.1), 
			Enum.EasingStyle.Quad, 
			Enum.EasingDirection.Out, 0, false, 0
		};
		["variance"] = 0;
		["magnitude_variance"] = 0;
		["revolutions"] = 2;
		["depth"] = 0;
		["radius"] = 4;
		["accent"] = 4;
		["spawn_middle"] = false;
	};

	["splash"] = {
		["size"] = NumberRange.new(1, 2);
		["spread_angle"] = Vector2.new(0, 0);
		["power"] = NumberRange.new(20, 20);
		["count"] = NumberRange.new(0, 0);
		["cone_distance"] = NumberRange.new(0, math.huge);
		["velocity_duration"] = 0.1;
		["collidable"] = true;
		["between_cone"] = false;
	}
}