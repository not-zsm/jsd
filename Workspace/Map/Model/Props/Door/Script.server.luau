local main = script.Parent
local door = main.door

local hitbox = main:WaitForChild("hitbox")
local prompt = hitbox:WaitForChild("prompt")

local ServerScriptService = game:GetService("ServerScriptService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local ServerStorage = game:GetService("ServerStorage")
local LuaPlayerList = require( ServerStorage.modules.LuaPlayerList )
local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )
local Job = require( replicatedStorage.modules.shared.Utilities.Job )

prompt.Triggered:Connect(function(player_who_triggered)
	if main:GetAttribute("Destructed") or not prompt.Enabled then return end
	
	--if not prompt.Enabled then return end
	
	local luaplayer = LuaPlayerList.LuaPlayers[player_who_triggered]
	
	if luaplayer then
		local kick_anim : AnimationTrack = luaplayer.Character:LoadAnimation(replicatedStorage.Animations.Miscellaneous.KickDoor)
		if (kick_anim == nil) then return end

		prompt.Enabled = false
		
		local prompt_job = Job.new()

		prompt_job:Task(function()
			prompt.Enabled = true
			
			if (door ~= nil) then
				door.Parent = main
			end
		end)
		
		task.delay(20, function()
			prompt_job:Destroy()
		end)
		
		local new_job = Job.new()
		
		new_job:Task(function()
			kick_anim:Stop()
			kick_anim:Destroy()
			kick_anim = nil
		end)
		
		new_job:Task(kick_anim:GetMarkerReachedSignal("kick"):Once(function()
			print("hello")
			
			local kicked_door = door:Clone()
			kicked_door.PrimaryPart.CFrame = door.PrimaryPart.CFrame + (luaplayer.Character.RootPart.CFrame.LookVector * 2)
			kicked_door.PrimaryPart.Anchored = false
			kicked_door.Parent = workspace.Visuals
			
			print(kicked_door)
			
			prompt_job:Task(kicked_door)
			
			for _, item in ipairs(kicked_door:GetChildren()) do
				if item:IsA("BasePart") and item:CanSetNetworkOwnership() then
					item:SetNetworkOwner(nil)
				end
			end
		
			kicked_door.PrimaryPart.AssemblyLinearVelocity = (luaplayer.Character.RootPart.CFrame.LookVector * 200)
			
			EffectUtility.EmitEffects(main.kick_vfx, kicked_door.PrimaryPart)

			task.delay(1 / 60, function()
				print("yo")
				door.Parent = nil
			end)
			
			task.wait(0.5)
			
			new_job:Destroy()
		end))
		
		new_job:Task(luaplayer.Character.Combat.OnStateChanged:Connect(function(State : any, Value : any)
			if (State == "Stunned" or State == "Ragdolled") and Value then
				new_job:Destroy()
			end
		end))
		
		print("hell2o")
		
		kick_anim:Play()
	end
end)