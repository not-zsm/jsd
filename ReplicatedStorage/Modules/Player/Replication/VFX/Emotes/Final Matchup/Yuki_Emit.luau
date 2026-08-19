local EnableItems = {`ParticleEmitter`, `Beam`, `Trail`, `PointLight`, `SpotLight`}

local Utility = {}

function Utility.Enable(Container : Instance | {}, State : boolean)
	local Directory = if typeof(Container) == "Instance" then Container:GetDescendants() else Container

	if typeof(Container) == "Instance" and table.find(EnableItems, Container.ClassName) then
		Container.Enabled = State
	end

	for _, Item in Directory do
		if typeof(Item) == `table` then
			Utility.Enable(Item, State) continue
		end

		if not table.find(EnableItems, Item.ClassName) then
			continue
		end

		Item.Enabled = State
	end
end

function Utility.Emit(Container : Instance | {})
	local Directory = if typeof(Container) == "Instance" then Container:GetDescendants() else Container

	for _, Item : ParticleEmitter in Directory do
		if typeof(Item) == `table` then
			Utility.Emit(Item) continue
		end

		if not table.find({`ParticleEmitter`}, Item.ClassName) then
			continue
		end

		task.spawn(function()
			if Item:GetAttribute("EmitDelay") then
				task.wait(Item:GetAttribute("EmitDelay"))
			end

			Item:Emit(Item:GetAttribute("EmitCount") or Item:GetAttribute("Rate") or Item.Rate)

			if Item:GetAttribute("EmitDuration") then
				Utility.Enable(Item, true)

				task.wait(tonumber(Item:GetAttribute("EmitDuration")))

				Utility.Enable(Item, false)
			end
		end)
	end
end

function Utility.GetMaxLifetime(Item : Instance | {})
	if typeof(Item) == "Instance" and Item:GetAttribute("Lifetime") then
		return Item:GetAttribute("Lifetime")
	else
		local Return = 0

		local Directory = typeof(Item) == "Instance" and Item:GetDescendants() or Item

		for _, Emitter in Directory do
			if typeof(Emitter) ~= "Instance" then
				continue
			end

			if not Emitter:IsA("ParticleEmitter") then
				continue
			end

			local Attributes = Emitter:GetAttributes()

			local EmitDuration = Attributes["EmitDuration"] or 0
			local EmitDelay =  Attributes["EmitDelay"] or 0
			local LifeTime = (Emitter.Lifetime.Max + EmitDuration + EmitDelay) / Emitter.TimeScale

			if Attributes["Lifetime"] then
				LifeTime = math.max(LifeTime, Attributes["LifeTime"])
			end

			if Return < LifeTime and LifeTime < 1e999 then
				Return = LifeTime
			end
		end

		return Return
	end
end

function Utility.DisableRemove(Item : Instance)
	if Item == nil then
		return
	end

	Utility.Enable(Item, false)

	task.wait(Utility.GetMaxLifetime(Item))

	if Item == nil then
		return
	end

	Item:Destroy()
end

function Utility.SimpleEmit(Effect : Instance, Origin : CFrame, Parent : Instance?)
	Parent = Parent or workspace.Terrain
	
	local Clone = Effect:Clone()
	Clone.CFrame = Origin
	Clone.Parent = Parent
	
	Utility.Emit(Clone)
	
	task.delay(Utility.GetMaxLifetime(Clone), Clone.Destroy, Clone)
end

return Utility