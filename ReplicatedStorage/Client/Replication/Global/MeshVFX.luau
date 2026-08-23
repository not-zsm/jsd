local TweenService = game:GetService("TweenService")
-- made by Fw_Yuki

--//setting up a custom type
export type MeshData = {
	CFrame : CFrame?,
	TweenDuration : number?,
	Duration : number?,
	TweenProperties : {[string] : any}?,
	TweenDelay : number?,
	MeshPart : MeshPart?,
	Parent : Instance?,
}

--//setting up default data, this is sort of like a CONFIG, basically when you leave things blank ot will use these
local DEFAULT_MESH_DATA : MeshData = {
	TweenDuration = 0.1,
	Duration = 1,
	TweenProperties = {
		Transparency = 1,
	},
	TweenDelay = 0,
	MeshPart = script.Part,
}

local TweenService = game:GetService(`TweenService`)
local RunService = game:GetService(`RunService`)

local meshEffects = {}

function meshEffects.new(meshData : MeshData, dontAnchor : boolean?)
	meshData = meshData or {} -- just incase they never passed through a table
	
	if not meshData.CFrame then -- check if a cframe was passed
		error(`[ERROR] Invalid CFrame " {meshData.CFrame}" passed through`) -- if not then throw out an error into the console
	end

	setmetatable(meshData, {__index = DEFAULT_MESH_DATA}) -- if any properties are missing they will get index

	local meshPart : MeshPart = meshData.MeshPart:Clone() do -- clone the part
		meshPart.Anchored = not dontAnchor
		meshPart.Massless = true
		meshPart.CanCollide = false
		meshPart.CFrame = meshData.CFrame -- adjust the CFrame
		meshPart.Parent = workspace.Visuals
	end

	--//tween stuff
	local tweenInfo = TweenInfo.new(meshData.TweenDuration, Enum.EasingStyle.Sine,Enum.EasingDirection.Out)
	local tweenFX = TweenService:Create(meshPart, tweenInfo, meshData.TweenProperties) -- define the tween

	task.delay(meshData.TweenDelay,function()
		if not meshPart:IsDescendantOf(game) then -- check if the mesh is still in the game
			tweenFX = nil -- a micro way to preserve data because as time goes on these build up
			return
		end

		tweenFX:Play() -- if the part is still in game, play the tween

		tweenFX.Completed:Once(function()
			tweenFX = nil -- when the tween is done set it to nil because of the same reason as before
		end)
	end)

	--//this is sort of an alternative to game:GetService(`Debris`):AddItem() because that is bad as it runs on 30hz
	task.delay(meshData.Duration, function()
		if not meshPart:IsDescendantOf(game) then -- check whether the mesh still exists
			return
		end
		meshPart:Destroy() -- destroy it
	end)

	-- tables take up alot of memory so clear them to save space

	setmetatable(meshData, nil)
	table.clear(meshData)
	meshData = nil

	return meshPart -- return the part just incase they want to do other stuff with it
end

return meshEffects