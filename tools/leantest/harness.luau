-- Minimal Roblox stubs, enough to run lean.client.luau's pose maths offline.

local vec

local world = {
	velocity = { X = 0, Y = 0, Z = 0 },
	angularY = 0,
	moveDirection = { X = 0, Y = 0, Z = 0 },
	anchored = false,
	sit = false,
	platformStand = false,
	enabled = true,
	health = 100,
	walkSpeed = 16,
	floor = "Grass",
	cameraDistance = 10,
}

local writes = { count = 0 }

local vecMeta = {}
vecMeta.__index = vecMeta
vecMeta.__mul = function(a, k) return vec(a.X * k, a.Y * k, a.Z * k) end

function vec(x, y, z)
	local v = setmetatable({ X = x, Y = y, Z = z }, vecMeta)
	v.Magnitude = math.sqrt(x * x + y * y + z * z)
	if v.Magnitude > 0 then
		v.Unit = setmetatable({ X = x / v.Magnitude, Y = y / v.Magnitude, Z = z / v.Magnitude }, vecMeta)
	end
	return v
end

Vector3 = setmetatable({ zero = vec(0, 0, 0) }, { __index = { new = vec } })
Vector3.new = vec

-- the root is axis aligned in every case we test, so object space == world space
local identity
local function makeCF(angles)
	return {
		angles = angles,
		Position = vec(0, 0, 0),
		VectorToObjectSpace = function(_, v) return v end,
		__mul = nil,
	}
end

local cfMeta = {}
cfMeta.__index = cfMeta
cfMeta.__mul = function(a, b)
	return setmetatable({ base = a, angles = b.angles or a.angles }, cfMeta)
end
function cfMeta:VectorToObjectSpace(v) return v end

CFrame = {
	Angles = function(x, y, z)
		return setmetatable({ angles = { x, y, z } }, cfMeta)
	end,
	identity = setmetatable({ angles = { 0, 0, 0 } }, cfMeta),
}
identity = CFrame.identity

Enum = { Material = { Air = "Air", Grass = "Grass" } }

local function joint(name)
	local j = { Parent = true, Enabled = true, Name = name }
	j.C0 = setmetatable({ base = name, angles = { 0, 0, 0 } }, cfMeta)
	return setmetatable({}, {
		__index = function(_, k)
			if k == "Enabled" then return world.enabled end
			return j[k]
		end,
		__newindex = function(_, k, v)
			if k == "C0" then
				writes.count += 1
				writes[name] = v.angles or { 0, 0, 0 }
				writes.last = name
			end
			j[k] = v
		end,
	})
end

local joints = {}
for _, n in { "RootJoint", "Neck", "Right Shoulder", "Left Shoulder", "Right Hip", "Left Hip" } do
	joints[n] = joint(n)
end

local function child(name)
	if joints[name] then return joints[name] end
	if name == "Humanoid" then
		return setmetatable({}, { __index = function(_, k)
			if k == "MoveDirection" then return vec(world.moveDirection.X, 0, world.moveDirection.Z) end
			if k == "WalkSpeed" then return world.walkSpeed end
			if k == "FloorMaterial" then return world.floor end
			if k == "Health" then return world.health end
			if k == "Sit" then return world.sit end
			if k == "PlatformStand" then return world.platformStand end
			return nil
		end })
	end
	if name == "HumanoidRootPart" or name == "Torso" then
		return setmetatable({}, {
			__index = function(_, k)
				if k == "WaitForChild" then return function(_, n) return child(n) end end
				if k == "CFrame" then return setmetatable({ angles = { 0, 0, 0 } }, cfMeta) end
				if k == "AssemblyLinearVelocity" then return vec(world.velocity.X, world.velocity.Y, world.velocity.Z) end
				if k == "AssemblyAngularVelocity" then return vec(0, world.angularY, 0) end
				if k == "Anchored" then return world.anchored end
				if k == "Position" then return vec(0, 0, 0) end
				if joints[k] then return joints[k] end
				return nil
			end,
			__call = function() end,
		})
	end
	return nil
end

local partMeta = { WaitForChild = function(_, n) return child(n) end }
partMeta.__index = partMeta

local characterStub = setmetatable({}, {
	__index = function(_, k)
		if k == "WaitForChild" then return function(_, n) return child(n) end end
		if k == "GetAttribute" then return function() return nil end end
		return nil
	end,
})

local scriptParent = { Parent = characterStub, IsDescendantOf = function() return true end }
script = setmetatable({}, {
	__index = function(_, k)
		if k == "Parent" then return scriptParent end
		if k == "GetAttribute" then return function() return nil end end
		return nil
	end,
})

workspace = { CurrentCamera = { CFrame = { Position = setmetatable({}, {
	__sub = function() return { Magnitude = world.cameraDistance } end,
}) } } }

local update
local services = {
	RunService = { PreRender = { Connect = function(_, fn) update = fn end } },
	Players = { LocalPlayer = { Character = characterStub } },
	ReplicatedStorage = { info = "info" },
}
game = {
	GetService = function(_, n) return services[n] end,
	IsLoaded = function() return true end,
}

local realRequire = require
require = function(x)
	if x == "info" then return { walkSpeed = 16 } end
	return realRequire(x)
end

task = { wait = function() end }

return {
	world = world,
	writes = writes,
	joints = joints,
	run = function(main)
		main()
		return update
	end,
}
