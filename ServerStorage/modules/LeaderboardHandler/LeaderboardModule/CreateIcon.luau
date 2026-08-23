-- Change the icon template below to your liking
return function(name: string, value : string, rank: number, thumbnail: string)
	local playerFrame = script.Template:Clone()

	playerFrame.Name = name
	playerFrame.PlayerName.Text = `@{name}`
	
	playerFrame.Rank.Text = `#{rank}`
	playerFrame.LayoutOrder = rank
	
	playerFrame.Value.Text = value
	
	if thumbnail then
		playerFrame.Icon.Image = thumbnail
	end

	
	return playerFrame
end