local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local StardustCrusaderAssets = ReplicatedStorage.Effects.Characters["Stardust Crusader"]

local SFX = StardustCrusaderAssets.SFX
local VFX = StardustCrusaderAssets.VFX

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

return {
	Hit = function(Attacker : Model, Victim : Model, Pushed : boolean)
		if EffectUtility.Distance_Close(Victim) then
			
			if Pushed then
				CameraShake(5, 45, 0.01, 0.6, Vector3.one * 0.8, Vector3.one * 0.5)
			else
				CameraShake(2, 20, 0.01, 0.5, Vector3.one * 0.8, Vector3.one * 0.3)
			end
			
			Vignette(Color3.fromRGB(109, 60, 255), 0.75, 0.2)
		end
		
		Blood.BloodRaysWithoutPreset(Victim.Head, {
			Power = 35,

			Amount = Vector2.new(7, 10),
			Spread = Vector2.new(65, 65),

			Face = Enum.NormalId.Front,

			Color = Color3.fromRGB(66, 0, 0),

			PoolSize = 1.6,

			PoolDuration = 5,
			PoolDurationTransition = 1.5,
		})
		
		local LookAtCF = CFrame.lookAt(Victim.PrimaryPart.Position, Attacker.PrimaryPart.Position)

		local NewSFX = SFX.HeavyHit:Clone()
		NewSFX.Parent = Victim.PrimaryPart
		
		local Heavy = VFX.Heavy:Clone()
		Heavy.WorldCFrame = LookAtCF * CFrame.Angles(math.rad(90), math.pi, 0)
		Heavy.Parent = workspace.Terrain

		local Size_I_Like = Vector3.new(10, 2, 10)

		local Mesh = VFX.Shockwave:Clone()
		Mesh.Size = Size_I_Like * 0.1
		Mesh:PivotTo(LookAtCF * CFrame.Angles(math.rad(90), 0, 0))
		Mesh.Parent = workspace.Visuals

		task.delay(5, NewSFX.Destroy, NewSFX)
		task.delay(0.6, Mesh.Destroy, Mesh)

		NewSFX:Play()
		EffectUtility.Arc.EmitAttachment(Heavy)
		EffectUtility.CloneAndEmit(VFX.HeavyHit, Victim.PrimaryPart)
		
		TweenService:Create(Mesh, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{Size = Size_I_Like * 1.5, CFrame = Mesh:GetPivot() * CFrame.new(0, 0, -0.5) * CFrame.Angles(0, math.pi * 5, 0), Transparency = 1}
		):Play()
	end,
}