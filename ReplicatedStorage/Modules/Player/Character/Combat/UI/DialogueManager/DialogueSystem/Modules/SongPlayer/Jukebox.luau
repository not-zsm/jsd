-- Jukebox.lua
-- Usage:
-- local JukeboxModule = require(path.to.Jukebox)
-- local MyJukebox = JukeboxModule.new(Gui, SongsDictionary, InitialQueueOptional)

local SoundService = game:GetService("SoundService")

local Jukebox = {}
Jukebox.__index = Jukebox

-- SongsDictionary example:
-- local Songs = {
--     [93627896158306] = { Name = "Blood Sonata", Artist = "BruhSalino", Thumbnail = "rbxassetid://91022825452126" },
--     [129531185875612] = { Name = "Heart Sever", Artist = "BruhSalino", Thumbnail = "rbxassetid://104051088993338" },
-- }

-- Helper: Fisher Yates shuffle (in-place)
local function ShuffleRange(Array, StartIndex)
	StartIndex = StartIndex or 1
	for I = #Array, StartIndex + 1, -1 do
		local J = math.random(StartIndex, I)
		Array[I], Array[J] = Array[J], Array[I]
	end
end

function Jukebox.new(Gui, Songs, InitialQueue)
	assert(type(Songs) == "table", "Songs table is required")

	local self = setmetatable({}, Jukebox)

	-- Public properties (capitalized)
	self.Gui = Gui
	self.Songs = Songs

	-- Internal state
	self.Queue = {}
	self.History = {}
	self.Current = nil -- Current SongId
	self.State = "Stopped" -- "Playing", "Paused", "Stopped"
	self.Sound = Instance.new("Sound")
	self.Sound.Parent = SoundService
	self.Sound.Looped = false
	self.Sound.Volume = 1
	self.EndedConnection = nil

	-- Build initial queue:
	if type(InitialQueue) == "table" and #InitialQueue > 0 then
		-- Validate initial queue members are present in Songs
		for _, SongId in ipairs(InitialQueue) do
			if self.Songs[SongId] then
				table.insert(self.Queue, SongId)
			end
		end
	else
		-- Build queue from Songs keys (order is iteration order)
		for SongId, _ in pairs(self.Songs) do
			table.insert(self.Queue, SongId)
		end
	end

	-- Ensure random seed for shuffle
	math.randomseed(tick() + os.time())

	-- Bind Ended event
	self.EndedConnection = self.Sound.Ended:Connect(function()
		-- When a song ends: place it at the end of the queue and play the next one
		self:_OnSongEnded()
	end)

	return self
end

-- Private: Update GUI with the provided SongId
function Jukebox:_UpdateGui(SongId)
	local Success, Err = pcall(function()
		if not self.Gui or not self.Gui:FindFirstChild("Holder") then
			return
		end

		local Holder = self.Gui.Holder
		local SongInfo = self.Songs[SongId]

		if SongInfo then
			if Holder:FindFirstChild("Cover") and Holder.Cover:IsA("ImageLabel") then
				Holder.Cover.Image = SongInfo.Thumbnail or ""
			end
			if Holder:FindFirstChild("SongName") and Holder.SongName:IsA("TextLabel") then
				Holder.SongName.Text = SongInfo.Name or ""
			end
			if Holder:FindFirstChild("Artist") and Holder.Artist:IsA("TextLabel") then
				Holder.Artist.Text = SongInfo.Artist or ""
			end
		else
			-- Clear GUI if SongInfo not found
			if Holder:FindFirstChild("Cover") and Holder.Cover:IsA("ImageLabel") then
				Holder.Cover.Image = ""
			end
			if Holder:FindFirstChild("SongName") and Holder.SongName:IsA("TextLabel") then
				Holder.SongName.Text = ""
			end
			if Holder:FindFirstChild("Artist") and Holder.Artist:IsA("TextLabel") then
				Holder.Artist.Text = ""
			end
		end
	end)
	if not Success then
		warn("Jukebox: Failed to update GUI -", Err)
	end
end

-- Private: internal play by SongId. AddToHistory controls whether to push previous current into History.
function Jukebox:_PlayById(SongId, AddToHistory)
	if not SongId then return false end
	if not self.Songs[SongId] then
		warn("Jukebox: SongId not found in Songs table:", SongId)
		return false
	end

	-- Push previous current to History if necessary
	if AddToHistory ~= false and self.Current and self.Current ~= SongId then
		table.insert(self.History, self.Current)
	end

	-- Set current
	self.Current = SongId

	-- Ensure current is at front of queue (if present elsewhere, remove it and put front)
	for I = #self.Queue, 1, -1 do
		if self.Queue[I] == SongId then
			table.remove(self.Queue, I)
			break
		end
	end
	table.insert(self.Queue, 1, SongId)

	-- Configure Sound
	self.Sound:Stop()
	self.Sound.SoundId = "rbxassetid://" .. tostring(SongId)
	-- Small wait to allow Roblox to load the SoundId if necessary (not yieldy, quick)
	-- Play
	local Success, Err = pcall(function()
		self.Sound:Play()
		self.State = "Playing"
		self:_UpdateGui(SongId)
	end)
	if not Success then
		warn("Jukebox: Failed to Play sound -", Err)
		return false
	end

	return true
end

-- Private: play the first item in the queue; AddToHistory controls whether to push previous current into History.
function Jukebox:_PlayFirstInQueue(AddToHistory)
	if #self.Queue == 0 then
		self.Current = nil
		self.State = "Stopped"
		self:_UpdateGui(nil)
		return false
	end
	local NextId = self.Queue[1]
	return self:_PlayById(NextId, AddToHistory)
