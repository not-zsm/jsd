local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Utility = require( ReplicatedStorage.modules.shared.Utilities.Utility )

return {
	["Invincible_Ultimate"] = function(self)
		self.LuaCharacter.Humanoid:SetAttribute("LockShiftlockCFrame", true)
		
		local Gyro = Instance.new("BodyGyro")
		Gyro.MaxTorque = Vector3.one * 400000
		Gyro.D = 100
		Gyro.P = 5000

		local function Update()
			local Position : Vector3 = self.LuaCharacter.RootPart.Position
			local LookAt : Vector3 = self.LuaPlayer.Mouse.Hit.LookVector

			Gyro.CFrame = CFrame.lookAlong(Position, LookAt)
		end

		Update()
		RunService:BindToRenderStep("AimToMouseGyroUpdate", Utility.CharacterRenderPriority, Update)

		Gyro.Destroying:Once(function()
			RunService:UnbindFromRenderStep("AimToMouseGyroUpdate")
			self.LuaCharacter.Humanoid:SetAttribute("LockShiftlockCFrame", false)
		end)

		Gyro.Parent = self.LuaCharacter.RootPart
		
		return Gyro
	end,
}