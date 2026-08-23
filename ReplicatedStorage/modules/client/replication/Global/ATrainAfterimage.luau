local replicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )

local States = {}
local StateConnection = nil

local function StateStepped(Delta)
	for Character, State in States do
		if not Character:IsDescendantOf(workspace) then
			State:Destroy()
			continue
		end
		for i, AfterimageState in State.Afterimages do
			for i, v in AfterimageState.CharacterParts do
				v.CFrame = State.CharacterParts[i].CFrame + Vector3.new((math.sin(tick() * 40) * 0.8) * AfterimageState.TheMethod, math.sin(tick() * 0.2) * 0.1, (math.cos(tick() * 37.5) * 0.5) * -AfterimageState.TheMethod)
			end
		end
	end
end

local CleanClasses = {"Fire", "Sparkles", "Smoke", "ParticleEmitter", "Sound", "Trail", "Beam", "Attachment", "WeldConstraint", "BillboardGui"}
local CleanInstance, Clean = nil, nil

function CleanInstance(State, v)
	if v:IsA("LuaSourceContainer") or v:IsA("JointInstance") or v:IsA("Constraint") or table.find(CleanClasses, v.ClassName) then
		v:Destroy()
		return true
	elseif v:IsA("Decal") and not table.find(State.CharacterTextures, v) then
		table.insert(State.CharacterTextures, v)
	else
		for i, v in v:GetChildren() do
			CleanInstance(State, v)
		end
	end
end

local AfterimageClass = {
	Destroy = function(self)
		for i, v in self.Afterimages do v.Model:Destroy() end
		States[self.Model] = nil
	end,
}
local AfterimageMeta = {__index = AfterimageClass}

return function(Character, Toggle)
	if Toggle then
		if States[Character] then return end

		local State = setmetatable({Model = Character, CharacterParts = {}, CharacterOthers = {}, Afterimages = {}}, AfterimageMeta)

		for i, v in Character:GetDescendants() do
			if v:IsA("BasePart") and not v:GetAttribute("AfterimageIgnore") then
				table.insert(State.CharacterParts, v)
			end
		end

		for i, v in Character:GetChildren() do
			if v:IsA("Clothing") or v:IsA("ShirtTemplate") or v:IsA("CharacterMesh") or v:IsA("BodyColors") then
				table.insert(State.CharacterOthers, v)
			end
		end

		for i = 1, 2 do
			local AfterimageState = {
				TheMethod = i == 1 and -1 or 1,
				Model = nil, Humanoid = nil,
				CharacterParts = {},
				CharacterTextures = {},
				CharacterOthers = {},
			}

			local Model = Instance.new("Model")
			local Humanoid = Instance.new("Humanoid")
			Humanoid.DisplayDistanceType = "None"
			Humanoid.HealthDisplayType = "AlwaysOff"
			Humanoid.BreakJointsOnDeath = false
			Humanoid.EvaluateStateMachine = false
			Humanoid.RequiresNeck = false
			Humanoid.AutomaticScalingEnabled = false
			Humanoid.Parent = Model
			
			if i == 1 then
				for _, v in State.CharacterParts do
					local Clone = Instance.fromExisting(v)
					for i, v in v:GetChildren() do
						if v:IsA("DataModelMesh") or v:IsA("SurfaceAppearance") then
							local m = Instance.fromExisting(v)
							m.Parent = Clone
						elseif v:IsA("Texture") then
							local m = Instance.fromExisting(v)
							m.Parent = Clone
							table.insert(AfterimageState.CharacterTextures, m)
						end
					end
					Clone.CollisionGroup = "NoCollision"
					Clone.Anchored = true
					Clone.CanCollide = false
					Clone.CanTouch = false
					Clone.CanQuery = false
					Clone.Massless = true
					Clone.CastShadow = false
					Clone.Archivable = true
					Clone.Transparency = math.lerp(v.Transparency, 1, 0.7)
					table.insert(AfterimageState.CharacterParts, Clone)
					Clone.Parent = Model
				end
			else
				for _, v in State.Afterimages[1].CharacterParts do
					local Clone = v:Clone()
					Clone.Parent = Model
					table.insert(AfterimageState.CharacterParts, Clone)
				end
			end
			
			for _, v in AfterimageState.CharacterTextures do
				v.Transparency = math.lerp(v.Transparency, 1, 0.7)
			end

			for _, v in State.CharacterOthers do
				local Clone = Instance.fromExisting(v)
				Clone.Parent = Model
			end

			AfterimageState.Model = Model
			AfterimageState.Humanoid = Humanoid

			Model.Parent = workspace.Visuals
			table.insert(State.Afterimages, AfterimageState)
		end
		
		if not StateConnection then
			StateConnection = RunService.RenderStepped:Connect(StateStepped)
		end

		States[Character] = State
	else
		local State = States[Character]
		if State then State:Destroy() end
		if StateConnection and next(States) == nil then StateConnection:Disconnect() StateConnection = nil return end
	end
end