local replicatedStorage = game:GetService("ReplicatedStorage")

local RockHandler = require( replicatedStorage.modules.client.replication.Global.RockHandler )

return {
	["Purple"] = function(Origin : Vector3, Direction : Vector3)
		local CF = CFrame.lookAlong(Origin, Direction)
		
		local Purple = script.Purple:Clone()
		Purple.CFrame = CF
		Purple.Parent = workspace.Visuals
		
		Purple.Sound:Play()
		
		local Thread = coroutine.create(function()
			while Purple.Parent ~= nil do
				RockHandler.Rocks("Purple", Purple)
				RockHandler.Rockst(Purple.Position, Vector3.yAxis * -35, {Count = 1, Size = {1.25, 1.75}, Velocity = 50})
				
				task.wait(0.01)
			end
		end)
		
		coroutine.resume(Thread)
		
		Purple.Destroying:Connect(function()
			coroutine.close(Thread)
		end)
		
		return Purple, CF
	end,
	
	["Raygun"] = function(Origin : Vector3, Direction : Vector3, Upgraded : Bolean)
		local CF = CFrame.lookAlong(Origin, Direction)

		local Bullet = if not Upgraded then script.GreenBullet:Clone() else script.RedBullet:Clone()
		Bullet.CFrame = CF
		Bullet.Parent = workspace.Visuals

		return Bullet, CF
	end,
}