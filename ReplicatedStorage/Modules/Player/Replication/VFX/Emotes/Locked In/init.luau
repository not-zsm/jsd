local Graphics = require( script.Graphics )

local VFX = {}
local Currents = setmetatable({}, {__mode = "k"})

function VFX.Start(Player : Player)
	if not Player or Player.Parent == nil then return end
	
	VFX.Remove(Player)
	
	local Character = Player:IsA("Player") and Player.Character or Player;
	local Humanoid = Character:WaitForChild("Humanoid") :: Humanoid;
	local RootPart = Character:WaitForChild("HumanoidRootPart") :: BasePart;
	
	local Graphic = script.Graphic:Clone();
	Graphic.Parent = RootPart;
	Graphics.play(Graphic);
	
	Currents[Player] = Graphic
end

function VFX.Remove(Player : Player)
	if Currents[Player] then
		Currents[Player]:Destroy()
		Currents[Player] = nil
	end
end

return VFX
