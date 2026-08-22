-- `harness` and `leanMain` are supplied by leantest.py, which concatenates the
-- stubs, the script under test and this file into one chunk so they share a
-- global environment.
local world, writes = harness.world, harness.writes
local update = harness.run(leanMain)

local FRAME = 1 / 60
local failures = 0

local function check(name, ok, detail)
	if ok then
		print(("  ok    %s"):format(name))
	else
		failures += 1
		print(("  FAIL  %s  %s"):format(name, detail or ""))
	end
end

local function step(n)
	for _ = 1, n do update(FRAME) end
end

local function deg(rad) return rad * 180 / math.pi end

local function torso() return writes.RootJoint or { 0, 0, 0 } end

local function reset()
	world.velocity = { X = 0, Y = 0, Z = 0 }
	world.angularY = 0
	world.moveDirection = { X = 0, Y = 0, Z = 0 }
	world.anchored = false
	world.walkSpeed = 16
	world.floor = "Grass"
	world.cameraDistance = 10
	step(180)
end

print("\nstanding still, ground contact noise on the velocity")
reset()
for i = 1, 240 do
	-- a resting humanoid never reads exactly zero
	world.velocity = { X = (i % 3 - 1) * 0.4, Y = math.sin(i) * 0.3, Z = (i % 5 - 2) * 0.3 }
	update(FRAME)
end
local before = writes.count
step(60)
check("no joint writes once settled", writes.count == before,
	("%d writes over 60 idle frames"):format(writes.count - before))
check("pose is exactly neutral", torso()[1] == 0 and torso()[2] == 0 and torso()[3] == 0,
	("pitch %.4f roll %.4f yaw %.4f deg"):format(deg(torso()[1]), deg(torso()[2]), deg(torso()[3])))

print("\nstanding still, looking around in shiftlock")
reset()
local peak = 0
for i = 1, 240 do
	world.angularY = math.sin(i * 0.7) * 4     -- mouse flicks spin the root
	update(FRAME)
	peak = math.max(peak, math.abs(torso()[2]))
end
check("torso does not roll with the camera", deg(peak) < 0.01,
	("peak roll %.3f deg"):format(deg(peak)))

print("\nstrafing right at walk speed")
reset()
world.moveDirection = { X = 1, Y = 0, Z = 0 }
world.velocity = { X = 16, Y = 0, Z = 0 }
step(120)
check("torso yaws into the strafe", math.abs(deg(torso()[3]) + 35) < 0.5,
	("yaw %.2f deg, want -35"):format(deg(torso()[3])))
check("torso rolls away from the strafe", math.abs(deg(torso()[2]) + 5) < 0.5,
	("roll %.2f deg, want -5"):format(deg(torso()[2])))

print("\nrunning forward")
reset()
world.walkSpeed = 28
world.moveDirection = { X = 0, Y = 0, Z = -1 }
world.velocity = { X = 0, Y = 0, Z = -28 }
step(120)
check("torso pitches forward", math.abs(deg(torso()[1]) - 7) < 0.5,
	("pitch %.2f deg, want 7"):format(deg(torso()[1])))

print("\nbanking through a turn while running")
reset()
world.walkSpeed = 28
world.moveDirection = { X = 0, Y = 0, Z = -1 }
world.velocity = { X = 0, Y = 0, Z = -28 }
world.angularY = 6
step(120)
check("banks into the turn", deg(torso()[2]) > 6,
	("roll %.2f deg, want > 6"):format(deg(torso()[2])))

print("\ncutscene: character anchored mid-strafe and CFramed about")
reset()
world.moveDirection = { X = 1, Y = 0, Z = 0 }
world.velocity = { X = 16, Y = 0, Z = 0 }
step(120)
check("leaning before the cutscene", math.abs(deg(torso()[3])) > 30)

world.anchored = true
world.velocity = { X = 400, Y = 120, Z = -300 }   -- what a PivotTo looks like
world.angularY = 25
step(120)
check("pose returns to neutral", torso()[1] == 0 and torso()[2] == 0 and torso()[3] == 0,
	("pitch %.3f roll %.3f yaw %.3f deg"):format(deg(torso()[1]), deg(torso()[2]), deg(torso()[3])))
before = writes.count
step(120)
check("joints handed back to the animator", writes.count == before,
	("%d writes over 120 anchored frames"):format(writes.count - before))

print("\nragdoll: motors disabled")
reset()
world.moveDirection = { X = 1, Y = 0, Z = 0 }
world.velocity = { X = 16, Y = 0, Z = 0 }
step(120)
world.enabled = false
step(120)
before = writes.count
step(120)
check("stops writing to disabled motors", writes.count == before,
	("%d writes"):format(writes.count - before))
world.enabled = true

print("\nslowed to a crawl by a stun, still drifting")
reset()
world.walkSpeed = 1
world.velocity = { X = 0, Y = 0, Z = -3 }
step(120)
check("drift does not become a full-tilt lean", math.abs(deg(torso()[1])) < 3,
	("pitch %.2f deg"):format(deg(torso()[1])))

print(("\n%s"):format(failures == 0 and "all checks passed" or (failures .. " FAILED")))
if failures > 0 then error("lean checks failed", 0) end
