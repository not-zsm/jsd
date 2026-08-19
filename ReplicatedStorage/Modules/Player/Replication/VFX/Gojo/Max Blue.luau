local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local Smoke = require( ReplicatedStorage.Modules.Player.Replication.Global.Smoke )
local ScreenPulse = require( ReplicatedStorage.Modules.Player.Replication.Global.ScreenPulse )

local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )
local Bubble = require( ReplicatedStorage.Modules.Player.Replication.Global.Bubble )

local SharmMeshVFX = require( ReplicatedStorage.Modules.Player.Replication.Global.SharmMeshVFX )

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local WindupAssets = script.Windup
local WindupAttachmentAssets = WindupAssets.AttachmentAssets

local MaxBlueAssets = script.Blue
local MaxBlueAttachmentAssets = MaxBlueAssets.AttachmentAssets

local HitAssets = script.Hit
local HitAttachmentAssets = HitAssets.AttachmentAssets

local VFX = {}

-------------------------------------------------------------------------------------------------

function VFX.HitStart(RootPart : BasePart, VictimTorso : BasePart)
	if (VictimTorso == nil or VictimTorso.Parent == nil) then return end

	local Distance = Players.LocalPlayer:DistanceFromCharacter(VictimTorso.Position)

	if (Distance < 25) then
		CameraShake(2, 20, 0.05, 0.3, Vector3.one * 0.8)
	end
	
	if (Distance < 75) then
		EffectUtility.EmitEffects(HitAssets.StartHit, VictimTorso)
	end
end

