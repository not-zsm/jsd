local Handler = {}

function Handler.RigSpirit(Character : Model)
	local Spirit = script.AnubisSpirit:Clone()
	
	local Join = Spirit.Join
	Join.Part0 = Character.HumanoidRootPart
	
	Spirit.Parent = workspace.Visuals
	
	return Spirit
end	

return Handler
