--[[
    © 2025 swrerm. All Rights Reserved.
    Author: swrerm
    Created: July 16, 2024
    Developed under the group: Jimpee's Cabin

    Licensed for use by Jimpee's Cabin only.
    Redistribution, resale, or unauthorized use of this code, 
    in whole or in part, without express permission from the author
    is strictly prohibited.

    This script is the original work of the author listed above.

    Contacts:
      wboyd4029@gmail.com
      jimpeeisbusiness@gmail.com
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local LuaPlayerList = require( ServerScriptService.Scripts.Game.Modules.LuaPlayerList )
local Sphere = require( ReplicatedStorage.Modules.Shared.Game.Hitbox.Type.Sphere )
local EventService = require( ReplicatedStorage.Modules.Shared.Utilities.EventService )

local Remotes = ReplicatedStorage.Remotes
local CombatRemotes = Remotes.Combat

local function Anchor(Model : Model, Value : boolean)
	for _, Item in ipairs(Model:GetDescendants()) do
		if Item:IsA("BasePart") then
			Item.Anchored = Value
		end
	end
end

return {
	--Whitelist = {7207821215, 1242679803},
	GitHubWhitelist = "Crusader",
	RestrictSetCharacter = true,
	StandName = "Star Platinum",
	
	Ultimate = {
		OneTimePop = true,
		
		Function = function(self, StartAnimation : AnimationTrack)
			self.Combat:StackState("Attacking", true)
			self.Combat:DivideSpeed(200)

			local StandAnimation : AnimationTrack
			local StandHandler = self.Combat.Attacks["Star Platinum"]

			local Duration = 5 + (1.8333333333333333)
			
			if StandHandler then
				StandAnimation = StandHandler.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Global.Ultimate["Stardust Crusader"].Stand)
				StandHandler:MoveStand(CFrame.identity, 0)

				local StandJob = Job.new()

				StandJob:Task(StandAnimation:GetMarkerReachedSignal("end"):Once(function()
					StandHandler:MoveStandByAction("Idle", 0)
					StandAnimation:Stop(0)
				end))

				StandJob:Task(self.Combat.OnStateChanged:Connect(function(State : any, Value : boolean)
					if Value and (State == "Attacking" or State == "M1ing") then
						StandAnimation:Stop()
					end
				end))

				StandAnimation.Stopped:Once(function()
					StandJob:Destroy()
				end)
			end
			
			--local Hitbox = self.Combat.Hitbox:Create(true)
			--Hitbox.Adornee = self.Combat:GetSimulatedRoot().Position
			--Hitbox.Params.MaxTargets = -1
			--Hitbox.Params.Offset = CFrame.identity
			--Hitbox.Params.Size = 60
			--Hitbox.Params.DestroyOnEndCast = false

			local Params = Sphere.NewParams()
			Params.MaxTargets = -1
			Params.Offset = CFrame.identity
			Params.Size = 60
			Params.DestroyOnEndCast = false
			Params.Ignore = {self.LuaCharacter.Model}
			Params.Debug = workspace:GetAttribute("HitboxVisible")

			local Adornee : BasePart = self.Combat:GetSimulatedRoot()
			local Hitbox = Sphere.new(Adornee.Position, Params)

			local Timestopped = {}
			
			Hitbox.Events.HumanoidHit:Connect(function(Humanoid : Humanoid)
				local VictimLuaPlayer = LuaPlayerList.Get(Humanoid)
				if (VictimLuaPlayer == nil) then return end
				
				local VictimLuaCharacter = VictimLuaPlayer.Character
				local VictimCombat = VictimLuaCharacter.Combat
				
				if VictimLuaCharacter.HumanoidExists then
					local Validated = self:Afflict(VictimLuaPlayer, {
						TriggerActiveCounterOverOrEqualLevel = -1,
						DontCheckForHitboxImmunity = true,
						CannotBeAdapted = true,
						DontCheckBlock = true,
						DontBypassIFrames = {},
					})

					if Validated then
						local TimestopJob = Job.new()
						
						TimestopJob:Task(VictimCombat:GetStateChanged("Timestopped"):Connect(function(Value : boolean)
							VictimCombat:StackState("CannotDash", Value)
							Anchor(VictimLuaCharacter.Model, Value)

							if Value then
								VictimCombat:TrueStun()
							else
								VictimCombat:Unstun()
							end
						end))

						if not VictimLuaPlayer.IsNPC then
							CombatRemotes.UpdatePivotRealtime:FireAllClients(VictimLuaPlayer.Player);
						end;
						
						VictimCombat:StackState("Timestopped", true)
						Timestopped[VictimLuaPlayer] = TimestopJob
					end;
				end;
			end);
			
			self.Thread.OnClosed:Connect(function()
				self.Combat:TimesSpeed(200)
				self.Combat:StackState("Attacking", false)
			end)

			self.Thread.Job:Task(StartAnimation:GetMarkerReachedSignal("timestop"):Connect(function()
				self.Combat:StackState("HitboxImmunity", true)
				
				Hitbox:BeginCast()
				
				task.delay(Duration, function()
					for VictimLuaPlayer, TimestopJob in Timestopped do
						VictimLuaPlayer.Character.Combat:StackState("Timestopped", false)
						TimestopJob:Destroy()
					end
					
					table.clear(Timestopped)
					
					Hitbox:EndCast()
					Hitbox:Destroy()
					
					self.Combat:StackState("HitboxImmunity", false)
				end)
			end))

			self.Thread.Job:Task(StartAnimation:GetMarkerReachedSignal("end"):Connect(function()
				self:Close()
			end))

			StandAnimation:Play()
			StartAnimation:Play()
			
			self:FireReliableVFX("Stardust Crusader/Timestop", "Start", self.LuaCharacter.Model, Duration)
		end,
		
		Name = "ZA WARUDO",
		Color = ColorSequence.new(Color3.fromRGB(92, 0, 172)),
	},

	Stats = {
		M1 = {
			Speed = 1.45,
			EndlagAfterSwing = 0.09,

			LastM1KnocksUp = true,

			Hitbox = {
				Offset = CFrame.new(0, 0, -2.65 * 1.5),
				Size = Vector3.new(6, 6, 6.8 * 1.5)
			}
		},
	}, 

	--M1 = {
	--	CustomFunction = "Stands/Stand M1";
	--},
	
	--Dash = {
	--	CustomFunction = "Stands/Stand FrontDash";
	--},

	OnSpawn = function(LuaPlayer)
		local Hat = script.Hat:Clone()
		Hat.Name = "Handle"
		Hat.Weld.Part0 = LuaPlayer.Character.Head
		Hat.Parent = LuaPlayer.Character.Model

		LuaPlayer.Character.Combat.SpawnJob:Task(Hat)
		LuaPlayer.Character.Combat:CreateAttack("Star Platinum")
	end,

	OnRemoved = function(LuaPlayer)
		LuaPlayer.Character.Combat:RemoveAttack("Star Platinum")
	end,

	StandOnAttacks = {
		["Heavy Barrage"] = Enum.KeyCode.One,
		["Star Finger"] = Enum.KeyCode.Two,
	};
	
	StandOffAttacks = {
		
	};

	Attacks = {
		["Yare Yare Daze"] = Enum.KeyCode.R
	}
}