function VFX.HitSpin(Torso : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(Torso.Position)

	if (Distance < 75) then
		local Spin = HitAttachmentAssets.Spin:Clone()
		Spin.Parent = Torso
		EffectUtility.Emit(Spin)
	end
end

function VFX.HitSlam(VictimTorso : BasePart)
	if (VictimTorso == nil or VictimTorso.Parent == nil) then return end
	
	local Distance = Players.LocalPlayer:DistanceFromCharacter(VictimTorso.Position)

	if (Distance < 25) then
		CameraShake(2, 20, 0.05, 0.3, Vector3.one * 0.8)
	end
	
	if (Distance < 75) then
		local Raycast = workspace:Raycast(VictimTorso.Position + Vector3.yAxis * 2, Vector3.yAxis * -10, Utility.VisualParams)

		if (Raycast ~= nil) then
			EffectUtility.EmitEffects(HitAssets.Slam, workspace.Terrain, Raycast.Position - Vector3.new(0, 0.13, 0))
		end
	end
end

function VFX.HitLeg(LeftLeg : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(LeftLeg.Position)

	if (Distance < 75) then
		local Effect = HitAttachmentAssets.BlueLeg:Clone()
		Effect.Parent = LeftLeg
		EffectUtility.Emit(Effect)
	end
end

function VFX.HitKick(VictimTorso : BasePart)
	if (VictimTorso == nil or VictimTorso.Parent == nil) then return end
	
	local Distance = Players.LocalPlayer:DistanceFromCharacter(VictimTorso.Position)

	if (Distance < 25) then
		CameraShake(3.5, 35, 0.05, 0.3, Vector3.one * 0.8)
	end
	
	if (Distance < 75) then
		local Raycast = workspace:Raycast(VictimTorso.Position + Vector3.yAxis * 2, Vector3.yAxis * -10, Utility.VisualParams)

		if (Raycast ~= nil) then
			local Position = Raycast.Position

			EffectUtility.EmitEffects(HitAssets.Kick.VFX, workspace.Terrain, Raycast.Position)
			
			SharmMeshVFX.Create(HitAssets.Kick.Meshes.AnotherWind, Position + Vector3.new(0, 2.2, 0), Vector3.new(0, -0.7, 0))
			SharmMeshVFX.Create(HitAssets.Kick.Meshes.Mesh1, Position + Vector3.new(0, 15, 0), Vector3.new(0, -13.5, 0))
		end
		
		Blood.BloodRaysWithoutPreset(VictimTorso.Parent.Head.MouthAttachment, {Power = 35, Amount = Vector2.new(3, 5), Face = Enum.NormalId.Top})
	end
end

-------------------------------------------------------------------------------------------------

function VFX.Pulled(Torso : BasePart)
	EffectUtility.EmitEffects(MaxBlueAssets.Pulled, Torso)
end

function VFX.Ball(Torso : BasePart, BlueFollow : BasePart, TotalTime : number)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(Torso.Position)

	if (Distance < 75) then
		local Raycast = workspace:Raycast(Torso.Position, Vector3.yAxis * -10, Utility.VisualParams)

		if (Raycast ~= nil) then
			EffectUtility.EmitEffects(WindupAssets.Spin2Floor, workspace.Terrain, Torso.CFrame * CFrame.new(0, -Raycast.Distance + 0.13, 0))
		end

		local Spin = WindupAttachmentAssets.Spin2:Clone()
		Spin.Parent = Torso
		EffectUtility.Emit(Spin)
		
		local Hand = MaxBlueAttachmentAssets.Hand:Clone()
		Hand.Parent = Torso.Parent["Right Arm"]
		
		EffectUtility.Toggle(Hand, true)
		
		task.delay(TotalTime, EffectUtility.Toggle, Hand, false)
		task.delay(TotalTime * 2, Hand.Destroy, Hand)
	end
	
	if (Distance < 200) then
		local ChosenCFrame = CFrame.new(5, -30, 0)

		local Blue = MaxBlueAssets.MaxBlue:Clone()
		Blue.Position = BlueFollow.Position
		Blue.Parent = workspace.Visuals
		
		EffectUtility.Emit(Blue, true)
		EffectUtility.EmitEffects(MaxBlueAssets.Summon, Blue)

		local Loop = MaxBlueAssets.Loop.maxbluehit:Clone()
		Loop.Parent = Blue
		Loop:Play()
		
		local Shake = CameraShake(2.5, 15, 0.1, 0, Vector3.one * 0.8)
		local CF = (BlueFollow.CFrame * ChosenCFrame)
	
		local Step = 0
		local Start = os.clock()
		
		local RocksTakenFromGround = {}

		local RaycastDirection = Vector3.yAxis * -10
		local BlueDirectionUp = Vector3.yAxis * 4
		local Direction = Vector3.yAxis * -30
		local BlueDirectionDown = Vector3.yAxis * -25

		local Removed = false
		local Connection : RBXScriptConnection
		
		local function Remove()
			if Removed then return end
			
			Removed = true
			
			if Blue ~= nil and Blue.Parent ~= nil then
				EffectUtility.Toggle(Blue, false)
				task.delay(2, Blue.Destroy, Blue)
			end
		
			if Shake then
				Shake:StartFadeOut(0.3)
			end
			
			Loop:Destroy()
			EffectUtility.EmitEffects(MaxBlueAssets.End, Blue)

			if Connection.Connected then
				Connection:Disconnect()
			end

			for Rock in RocksTakenFromGround do
				if (Rock == nil or Rock.Parent == nil) then continue end

				local BodyPosition = Rock:FindFirstChild("BodyPosition")
				if (BodyPosition == nil) then continue end

				BodyPosition:Destroy()

				local Touched : RBXScriptConnection; Touched = Rock.Touched:Connect(function(Part)
					if not Part:IsDescendantOf(workspace.Map) then return end

					if Touched.Connected then
						Touched:Disconnect()
					end

					local Position = Rock.Position
					local Direction = Vector3.yAxis * -10

					EffectUtility.RaycastCraterSmoke("Small", Position, Direction)

					coroutine.wrap(RockHandler.Crater)(Position, Direction, {
						Amount = 5;
						Distance = 4,

						LookAt = {
							Min = -3,
							Max = -3
						},

						Exposure = {
							Min = 0.2,
							Max = 0.4
						},

						BaseX = 3,
						BaseZ = 1.5,

						CastShadow = false,
						SizeMagnitude = 0.8,
					})

					CameraShake(1.2, 12.5, 0.05, 0.15, Vector3.one * 0.8)
					EffectUtility.EmitEffects(MaxBlueAssets.RockFormingOut, workspace.Terrain, Position)
				end)

				Rock.AncestryChanged:Connect(function(_, Parent) 
					if (Parent == nil) then -- safe because it could fall through floor and give a mem leak if i connect to destroying
						Touched:Disconnect()
					end
				end)

				task.delay(2, Rock.Destroy, Rock)
			end
		end
		
		local RockCount = 0
	
		Connection = RunService.PreSimulation:Connect(function(Delta)
			if (Blue == nil or Blue.Parent == nil or Torso == nil or Torso.Parent == nil) then
				return Remove()
			end

			Step += 1
			
			local CurrentTime = os.clock()

			if Step % (12 - Utility.GetQuality()) == 0 and CurrentTime - Start < TotalTime then
				local NewDistance = Players.LocalPlayer:DistanceFromCharacter(Torso.Position)

				if (NewDistance < 50) then
					CameraShake(0.75, 8.5, 0.05, 0.075, Vector3.one * 0.8)
				end
				
				if (NewDistance < 300) then
					Smoke(Blue, 15, 25)
					
					for Index = 1, 2 do
						RockHandler.Rocks("Gojo Max Blue", Blue)
					end
					
					if (RockCount <= 30) then
						local RandomPosition = Blue.Position + Vector3.new(Utility.Seed:NextNumber(-20, 20), 0, Utility.Seed:NextNumber(-20, 20))
						local Raycast = workspace:Raycast(RandomPosition, Direction, Utility.VisualParams)

						if (Raycast ~= nil) then
							RockCount += 1
							EffectUtility.EmitEffects(MaxBlueAssets.RockFormingOut, workspace.Terrain, Raycast.Position)

							local Rock = Instance.new("Part")
							Rock.Color = Raycast.Instance.Color
							Rock.Material = Raycast.Instance.Material
							Rock.CanCollide = false
							Rock.CastShadow = false
							Rock.Size = Vector3.one * Utility.Seed:NextNumber(1.5, 2.5)
							Rock.Position = Raycast.Position

							if NewDistance < 50 and Utility.GetQuality() >= 5 then
								coroutine.wrap(RockHandler.Crater)(Raycast.Position, RaycastDirection, {
									Amount = 5;
									Distance = 3,

									LookAt = {
										Min = -3,
										Max = -3
									},

									Exposure = {
										Min = 0.2,
										Max = 0.4
									},

									BaseX = 3,
									BaseZ = 1.5,

									CastShadow = false,
									SizeMagnitude = 0.8,
								})

								EffectUtility.CraterSmoke("Small", Raycast)
							end

							local BodyPosition = Instance.new("BodyPosition")
							BodyPosition.MaxForce = Vector3.one * 100000
							BodyPosition.P = 35000
							BodyPosition.Position = RandomPosition
							BodyPosition.Parent = Rock

							Rock.Parent = workspace.Visuals
							Rock.AssemblyAngularVelocity = Vector3.one * (math.random(1, 2) == 1 and 5 or -5)

							RocksTakenFromGround[Rock] = true
						end
					end
				end
			end

			if Step % (16 - Utility.GetQuality()) == 0 and CurrentTime - Start < TotalTime then
				local NewDistance = Players.LocalPlayer:DistanceFromCharacter(Torso.Position)
				if NewDistance > 100 then return end
				
				local Circle = MaxBlueAssets.Wind:Clone()
				Circle.CFrame = CFrame.new(Blue.Position) * CFrame.Angles(math.rad(Utility.Seed:NextNumber(-90, 90)), math.rad(Utility.Seed:NextNumber(-90, 90)), math.rad(Utility.Seed:NextNumber(-90, 90)))
				Circle.Parent = workspace.Visuals

				TweenService:Create(Circle, TweenInfo.new(0.6), 
					{Transparency = 1, Size = Vector3.new(50, 25, 50)}
				):Play()
				
				if (Players.LocalPlayer:DistanceFromCharacter(Torso.Position) < 30) then
					ScreenPulse("Blue Choose")
				end

				task.delay(0.6, Circle.Destroy, Circle)
			end

			if Step % (18 - Utility.GetQuality()) == 0 and CurrentTime - Start < (TotalTime - 0.5) then
				local NewDistance = Players.LocalPlayer:DistanceFromCharacter(Torso.Position)
				if NewDistance > 150 then return end
				
				Bubble(Blue, 6, Vector3.one * 10, Vector3.one * 32.5, 0.5)
			end

			local LerpTime = math.min(0.1, (CurrentTime - Start) / 4) * (Delta * 60)
			local Raycast = workspace:Raycast(Blue.Position + BlueDirectionUp, BlueDirectionDown, Utility.VisualParams)
			
			if Raycast then
				Blue.CFrame = Blue.CFrame:Lerp(CFrame.new(CF.X, Raycast.Position.Y + 10, CF.Z), LerpTime)
				CF = (BlueFollow.CFrame * ChosenCFrame)
			else
				Blue.CFrame = Blue.CFrame:Lerp(CF, LerpTime)
				CF = (BlueFollow.CFrame * ChosenCFrame)
			end

			if CurrentTime - Start < TotalTime then
				for Rock in RocksTakenFromGround do
					if (Blue == nil or Blue.Parent == nil) then
						break
					end
					
					if (Rock.Parent == nil) then continue end
					
					local BodyPosition = Rock:FindFirstChild("BodyPosition")
					if (BodyPosition == nil) then return end
					
					local X = Utility.Seed:NextNumber(-10, 10)
					local Y = Utility.Seed:NextNumber(-10, 10)
					local Z = Utility.Seed:NextNumber(-10, 10)
					
					BodyPosition.Position = Blue.Position + Vector3.new(X + (X < 0 and -17.5 or 17.5), Y + (Y < 0 and -15 or 15), Z + (Z < 0 and -17.5 or 17.5))
				end
			end
		end)

		task.delay(TotalTime, Remove)
	end
end

-------------------------------------------------------------------------------------------------

function VFX.WindupCharge(RootPart : BasePart)
	local Model : Model = RootPart.Parent
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)

	if (Distance < 10) then
		CameraShake(0.85, 12.5, 0.1, 0.15, Vector3.one * 0.8)
	end
	
	if (Distance < 75) then
		local Hand = WindupAttachmentAssets.Hand:Clone()
		Hand.Parent = Model["Right Arm"]
		EffectUtility.Emit(Hand)
		
		local Raycast = workspace:Raycast(RootPart.Position, Vector3.yAxis * -10, Utility.VisualParams)
		
		if (Raycast ~= nil) then
			EffectUtility.EmitEffects(WindupAssets.Wind, workspace.Terrain, Raycast.Position - Vector3.new(0, 0.13, 0))
		end
	end
end

function VFX.WindupSwing(RootPart : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)

	if (Distance < 10) then
		CameraShake(1, 15, 0.1, 0.15, Vector3.one * 0.8)
	end
	
	if (Distance < 75) then
		local Hand = WindupAttachmentAssets.Swing:Clone()
		Hand.Parent = RootPart
		EffectUtility.Emit(Hand)
	end
end

function VFX.WindupHit(RootPart : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)

	if (Distance < 75) then
		local Raycast = workspace:Raycast(RootPart.Position, Vector3.yAxis * -10, Utility.VisualParams)

		if (Raycast ~= nil) then
			EffectUtility.EmitEffects(WindupAssets.SwingDust, workspace.Terrain, RootPart.CFrame * CFrame.new(0, -Raycast.Distance + 0.13, 0))
		end
	end
end

function VFX.WindupSpin(RootPart : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)

	if (Distance < 75) then
		local Raycast = workspace:Raycast(RootPart.Position, Vector3.yAxis * -10, Utility.VisualParams)

		if (Raycast ~= nil) then
			EffectUtility.EmitEffects(WindupAssets.Spin1Floor, workspace.Terrain, RootPart.CFrame * CFrame.new(0, -Raycast.Distance + 0.13, 0))
		end
		
		local Hand = WindupAttachmentAssets.Spin1.Arm:Clone()
		Hand.Parent = RootPart.Parent["Right Arm"]
		EffectUtility.Emit(Hand)
		
		local Torso = WindupAttachmentAssets.Spin1.Torso:Clone()
		Torso.Parent = RootPart
		EffectUtility.Emit(Torso)
	end
end

-------------------------------------------------------------------------------------------------

return VFX