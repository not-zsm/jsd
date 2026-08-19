--// MusicManager.lua
local SoundService = game:GetService("SoundService")

local MusicManager = {}
MusicManager.MusicList = {
	"rbxassetid://108378871461558", -- Neon Lullaby
	"rbxassetid://94460987417197", -- Blessed Tinnitus
}

MusicManager.CurrentIndex = 1
MusicManager.CurrentSound = nil
MusicManager.Playing = false

--// Plays the current song
function MusicManager:PlayCurrent()
	if self.CurrentSound then
		self.CurrentSound:Destroy()
	end

	local Sound = Instance.new("Sound")
	Sound.Name = "ArcadeMusic"
	Sound.SoundId = self.MusicList[self.CurrentIndex]
	Sound.Volume = 0.35
	Sound.Looped = false
	Sound:SetAttribute("SoundGroup", "Environment")
	Sound:AddTag("UpdateSoundGroup")
	Sound.Parent = SoundService

	self.CurrentSound = Sound
	self.Playing = true
	Sound:Play()

	-- When the song finishes, go to next
	Sound.Ended:Connect(function()
		self:Next()
	end)
end

--// Plays the next song in the queue
function MusicManager:Next()
	self.CurrentIndex += 1
	if self.CurrentIndex > #self.MusicList then
		self.CurrentIndex = 1 -- Loop back to start
	end
	self:PlayCurrent()
end

--// Start playing the playlist
function MusicManager:Start()
	if self.Playing then return end
	self.CurrentIndex = math.random(1, #self.MusicList)
	self:PlayCurrent()
end

--// Stop the current song
function MusicManager:Stop()
	if self.CurrentSound then
		self.CurrentSound:Stop()
		self.CurrentSound:Destroy()
		self.CurrentSound = nil
	end
	self.Playing = false
end

return MusicManager
