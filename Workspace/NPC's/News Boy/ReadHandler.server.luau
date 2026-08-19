local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LuaPlayerList = require( ServerScriptService.Scripts.Game.Modules.LuaPlayerList )

local JobModule = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local PaperAnimations = {}

local function StopReading(Player)
	if PaperAnimations[Player] then
		PaperAnimations[Player]:Stop()
		PaperAnimations[Player]:Destroy()

		PaperAnimations[Player] = nil
	end

	if Player.Character:FindFirstChild("OpenedPaper") then
		Player.Character.OpenedPaper:Destroy()
	end
end

--ReplicatedStorage.Assets.Remotes.NPCs.ReadPaper.OnServerEvent:Connect(function(Player, Reading)
--	if Reading then
--		if PaperAnimations[Player] then return end
		
--		local Chance = math.random(1, 50)
--		local Anim = ((Chance == 1) and script.Rare) or script.Normal

--		local ReadPaper : AnimationTrack = Player.Character.Humanoid.Animator:LoadAnimation(Anim)
--		ReadPaper:Play()

--		local Paper = ServerStorage.NPCs.OpenedPaper:Clone()
--		Paper.Weld.Part0 = Player.Character["Right Arm"]
--		Paper.Parent = Player.Character

--		PaperAnimations[Player] = ReadPaper
--		local LuaPlayer = LuaPlayerList.LuaPlayers[Player]
		
--		local Job = JobModule.new()
--		LuaPlayer.Character.Combat:DivideSpeed(100)
		
--		Job:Task(function()
--			LuaPlayer.Character.Combat:TimesSpeed(100)
--		end)
		
--		Job:Task(ReadPaper.Ended:Connect(function()
--			Job:Destroy()
--		end))
		
--		Job:Task(LuaPlayer.Character.Combat.OnStateChanged:Once(function(State : string, Value : boolean)
--			Job:Destroy()
--			StopReading(Player)
--		end))
--	else
--		StopReading(Player)
--	end
--end)
