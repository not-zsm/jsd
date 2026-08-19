local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local ScreenPulse = require( ReplicatedStorage.Modules.Player.Replication.Global.ScreenPulse )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local AttributeListener = require( ReplicatedStorage.Modules.Player.Replication.Global.AttributeListener )

function VFX.Windup(RootPart : BasePart)
	task.delay(0.45, function()
		local Trail =  EffectUtility.WeldArmTrail(RootPart.Parent["Right Arm"])
		task.delay(0.75, Trail.Destroy, Trail)
	end)
	
	task.delay(0.25, EffectUtility.EmitEffects, script.WindupSFX, RootPart)
end

function VFX.Hit(RootPart : BasePart)
	local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)

	if (Distance <= 100) then
		EffectUtility.EmitEffects(script.Ground, workspace.Terrain, RootPart.CFrame * CFrame.new(0, -3, 0))
		EffectUtility.EmitEffects(script.Hit, workspace.Terrain, RootPart.CFrame * CFrame.new(0, 5.45, -3.25) * CFrame.Angles(math.rad(85), 0, 0))
	end
end

function VFX.Spin(RootPart : BasePart)
	local Replication = AttributeListener.GetReplicationFromSource(RootPart)

	local Wind = script.Wind.Attachment:Clone()
	Wind.Parent = RootPart
	EffectUtility.Emit(Wind, true)
	EffectUtility.Toggle(Wind, true)

	local CancelAttribute : RBXScriptConnection = nil

	local function Remove()
		if CancelAttribute.Connected then
			CancelAttribute:Disconnect()
		end

		EffectUtility.Toggle(Wind, false)
		task.delay(1, Wind.Destroy, Wind)
	end

	CancelAttribute = Replication:GetAttributeChangedSignal("Pushed"):Connect(function()
		if not Replication:GetAttribute("Pushed") then
			Remove()
		end
	end)

	if not Replication:GetAttribute("Pushed") then
		Remove()
	end
end

local FinisherEffects = {}
local FinisherFriends = {}
local Friends = {}

--function VFX.CreateFriend(RootPart : BasePart, UserId : number)
--	local FriendModel = script.Friend:Clone()
--	FriendModel.Parent = workspace.Visuals

--	task.spawn(function()
--		local Description = Players:GetHumanoidDescriptionFromUserId(UserId)
--		FriendModel.Humanoid:ApplyDescription(Description)
--	end)

--	FinisherFriends[RootPart] = FriendModel
--end

function VFX.CreateFriend(RootPart : BasePart)
	local FriendModel = script.Friend:Clone()
	FriendModel.Parent = workspace.Visuals
	
	task.spawn(function()
		FriendModel.Humanoid:ApplyDescriptionReset(ReplicatedStorage.Effects.Characters.Reigen.Mob.Humanoid.HumanoidDescription)
	end)
	
	FinisherFriends[RootPart] = FriendModel
end

function VFX.AppearFriend(RootPart : BasePart)
	local Friend = FinisherFriends[RootPart]
	if (Friend == nil) then return end

	EffectUtility.Weld(Friend.HumanoidRootPart, RootPart)

	local Animation = Friend.Humanoid.Animator:LoadAnimation(ReplicatedStorage.Animations.Global.GrabVictims.ReigenUppercutFriend)
	Animation:Play(0, 1, 0)
	
	EffectUtility.EmitEffects(script.Teleport, Friend.Torso)

	task.wait(0.15)

	Animation:AdjustSpeed(1)
end

function VFX.FriendLand(RootPart : BasePart)
	local Effect = script.WindPartHolder:Clone()
	Effect.CFrame = RootPart.CFrame * CFrame.new(3.2, -3, 5.3) * CFrame.Angles(0, 0, math.rad(-90))
	Effect.Parent = workspace.Visuals

	EffectUtility.Emit(Effect)
end

