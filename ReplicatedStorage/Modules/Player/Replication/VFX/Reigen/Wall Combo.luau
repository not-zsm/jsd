local VFX = {}
local Coins = {}

function VFX.SmackToWall(RootPart : BasePart)
	
end
	
function VFX.Coin(Model : Model, Value : string)
	if (Model ~= nil and Model.Parent ~= nil) then
		if (Value == "true" and Coins[Model] == nil) then
			local Coin = script.Coin:Clone()
			Coin.Weld.Part0 = Model["Right Arm"]
			Coin.Parent = Model

			Coins[Model] = Coin
			
		elseif (Value == "false" and Coins[Model] ~= nil) then
			Coins[Model]:Destroy()
			Coins[Model] = nil
		end
	end
end

return VFX
