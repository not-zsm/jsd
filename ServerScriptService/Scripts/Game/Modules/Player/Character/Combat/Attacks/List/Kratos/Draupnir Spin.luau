local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

----------------------------------------------------------------------------------

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(50)

	local Weapons = self.Combat.Attacks.Weapons

	if Weapons then
		Weapons:SetCurrent("Spear")
	end
	
	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(20)
		
		if Weapons then
			Weapons:BringBackPreviouslyUsing()
		end

		self.Combat:TimesSpeed(50)
		self.Combat:StackState("Attacking", false)
	end)
	
	self.Thread.CancelJob:Task(
		self:CreateMoveSFX("Kratos", "Draupnir Spin")
	)

	self:FireReliableVFX("Kratos/Draupnir Spin", "Start", self.LuaCharacter.Model)

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("spin"):Connect(function(Index : string)
		Index = tonumber(Index)
		
		if Index == 4 then
			self:CreateMoveSFX("Kratos", "Draupnir Spin", "Slash")
		end
		
		task.wait(0.1)

		if Index > 1 and Index < 5 then
			local Hitbox = self:CreateHitbox(false);
			Hitbox.Params.Size = Vector3.new(15, 8, 15)
			Hitbox.Params.Offset = CFrame.identity
			
			Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
				if Index == 4 then
					local Validated = self:Afflict(VictimLuaPlayer, {
						--YDifferenceValue = -2,
						Damage = 1
					})

					if Validated then
						self.Combat:TSBPushVictim(VictimLuaPlayer, {
							DontBeginAoeHitbox = true,
							LookVectorInsteadOfDifference = true,
							LandedRollVelocityZ = 140,
							LandedRollDuration = 0.6
						})
					end
				else
					self:Afflict(VictimLuaPlayer, {
						--YDifferenceValue = -2,
						DontBypassIFrames = {"Grab", "Backdash"},
						TrueStun = 0.6,
						PlayRandomHitReaction = true,
						Damage = 1,
						CannotBeAdapted = true
					})
				end

			end)

			Hitbox:Detect()
			self.Combat.Hitbox:Destruction(Hitbox.Params.Offset, Hitbox.Params.Size, 1)
		end
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("slash"):Connect(function()
		local Distance = 60

		local StartCFrame : CFrame = self.Combat:GetSimulatedRoot().CFrame * CFrame.new(0, -2.4, -12)

		local Raycast = workspace:Raycast((StartCFrame * CFrame.new(0, 5, 2)).Position, StartCFrame.LookVector * Distance, Utility.VisualParams)
		local EndCFrame = StartCFrame * CFrame.new(0, 0, -((Raycast) and (Raycast.Distance - 6) or Distance))

		local Duration = 1.5
		local StartTime = os.clock()

		local Hitbox = self:CreateHitbox(false, true);
		Hitbox.Adornee = StartCFrame
		Hitbox.Params.Size = Vector3.new(16.5, 16.039, 16.448) * 1.15
		Hitbox.Params.Offset = CFrame.new(0, Hitbox.Params.Size.Y / 2, 0)
		Hitbox.Params.DestroyOnEndCast = true
		
		local TornadoPart = Instance.new("Part")
		TornadoPart.CanCollide = false
		TornadoPart.Anchored = true
		TornadoPart.CanQuery = false
		TornadoPart.CanTouch = false
		TornadoPart.Transparency = 1
		TornadoPart.Size = Vector3.one
		TornadoPart.CFrame = StartCFrame
		TornadoPart.Name = "TornadoOffsets"
		TornadoPart.Parent = workspace.Visuals
		
		local TornadoAttachment = Instance.new("Attachment")
		TornadoAttachment.Name = "TornadoAttachment"
		TornadoAttachment.Parent = TornadoPart
		
		local Aligns = {}
		
		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			local Blocked = VictimCombat:GetState("Blocking") and self.Combat:CalculateHitAngle(VictimLuaPlayer) <= math.rad(90)
			local DistanceFromEnd = (EndCFrame.Position - VictimCombat:GetSimulatedRoot().Position).Magnitude

			local Validated = self:Afflict(VictimLuaPlayer, {
				TriggerActiveCounterOverOrEqualLevel = -1,
				DontCheckBlock = true,
			})

			if Validated then
				if not Blocked then
					VictimCombat:TrueStun(DistanceFromEnd / 30)
					VictimCombat:PlayRandomHitReaction()

					self.Combat:DealDamage(VictimLuaPlayer, 1.25)
				end
				
				local Model = VictimLuaCharacter.Model

				if (Model and Aligns[Model] == nil and not VictimCombat:GetState("Evasived")) then
					local OffsetAttachment = Instance.new("Attachment")
					OffsetAttachment:SetAttribute("RemoveOn", VictimLuaPlayer.Player.Name)
					OffsetAttachment:AddTag("RemoveOnEvasive")
					OffsetAttachment.Name = "VictimOffsetAttachment"
					OffsetAttachment.Position = TornadoPart.CFrame:PointToObjectSpace(VictimCombat:GetSimulatedRoot().Position) + Vector3.yAxis * 2.5
					OffsetAttachment.Parent = TornadoPart
					
					local AlignPosition = Instance.new("AlignPosition")
					AlignPosition.Responsiveness = 75
					AlignPosition.MaxForce = 100000
					AlignPosition.MaxVelocity = 100
					AlignPosition.Mode = Enum.PositionAlignmentMode.TwoAttachment
					AlignPosition.Attachment0 = VictimLuaCharacter.RootPart.RootAttachment
					AlignPosition.Attachment1 = OffsetAttachment
					AlignPosition.Parent = OffsetAttachment

					VictimCombat:StackState("EvasiveState", true)
					
					Hitbox.Events.OnCastEnded:Connect(function()
						VictimCombat:StackState("EvasiveState", false)
					end)
					
					Aligns[Model] = true
				end
			end

			task.delay(0.2, Hitbox.RemoveHumanoid, Hitbox, VictimLuaCharacter.Humanoid)
		end)
		
		Hitbox.Events.OnCastEnded:Connect(function()
			TornadoPart:Destroy()
			table.clear(Aligns)
		end)
		
		local Last = os.clock()
		local PartRandom = {};
		
		local Connection; Connection = RunService.PostSimulation:Connect(function(Dt)
			local Elapsed = os.clock() - StartTime
			
			if Elapsed > Duration then
				table.clear(PartRandom);
				
				return Connection:Disconnect()
			end
			
			local Alpha = TweenService:GetValue(Elapsed / Duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			Hitbox.Adornee = StartCFrame:Lerp(EndCFrame, Alpha)
			TornadoPart.CFrame = Hitbox.Adornee

			if os.clock() - Last > 0.2 then
				self.Combat.Hitbox:DestructionAt(Hitbox.Adornee, Hitbox.Params.Size, 1);
				
				self.Combat.Hitbox:CreateHavocReplicated({
					parameters = {
						origin = Hitbox:GetCFrame(),
						shape = "Sphere", 
						radius = 17.5,
						block_size = 7,
					},
					debris = {
						scale = 0.9,
						radius = 25,
						velocity = function(part)
							if not PartRandom[part] then
								PartRandom[part] = math.random() * math.pi * 2;
							end;
							
							local Ran = PartRandom[part];
							local Elapse = Elapsed * math.pi * 1.5 + Ran;
							
							return (Hitbox:GetPosition() - part.Position).Unit * 75 + CFrame.Angles((Ran - math.pi) * 0.2, Elapse, 0).LookVector * 105 + Vector3.yAxis * (Ran - math.pi) * 25;
						end,
					},
				});
				
				Last = os.clock()
			end
		end)

		Hitbox:BeginCast(Duration / 1.25)
		self:FireReliableVFX("Kratos/Draupnir Spin", "Slash", self.LuaCharacter.Model, StartCFrame, EndCFrame, Duration)

		self.Animations.Windup:AdjustSpeed(1.2)
	end))

	self.Animations.Windup:GetMarkerReachedSignal("end"):Wait()

	self:Close()
end

function Attack.new(...) 
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack