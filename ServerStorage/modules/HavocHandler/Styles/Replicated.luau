local replicatedStorage = game:GetService("ReplicatedStorage")

local Havoc = require("../Havoc");

local Shared = replicatedStorage.modules.shared.havoc;
local Remotes = Shared.Remotes;

local ReplicatedDestruction = setmetatable({}, Havoc);
ReplicatedDestruction.__index = ReplicatedDestruction;

function ReplicatedDestruction.new(DestructionHandler, ...)
	local self = setmetatable(Havoc.create(...), ReplicatedDestruction);
	
	self.destruction_handler = DestructionHandler;
	
	return self;
end;

function ReplicatedDestruction:create_effects()
	--Shared.Remotes.CreateEffects

end

function ReplicatedDestruction:create_crater(info)
	local crater = Havoc.create_crater(self, info);
	
	for _, part in crater do
		part.Parent = Havoc.folder.Static;
	end;
	
	return crater;
end

function ReplicatedDestruction:create_debris(info)
	local bases = {};
	
	local function create_part_callback(cube, base, slice)
		if not bases[base] then
			bases[base] = {};
		end;
		
		slice.part = cube;
		table.insert(bases[base], slice);
	end
	
	if info.create_part_callback then
		local user_create_callback = info.create_part_callback;
		
		function info.create_part_callback(...)
			user_create_callback(...);
			create_part_callback(...);
		end
	else
		info.create_part_callback = create_part_callback;
	end;
	
	local debris = Havoc.create_debris(self, info);
	
	self.destruction_handler:give_active_debris(bases);
	
	return debris;
end

table.freeze(ReplicatedDestruction);

return ReplicatedDestruction;