local DojyanUtil = {}

function DojyanUtil.EmitAndRemove(NewEffect : Part) -- dont need to use this, deletes the vfx after all of the particles are hidden
	local Timer = DojyanUtil.Emit(NewEffect)
	task.delay(Timer, NewEffect.Destroy, NewEffect)
end

-- emit function
-- u already know about EmitCount
-- add the attribute "EnableDuration" that is a number to a particle to make it enable for that duration, stacks with emit count

function DojyanUtil.Emit(Effect : Part)
	local Timer = 0

	for _, ParticleEmitter : ParticleEmitter in pairs(Effect:GetDescendants()) do 
		if ParticleEmitter.ClassName == "ParticleEmitter" then 
			local Attributes = ParticleEmitter:GetAttributes()

			local EmitCount = Attributes.EmitCount or 1
			local EnableDuration = Attributes.EnableDuration or 0

			if EnableDuration > 0 then
				ParticleEmitter.Enabled = true

				task.delay(EnableDuration, function()
					ParticleEmitter.Enabled = false
				end)
			end

			ParticleEmitter:Emit(EmitCount)

			Timer = math.max(Timer, (
				(ParticleEmitter.Lifetime.Min + ParticleEmitter.Lifetime.Max) + EnableDuration) / ParticleEmitter.TimeScale
			)
		end 
	end

	return Timer
end

function DojyanUtil.VFXCFramedWithItself(Effect : Part, RootPart : BasePart) -- this what jsd uses since i just move all of the vfx at 0 0 0, automatically puts proper offsets in game
	local NewEffect = Effect:Clone()
	NewEffect.CFrame = RootPart.CFrame * Effect.CFrame
	NewEffect.Parent = workspace.Visuals
	DojyanUtil.EmitAndRemove(NewEffect)
end

return DojyanUtil
