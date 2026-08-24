local VFX = {};

local replicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )
local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )

local CameraShake = require( replicatedStorage.modules.client.replication.Global.CameraShake )
local RockHandler = require( replicatedStorage.modules.client.replication.Global.RockHandler )

local Vignette = require( replicatedStorage.modules.client.replication.Global.Vignette )

local MeshVFX = require( replicatedStorage.modules.client.replication.VFX.kratos["Wall Combo"].MeshVFX )

--local MeshVFX = require( script.MeshVFX )

local Meshes = script.Meshes

function VFX.LeftStartup(RootPart : BasePart)
	local FX = script.Holder.Left:Clone()
	FX.Parent = RootPart

	EffectUtility.EmitAttachment(FX)
end

function VFX.RightStartup(RootPart : BasePart)
	local FX = script.Holder.Right:Clone()
	FX.Parent = RootPart

	EffectUtility.EmitAttachment(FX)
end

function VFX.FrontStartup(RootPart : BasePart)
	local FX = script.Holder.Front:Clone()
	FX.CFrame = CFrame.new(0,0,-2) * CFrame.Angles(0, math.pi, 0)
	FX.Parent = RootPart

	EffectUtility.EmitAttachment(FX)
	
	if (LocalPlayer:DistanceFromCharacter(RootPart.Position) < 25) then
		CameraShake(8, 4, 0.15, 0.5, Vector3.one * 0.8)
	end

	local Positions = {
		["ehe1"] = CFrame.new(0, 0, -12) * CFrame.Angles(math.rad(-90), 0, 0);
		["ehe2"] = CFrame.new(0, 0, -12) * CFrame.Angles(math.rad(-90), 0, 0);
		["ehe3"] = CFrame.new(0, 0, -15) * CFrame.Angles(math.rad(-90), 0, 0);
		["ehe4"] = CFrame.new(0, 0, -18) * CFrame.Angles(0, 0, 0);
		["ehe5"] = CFrame.new(0, 0, -16) * CFrame.Angles(0, math.rad(-90), 0);
		["ehe6"] = CFrame.new(0, 0, -14) * CFrame.Angles(0, math.rad(-90), 0);
		["ehe7"] = CFrame.new(0, 0, -15) * CFrame.Angles(0, math.rad(-90), 0);
	} -- i also have to do something like this on the limitless strikes finisher the same dude who did this vfx did that too

	for Index, Mesh : Model in Meshes.swing3:GetChildren() do
		if Positions[Mesh.Name] then
			local NewCFrame = Positions[Mesh.Name]

			Mesh:PivotTo(RootPart.CFrame * NewCFrame)
			MeshVFX.Emit(Mesh)
		end
	end
end

local Flames = {}

function VFX.EnableFlames(RootPart, BladeObjects)
	Flames[RootPart] = {}
	
	for _, Blade : Model in BladeObjects do
		for _, BasePart in Blade:GetChildren() do
			if BasePart:IsA("BasePart") then
				local FlamesClone = script.Flames:Clone()

				for Index, Flame in FlamesClone:GetChildren() do
					Flame.Enabled = true
					Flame.Parent = BasePart
					table.insert(Flames[RootPart], Flame)
				end

				FlamesClone:Destroy()
			end
		end
	end
end

function VFX.DisableFlames(RootPart)
	if (RootPart == nil or RootPart.Parent == nil) or (Flames[RootPart] == nil) then return end
	
	for _, Item in Flames[RootPart] do
		if typeof(Item) == "Instance" and Item:IsA("ParticleEmitter") then
			Item.Enabled = false
			task.delay(1, Item.Destroy, Item)
		end
	end

	table.clear(Flames[RootPart])
	Flames[RootPart] = nil
end

function VFX.SpinSlash(RootPart : BasePart)
	local FX = script.Holder.SpinSlash:Clone()
	FX.Parent = RootPart

	EffectUtility.EmitAttachment(FX)

	if (LocalPlayer:DistanceFromCharacter(RootPart.Position) < 25) then
		Vignette(Color3.fromRGB(213, 110, 19), 0.35)
		CameraShake(8, 7, 0.05, 0.15, Vector3.one)
	end

	local Positions = {
		["ehe1"] = CFrame.new(0, -3, -8);
		["ehe2"] = CFrame.new(0, -3, -8);
		["ehe3"] = CFrame.new(0, -3, -8);
		["ehe4"] = CFrame.new(0, -3, -8);
		["ehe5"] = CFrame.new(0, -3, -8);
		["ehe6"] = CFrame.new(0, -3, -8);
		["ehe7"] = CFrame.new(0, -3, -8);
		["ehe8"] = CFrame.new(0, -3, -10);
		["ehe9"] = CFrame.new(0, -3, -8);
	} 

	for Index, Mesh : Model in Meshes.slash1:GetChildren() do
		if Positions[Mesh.Name] then
			local NewCFrame = Positions[Mesh.Name]

			Mesh:PivotTo(RootPart.CFrame * NewCFrame)
			MeshVFX.Emit(Mesh)
		end
	end
end

local SparksStuff = {}

