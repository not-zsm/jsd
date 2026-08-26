local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local AnimationRetriever = require(replicatedStorage.modules.client.replication.VFX.AnimationRetriever)
local CameraShake = require(replicatedStorage.modules.client.replication.Global.CameraShake)
local RockHandler = require(replicatedStorage.modules.client.replication.Global.RockHandler)
local EffectUtility = require(replicatedStorage.modules.client.replication.EffectUtility)
local BugoVFX = require(replicatedStorage.modules.client.replication.EffectUtility.Bugo)
local Vignette = require(replicatedStorage.modules.client.replication.Global.Vignette)
local Yuki_FOV = require(replicatedStorage.modules.client.replication.Global.Yuki_FOV)
local Utility = require(replicatedStorage.modules.shared.Utilities.Utility)
local Table = require(replicatedStorage.packages.Table)

local EffectFolder = script.Effects

local function get_max_lifetime(item : Instance | {})
	if typeof(item) == "Instance" and item:GetAttribute("Lifetime") then
		return item:GetAttribute("Lifetime")
	else
		local max_lifetime = 0

		local directory = if typeof(item) == "Instance" then item:GetDescendants() else item

		for _, emitter in directory do
			if typeof(emitter) ~= "Instance" then
				continue
			end

			if not emitter:IsA("ParticleEmitter") then
				continue
			end

			local emitter_attributes = emitter:GetAttributes()

			local emit_duration = emitter_attributes["EmitDuration"] or 0
			local emit_delay =  emitter_attributes["EmitDelay"] or 0
			local lifetime = (emitter.Lifetime.Max + emit_duration + emit_delay) / emitter.TimeScale

			if emitter_attributes["Lifetime"] then
				lifetime = math.max(lifetime, emitter_attributes["LifeTime"])
			end

			if max_lifetime < lifetime and lifetime < 1e999 then
				max_lifetime = lifetime
			end
		end

		return max_lifetime
	end
end

