local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local CameraShaker = {}
CameraShaker.__index = CameraShaker

local CameraShakeInstance = require(script.Instance)
local CameraShakeState = CameraShakeInstance.CameraShakeState

local defaultPosInfluence = Vector3.one * 0.8
local defaultRotInfluence = Vector3.zero

CameraShaker.CameraShakeInstance = CameraShakeInstance

local function AdjustValueWithSetting(Value : number)
	if Player:GetAttribute("Camera_Shake") then
		return (Value * (Player:GetAttribute("Camera_Shake") / 100))
	end

	return Value
end

function CameraShaker.new(RenderPriority : number, Callback : () -> (number))
	assert(type(RenderPriority) == "number", "RenderPriority must be a number")
	assert(type(Callback) == "function", "Callback must be a function")

	return setmetatable({
		_Running = false,
		_RenderName = "CameraShaker",
		_RenderPriority = RenderPriority,
		_CamShakeInstances = {},
		_RemoveInstances = {},
		_Callback = Callback,
	}, CameraShaker)
end


function CameraShaker:Start()
	if self._Running then return end
	self._Running = true

	local callback = self._Callback

	RunService:BindToRenderStep(self._RenderName, self._RenderPriority, function(Delta)
		callback(self:Update(Delta))
	end)
end


function CameraShaker:Stop()
	if not self._Running then return end

	RunService:UnbindFromRenderStep(self._RenderName)
	self._running = false
end


function CameraShaker:Update(Delta)
	local PosAddShake = Vector3.zero
	local RotAddShake = Vector3.zero

	local Instances = self._CamShakeInstances

	-- Update all instances:
	for Index = 1, #Instances do

		local Shake : typeof(CameraShakeInstance.new()) = Instances[Index]
		local State = Shake:GetState()

		if (State == CameraShakeState.Inactive and Shake.DeleteOnInactive) then
			self._RemoveInstances[#self._RemoveInstances + 1] = Index

		elseif (State ~= CameraShakeState.Inactive) then
			local ShakeVector = Shake:UpdateShake(Delta)
			PosAddShake += (ShakeVector * Shake.PositionInfluence)
			RotAddShake += (ShakeVector * Shake.RotationInfluence)
		end

	end

	-- Remove dead instances:
	for Index = #self._RemoveInstances, 1, -1 do
		local instIndex = self._RemoveInstances[Index]
		table.remove(Instances, instIndex)
		self._RemoveInstances[Index] = nil
	end

	return CFrame.new(PosAddShake) * CFrame.Angles(
		math.rad(RotAddShake.X), 
		math.rad(RotAddShake.Y), 
		math.rad(RotAddShake.Z)
	)
end

function CameraShaker:Fire(magnitude, roughness, fadeInTime, fadeOutTime, posInfluence, rotInfluence)
	magnitude = AdjustValueWithSetting(magnitude)

	local NewShakeInstance = CameraShakeInstance.new(magnitude, roughness, fadeInTime, fadeOutTime)
	NewShakeInstance.PositionInfluence = (typeof(posInfluence) == "Vector3" and posInfluence or defaultPosInfluence)
	NewShakeInstance.RotationInfluence = (typeof(rotInfluence) == "Vector3" and rotInfluence or defaultRotInfluence)

	self._CamShakeInstances[#self._CamShakeInstances + 1] = NewShakeInstance

	return NewShakeInstance
end

return CameraShaker