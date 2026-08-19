local TweenService = game:GetService("TweenService")

local module = {}

function module.MeshEmit(Mesh : Model & {Start : MeshPart, End : MeshPart}, Pivot : CFrame, TweenIn)	
	local Clone = Mesh:Clone()
	Clone.Start.CFrame = Pivot
	Clone.End.CFrame = Clone.Start.CFrame * Mesh.Start.CFrame:ToObjectSpace(Mesh.End.CFrame)
	Clone.Parent = workspace.Visuals

	TweenService:Create(Clone.Start, TweenInfo.new(unpack(TweenIn)), {
		Transparency = Clone.End.Transparency,
		Color = Clone.End.Color,

		Size = Clone.End.Size,
		CFrame = Clone.End.CFrame,
	}):Play()

	task.delay(TweenIn[1], Clone.Destroy, Clone)
end

local Meshes = script.Meshes

function module.HevayShockWave(Origin : CFrame)
	Origin = if typeof(Origin) == "CFrame" then Origin elseif table.find({"Vector3", "vector"}, typeof(Origin)) then CFrame.new(Origin) elseif typeof(Origin) == "Instance" and Origin:IsA("BasePart") then Origin.CFrame else error(`Not a valid origin type`)

	module.MeshEmit(
		Meshes.Mesh1,
		Origin * CFrame.new(2.09424019, 2.57967567, 0, 0, -0.999999523, 0, 5.96046661e-08, 0, -1.00000119, 0.999999404, 0, -2.98023295e-08),
		{2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out}
	)

	module.MeshEmit(
		Meshes.Ring,
		Origin * CFrame.new(2.09805489, 1.85861731, 0, 0, -1, 0, -1.00000119, 0, -2.98023295e-08, -2.98023295e-08, 0, -1),
		{0.85, Enum.EasingStyle.Quint, Enum.EasingDirection.Out}
	)

	module.MeshEmit(
		Meshes.Wind4,
		Origin * CFrame.new(2.49778938, 1.85864687, 0, 0, -1, 0, -0.25881961, 0, -0.965927005, 0.965925694, 0, -0.258819371),
		{1.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out}
	)
end

return module