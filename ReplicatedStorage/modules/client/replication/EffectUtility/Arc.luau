local EffectUtility = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Blood = require( ReplicatedStorage.modules.client.replication.Global.Blood )

function EffectUtility.ToggleAttachment(Attachment : Attachment, Value : boolean, DurationUntilDisable : number?)
	for _, Effect : ParticleEmitter in ipairs(Attachment:GetDescendants()) do
		if Effect:IsA("ParticleEmitter") or Effect:IsA("Trail") or Effect:IsA("Beam") then
			Effect.Enabled = Value
		end
	end

	if (DurationUntilDisable ~= nil and DurationUntilDisable > 0) then
		task.delay(DurationUntilDisable, EffectUtility.ToggleAttachment, Attachment, false)
	end
end

function EffectUtility.CloneAndEmit(VFX : Attachment, Parent : BasePart)
	local NewVFX = VFX:Clone()
	NewVFX.Parent = Parent
	EffectUtility.EmitAttachment(NewVFX)
	
	return NewVFX
end
	
function EffectUtility.EmitAttachment(Attachment : Attachment)
	local lifetime = 0
	
	for _, Effect in ipairs(Attachment:GetDescendants()) do
		if Effect:IsA("ParticleEmitter") and Blood.ParticleSupportsBlood(Effect) then
			local Attributes = Effect:GetAttributes()

			local EnableDuration : number = Attributes.EnableDuration or 0
			local EmitCount : number = Attributes.EmitCount or 1
			local EmitDelay = Attributes.EmitDelay or 0

			if (EmitDelay > 0) then
				task.delay(EmitDelay, Effect.Emit, Effect, EmitCount)
			else
				Effect:Emit(EmitCount)
			end

			if (EnableDuration > 0) then
				Effect.Enabled = true

				task.delay(EnableDuration, function()
					Effect.Enabled = false
				end)
			end
			
			lifetime = math.max(lifetime, ((Effect.Lifetime.Min + Effect.Lifetime.Max) + (EmitDelay + EnableDuration) / Effect.TimeScale))

		elseif Effect:IsA("Trail") then
			local EnableDuration : number = Effect:GetAttribute("EnableDuration") or 0

			if (EnableDuration > 0) then
				Effect.Enabled = true

				task.delay(EnableDuration, function()
					Effect.Enabled = false
				end)
			end
			
			lifetime = math.max(lifetime, EnableDuration)

		elseif Effect:IsA("Light") then
			local Attributes = Effect:GetAttributes()
			local EnableDuration : number = Attributes.EnableDuration or 0

			if (EnableDuration > 0) then
				local StartFade : number = Attributes.StartFade or 0
				local EndFade : number = Attributes.EndFade or 0

				local StartFadeStyle : number = Attributes.StartFadeStyle or "Cubic"
				local EndFadeStyle : number = Attributes.EndFadeStyle or "Cubic"

				local Brightness = Attributes.Brightness or Effect.Brightness

				if StartFade > 0 then
					Effect.Brightness = 0

					TweenService:Create(Effect, TweenInfo.new(StartFade, Enum.EasingStyle[StartFadeStyle], Enum.EasingDirection.Out),
						{Brightness = Brightness}
					):Play()
				else
					Effect.Brightness = Brightness
				end

				Effect.Enabled = true

				task.delay(EnableDuration, function()
					if EndFade > 0 then
						TweenService:Create(Effect, TweenInfo.new(EndFade, Enum.EasingStyle[EndFadeStyle], Enum.EasingDirection.Out),
							{Brightness = 0}
						):Play()

						task.delay(EndFade, function()
							Effect.Enabled = false
							Effect.Brightness = Brightness
						end)
					else
						Effect.Enabled = false
					end
				end)
				
				lifetime = math.max(lifetime, (StartFade + EndFade) + EnableDuration)
			end

		elseif Effect:IsA("Beam") then
			local Attributes = Effect:GetAttributes()
			local EnableDuration : number = Attributes.EnableDuration or 0

			if (EnableDuration > 0) then
				local StartFade : number = Attributes.StartFade or 0
				local EndFade : number = Attributes.EndFade or 0

				local StartFadeStyle : number = Attributes.StartFadeStyle or "Cubic"
				local EndFadeStyle : number = Attributes.EndFadeStyle or "Cubic"

				local Brightness = Attributes.Brightness or Effect.Brightness

				if StartFade > 0 then
					Effect.Brightness = 0

					TweenService:Create(Effect, TweenInfo.new(StartFade, Enum.EasingStyle[StartFadeStyle], Enum.EasingDirection.Out),
						{Brightness = Brightness}
					):Play()
				else
					Effect.Brightness = Brightness
				end

				Effect.Enabled = true

				task.delay(EnableDuration, function()
					if EndFade > 0 then
						TweenService:Create(Effect, TweenInfo.new(EndFade, Enum.EasingStyle[EndFadeStyle], Enum.EasingDirection.Out),
							{Brightness = 0}
						):Play()

						task.delay(EndFade, function()
							Effect.Enabled = false
							Effect.Brightness = Brightness
						end)
					else
						Effect.Enabled = false
					end
				end)
				
				lifetime = math.max(lifetime, (StartFade + EndFade) + EnableDuration) 
			end
		end
	end

	--for _, Effect in ipairs(Attachment:GetDescendants()) do
	--	if Effect:IsA("ParticleEmitter") and Blood.ParticleSupportsBlood(Effect) then
	--		local Attributes = Effect:GetAttributes()
			
	--		local EnableDuration : number = Attributes.EnableDuration or 0
	--		local EmitCount : number = Attributes.EmitCount or 1
	--		local EmitDelay = Attributes.EmitDelay or 0

	--		if (EmitDelay > 0) then
	--			task.delay(EmitDelay, Effect.Emit, Effect, EmitCount)
	--		else
	--			Effect:Emit(EmitCount)
	--		end

	--		if (EnableDuration > 0) then
	--			Effect.Enabled = true

	--			task.delay(EnableDuration, function()
	--				Effect.Enabled = false
	--			end)
	--		end
			
	--		lifetime = math.max(lifetime, ((Effect.Lifetime.Min + Effect.Lifetime.Max) + (EmitDelay + EnableDuration) / Effect.TimeScale))

	--	elseif Effect:IsA("PointLight") then
	--		local Attributes = Effect:GetAttributes()
	--		local EnableDuration : number = Attributes.EnableDuration or 0

	--		if (EnableDuration > 0) then
	--			local StartFade : number = Attributes.StartFade or 0
	--			local EndFade : number = Attributes.EndFade or 0

	--			local StartFadeStyle : number = Attributes.StartFadeStyle or "Cubic"
	--			local EndFadeStyle : number = Attributes.EndFadeStyle or "Cubic"

	--			local Brightness = Attributes.Brightness or Effect.Brightness

	--			if StartFade > 0 then
	--				Effect.Brightness = 0

	--				TweenService:Create(Effect, TweenInfo.new(StartFade, Enum.EasingStyle[StartFadeStyle], Enum.EasingDirection.Out),
	--					{Brightness = Brightness}
	--				):Play()
	--			else
	--				Effect.Brightness = Brightness
	--			end

	--			Effect.Enabled = true

	--			task.delay(EnableDuration, function()
	--				if EndFade > 0 then
	--					TweenService:Create(Effect, TweenInfo.new(EndFade, Enum.EasingStyle[EndFadeStyle], Enum.EasingDirection.Out),
	--						{Brightness = 0}
	--					):Play()

	--					task.delay(EndFade, function()
	--						Effect.Enabled = false
	--						Effect.Brightness = Brightness
	--					end)
	--				else
	--					Effect.Enabled = false
	--				end
	--			end)
				
	--			lifetime = math.max(lifetime, (StartFade + EndFade) + EnableDuration)
	--		end
	--	end
	--end
	
	task.delay(lifetime, Attachment.Destroy, Attachment)
end

return EffectUtility