function VFX.SparksStart(BladeObjects)
	for _, Blade : Model in BladeObjects do
		local BladeMesh = Blade:FindFirstChildOfClass("MeshPart")
		local Sparks = BladeMesh:FindFirstChild("Sparks")

		if not Sparks then
			local FX = script.Holder.Sparks:Clone()
			FX.Parent = BladeMesh
		end
	end
end

function VFX.SparksEnd(BladeObjects)
	for _, Blade : Model in BladeObjects do
		local BladeMesh = Blade:FindFirstChildOfClass("MeshPart")
		local Sparks = BladeMesh:FindFirstChild("Sparks")

		if Sparks then
			EffectUtility.Toggle(Sparks, false)
			task.delay(2, Sparks.Destroy, Sparks)
		end
	end
end

local SpinStuff = {}

function VFX.StartSpin(RootPart : BasePart)
	local FX = script.Spin:Clone()
	FX.CFrame = RootPart.CFrame
	FX.Parent = workspace.Visuals

	EffectUtility.Weld(FX, RootPart, CFrame.new(0,-0.5, -4) * CFrame.Angles(0, math.pi, 0))
	EffectUtility.Weld(FX.ground, RootPart, CFrame.new(0, -2.5, 1) * CFrame.Angles(0, math.pi, 0))
	EffectUtility.Weld(FX.hits, RootPart, CFrame.new(0,-0.5, 2))

	for _, Particle in FX:GetDescendants() do
		if Particle:IsA("ParticleEmitter") then
			Particle.Enabled = true
		end
	end

	SpinStuff[RootPart] = {FX}	
end

function VFX.StopSpin(RootPart : BasePart)
	if (RootPart == nil or RootPart.Parent == nil) or (SpinStuff[RootPart] == nil) then return end

	for _, Item in SpinStuff[RootPart] do
		if typeof(Item) == "Instance" and Item:IsA("BasePart") then
			EffectUtility.Toggle(Item, false)
			task.delay(2, Item.Destroy, Item)
		end
	end

	table.clear(SpinStuff[RootPart])
	SpinStuff[RootPart] = nil
end

function VFX.Slash(RootPart : BasePart)
	local FX = script.Slash2:Clone()
	FX.CFrame = RootPart.CFrame
	FX.Parent = workspace.Visuals

	EffectUtility.Weld(FX, RootPart, CFrame.new(0, -0.5, -12) * CFrame.Angles(0, 0, math.rad(30)))
	EffectUtility.Weld(FX.yes, RootPart, CFrame.new(0, -0.5, -14) * CFrame.Angles(0, 0, math.rad(30)))
	
	EffectUtility.Emit(FX)

	VFX.Hit(RootPart)
end

function VFX.Uppercut(RootPart : BasePart)
	local FX = script.Uppercut:Clone()
	FX.CFrame = RootPart.CFrame
	FX.Parent = workspace.Visuals
	
	EffectUtility.Weld(FX, RootPart, CFrame.new(0, -0.5, -12))
	EffectUtility.Weld(FX.yes, RootPart, CFrame.new(0, -0.5, -12) * CFrame.Angles(0, 0, math.rad(90)))
	
	EffectUtility.Emit(FX)

	VFX.Hit(RootPart)
end

function VFX.Jump(RootPart : BasePart)
	local FX = script.Jump:Clone()
	FX.CFrame = RootPart.CFrame * CFrame.new(0, -4, -11)
	FX.Parent = workspace.Visuals

	EffectUtility.Emit(FX)
end

function VFX.Slam(RootPart : BasePart)
	local FX = script.Slam:Clone()
	FX.CFrame = RootPart.CFrame * CFrame.new(0, -1, -8)
	FX.Parent = workspace.Visuals

	EffectUtility.Emit(FX)

	if (LocalPlayer:DistanceFromCharacter(RootPart.Position) < 25) then
		Vignette(Color3.fromRGB(213, 110, 19), 0.15)
		CameraShake(12, 7, 0.15, 0.5, Vector3.one)
	end

	local Positions = {
		["ehe1"] = CFrame.new(0, -4, -8);
		["ehe2"] = CFrame.new(0, -4, -10);
		["ehe3"] = CFrame.new(0, -4, -8);
		["ehe4"] = CFrame.new(0, -4, -8);
		["ehe5"] = CFrame.new(0, -4, -10);
		["ehe6"] = CFrame.new(0, -12, -8);
		["ehe7"] = CFrame.new(0, -10, -8);
		["ehe8"] = CFrame.new(0, -8, -10);
		["ehe9"] = CFrame.new(0, -8, -8);
		["ehe10"] = CFrame.new(0, -12, -10);
	} 

	for Index, Mesh : Model in Meshes.slam:GetChildren() do
		if Positions[Mesh.Name] then
			local NewCFrame = Positions[Mesh.Name]

			Mesh:PivotTo(RootPart.CFrame * NewCFrame)
			MeshVFX.Emit(Mesh)
		end
	end
end

function VFX.Hit(RootPart : BasePart)
	if (LocalPlayer:DistanceFromCharacter(RootPart.Position) < 25) then
		Vignette(Color3.fromRGB(213, 110, 19), 0.35)
		CameraShake(5.8, 5.1, 0.05, 0.1, Vector3.one * 0.75)
	end
end

return VFX