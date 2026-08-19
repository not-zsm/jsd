-----------------------------
-- SERVICES --
-----------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-----------------------------
-- VARIABLES --
-----------------------------

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

-----------------------------
-- TYPES --
-----------------------------
export type EasingStyles = "Linear" | "Sine" | "Quad" | "Cubic" | "Quart" | "Quint" | "Exponential" | "Circular" | "Back" | "Bounce" | "Elastic"
export type EasingDirections = "In" | "Out" | "InOut"

export type ObjectWithChildren<Object> = Object & {[any]: any}

-----------------------------
-- LOCAL FUNCTIONS --
-----------------------------
local function can_show_blood()
	if RunService:IsServer() then
		print("you're emitting on the server, hiding all blood")
		return false
	end
	
	return (Players.LocalPlayer:GetAttribute("Blood") == true)
end

local function Debris<T>(Object: T, Time: number)
	task.delay(Time, function()
		if typeof(Object) == "Instance" and Object.Destroy then
			Object:Destroy()
		end
	end)

	return Object
end

local function EmitParticle(ParticleEmitter: ParticleEmitter, Lifetime: number)
	if (ParticleEmitter.Name:lower():match("blood")) and not can_show_blood() then
		return Lifetime
	end
	
	ParticleEmitter:Emit(ParticleEmitter:GetAttribute("EmitCount") or ParticleEmitter.Rate)
	return (ParticleEmitter.Lifetime.Max > Lifetime and ParticleEmitter.Lifetime.Max) or Lifetime
end

local function Emit(Object: (Model | BasePart | Attachment), Where: (CFrame | BasePart)?, CustomDebris: number?, Parent : Instance?)
	if Where then
		Object = Object:Clone()

		if Object:IsA("Attachment") then
			Object.Parent = Where -- ignore since "Where" should always be part when "VFX" is an attachment
		else
			if typeof(Where) == "CFrame" then
				if Object:IsA("Model") then
					Object:PivotTo(Where)
				else
					Object.CFrame = Where
				end
			else
				local WeldVFX = (Object:IsA("Model") and Object.PrimaryPart) or Object
				local Weld = Instance.new("Weld")
				Weld.Part0 = Where
				Weld.Part1 = WeldVFX
				Weld.Parent = WeldVFX
			end

			Object.Parent = Parent or workspace.Visuals
		end
	end

	local Lifetime = 0

	for _, ParticleEmitter in Object:GetDescendants() do
		if not ParticleEmitter:IsA("ParticleEmitter") then
			continue
		end

		local EmitDelay = ParticleEmitter:GetAttribute("EmitDelay")

		if EmitDelay and EmitDelay ~= 0 then
			task.delay(EmitDelay, function()
				if Object then
					Lifetime = EmitParticle(ParticleEmitter, Lifetime)
				end
			end)
		else
			Lifetime = EmitParticle(ParticleEmitter, Lifetime)
		end
	end

	task.delay(CustomDebris or Lifetime, function()
		if Object then
			Object:Destroy()
		end
	end)

	return Object
end

local function Enable(Type: (string | {string}), Object: Instance, Where: (BasePart? | CFrame?), Time: number?, Disable: boolean?, Parent : Instance?)
	if Where then
		Object = Object:Clone()

		if typeof(Where) == "CFrame" then
			Object.CFrame = Where
			Object.Parent = Parent or workspace.Visuals
			
		elseif Object:IsA("BasePart") then
			local Weld = Instance.new("Weld")
			Weld.Part0 = Where
			Weld.Part1 = Object
			Weld.Parent = Object
			Object.Parent = Parent or Where
		elseif Object:IsA("Attachment") then
			Object.Parent = Parent or Where
		end
	end

	local Enabled = {}
	local Lifetime = 0

	for _, Object in Object:GetDescendants() do
		if (typeof(Type) == "string" and not Object:IsA(Type)) or (typeof(Type) == "table" and not table.find(Type, Object.ClassName)) then
			continue
		end

		Object.Enabled = (not Disable and true) or false

		if Time then
			if not Object:IsA("Beam") then
				local ObjectLifetime = (typeof(Object.Lifetime) == "NumberRange" and Object.Lifetime.Max) or Object.Lifetime
				Lifetime = (ObjectLifetime > Lifetime and ObjectLifetime) or Lifetime
			end

			table.insert(Enabled, Object)
		end
	end

	if Time then
		task.delay(Time, function()
			for _, Object in Enabled do
				Object.Enabled = (Disable and true) or false
			end

			task.wait(Lifetime)

			if Object then
				Object:Destroy()
			end
		end)
	end

	return Object
end

local function Mesh(Mesh: BasePart, Where: (BasePart | CFrame | Vector3), RemoveTime: number?)
	local Mesh = Mesh:Clone()
	
	if typeof(Where) == "CFrame" then
		Mesh.CFrame = Where
	elseif typeof(Where) == "Vector3" then
		Mesh.Position = Where
	else
		Mesh.Anchored = false

		local Weld = Instance.new("Weld")
		Weld.Part0 = Where
		Weld.Part1 = Mesh
		Weld.Parent = Mesh
	end

	Mesh.Parent =  workspace.Visuals

	if RemoveTime then
		Debris(Mesh, RemoveTime)
	end

	return Mesh
end

