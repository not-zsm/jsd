local RunService = game:GetService("RunService")
local IsServer = RunService:IsServer();

export type DebrisStruct = {
	time_create: number,
	time_idle: number,
	part: BasePart,
};

local Debris = {};
Debris.count = 0;
Debris.pool = {};
Debris.id_pool = {};

function Debris.set_sleep(part: BasePart, sleep: boolean)
	local debris = Debris.pool[part];
	
	if debris and not sleep then
		debris.time_idle = -1;
	end;
	
	if sleep then
		part.Anchored = true;
		part.AssemblyLinearVelocity = Vector3.zero;
		part.AssemblyAngularVelocity = Vector3.zero;
	else
		part.Anchored = false;
		
		if IsServer and part:CanSetNetworkOwnership() then
			part:SetNetworkOwner(nil);
		end;
	end;
end;

function Debris.add(id: number, part: BasePart): DebrisStruct
	local debris = {
		id = id;
		part = part,
		time_idle = -1;
		time_create = tick();
	};
	
	Debris.pool[part] = debris;
	Debris.id_pool[id] = debris;
	
	Debris.count += 1;
	
	return debris;
end;

function Debris.remove(id: number)
	local debris = Debris.id_pool[id];
	
	if debris then
		Debris.pool[debris.part] = nil;
		Debris.id_pool[id] = nil;
		
		Debris.count -= 1;
	end;
end;

return Debris;