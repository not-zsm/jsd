local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MaidModule = require( ReplicatedStorage.Packages.Maid )

return function()
	local Maid = MaidModule.new()
	
	local MusicPlayer = Maid:add(script.MusicPlayer:Clone())
	MusicPlayer.Parent = game:GetService("Players").LocalPlayer.PlayerGui
	MusicPlayer.Enabled = true
	
	local Holder = MusicPlayer.Holder
	local Artist = Holder.Artist
	local SongName = Holder.SongName
	local Cover = Holder.Cover
	
	local OptionsFrame = Holder.Options
	local Topbar = Holder.TopBar
	
	Maid:add(Topbar.Close.MouseButton1Click:Connect(function()
		Maid:destroy()
	end))
	
	local SongTable = require( script.Songs )
	
	local Jukebox = require(script.Jukebox)
	local SongPlayer = Jukebox.new(MusicPlayer, SongTable)
	SongPlayer:Play()
	OptionsFrame.Play:SetAttribute("Playing", true)
	
	Maid:add(function()
		SongPlayer:Destroy()
	end)
	
	local function ChangePlayStatus(Playing : Bolean)
		OptionsFrame.Play.Resume.Visible = not Playing
		OptionsFrame.Play.Pause.Visible = Playing
	end
	
	Maid:add(OptionsFrame.Play.MouseButton1Click:Connect(function()
		if SongPlayer:GetState() == "Playing" then
			SongPlayer:Pause()
			ChangePlayStatus(false)
		else
			SongPlayer:Resume()
			ChangePlayStatus(true)
		end
	end))
	
	Maid:add(OptionsFrame.Next.MouseButton1Click:Connect(function()
		SongPlayer:Next()
		ChangePlayStatus(true)
	end))
	
	Maid:add(OptionsFrame.Previous.MouseButton1Click:Connect(function()
		SongPlayer:Previous()
		ChangePlayStatus(true)
	end))
end