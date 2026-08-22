export type UserRole = {
	Level: number,
	Permission: string,
	GlobalCooldown: number?,
	RestrictToSelf: boolean?;
	BypassBosses: boolean?;
	RateLimit : number?;
};

local UserRoles = {
	["None"] = {
		Level = 0
	};
	["PS"] = {
		Level = 1,
	};
	["PS+"] = {
		Level = 2,
	};
	["Staff"] = {
		Level = 3,
		BypassBosses = true;
		GlobalCooldown = 1;
		RateLimit = 5,
	};
	["Developer"] = {
		Level = 4,
		BypassBosses = true;
		GlobalCooldown = 1;
		RestrictToSelf = true;
		RateLimit = 5,
	};
	["GOB"] = {
		Level = 5,
		RateLimit = -1,
		BypassBosses = true;
	};
	["Owner"] = {
		Level = 6,
		RateLimit = -1,
		BypassBosses = true;
	};
};

for Permission, Role in UserRoles do
	Role.Permission = Permission;
end;

return UserRoles;