return {
	Start = function(character : Model)
		local retrieved = AnimationRetriever.new(character, replicatedStorage.ass.emotes["Super Saiyan"])
		if (retrieved == nil) then return end
		
		local root_part = retrieved.RootPart
		local track = retrieved.Animation
		
		local rock_table : {[BasePart] : RaycastResult} = Table.weak_keys({})
		local is_me = (LocalPlayer.Character == character)
		local suck_ended = false
		local suck_shake
		
		local function add<T>(object : T) : T
			return retrieved.Job:Task(object)
		end
		
		local function clean_suck_shake()
			if suck_ended then
				return
			end
			
			suck_ended = true
			
			if suck_shake then
				suck_shake:StartFadeOut(0.2)
			end
		end
		
		add(clean_suck_shake)
		
		if is_me then
			local function reset_fov()
				Yuki_FOV.Tween(70, {0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In})
			end
			
			add(task.delay(75/60, function()
				Yuki_FOV.Tween(100, {0.15, Enum.EasingStyle.Circular, Enum.EasingDirection.Out})
			end))
			
			add(task.delay(140/60, reset_fov))
			add(reset_fov)
		end
		
		add(track:GetMarkerReachedSignal("Emit"):Connect(function(effect_name)
			BugoVFX(EffectFolder:FindFirstChild(effect_name), root_part)
			
			if effect_name == "Explo"then
				if ((LocalPlayer:DistanceFromCharacter(root_part.Position) <= 30) or is_me) then
					CameraShake(10, 20, 0.05, 0.75, vector.create(0.65, 0.65, 0.65))
					Vignette(Color3.fromRGB(254, 205, 92), 0.35)
				end
			
				for rock in rock_table do
					if (rock.Parent == nil) then continue end
					
					local body_position = rock:FindFirstChild("BodyPosition")
					
					if body_position then
						body_position:Destroy()
					end
					
					rock.AssemblyLinearVelocity = vector.normalize(rock.Position - root_part.Position) * 60
					rock.CanCollide = true
					
					task.delay(2, function()
						if not rock:IsDescendantOf(game) then
							return
						end
						
						TweenService:Create(rock, TweenInfo.new(1), {
							Size = vector.zero,
							Transparency = 1
						}):Play()
						
						task.delay(1, rock.Destroy, rock)
					end)
				end
			end
		end))
		
		add(track:GetMarkerReachedSignal("Enable"):Connect(function(effect_name)
			local effect_part = EffectFolder:FindFirstChild(effect_name)
			
			if not effect_part then
				return warn(`{effect_name} is not an effect for the super saiyan emote`)
			else
				effect_part = add(effect_part:Clone())
			end
			
			effect_part.Join.Part0 = root_part
			effect_part.Parent = root_part
			
			EffectUtility.Toggle(effect_part, true)
			
			if effect_name == "Suckenable" then 
				
				local distance_from_user = if is_me then 0 else LocalPlayer:DistanceFromCharacter(root_part.Position)
				
				if (distance_from_user <= 20) then
					suck_shake = CameraShake(2.75, 8.5, 0.1, 0, vector.create(0.65, 0.65, 0.65))
				end
				
				task.spawn(function()
					local highlight_effect = add(Instance.new("Highlight"))
					highlight_effect.FillTransparency = -1
					highlight_effect.FillColor = Color3.fromRGB(255, 216, 74)
					highlight_effect.OutlineTransparency = 1
					highlight_effect.OutlineColor = Color3.new()
					highlight_effect.DepthMode = Enum.HighlightDepthMode[if is_me then "AlwaysOnTop" else "Occluded"]
					highlight_effect.Enabled = true
					highlight_effect.Adornee = character
					highlight_effect.Parent = character
					
					while (not suck_ended and track.IsPlaying) do
						TweenService:Create(highlight_effect, TweenInfo.new(1/20, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
							FillTransparency = 1,
						}):Play()
						
						if (distance_from_user <= 20) then
							Vignette(Color3.fromRGB(254, 205, 92), 0.65, 1/10)
						end
						
						task.wait(1/20)
						
						highlight_effect.FillTransparency = -1
					end
					
					highlight_effect:Destroy()
				end)
				
				task.spawn(function()
					for _ = 1, 15 do
						local random_position = root_part.Position + vector.create(Utility.Seed:NextInteger(-12, 12), 0, Utility.Seed:NextInteger(-12, 12))
						
						local raycast_result = workspace:Raycast(random_position, vector.create(0, -10, 0), Utility.VisualParams)
						
						if (raycast_result == nil) then
							continue 
						end
						
						local flying_rock = add(Instance.new("Part"))
						flying_rock.Color = raycast_result.Instance.Color
						flying_rock.Material = raycast_result.Instance.Material
						flying_rock.CanCollide = false
						flying_rock.Size = vector.zero
						flying_rock.Position = raycast_result.Position

						local body_position = Instance.new("BodyPosition")
						body_position.MaxForce = vector.one * 80000
						body_position.P = Utility.Seed:NextNumber(2900, 3100)
						body_position.Position = random_position + (vector.create(0, Utility.Seed:NextNumber(5, 15), 0))
						body_position.Parent = flying_rock
						
						flying_rock.Parent = workspace.Visuals
						
						rock_table[flying_rock] = true
						
						flying_rock.AssemblyAngularVelocity = vector.one * Utility.Seed:NextNumber(-15, 15)
						
						TweenService:Create(flying_rock, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),{
							Size = vector.one * Utility.Seed:NextNumber(0.65, 1.65)
						}):Play()
					end
				end)
			end
		end))
		
		add(track:GetMarkerReachedSignal("Disable"):Connect(function(effect_name)
			local effect_part = root_part:FindFirstChild(effect_name)

			if not effect_part then
				return warn(`{effect_name} is not an effect inside the rootpart`)
			end
			
			EffectUtility.Toggle(effect_part, false)
			
			task.delay(get_max_lifetime(effect_part), effect_part.Destroy, effect_part)
			
			if effect_name == "Suckenable" then
				clean_suck_shake()
			end
		end))
	end,
}