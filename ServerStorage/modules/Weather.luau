local ServerScriptService = game:GetService("ServerScriptService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local network = require( replicatedStorage.modules.network )
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ServerStorage = game:GetService("ServerStorage")
local Remotes = replicatedStorage.Remotes


local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )
local Hitbox = require( replicatedStorage.modules.shared.Game.Hitbox.Type.Box )

local LuaPlayerList = require( ServerStorage.modules.LuaPlayerList )

-- Temporarily off. Flip this back to true to restore the random cycle; the
-- /smite command and Weather.Rain still work either way, and so does the
-- thunder that follows the Rain attribute however it gets set.
local RANDOM_WEATHER = false

local Weather = {}
local ThunderThread = nil

workspace:GetAttributeChangedSignal("Rain"):Connect(function()
	local Value = workspace:GetAttribute("Rain")
	
	if Value then
		ThunderThread = coroutine.create(function()
			while true do
				if math.random(1, 50) == 1 then
					Weather.SmiteAtRandomPosition()
				end

				task.wait(0.2)
			end
		end)

		coroutine.resume(ThunderThread)
	else
		if (ThunderThread ~= nil and coroutine.status(ThunderThread) == "suspended") then
			coroutine.close(ThunderThread)
		end
	end
end)

function Weather.Rain()
	workspace:SetAttribute("Rain", true)

	task.wait(Utility.Seed:NextNumber(60, 120))

	workspace:SetAttribute("Rain", false)
end

function Weather.Smite(Position : Vector3)
	local Raycast = workspace:Raycast(Position, Vector3.yAxis * -225, Utility.VisualParams)
	if (Raycast == nil) then return end
	
	network.vfxReliable.sendToAll({
		directory = "Global/Lightning",
		fn = "Strike",
		args = table.pack(Raycast.Position, Raycast.Instance.Color),
	})
	
	local Params = Hitbox.NewParams()
	Params.Offset = CFrame.new(0, 3, 0)
	Params.Size = Vector3.new(50, 10, 50)

	local Hitbox = Hitbox.new(CFrame.new(Raycast.Position), Params)

	Hitbox.Events.HumanoidHit:Connect(function(Humanoid : Humanoid)
		local Model : Model = Humanoid.Parent
		local Player = Players:GetPlayerFromCharacter(Model) or Model

		local VictimLuaPlayer = LuaPlayerList.LuaPlayers[Player]
		if (VictimLuaPlayer == nil) then return end
		
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat
		
		if VictimCombat:GetState("HitboxImmunity") then return end
		
		VictimLuaCharacter.Humanoid:TakeDamage(15)
		
		local VelocityObject = VictimCombat:Velocity()
		VelocityObject.Settings.RemoveTime = 0.025
		VelocityObject.Settings.Velocity = Vector3.yAxis * 150
		VelocityObject:Fire()

		VictimCombat.Ragdoll:Toggle(true, 4)
		
		VictimCombat:ImpactOnGroundHit()
	end)
	
	Hitbox:Detect()
	task.defer(Hitbox.Destroy, Hitbox)
end

function Weather.SmiteAtRandomPosition()
	local x = Utility.Seed:NextNumber(-300, 300)
	local z = Utility.Seed:NextNumber(-300, 300)

	Weather.Smite(CFrame.new(x, 200, z).Position)
end

if RANDOM_WEATHER then
	task.spawn(function()
		if (math.random(1, 5) == 1) then
			Weather.Rain()
		end

		while true do
			if (math.random(1, 500) == 1) then
				Weather.Rain()
			end

			task.wait(1)
		end
	end)
end

return Weather
