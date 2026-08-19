local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local RemoteRateLimiter = require( ServerScriptService.Scripts.Game.Modules.Utility.RemoteRateLimiter )

local EventService = require( ReplicatedStorage.Modules.Shared.Utilities.EventService )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local function ToMinutes(Value : number)
	return Value * 60
end

local CharaSpawner = {}
CharaSpawner.SpawnCF = workspace.Terrain["Chara_Spawn"].WorldCFrame :: CFrame
CharaSpawner.OnSpawned = EventService.new(true)
CharaSpawner.OnDespawned = EventService.new(true)
CharaSpawner.CurrentChara = nil :: Model?
CharaSpawner.TimerThread = nil :: thread?
CharaSpawner.CharaJob = Job.new()
CharaSpawner.Spawned = false

function CharaSpawner.Spawn(StartCF : CFrame)
	if CharaSpawner.Spawned then return end
	
	task.defer(CharaSpawner.StopTimer)

	CharaSpawner.Spawned = true
	CharaSpawner.OnSpawned:Fire()

	local Chara = script.Chara:Clone()
	Chara:PivotTo(StartCF)
	Chara.Parent = workspace.Models
	
	Chara.Animate.Enabled = true
	Chara:AddTag("NPC")

	CharaSpawner.CharaJob:Task(Chara.AncestryChanged:Connect(function(_, Parent)
		if (Parent == nil) then
			CharaSpawner.Despawn()
		end
	end))
	
	CharaSpawner.CharaJob:Task(Chara.PrimaryPart.AncestryChanged:Connect(function(_, Parent)
		if (Parent == nil) then
			CharaSpawner.Despawn()
		end
	end))

	CharaSpawner.CurrentChara = Chara
end

function CharaSpawner.Despawn()
	if not CharaSpawner.Spawned then return end
	
	CharaSpawner.CharaJob:Clean()
	CharaSpawner.OnDespawned:Fire()
	
	if CharaSpawner.CurrentChara then
		CharaSpawner.CurrentChara:Destroy()
	end
	
	CharaSpawner.CurrentChara = nil
	CharaSpawner.Spawned = false

	task.defer(CharaSpawner.StartTimer)
end

local MinutesUntilSpawn = 17.5
local RNG = 2

print("chara mins until spawn:", MinutesUntilSpawn)
print("chara rng: 1 in", RNG)

--local IsTestPlace = RunService:IsStudio() or game.PlaceId == 95576587700882

--if IsTestPlace then
--	MinutesUntilSpawn = 1
--end

function CharaSpawner.StartTimer()
	if (CharaSpawner.TimerThread ~= nil) then return end

	CharaSpawner.TimerThread = task.spawn(function()
		while RunService:IsRunning() do

			task.wait(ToMinutes(MinutesUntilSpawn))

			if (RNG == 1) then
				task.defer(CharaSpawner.Spawn, CharaSpawner.SpawnCF)
			else
				if (math.random(1, RNG) == 1) then
					task.defer(CharaSpawner.Spawn, CharaSpawner.SpawnCF)
				end
			end
			
			--if IsTestPlace or math.random(1, 2) == 1 then
			--	task.defer(CharaSpawner.Spawn, CharaSpawner.SpawnCF)
			--end
		end
	end)
end

function CharaSpawner.StopTimer()
	Utility.CloseThreadSafe(CharaSpawner.TimerThread)
	CharaSpawner.TimerThread = nil
end

function CharaSpawner.SafeToSpawn()
	return (not workspace:GetAttribute("DisableBosses") and not CharaSpawner.Spawned and CharaSpawner.TimerThread ~= nil)
end

CharaSpawner.StartTimer()

ReplicatedStorage.Remotes.SpawnCharaBoss.OnServerEvent:Connect(function(Player)
	if (RemoteRateLimiter.Check(ReplicatedStorage.Remotes.SpawnCharaBoss, Player, 5) == false) then
		return
	end

	if CharaSpawner.SafeToSpawn() then
		Player:SetAttribute("CannotUseCommands", true)
		MarketplaceService:PromptProductPurchase(Player, 3348046631)
	else
		ReplicatedStorage.Remotes.Notification:FireClient(Player, {
			Title = "Error", 
			Text = CharaSpawner.Spawned and "You cannot spawn chara because it is already spawned." or "You cannot spawn chara because you used commands.", 
			Icon = "rbxassetid://112856803225144",
			Duration = 5
		})
	end
end)

task.spawn(function()
	local MessagingService = game:GetService("MessagingService")

	local Success, Result = pcall(function()
		return MessagingService:SubscribeAsync("SpawnChara", function()
			if not CharaSpawner.SafeToSpawn() then
				return
			end
			
			task.defer(CharaSpawner.Spawn, CharaSpawner.SpawnCF)
		end)
	end)
	
	if not Success then
		warn(Result)
	end
end)

return CharaSpawner