end

-- Private: called when Sound.Ended fires
function Jukebox:_OnSongEnded()
	local PrevId = self.Current
	if PrevId then
		-- push prev into history
		table.insert(self.History, PrevId)

		-- move prev from front to end if it's at front
		if self.Queue[1] == PrevId then
			table.remove(self.Queue, 1)
			table.insert(self.Queue, PrevId)
		end
	end

	-- Play next (do not add this automatic change to history again)
	if #self.Queue > 0 then
		-- If queue became empty for some reason
		self:_PlayFirstInQueue(false)
	else
		self.Current = nil
		self.State = "Stopped"
		self:_UpdateGui(nil)
	end
end

-- Public: Play(SongId or TableIndex)
function Jukebox:Play(Identifier)
	-- Identifier can be:
	-- 1) a SongId (key in Songs)
	-- 2) a numeric index into the Queue (1..#Queue)
	local SongId = nil

	if type(Identifier) == "number" then
		-- Prefer treat as index if within queue; otherwise treat as SongId if present in Songs
		if Identifier >= 1 and Identifier <= #self.Queue then
			SongId = self.Queue[Identifier]
		end
		if not SongId and self.Songs[Identifier] then
			SongId = Identifier
		end
	elseif type(Identifier) == "string" then
		local Num = tonumber(Identifier)
		if Num and self.Songs[Num] then
			SongId = Num
		end
	end

	-- If no identifier given, just attempt to play first in queue
	if not SongId then
		if Identifier == nil then
			return self:_PlayFirstInQueue(true)
		end
		warn("Jukebox: Play - invalid Identifier:", Identifier)
		return false
	end

	return self:_PlayById(SongId, true)
end

function Jukebox:Pause()
	if self.Sound and self.State == "Playing" then
		self.PausedTime = self.Sound.TimePosition
		self.Sound:Pause()
		self.State = "Paused"
		return true
	end
	return false
end

function Jukebox:Resume()
	if self.Sound and self.State == "Paused" then
		-- Restore last saved position
		if self.PausedTime then
			self.Sound.TimePosition = self.PausedTime
		end
		self.Sound:Play()
		self.State = "Playing"
		self.PausedTime = nil
		return true
	end
	return false
end
function Jukebox:Destroy()
	if self.EndedConnection then
		self.EndedConnection:Disconnect()
		self.EndedConnection = nil
	end
	if self.Sound then
		self.Sound:Stop()
		self.Sound:Destroy()
		self.Sound = nil
	end
	-- Clear state
	self.Queue = {}
	self.History = {}
	self.Current = nil
	self.State = "Destroyed"
	-- Clear GUI
	pcall(function()
		if self.Gui and self.Gui:FindFirstChild("Holder") then
			local Holder = self.Gui.Holder
			if Holder:FindFirstChild("Cover") then Holder.Cover.Image = "" end
			if Holder:FindFirstChild("SongName") then Holder.SongName.Text = "" end
			if Holder:FindFirstChild("Artist") then Holder.Artist.Text = "" end
		end
	end)
	return true
end

function Jukebox:Next()
	if not self.Current then
		return self:_PlayFirstInQueue(true)
	end

	local PrevId = self.Current

	-- push to history
	table.insert(self.History, PrevId)

	-- move current (front) to end if present
	if #self.Queue > 0 and self.Queue[1] == PrevId then
		table.remove(self.Queue, 1)
		table.insert(self.Queue, PrevId)
	end

	-- Play next (do not duplicate history)
	return self:_PlayFirstInQueue(false)
end

function Jukebox:Previous()
	if #self.History == 0 then
		warn("Jukebox: No previous song in history")
		return false
	end

	local PrevId = table.remove(self.History) -- last played
	if not PrevId then return false end

	-- Stop current and play PrevId (do not add current into history again)
	if self.Sound then
		self.Sound:Stop()
	end

	-- Ensure PrevId exists in Songs
	if not self.Songs[PrevId] then
		warn("Jukebox: Previous song removed from Songs table:", PrevId)
		return false
	end

	return self:_PlayById(PrevId, false)
end

-- Shuffle queue - keep currently playing song position unchanged.
function Jukebox:Shuffle()
	if #self.Queue <= 1 then return end

	-- Ensure current is at index 1; if not present move it to 1 temporarily so it won't be shuffled
	local CurrentId = self.Current
	local KeepIndex = 1
	if CurrentId then
		-- Remove any occurrence of current from queue and insert at front
		for I = #self.Queue, 1, -1 do
			if self.Queue[I] == CurrentId then
				table.remove(self.Queue, I)
				break
			end
		end
		table.insert(self.Queue, 1, CurrentId)
		KeepIndex = 2 -- shuffle from 2..n (leave index 1 intact)
	else
		KeepIndex = 1 -- shuffle entire queue if nothing is playing
	end

	ShuffleRange(self.Queue, KeepIndex)
	return true
end

function Jukebox:GetState()
	return self.State
end

-- Optionally: expose a method to get the queue copy
function Jukebox:GetQueue()
	local Copy = {}
	for I, V in ipairs(self.Queue) do
		Copy[I] = V
	end
	return Copy
end

-- Optionally: set sound volume
function Jukebox:SetVolume(Amount)
	if self.Sound then
		self.Sound.Volume = Amount
		return true
	end
	return false
end

return Jukebox
