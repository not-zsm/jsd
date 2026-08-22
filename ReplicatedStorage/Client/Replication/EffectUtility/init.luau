local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local CraterDust = ReplicatedStorage.Effects.Smoke

local Blood = require( ReplicatedStorage.Client.Replication.Global.Blood )
local Utility = require( ReplicatedStorage.Shared.Utilities.Utility )
local Job = require( ReplicatedStorage.Shared.Utilities.Job )

local UndefinedTimeout = 60;

local EffectUtility = {}
EffectUtility.AenoirEmit = require(script.AenoirEmit)
EffectUtility.Arc = require(script.Arc)
EffectUtility.Dojyan = require(script.Dojyan)
-- love u guys, u guys my everything ❤	if EffectUtility.Distance_Close(Model) then

function EffectUtility.Toggle(Item : Instance, Value : boolean, SearchChildrenOnly : boolean?)
	assert(Item, "No Item");
	
	if SearchChildrenOnly then
		for _, Item in ipairs(Item:GetChildren()) do
			if Item:IsA("ParticleEmitter") or Item:IsA("Trail") or Item:IsA("Beam") or Item:IsA("PointLight") then
				Item.Enabled = Value
			end
		end
	else
		for _, Item in ipairs(Item:GetDescendants()) do
			if Item:IsA("ParticleEmitter") or Item:IsA("Trail") or Item:IsA("Beam") or Item:IsA("PointLight") then
				Item.Enabled = Value
			end
		end
	end
end

function EffectUtility.ToggleForTime(Item : Instance, Duration : number, SearchChildrenOnly : boolean, DontDestroy : boolean)
	assert(Item, "No Item");
	EffectUtility.Toggle(Item, true, SearchChildrenOnly)
	task.delay(Duration, EffectUtility.Toggle, Item, false, SearchChildrenOnly)
	
	if not DontDestroy then
		task.delay(Duration * 2, Item.Destroy, Item)
	end
end

local function PlaySound(Sound : Sound, OnPlayed : (Length : number) -> ())
	local WasLoaded = Sound.IsLoaded
	
	local function Play()
		if OnPlayed then
			OnPlayed(Sound.TimeLength)
		end

		Sound:Play()
	end

	if not WasLoaded then
		Sound.Loaded:Once(Play)
	else
		Play()
	end
	
	return WasLoaded
end

--local function PlaySound(Sound : Sound, Folder : Folder, Parent : Instance, OnPlayed : (Length : number) -> ())
	--local WasLoaded = Sound.IsLoaded
	--local Parented = false
	
	--local function Play()
		--if WasLoaded and Parented then
		--	task.delay(Sound.TimeLength, Sound.Destroy, Sound)
		--end
		
		--if OnPlayed then
		--	OnPlayed(Sound.TimeLength)
		--end
		
		--Sound:Play()
	--end

	--if not WasLoaded then
	--	if not Parented and (Parent and Parent.Parent ~= nil and Parent.ClassName == "Part") then
	--		Sound.Parent = Parent
	--		Parented = true
	--	end

	--	Sound.Loaded:Once(Play)
	--else
	--	Play()
	--end
--end

local EventService = require( ReplicatedStorage.Shared.Utilities.EventService )

