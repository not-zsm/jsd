-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local Constants = require(script.Parent.Constants)
local Units = require(script.Parent.Units)
local lerp = math.lerp
local Parent = script.Parent.Parent
local Chassis = Parent:FindFirstChild("Chassis")
if Chassis == nil then
	return
else
	local Inputs = Parent.Inputs
	local Engine = Parent.Engine
	local Steering = Parent.Steering
	local Wheels = Parent:FindFirstChild("Wheels")
	if Wheels == nil then
		return
	elseif Wheels:FindFirstChild("WheelFR") ~= nil then
		local t = {
			Wheels.WheelFR:FindFirstChild("Wheel"),
			Wheels.WheelFL:FindFirstChild("Wheel"),
			Wheels.WheelRR:FindFirstChild("Wheel"),
			(Wheels.WheelRL:FindFirstChild("Wheel"))
		}
		if t[1] ~= nil then
			local t2 = {
				forwardMaxSpeed = 30,
				reverseMaxSpeed = 15,
				acceleration = 1,
				deceleration = 5,
				braking = 2,
				engineSpeedCorrection = 0,
				minSpeedTorque = 0,
				maxSpeedTorque = 0,
				handBrakeTorque = 0,
				nitroTorque = 0,
				nitroTime = 0,
				nitroRechargeTime = 0,
				nitroMaxSpeed = 0,
				nitroAcceleration = 100
			}
			local t3 = { steeringReduction = 0 }
			local t4 = {
				density = 0,
				elasticity = 0,
				staticFriction = 0,
				kineticFriction = 0,
				slipThreshold = 0
			}
			local v_u_1 = t[1].Size.Y / 2
			local function updateNitro(p2: number)
				--[[ line: 64 | upvalues: (copy) Inputs, (copy) Constants, (copy) Engine, (copy) t2]]
				local NITRO_INPUT_ATTRIBUTE = Inputs:GetAttribute(Constants.NITRO_INPUT_ATTRIBUTE)
				local ENGINE_NITRO_ATTRIBUTE = Engine:GetAttribute(Constants.ENGINE_NITRO_ATTRIBUTE)
				if NITRO_INPUT_ATTRIBUTE then
					NITRO_INPUT_ATTRIBUTE = ENGINE_NITRO_ATTRIBUTE > 0
				end
				local v3
				if NITRO_INPUT_ATTRIBUTE then
					local v4 = ENGINE_NITRO_ATTRIBUTE - 1 / t2.nitroTime * p2
					v3 = math.max(v4, 0)
					if v3 == 0 then
						Inputs:SetAttribute(Constants.NITRO_INPUT_ATTRIBUTE, false)
					end
				else
					local v5 = ENGINE_NITRO_ATTRIBUTE + 1 / t2.nitroRechargeTime * p2
					v3 = math.min(v5, 1)
				end
				Engine:SetAttribute(Constants.ENGINE_NITRO_ATTRIBUTE, v3)
				Engine:SetAttribute(Constants.NITRO_ENABLED_ATTRIBUTE, NITRO_INPUT_ATTRIBUTE)
				Engine.NitroVelocity.Enabled = NITRO_INPUT_ATTRIBUTE
				local NitroVelocity = Engine.NitroVelocity
				local v6 = -t2.nitroMaxSpeed
				NitroVelocity.VectorVelocity = Vector3.new(0, 0, v6)
			end
			local function updateEngine(p7: number)
				--[[ line: 92 | upvalues: (copy) Inputs, (copy) Constants, (copy) Engine, (copy) t2, (copy) Chassis, (copy) Units, (copy) lerp, (copy) v_u_1]]
				local HAND_BRAKE_INPUT_ATTRIBUTE = Inputs:GetAttribute(Constants.HAND_BRAKE_INPUT_ATTRIBUTE)
				local THROTTLE_INPUT_ATTRIBUTE = Inputs:GetAttribute(Constants.THROTTLE_INPUT_ATTRIBUTE)
				local v8 = math.clamp(THROTTLE_INPUT_ATTRIBUTE, -1, 1)
				local v9 = math.sign(v8)
				local ENGINE_SPEED_ATTRIBUTE = Engine:GetAttribute(Constants.ENGINE_SPEED_ATTRIBUTE)
				local NITRO_ENABLED_ATTRIBUTE = Engine:GetAttribute(Constants.NITRO_ENABLED_ATTRIBUTE)
				local forwardMaxSpeed = t2.forwardMaxSpeed
				local reverseMaxSpeed = t2.reverseMaxSpeed
				local v10 = math.max(forwardMaxSpeed, reverseMaxSpeed)
				local v11
				if v9 >= 0 then
					v11 = t2.forwardMaxSpeed
				else
					v11 = t2.reverseMaxSpeed
				end
				local v12 = v8 * v11
				local AssemblyLinearVelocity = Chassis.CFrame:VectorToObjectSpace(Chassis.AssemblyLinearVelocity)
				local v13 = Units.studsPerSecondToMilesPerHour(-AssemblyLinearVelocity.Z)
				local v14
				if v9 == 0 or math.abs(v13) <= 1 then
					v14 = false
				else
					v14 = v9 ~= math.sign(v13)
				end
				local acceleration = t2.acceleration
				if NITRO_ENABLED_ATTRIBUTE then
					acceleration = t2.nitroAcceleration
					v12 = t2.nitroMaxSpeed
				elseif v14 then
					acceleration = t2.braking
					v12 = 0
				elseif math.abs(v12) < math.abs(ENGINE_SPEED_ATTRIBUTE) then
					acceleration = t2.deceleration
				end
				local v15 = p7 * t2.engineSpeedCorrection
				local v16 = lerp(ENGINE_SPEED_ATTRIBUTE, v13, (math.min(v15, 1)))
				local v17
				if v16 < v12 then
					local v18 = v16 + acceleration * p7
					v17 = math.min(v18, v12)
				else
					local v19 = v16 - acceleration * p7
					v17 = math.max(v19, v12)
				end
				Engine:SetAttribute(Constants.ENGINE_SPEED_ATTRIBUTE, v17)
				local AssemblyLinearVelocity2 = Chassis.CFrame:VectorToObjectSpace(Chassis.AssemblyLinearVelocity)
				local v20 = Units.studsPerSecondToMilesPerHour(-AssemblyLinearVelocity2.Z)
				local v21 = math.min(v20, v10) / v10
				local v22 = lerp(t2.minSpeedTorque, t2.maxSpeedTorque, v21)
				if NITRO_ENABLED_ATTRIBUTE then
					v22 = t2.nitroTorque
				end
				local v23 = Units.milesPerHourToStudsPerSecond(v17) / v_u_1
				Engine.WheelFRMotor.AngularVelocity = v23
				Engine.WheelFRMotor.MotorMaxTorque = v22
				Engine.WheelFLMotor.AngularVelocity = -v23
				Engine.WheelFLMotor.MotorMaxTorque = v22
				if HAND_BRAKE_INPUT_ATTRIBUTE then
					Engine.WheelRRMotor.AngularVelocity = 0
					Engine.WheelRRMotor.MotorMaxTorque = t2.handBrakeTorque
					Engine.WheelRLMotor.AngularVelocity = 0
					Engine.WheelRLMotor.MotorMaxTorque = t2.handBrakeTorque
				else
					Engine.WheelRRMotor.AngularVelocity = v23
					Engine.WheelRRMotor.MotorMaxTorque = v22
					Engine.WheelRLMotor.AngularVelocity = -v23
					Engine.WheelRLMotor.MotorMaxTorque = v22
				end
			end
			local function updateSteering()
				--[[ line: 162 | upvalues: (copy) Inputs, (copy) Constants, (copy) t2, (copy) Chassis, (copy) Units, (copy) t3, (copy) Steering]]
				local STEERING_INPUT_ATTRIBUTE = Inputs:GetAttribute(Constants.STEERING_INPUT_ATTRIBUTE)
				local v24 = math.clamp(STEERING_INPUT_ATTRIBUTE, -1, 1)
				local forwardMaxSpeed2 = t2.forwardMaxSpeed
				local reverseMaxSpeed2 = t2.reverseMaxSpeed
				local v25 = math.max(forwardMaxSpeed2, reverseMaxSpeed2)
				local AssemblyLinearVelocity3 = Chassis.CFrame:VectorToObjectSpace(Chassis.AssemblyLinearVelocity)
				local v26 = Units.studsPerSecondToMilesPerHour(-AssemblyLinearVelocity3.Z)
				local v27 = 1 - math.min(v26, v25) / v25 * t3.steeringReduction
				local v28 = v24 * math.max(v27, 0)
				if v28 > 0 then
					Steering.SteeringRack.TargetPosition = v28 * Steering.SteeringRack.LowerLimit
				else
					Steering.SteeringRack.TargetPosition = -v28 * Steering.SteeringRack.UpperLimit
				end
			end
			local function updateWheelFriction()
				--[[ line: 177 | upvalues: (copy) t, (copy) v_u_1, (copy) t4]]
				for _, v29 in ipairs(t) do
					if v29 ~= nil then
						local v30 = v29.AssemblyLinearVelocity.Magnitude - v_u_1 * v29.AssemblyAngularVelocity.Magnitude
						local v31
						if math.abs(v30) > t4.slipThreshold then
							v31 = t4.kineticFriction
						else
							v31 = t4.staticFriction
						end
						v29.CustomPhysicalProperties = PhysicalProperties.new(t4.density, v31, t4.elasticity)
					end
				end
			end
			local function initialize()
				--[[ line: 194 | upvalues: (copy) t2, (copy) Engine, (copy) t3, (copy) Steering, (copy) t4, (copy) Wheels]]
				for v_u_32 in t2 do
					Engine:GetAttributeChangedSignal(v_u_32):Connect(function()
						--[[ line: 198 | upvalues: (ref) t2, (copy) v_u_32, (ref) Engine]]
						t2[v_u_32] = Engine:GetAttribute(v_u_32)
					end)
					t2[v_u_32] = Engine:GetAttribute(v_u_32)
				end
				for v_u_33 in t3 do
					Steering:GetAttributeChangedSignal(v_u_33):Connect(function()
						--[[ line: 205 | upvalues: (ref) t3, (copy) v_u_33, (ref) Steering]]
						t3[v_u_33] = Steering:GetAttribute(v_u_33)
					end)
					t3[v_u_33] = Steering:GetAttribute(v_u_33)
				end
				for v_u_34 in t4 do
					Wheels:GetAttributeChangedSignal(v_u_34):Connect(function()
						--[[ line: 212 | upvalues: (ref) t4, (copy) v_u_34, (ref) Wheels]]
						t4[v_u_34] = Wheels:GetAttribute(v_u_34)
					end)
					t4[v_u_34] = Wheels:GetAttribute(v_u_34)
				end
			end
			initialize()
			return { reset = function(_2)
					--[[ line: 221 | upvalues: (copy) Engine, (copy) Constants, (copy) t2, (copy) Steering, (copy) t, (copy) t4]]
					Engine:SetAttribute(Constants.ENGINE_SPEED_ATTRIBUTE, 0)
					Engine:SetAttribute(Constants.ENGINE_NITRO_ATTRIBUTE, 1)
					Engine.WheelFRMotor.AngularVelocity = 0
					Engine.WheelFRMotor.MotorMaxTorque = t2.minSpeedTorque
					Engine.WheelFLMotor.AngularVelocity = 0
					Engine.WheelFLMotor.MotorMaxTorque = t2.minSpeedTorque
					Engine.WheelRRMotor.AngularVelocity = 0
					Engine.WheelRRMotor.MotorMaxTorque = t2.minSpeedTorque
					Engine.WheelRLMotor.AngularVelocity = 0
					Engine.WheelRLMotor.MotorMaxTorque = t2.minSpeedTorque
					Engine.NitroVelocity.Enabled = false
					Steering.SteeringRack.TargetPosition = 0
					for _3, v35 in t do
						v35.CustomPhysicalProperties = PhysicalProperties.new(t4.density, t4.staticFriction, t4.elasticity)
					end
				end, update = function(_4, p36: number)
					--[[ line: 245 | upvalues: (copy) updateNitro, (copy) updateEngine, (copy) updateSteering, (copy) updateWheelFriction]]
					updateNitro(p36)
					updateEngine(p36)
					updateSteering()
					updateWheelFriction()
				end }
		end
	end
end