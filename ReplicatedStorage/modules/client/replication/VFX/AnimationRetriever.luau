local AnimationRetriever = {}

local replicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local Job = require( replicatedStorage.modules.shared.Utilities.Job )
local AenoirUtil = require( replicatedStorage.modules.shared.Utilities.Utility.AenoirUtil )

local Active = {}

function AnimationRetriever.RemoveActive(Model : Model, AnimName : string)
	if Active[Model] then
		Active[Model]:Destroy()
	end;
end;

export type Retrieved = {
	Animation : AnimationTrack,
	
	MainJob : Job.object,
	Job : Job.object,

	Model : Model,
	Torso : BasePart,
	Humanoid : Humanoid,
	RootPart : BasePart,
	Animator : Animator,
	
	IsLocalSource : boolean
}

function AnimationRetriever.new(Model : Model, Animation : Animation) : (Retrieved)
	if (Model == nil or Model.Parent == nil) then 
		return error("animation retriever: failed to get model")
	end
	
	local AnimName = Animation.Name
	AnimationRetriever.RemoveActive(Model, AnimName)
	
	local Torso : BasePart = Model and Model:FindFirstChild("Torso")
	local Humanoid : Humanoid = Model and Model:FindFirstChild("Humanoid")
	local RootPart : BasePart = Model and Model:FindFirstChild("HumanoidRootPart")
	local Animator : Animator = Humanoid and Humanoid:FindFirstChild("Animator")

	if (Torso == nil or Humanoid == nil or RootPart == nil or Animator == nil) then 
		return error("animation retriever: failed to get model children")
	end
	
	local Animation : AnimationTrack = AenoirUtil.WaitForAnimation(Animator, Animation.AnimationId, 3)
	
	if (Animation == nil) then
		return error("animation retriever: failed to get server animation on client with the name " .. Animation.Name .. ", probably isn't playing")
	end

	local MainJob = Job.new()
	local AnimationJob = Job.Extend(MainJob)
	
	-------------------------------------------------------------------
	
	MainJob:Task(function()
		if Active[Model] then
			Active[Model] = nil
		end
	end)
	
	MainJob:Task(Model.AncestryChanged:Connect(function(_, Parent)
		if (Parent == nil) then
			AnimationRetriever.RemoveActive(Model, AnimName)
		end
	end))

	MainJob:Task(Animation.Stopped:Connect(function()
		AnimationRetriever.RemoveActive(Model, AnimName)
	end))

	Active[Model] = MainJob
	
	-------------------------------------------------------------------
	
	return {
		Animation = Animation,
		
		MainJob = MainJob,
		Job = AnimationJob,
		
		Model = Model,
		Torso = Torso,
		Humanoid = Humanoid,
		RootPart = RootPart,
		Animator = Animator,
		
		IsLocalSource = (LocalPlayer.Character == Model)
	}
end

return AnimationRetriever