function VFX.FinisherPull(RootPart : BasePart, Victim : Model)
	local VictimTorso = Victim.Torso
	FinisherEffects[Victim] = {}
	
	if FinisherFriends[RootPart] then
		for _, Item in ipairs(FinisherFriends[RootPart]:GetDescendants()) do
			if Item:IsA("ParticleEmitter") or Item:IsA("Beam") or Item:IsA("PointLight") then
				if Item:IsA("ParticleEmitter") then
					Item:Emit(2)
				end

				Item.Enabled = true
			end
		end
	end

	EffectUtility.EmitEffects(script.Pull, VictimTorso)

	for _, Effect in ipairs(script.FinisherEffectHolder:GetChildren()) do
		local NewEffect = Effect:Clone()
		NewEffect.Parent = VictimTorso
		FinisherEffects[Victim][NewEffect] = NewEffect
	end
end

function VFX.FinisherStartCrushing(RootPart : BasePart, Victim : Model)
	local Highlight = Instance.new("Highlight")
	Highlight.FillColor = Color3.fromRGB(183, 96, 255)
	Highlight.OutlineTransparency = 1
	Highlight.FillTransparency = 1
	Highlight.Parent = Victim

	FinisherEffects[Victim][Highlight] = true
	TweenService:Create(Highlight, TweenInfo.new(0.75, Enum.EasingStyle.Linear), {FillTransparency = 0}):Play()

	if LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) or LocalPlayer == Players:GetPlayerFromCharacter(Victim) then
		Yuki_FOV.Tween(50, {1})
	end
end

function VFX.FinisherCrush(RootPart : BasePart, Victim : Model)
	local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)

	if Distance < 25 then
		ScreenPulse("Black Flash")
		CameraShake(2.5, 15, 0.05, 0.25, Vector3.one * 0.8)
	end

	if LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) or LocalPlayer == Players:GetPlayerFromCharacter(Victim) then
		Yuki_FOV.Tween(100, {0.15})
	end
	
	task.delay(0.45, function()
		if LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) or LocalPlayer == Players:GetPlayerFromCharacter(Victim) then
			Yuki_FOV.Tween(70, {0.55})
		end
	end)
	
	local Attachment = Instance.new("Attachment")
	Attachment.WorldCFrame = Victim.HumanoidRootPart.CFrame * CFrame.new(-3, 4, 7)
	Attachment.Parent = workspace.Terrain

	Blood.BloodRaysWithoutPreset(Attachment, {
		Gravity = 150,
		Power = 10,
		Amount = Vector2.new(12, 15),
		Spread = Vector2.new(90, 90),
		PoolSize = 1.25,
		PoolSizeRandom = Vector2.new(-0.25, 0.45),
		Face = Enum.NormalId.Top,
	})

	EffectUtility.EmitEffects(script.Crush, Attachment)

	for Item in FinisherEffects[Victim] do
		Item:Destroy()
	end

	for _, Item in ipairs(Victim:GetDescendants()) do -- make kid go invis
		if Item:IsA("BasePart") or Item:IsA("Decal") then
			Item.Transparency = 1
		end
	end

	table.clear(FinisherEffects)
	FinisherEffects[Victim] = nil
end

function VFX.FriendBye(RootPart : BasePart, Victim)
	local FriendModel = FinisherFriends[RootPart]
	if (FriendModel == nil) then return end
	
	local FriendTorso = FriendModel.Torso -- why does this error sometimes no clue

	EffectUtility.EmitEffects(script.Teleport, FriendTorso)
	
	if (Victim ~= nil and Victim.Parent ~= nil and FinisherEffects[Victim]) then
		for Item in FinisherEffects[Victim] do
			Item:Destroy()
		end

		table.clear(FinisherEffects)
		FinisherEffects[Victim] = nil
	end

	task.wait(0.5)

	if FinisherFriends[RootPart] then
		FinisherFriends[RootPart]:Destroy()
		FinisherFriends[RootPart] = nil
	end
end

function VFX.FinisherHit(RootPart : BasePart, VictimTorso : BasePart)
	EffectUtility.EmitEffects(script.FinisherSFX, RootPart)
	
	local Wind = script.Wind.Attachment:Clone()
	Wind.Parent = VictimTorso
	EffectUtility.Emit(Wind, true)
	EffectUtility.Toggle(Wind, true)
	
	task.delay(0.75, function()
		EffectUtility.Toggle(Wind, false)
		
		task.wait(1)
		
		Wind:Destroy()
	end)
end

return VFX
