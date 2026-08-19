local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )

local resources = script.resources

local quickutil = require( ReplicatedStorage.Modules.Player.Replication.Global.Dojyan_Util )
local MeshEmit = require( ReplicatedStorage.Modules.Player.Replication.Global.Dojyan_Util.MeshEmit )

local Smoke = require( ReplicatedStorage.Modules.Player.Replication.Global.Smoke )
local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local effects = script.effects
local meshes = effects.meshes

local Animations = ReplicatedStorage.Animations.Attacks.Mori[script.Name]

local function clone_emit_part(effect : BasePart, root : BasePart)
	local new = effect:Clone()
	new:PivotTo(root.CFrame - Vector3.yAxis * 3)
	new.Parent = workspace.Visuals
	quickutil:emit(new)
	task.delay(5, new.Destroy, new)
end

local function clone_emit_attach(effect : Attachment, root : BasePart)
	local new = effect:Clone()
	new.Parent = root
	quickutil:emit(new)
	task.delay(5, new.Destroy, new)
end

return {
	Start = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Windup)
		if (Retrieved == nil) then return end
		
		local Job = Retrieved.Job
		local Animation = Retrieved.Animation

		local clone = resources.highlight:Clone()
		clone.OutlineTransparency = 1
		clone.FillTransparency = 1
		clone.Parent = Model
		
		Job:Task(clone)
		
		Job:Task(EffectUtility.AddSFX(script.SFX.Windup, Retrieved.Torso, 0.4))
		
		Job:Task(Animation:GetMarkerReachedSignal("counter"):Connect(function(Parameter : string)
			clone.OutlineTransparency = (Parameter == "true") and 0 or 1
		end))
	end,
	
	Zap = function(Model : Model, VictimModel : Model)
		local RootPart = Model:FindFirstChild("HumanoidRootPart")
		local VictimRoot = VictimModel:FindFirstChild("HumanoidRootPart")

		quickutil:afterimage(Model, 1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, Color3.fromRGB(246, 181, 255), 0)

		clone_emit_part(effects.tproot["3"], RootPart)
		clone_emit_attach(effects.victim_root.hit3, VictimRoot)
		
		if EffectUtility.Distance_Close(Model) then
			CameraShake(1.75, 17.5, 0.01, 0.75, Vector3.one * 0.8, Vector3.one * 0.5)
		end

		local mesh = meshes.thirdhit:Clone()
		mesh:PivotTo(RootPart.CFrame - Vector3.yAxis * 3)

		for _, Start in ipairs(mesh:GetDescendants()) do
			if Start.Name == "Start" then
				MeshEmit(Start, true)
			end
		end

		task.delay(1, mesh.Destroy, mesh)

		do
			local clone = resources.windaround:Clone()
			clone:PivotTo(RootPart.CFrame - Vector3.yAxis * 3)
			clone.Parent = workspace.Visuals

			quickutil:tween_single(clone, 1.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {["CFrame"] = clone.CFrame * CFrame.new(7, 3, 0)})
			quickutil:tween_descendant(clone, "Beam", 1.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {TextureSpeed = -.1, Brightness = 0}, true)
		end

		do
			local clone = resources.windback:Clone()
			clone:PivotTo(RootPart.CFrame - Vector3.yAxis * 3)
			clone.Parent = workspace.Visuals

			quickutil:tween_single(clone, 3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {["CFrame"] = clone.CFrame * CFrame.new(0, 0, -4)})
			quickutil:tween_descendant(clone, "Beam", 2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {TextureSpeed = .3, Brightness = 0}, true)
		end

		do
			local clone = resources.highlight:Clone()
			clone.Parent = Model
			quickutil:tween_single(clone, 1.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {FillTransparency = 1}, true)
		end

		for Index = 1, 9 do
			Smoke(RootPart, 5, 3)
			RockHandler.Rocks("Forward Dash", RootPart)

			task.wait(0.06)
		end

		--task.wait()

		--local clone = resources.dust:Clone()
		--clone:PivotTo(RootPart.CFrame - Vector3.yAxis * 3)
		--clone.Parent = workspace.Visuals

		--quickutil:tween_single(clone, 1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, {["CFrame"] = clone.CFrame * CFrame.new(0, 0, 12)})

		--task.delay(0.5, function()
		--	quickutil:interact(clone, "ParticleEmitter", "Enabled", false)
		--	task.delay(2, clone.Destroy, clone)
		--end)
	end,
	
	Hit = function(Model : Model, VictimModel : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Hit)
		if (Retrieved == nil) then return end
		
		local VictimRoot = VictimModel:FindFirstChild("HumanoidRootPart")

		local Job = Retrieved.Job
		local Animation = Retrieved.Animation
		local RootPart = Retrieved.RootPart
		
		local hit_count = 0

		Job:Task(EffectUtility.AddSFX(script.SFX.Hit, Retrieved.RootPart, 0.4))
		
		Job:Task(Animation:GetMarkerReachedSignal("hit"):Connect(function()
			if (VictimRoot == nil) then return end
			
			hit_count = math.min(hit_count + 1, 2)
			clone_emit_attach(effects.victim_root["hit" .. hit_count], VictimRoot)
			
			if EffectUtility.Distance_Close(Model) then
				CameraShake(1, 10, 0.01, 0.4, Vector3.one * 0.8, Vector3.one * 0.3)
			end
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("tp"):Connect(function(tp_count : string)
			if (tp_count == "1") then
				clone_emit_part(effects.tproot["2"], RootPart)
				quickutil:afterimage(Model, 1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, Color3.fromRGB(207, 255, 162), 0)
				
			elseif (tp_count == "2") then
				clone_emit_part(effects.tproot["2"], RootPart)
				quickutil:afterimage(Model, 1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, Color3.fromRGB(255, 232, 148), 0)
			end
		end))
		
		task.spawn(function()
			local VictimRetrieved = AnimationRetriever.new(VictimModel, Animations.Victim)
			if (VictimRetrieved == nil) then return end
			
			local function shake(intensity : number)
				if LocalPlayer.Character == Model or EffectUtility.Distance_Close(VictimModel) then
					CameraShake(intensity, intensity * 10, 0.01, intensity / 3, Vector3.one * 0.8, Vector3.one * 0.3)
				end
			end
			
			VictimRetrieved.Job:Task(VictimRetrieved.Animation:GetMarkerReachedSignal("booms"):Once(function()
				VictimRetrieved.Job:Task(EffectUtility.AddSFX(script.SFX.Victim, VictimRetrieved.RootPart, 0.4))
				
				clone_emit_attach(effects.victim_root.afterhit1, VictimRetrieved.RootPart)
				shake(0.9)

				VictimRetrieved.Job:Task(task.delay(0.14, function()
					clone_emit_attach(effects.victim_root.afterhit2, VictimRetrieved.RootPart)
					shake(1.2)
				end))

				VictimRetrieved.Job:Task(task.delay(0.28, function()
					clone_emit_attach(effects.victim_root.afterhit3, VictimRetrieved.RootPart)
					shake(1.4)
					
					local mesh = meshes.thirdafterhit:Clone()
					mesh:PivotTo(VictimRetrieved.RootPart.CFrame - Vector3.yAxis * 3)

					for _, Start in ipairs(mesh:GetDescendants()) do
						if Start.Name == "Start" then
							MeshEmit(Start, true)
						end
					end

					task.delay(1, mesh.Destroy, mesh)
				end))
			end))
		end)
		
		--local VictimRoot = VictimModel:FindFirstChild("HumanoidRootPart")

		--Job:Task(Animation:GetMarkerReachedSignal("zap"):Connect(function()
		--	quickutil:afterimage(Model, 1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, Color3.fromRGB(194, 217, 255), .6)

		--	clone_emit_part(effects.tproot["3"], RootPart)
		--	clone_emit_attach(effects.victim_root.hit3, VictimRoot)
			
		--	local mesh = meshes.thirdhit:Clone()
		--	mesh:PivotTo(RootPart.CFrame - Vector3.yAxis * 3)
			
		--	for _, Start in ipairs(mesh:GetDescendants()) do
		--		if Start.Name == "Start" then
		--			MeshEmit(Start, true)
		--		end
		--	end
			
		--	task.delay(1, mesh.Destroy, mesh)

		--	do
		--		local clone = resources.windaround:Clone()
		--		clone:PivotTo(RootPart.CFrame - Vector3.yAxis * 3)
		--		clone.Parent = workspace.Visuals

		--		quickutil:tween_single(clone, 1.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {["CFrame"] = clone.CFrame * CFrame.new(7, 3, 0)})
		--		quickutil:tween_descendant(clone, "Beam", 1.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {TextureSpeed = -.1, Brightness = 0}, true)
		--	end
			
		--	do
		--		local clone = resources.windback:Clone()
		--		clone:PivotTo(RootPart.CFrame - Vector3.yAxis * 3)
		--		clone.Parent = workspace.Visuals

		--		quickutil:tween_single(clone, 3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {["CFrame"] = clone.CFrame * CFrame.new(0, 0, -4)})
		--		quickutil:tween_descendant(clone, "Beam", 2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {TextureSpeed = .3, Brightness = 0}, true)
		--	end
			
		--	do
		--		local clone = resources.highlight:Clone()
		--		clone.Parent = Model
		--		quickutil:tween_single(clone, 1.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {FillTransparency = 1}, true)
		--	end
			
		--	for Index = 1, 12 do
		--		Smoke(RootPart, 5, 2)
		--		RockHandler.Rocks("Forward Dash", RootPart)
				
		--		task.wait(0.1)
		--	end
			
		--	--task.wait()

		--	--local clone = resources.dust:Clone()
		--	--clone:PivotTo(RootPart.CFrame - Vector3.yAxis * 3)
		--	--clone.Parent = workspace.Visuals

		--	--quickutil:tween_single(clone, 1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, {["CFrame"] = clone.CFrame * CFrame.new(0, 0, 12)})

		--	--task.delay(0.5, function()
		--	--	quickutil:interact(clone, "ParticleEmitter", "Enabled", false)
		--	--	task.delay(2, clone.Destroy, clone)
		--	--end)
		--end))
		
		clone_emit_part(effects.tproot.counterstart, RootPart)
	end,
}