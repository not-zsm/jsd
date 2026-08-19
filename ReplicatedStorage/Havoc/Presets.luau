-- Presets for destruction

local RunService = game:GetService("RunService")

local rnd = Random.new();

return {
	
	--["Ray"] = {
		
		
	--	debris = function(havoc, parameters, was_join)
			
	--	end,
	--};
	
	["Punch"] = function(havoc, parameters, was_join)
		local destructed, crater, debris = havoc:destruct(parameters);
		--havoc:create_effects();
		
		for _, part in debris do
			--part.Anchored = true;
		end
	end,
	
	["Explode"] = function(havoc, parameters, was_join)
		if parameters.debris then
			parameters.debris.velocity = nil;
		end;
		
		local destructed, crater, debris = havoc:destruct(parameters);
		--havoc:create_effects();
		
		for _, part in debris do
			part.AssemblyLinearVelocity = rnd:NextUnitVector() * 200;
		end
	end,
	
	["Dustdevil"] = function(havoc, parameters, was_join)
		if parameters.debris then
			parameters.debris.velocity = nil;
		end;
		
		local destructed, crater, debris = havoc:destruct(parameters);
		local moving_debris = {};
		
		--havoc:create_effects();
		
		for _, part in debris do
			moving_debris[part] = { 
				coordinate = CFrame.lookAlong(Vector3.zero, rnd:NextUnitVector());
				elapsed = math.random();
				upvalue = rnd:NextNumber(-1, 1);
			};
		end
		
		local connection: RBXScriptConnection;
		
		connection = RunService.PreSimulation:Connect(function(dt)
			if not next(moving_debris) then
				connection:Disconnect();
			end;
			
			for part, data in moving_debris do
				data.elapsed += dt;
				
				if data.elapsed > 3 then
					moving_debris[part] = nil;
				else
					data.coordinate *= CFrame.Angles(
						math.rad( 480) * dt * data.upvalue,
						math.rad( 380) * dt * data.upvalue,
						0 --math.rad(-186) * dt * data.upvalue
					);
					part.AssemblyLinearVelocity = data.coordinate.LookVector * 80;
					part.AssemblyAngularVelocity = data.coordinate:PointToWorldSpace(data.coordinate.RightVector) * 15;
				end
			end
		end)
	end,
	
	["Erase"] = function(havoc, parameters, was_join)
		parameters.debris = nil;
		havoc:destruct(parameters);
	end,
} 
--:: {
--	[string]: (havoc: any, parameters: {info: any, crater: any, debris: any}, was_join: boolean) -> ();
--}