function EffectUtility.Emit(_Instance : Instance, DontRemove : boolean?)
	local ToCreateThread = false
	local Thread

	local Lifetime = 0
	local Items = {}
	
	local function UpdateLifetime(Length : number)
		if Thread then
			task.cancel(Thread)
		end

		Lifetime = math.max(Lifetime, Length)
		
		if ToCreateThread then
			Thread = task.delay(Lifetime, _Instance.Destroy, _Instance)
		end
	end
	
	for _, Item in ipairs(_Instance:GetDescendants()) do
		if Item:IsA("ParticleEmitter") and Blood.ParticleSupportsBlood(Item) then
			Item.Name = "Particle"
			Items[Item] = true
			
			if (Item:GetAttribute("EmitDuration") ~= nil and Item:GetAttribute("EmitDuration") ~= 0) then
				Item.Enabled = true
				
				task.delay(Item:GetAttribute("EmitDuration"), function()
					Item.Enabled = false
				end)
				
				UpdateLifetime((Item:GetAttribute("EmitDuration") + (Item.Lifetime.Min + Item.Lifetime.Max)) / Item.TimeScale)
				--Lifetime = math.max(Lifetime, (Item:GetAttribute("EmitDuration") + (Item.Lifetime.Min + Item.Lifetime.Max)) / Item.TimeScale)
			else
				local EmitCount = Item:GetAttribute("EmitCount") or 1
				local EmitDelay = Item:GetAttribute("EmitDelay") or 0

				if (EmitDelay ~= 0) then
					task.delay(EmitDelay, Item.Emit, Item, EmitCount)
					UpdateLifetime((EmitDelay + (Item.Lifetime.Min + Item.Lifetime.Max)) / Item.TimeScale)
					--Lifetime = math.max(Lifetime, (EmitDelay + (Item.Lifetime.Min + Item.Lifetime.Max)) / Item.TimeScale)
				else
					Item:Emit(EmitCount)
					UpdateLifetime((Item.Lifetime.Min + Item.Lifetime.Max) / Item.TimeScale)
					--Lifetime = math.max(Lifetime, (Item.Lifetime.Min + Item.Lifetime.Max) / Item.TimeScale)
				end
			end
			
 		
		elseif Item:IsA("Sound") then
			Item.Name = "Sound"

			--local WasLoaded = PlaySound(Item, _Instance, _Instance, function(Length : number)
			--	Lifetime = math.max(Lifetime, Length)
			--end)
			
			local WasLoaded = PlaySound(Item, UpdateLifetime)
			
			if not WasLoaded then
				UpdateLifetime(UndefinedTimeout)
			end
			
			Items[Item] = true
		end
	end

	if not DontRemove then
		ToCreateThread = true
		UpdateLifetime(Lifetime)
	end
	
	return Items :: {[Instance] : boolean}, Lifetime
end

function EffectUtility.CloneAndEmit(Item : Attachment | BasePart | ParticleEmitter, Parent : Instance, DontRemove : Boolean?)
	--if not LocalPlayer:GetAttribute("Blood") then
	--	if Item.Parent == ReplicatedStorage.Effects.Blood then
	--		return
	--	end
	--end
	
	local Effect = Item:Clone()
	Effect.Parent = Parent
	
	if Item:IsA("ParticleEmitter") then
		Effect:Emit(Effect:GetAttribute("EmitCount") or 1)
	else
		EffectUtility.Emit(Effect, DontRemove)
	end
	
	return Effect
end

function EffectUtility.CloneAndToggle(Item : Attachment | BasePart | ParticleEmitter, Parent : Instance, Value : Bolean, SearchChildrenOnly : Bolean)
	local Effect = Item:Clone()
	Effect.Parent = Parent

	EffectUtility.Toggle(Item, (Value or true), SearchChildrenOnly)

	return Effect
end

EffectUtility.EmitAttachment = EffectUtility.Emit