function Tween(Object: Instance, Time: number, Style: EasingStyles, Direction: EasingDirections, Changes: {[string]: any})
	local TweenObject = TweenService:Create(Object, TweenInfo.new(tonumber(Time), Enum.EasingStyle[Style], Enum.EasingDirection[Direction]), Changes)
	TweenObject:Play()

	local function Cleanup()
		TweenObject:Destroy()
	end

	TweenObject.Completed:Connect(Cleanup)
	return TweenObject
end

-----------------------------
-- FUNCTIONS --
-----------------------------
local AutoEffectsFunctions
AutoEffectsFunctions = {
	Meshes = function(Container: any, Object: BasePart, Parent : Instance?)
		local StartCFrame = Object.CFrame

		local StartMesh: ObjectWithChildren<BasePart> = Container.Start
		local EndMesh: ObjectWithChildren<BasePart> = Container.End

		local Transparency: number = Container:GetAttribute("StartTransparency")
		local Distortion: boolean = Container:GetAttribute("Distortion")
		local Duration: number = Container:GetAttribute("Duration")
		local Welded: boolean = Container:GetAttribute("Welded")

		local PartParams: {string} = Container:GetAttribute("Part_TweenParams"):split(",")
		local PartEasingStyle = PartParams[1]
		local PartEasingDirection = PartParams[2]

		local Mesh: ObjectWithChildren<BasePart> = Debris(StartMesh:Clone(), Duration)

		if Distortion then
			local Highlight = Instance.new("Highlight")
			Highlight.Enabled = false
			Highlight.Parent = Mesh
		end

		if Welded then
			local Weld = Instance.new("Weld")
			Weld.Part0 = Object
			Weld.Part1 = Mesh
			Weld.C0 = StartMesh.CFrame

			Weld.Parent = Mesh
			Tween(Weld, Duration, PartEasingStyle, PartEasingDirection, {C0 = EndMesh.CFrame})
		else
			Mesh.CFrame = StartCFrame * StartMesh.CFrame
		end

		local DecalMesh = Mesh:IsA("Part")
		if DecalMesh then -- Decal Mesh
			local MeshParams: {string} = Container:GetAttribute("Mesh_TweenParams"):split(",")
			local MeshEasingStyle = MeshParams[1]
			local MeshEasingDirection = MeshParams[2]

			local DecalParams: {string} = Container:GetAttribute("Decal_TweenParams"):split(",")
			local DecalEasingStyle = DecalParams[1]
			local DecalEasingDirection = DecalParams[2]

			Mesh.Decal.Transparency = Transparency

			Tween(Mesh.Decal, Duration, DecalEasingStyle, DecalEasingDirection, {Transparency = tonumber(Container:GetAttribute("EndTransparency")) or 1})
			Tween(Mesh.Mesh, Duration, MeshEasingStyle, MeshEasingDirection, {Scale = EndMesh.Mesh.Scale})
		else
			Mesh.Transparency = Transparency
		end

		Tween(Mesh, Duration, PartEasingStyle, PartEasingDirection, {
			CFrame = (not Welded and StartCFrame * EndMesh.CFrame) or nil,
			Size = EndMesh.Size,
			Transparency = (not DecalMesh and Container:GetAttribute("EndTransparency")) or 1
		})

		Mesh.Parent = Parent or workspace.Visuals
	end,

	Emit = function(Effect: BasePart, Object: BasePart, Parent : Instance?)
		local ParentDirectory: string = Effect:GetAttribute("Parent")
		local Raycasted: Vector3 = Effect:GetAttribute("Raycast")
		local Where: (BasePart | CFrame) = Object

		if ParentDirectory then
			Where = Object.Parent

			for _, Name in ParentDirectory:split(".") do
				if not Where then
					return
				end

				Where = Where:FindFirstChild(Name)
			end
		end

		if Raycasted then
			local Origin = (Object.CFrame * Effect.CFrame).Position
			local Raycast = workspace:Raycast(Origin, Raycasted, Utility.VisualParams)

			if not Raycast then
				return
			end

			local RaycastHitOffset: Vector3 = Effect:GetAttribute("RaycastHitOffset") or Vector3.zero
			Where = CFrame.new(Raycast.Position + RaycastHitOffset) * (Object.CFrame - Object.Position)
		end

		Emit(Effect, Where, nil, Parent)
	end,

	Enabled = function(Effect: BasePart, Object: any, EffectParent : Instance?)
		local ParentDirectory: string = Effect:GetAttribute("Parent")
		local Parent = Object.Parent

		if ParentDirectory then
			for _, Name in ParentDirectory:split(".") do
				if not Parent then
					return
				end

				Parent = Parent:FindFirstChild(Name)
			end
		end

		if not Parent then
			return
		end

		local Time = tonumber(Effect:GetAttribute("Time"))
		Enable({"ParticleEmitter", "Trail", "Beam"}, Effect, Parent, Time, nil, EffectParent)
	end,
}

return function(Assets: any, Object: BasePart, Parent : Instance?)
	for _, EffectType in Assets:GetChildren() do
		if not AutoEffectsFunctions[EffectType.Name] then
			continue
		end

		for _, Container in EffectType:GetChildren() do
			AutoEffectsFunctions[EffectType.Name](Container, Object, Parent)
		end
	end
end