function EffectUtility.EmitEffects(Folder : Folder, Parent : Instance, WorldPosition : (CFrame | Vector3), NormalPosition : (CFrame | Vector3))
	--local Lifetime = 0
	--local Items = {}
	
	local ToCreateThread = false
	local Thread

	local Lifetime = 0
	local Items = {}

	local Attachment = Instance.new("Attachment")
	
	local function UpdateLifetime(Length : number)
		if Thread then
			task.cancel(Thread)
		end

		Lifetime = math.max(Lifetime, Length)

		if ToCreateThread then
			Thread = task.delay(Lifetime, Attachment.Destroy, Attachment)
		end
	end
	
	if (WorldPosition ~= nil) then
		if typeof(WorldPosition) == "Vector3" then
			Attachment.WorldPosition = WorldPosition
			
		elseif typeof(WorldPosition) == "CFrame" then
			Attachment.WorldCFrame = WorldPosition
		end
		
	elseif (NormalPosition ~= nil) then
		if typeof(NormalPosition) == "Vector3" then
			Attachment.Position = NormalPosition

		elseif typeof(NormalPosition) == "CFrame" then
			Attachment.CFrame = NormalPosition
		end
	end
	
	Attachment.Parent = Parent
	
	local function Search()
		for _, Item in ipairs(Folder:GetChildren()) do
			if Item:IsA("Folder") and Item.Name == "Random" then
				local ChosenItem = Item[math.random(1, #Item:GetChildren())]:Clone()
				ChosenItem.Name = "RandomSound"
				ChosenItem.Parent = Attachment

				local WasLoaded = PlaySound(ChosenItem, UpdateLifetime)

				if not WasLoaded then
					UpdateLifetime(UndefinedTimeout)
				end

				--PlaySound(ChosenItem, Folder, Parent, function(Length : number)
				--	Lifetime = math.max(Lifetime, Length)
				--end)

				Items[ChosenItem] = true

			elseif Item:IsA("ParticleEmitter") and Blood.ParticleSupportsBlood(Item) then

				local NewItem = Item:Clone()
				NewItem.Name = "Particle"
				NewItem.Parent = Attachment

				if (NewItem:GetAttribute("EmitDuration") ~= nil and NewItem:GetAttribute("EmitDuration") ~= 0) then
					NewItem.Enabled = true

					task.delay(NewItem:GetAttribute("EmitDuration"), function()
						NewItem.Enabled = false
					end)

					UpdateLifetime(
						(NewItem:GetAttribute("EmitDuration") + (NewItem.Lifetime.Min + NewItem.Lifetime.Max)) / NewItem.TimeScale
					)
					
					--Lifetime = math.max(Lifetime, (NewItem:GetAttribute("EmitDuration") + (NewItem.Lifetime.Min + NewItem.Lifetime.Max)) / NewItem.TimeScale)
				else
					local EmitCount = NewItem:GetAttribute("EmitCount") or 1
					local EmitDelay = NewItem:GetAttribute("EmitDelay") or 0

					if (EmitDelay ~= 0) then
						task.delay(EmitDelay, NewItem.Emit, NewItem, EmitCount)
						
						UpdateLifetime(
							(EmitDelay + (NewItem.Lifetime.Min + NewItem.Lifetime.Max)) / NewItem.TimeScale
						)
						
						--Lifetime = math.max(Lifetime, (EmitDelay + (NewItem.Lifetime.Min + NewItem.Lifetime.Max)) / NewItem.TimeScale)
					else
						NewItem:Emit(EmitCount)
						
						UpdateLifetime(
							(NewItem.Lifetime.Min + NewItem.Lifetime.Max) / NewItem.TimeScale
						)
						
						--Lifetime = math.max(Lifetime, (NewItem.Lifetime.Min + NewItem.Lifetime.Max) / NewItem.TimeScale)
					end
				end

				Items[NewItem] = true

			elseif Item:IsA("Sound") then
				local NewItem = Item:Clone()
				NewItem.Name = "Sound"
				NewItem.Parent = Attachment
				
				local WasLoaded = PlaySound(NewItem, UpdateLifetime)

				if not WasLoaded then
					UpdateLifetime(UndefinedTimeout)
				end

				--local WasLoaded = PlaySound(NewItem, Folder, Parent, function(Length : number)
				--	Lifetime = math.max(Lifetime, Length)
				--end)
				
				--if not WasLoaded then
				--	Lifetime = UndefinedTimeout
				--end

				Items[NewItem] = true
			end
		end
	end

	if LocalPlayer then
		if not (not LocalPlayer:GetAttribute("Blood") and Folder:IsDescendantOf(ReplicatedStorage.Effects.Blood)) then
			Search()
		end
	else
		Search()
	end
	
	ToCreateThread = true;
	UpdateLifetime(Lifetime)
	--task.delay(Lifetime, Attachment.Destroy, Attachment)

	return Items :: {[Instance] : boolean}, Attachment
end

function EffectUtility.EmitEffectsOnBasePart(Folder : Folder, Parent : BasePart)
	local Particles = {}

	for _, Item in ipairs(Folder:GetChildren()) do
		if Item:IsA("Folder") and Item.Name == "Random" then
			local ChosenItem = Item[math.random(1, #Item:GetChildren())]:Clone()
			ChosenItem.Name = "RandomSound"
			ChosenItem.Parent = Parent
			
			PlaySound(ChosenItem, function(Length : number)
				task.delay(Length, ChosenItem.Destroy, ChosenItem)
			end)
			
			table.insert(Particles, ChosenItem)

		elseif Item:IsA("ParticleEmitter") and Blood.ParticleSupportsBlood(Item) then

			local NewItem = Item:Clone()
			NewItem.Name = "Particle"

			table.insert(Particles, NewItem)
			NewItem.Parent = Parent

			if (NewItem:GetAttribute("EmitDuration") ~= nil and NewItem:GetAttribute("EmitDuration") ~= 0) then
				NewItem.Enabled = true

				task.delay(NewItem:GetAttribute("EmitDuration"), function()
					NewItem.Enabled = false
				end)

				task.delay((NewItem.Lifetime.Min + NewItem.Lifetime.Max), NewItem.Destroy, NewItem)
			else
				local EmitCount = NewItem:GetAttribute("EmitCount") or 1
				local EmitDelay = NewItem:GetAttribute("EmitDelay") or 0

				if (EmitDelay ~= 0) then
					task.delay(EmitDelay, NewItem.Emit, NewItem, EmitCount)
					task.delay((EmitDelay + (NewItem.Lifetime.Min + NewItem.Lifetime.Max)), NewItem.Destroy, NewItem)
				else
					NewItem:Emit(EmitCount)
					task.delay((NewItem.Lifetime.Min + NewItem.Lifetime.Max), NewItem.Destroy, NewItem)
				end
			end

		elseif Item:IsA("Sound") then

			local NewItem = Item:Clone()
			NewItem.Name = "Sound"
			NewItem.Parent = Parent

			PlaySound(NewItem, function(Length : number)
				task.delay(Length, NewItem.Destroy, NewItem)
			end)
			
			table.insert(Particles, NewItem)
		end
	end

	return Particles
end

local FakeWeld = require( script.FakeWeld )
EffectUtility.Weld = FakeWeld.new

--function EffectUtility.Weld(Pivoted : (BasePart | Model), Follow : (BasePart | Attachment), AdditionalOffset : CFrame)
--	AdditionalOffset = AdditionalOffset or CFrame.identity

--	local IsAttachment = Follow:IsA("Attachment")

--	local function UpdateFakeWeld()
--		Pivoted:PivotTo((IsAttachment and Follow.WorldCFrame or Follow.CFrame) * AdditionalOffset)
--	end
	
--	local RenderName = ("Weld" .. Pivoted:GetFullName())
--	local NewJob = Job.new()
	
--	NewJob:Task(function()
--		RunService:UnbindFromRenderStep(RenderName)
--	end)
	
--	NewJob:Task(Pivoted.AncestryChanged:Connect(function(_, Parent)
--		if (Parent == nil) then
--			NewJob:Destroy()
--		end
--	end))
	
--	RunService:BindToRenderStep(RenderName, Enum.RenderPriority.Camera.Value - 1, UpdateFakeWeld)
--	UpdateFakeWeld()
--end

function EffectUtility.WeldArmTrail(Limb : BasePart) : typeof(ReplicatedStorage.Effects.Parts.Arm) -- welds cause weird mass behavior which made me crash out and break my keyboard (im not joking)
	if not Limb:IsA("BasePart") then
		warn("cannot do trail on a non limb")
		
		return nil
	end
	
	local FakeArm = ReplicatedStorage.Effects.Parts.Arm:Clone()
	FakeArm.Name = Limb.Name .. " Trail"
	FakeArm.CFrame = Limb.CFrame
	EffectUtility.Weld(FakeArm, Limb)

	FakeArm.Parent = workspace.Visuals
	EffectUtility.Toggle(FakeArm, true)
	
	return FakeArm
end

function EffectUtility.WeldTrailsToAllLimbs(Model : Model, Duration : number)
	local Trails = {}
	
	for _, Item in ipairs(Model:GetChildren()) do
		if Item:IsA("BasePart") and Item.Name ~= "HumanoidRootPart" then
			local Arm = EffectUtility.WeldArmTrail(Item)
			table.insert(Trails, Arm)
			
			if (Duration ~= nil) then
				task.delay(Duration, function()
					for _, Trail in Arm:GetChildren() do
						if Trail:IsA("Trail") then
							Trail.Enabled = false
						end
					end
					
					task.delay(1, Arm.Destroy, Arm)
				end)
			end
		end
	end
	
	return Trails
end

function EffectUtility.CraterSmoke(Type : string, Raycast : RaycastResult)
	if (Raycast == nil) then
		return
	end
	
	local Position = Raycast.Position + Vector3.yAxis * 3
	
	local Effects = EffectUtility.EmitEffects(
		CraterDust[Type], 
		workspace.Terrain, 
		CFrame.lookAt(Position, Position - Raycast.Normal)
	)

	for Item in Effects do
		if Item:IsA("ParticleEmitter") then
			Item.Color = ColorSequence.new(Raycast.Instance.Color)
		end
	end
end

function EffectUtility.RaycastCraterSmoke(Type : string, Position : Vector3, Direction : Vector3)
	local Raycast = workspace:Raycast(Position - (Direction / 2), Direction, Utility.VisualParams)

	if (Raycast == nil) then 
		return 
	end

	local Position = Raycast.Position + Vector3.yAxis * 3
	
	local Effects = EffectUtility.EmitEffects(
		CraterDust[Type], 
		workspace.Terrain, 
		CFrame.lookAt(Position, Position - Raycast.Normal)
	)

	for Item in Effects do
		if Item:IsA("ParticleEmitter") then
			Item.Color = ColorSequence.new(Raycast.Instance.Color)
		end
	end
end

function EffectUtility.AddSFX(SFX : Sound, Parent : Instance, FadeOnDestroy : number?)
	local NewSFX = SFX:Clone()
	NewSFX.Parent = Parent
	NewSFX:Play()
	
	if (FadeOnDestroy ~= nil and FadeOnDestroy > 0) then
		local FadeInfo = TweenInfo.new(FadeOnDestroy, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
			
		return {
			Destroy = function()
				if (NewSFX.Volume > 0 and NewSFX.IsPlaying) then
					local Tween = TweenService:Create(NewSFX, FadeInfo, {Volume = 0})

					Tween.Completed:Connect(function(State)
						if State == Enum.PlaybackState.Completed then
							Tween:Destroy()
							NewSFX:Destroy()
						end
					end)

					Tween:Play()
				else
					NewSFX:Destroy()
				end
			end,
		}
	else
		return NewSFX
	end
end

function EffectUtility.Distance_Close(Model : Model, Value : number?)
	return (if LocalPlayer.Character == Model then true else LocalPlayer:DistanceFromCharacter(Model.PrimaryPart.Position) < (Value or 17.5))
end

function EffectUtility.Distance_Far(Model : Model, Value : number?)
	return (if LocalPlayer.Character == Model then true else LocalPlayer:DistanceFromCharacter(Model.PrimaryPart.Position) < (Value or 75))
end

function EffectUtility.SetPrimary(CharacterTable)
	local IsPrimary = function(Func, ...)
		local Character = LocalPlayer.Character
		if not Character then return end

		for _, AllowedCharacter in ipairs(CharacterTable) do
			if Character == AllowedCharacter then
				if typeof(Func) == "function" then
					Func(...)
				end
				break
			end
		end
	end
	
	return IsPrimary
end

--function EffectUtility.ReadyImpactFrames(ImpactFrames : Frame, Value : boolean)
--	for _, Frame : ImageLabel in ipairs(ImpactFrames:GetDescendants()) do
--		if Frame:IsA("ImageLabel") then
--			Frame.Visible = Value
--		end
--	end

--	ImpactFrames.AnchorPoint = Vector2.zero
--end

function EffectUtility.ToggleImpactFrames(ImpactFrames : Frame, Value : boolean)
	if Value then
		ImpactFrames.AnchorPoint = Vector2.new(0, 1)
		
		for _, Frame : ImageLabel in ipairs(ImpactFrames:GetDescendants()) do
			if Frame:IsA("ImageLabel") then
				Frame.Visible = true
			end
		end
	else
		for _, Frame : ImageLabel in ipairs(ImpactFrames:GetDescendants()) do
			if Frame:IsA("ImageLabel") then
				Frame.Visible = false
			end
		end
		
		ImpactFrames.AnchorPoint = Vector2.zero
	end
end

function EffectUtility.EmitImpactFrames(ImpactFrames : Frame, FPS : number)
	if LocalPlayer:GetAttribute("Epileptic_Mode") then return end
	
	ImpactFrames.AnchorPoint = Vector2.zero

	for Index = 1, #ImpactFrames:GetChildren(), 1 do
		task.wait(1 / (FPS or 24))

		local Frame : ImageLabel = ImpactFrames[Index]
		Frame.Visible = false
	end
end

return EffectUtility