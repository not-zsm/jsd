local replicatedStorage = game:GetService("ReplicatedStorage")

local network = require( replicatedStorage.modules.network )
local connect = require( replicatedStorage.modules.network.connect )
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Chat = game:GetService("Chat")

local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )
local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )
local EventService = require( replicatedStorage.modules.shared.Utilities.EventService )

local CharacterTransparency = require( replicatedStorage.modules.client.replication.Global.CharacterTransparency )

local Type = require( replicatedStorage.Packages.Type )

local function CreateHands(AddRightHand : boolean, AddLeftHand : boolean, LuaCharacter : Model, HandFolder : Folder)
	HandFolder = HandFolder or script.Natsuki
	
	local Hands = {}
	
	if AddLeftHand then
		local LeftHand : typeof(script.Natsuki.LeftHand) = HandFolder.LeftHand:Clone()
		
		for _, Item in ipairs(LeftHand:GetChildren()) do
			if Item:IsA("BasePart") then
				Item.Color = LuaCharacter.LeftArm.Color
			end
		end

		LeftHand.Weld.Part0 = LuaCharacter.LeftArm
		LeftHand.Parent = LuaCharacter.Model
		
		Hands["Left"] = LeftHand
	end

	if AddRightHand then
		local RightHand : typeof(script.Natsuki.RightHand) = HandFolder.RightHand:Clone()
		
		for _, Item in ipairs(RightHand:GetChildren()) do
			if Item:IsA("BasePart") then
				Item.Color = LuaCharacter.RightArm.Color
			end
		end

		RightHand.Weld.Part0 = LuaCharacter.RightArm
		RightHand.Parent = LuaCharacter.Model
		
		Hands["Right"] = RightHand
	end
	
	return function()
		LuaCharacter.LuaPlayer.Replication:FireReliableVFX("Emotes/Hand Rig", "Remove", Hands)
		
		task.delay(1, function()
			for _, Hand in Hands do
				Hand:Destroy()
			end
		end)
	end
end

local function Wire(Source, Target, Name : String)
	local Wire = Instance.new("Wire")
	Wire.SourceInstance = Source
	Wire.TargetInstance = Target
	Wire.Parent = Source
	Wire.Name = Name or `{Source.Name} -> {Target.Name}`

	return Wire
end

local JJKAuraBlacklist = {"HumanoidRootPart"}

local function AddJJKPotentialVFX(Character : Model, Name : ("Itadori" | "Todo" | "Mahito"))
	local CharacterFolder : typeof(script.JJkPotential.Mahito) = script.JJkPotential:FindFirstChild(Name)
	
	if not CharacterFolder then
		return
	else
		CharacterFolder = CharacterFolder:Clone()
	end
	
	local Aura = CharacterFolder.Aura
	local Effects = {}
	
	for _, Part in Character:GetChildren() do
		if not Part:IsA("BasePart") then
			continue
		end
		
		if table.find(JJKAuraBlacklist, Part.Name) then
			continue
		end
		
		for _, Child in Aura:GetChildren() do
			local Clone = Child:Clone()
			table.insert(Effects, Clone)
			Clone.Parent = Part
		end
	end
	
	Aura:Destroy()
	
	for _, Part in CharacterFolder:GetChildren() do
		if not Part:IsA("BasePart") then
			continue
		end
		
		if not Part:FindFirstChild("Join") then
			continue
		end
		
		Part.Join.Part0 = Character:FindFirstChild(Part.Name)
		Part.Parent = workspace.Visuals
		
		table.insert(Effects, Part)
	end
	
	CharacterFolder:Destroy()
	
	local Theme = script.JJkPotential.Theme:Clone()
	Theme.Parent = Character:FindFirstChild("HumanoidRootPart") or Character:FindFirstChild("Torso")
	Theme:Play()
	
	table.insert(Effects, Theme)
	
	return Effects 
end

local function BasicEmote(Data : {Speed : number?, SyncMusicWithAnimationLoop : boolean?, NatsukiHands : boolean?, Collab : {[string] : any}?, Callback : ((...any) -> ())?, LockRotation : boolean?, NoStand : boolean?, }?)
	Data = Data or {}
	
	local Speed = Data.Speed or 50
	
	return {
		Collab = Data.Collab,
		
		CustomFunction = function(self, Job, Animation, ...) --> if u change this make sure callback line has been edited so it isnt missing properties
			self:DivideSpeed(Speed)
			
			Job:Task(function()
				self:TimesSpeed(Speed)
			end)
			
			if Data.LockRotation then
				Job:Task(self.LuaCharacter:StopAutoRotate())
			end
			
			if Data.NatsukiHands then
				local LeftHand : typeof(script.Natsuki.LeftHand) = Job:Task(script.Natsuki.LeftHand:Clone())
				local RightHand : typeof(script.Natsuki.RightHand) = Job:Task(script.Natsuki.RightHand:Clone())

				for _, Item in ipairs(LeftHand:GetChildren()) do
					if Item:IsA("BasePart") then
						Item.Color = self.LuaCharacter.LeftArm.Color
					end
				end

				for _, Item in ipairs(RightHand:GetChildren()) do
					if Item:IsA("BasePart") then
						Item.Color = self.LuaCharacter.RightArm.Color
					end
				end

				LeftHand.Weld.Part0 = self.LuaCharacter.LeftArm
				RightHand.Weld.Part0 = self.LuaCharacter.RightArm

				LeftHand.Parent = self.LuaCharacter.Model
				RightHand.Parent = self.LuaCharacter.Model

				Job:Task(Animation.Stopped:Once(function()
					Job:Destroy()
				end))
			end
			
			if Data.Callback then
				task.spawn(Data.Callback, self, Job, Animation, ...) --> this line here 
			end
		end,
		
		SyncMusicWithAnimationLoop = Data.SyncMusicWithAnimationLoop,
		
		NoStand = Data.NoStand,
	}
end

local EnableAble = {"ParticleEmitter", "Beam", "Trail", "PointLight", "SpotLight"}

return {
	--["Surf"] = {
	--	CustomFunction = function(self, Job)
			
	--	end,
	--},
	
	["FEEL LIKE A MONSTER"] = {
		CustomFunction = function(self, Job)
			self:HideUI(true)
			self.LuaPlayer.Replication:FireReliableVFXToSelf("Emotes/FEEL LIKE A MONSTER", "MONSTER", self.LuaCharacter.Model)

			Job:Task(function()
				self:HideUI(false)
			end)
			
			local MONSTER = script["FEEL LIKE A MONSTER"].Middle:Clone()
			MONSTER.Weld.Part0 = self.LuaCharacter.Torso
			MONSTER.Parent = self.LuaCharacter.Torso

			local SPIN = script["FEEL LIKE A MONSTER"].Part.Attachment:Clone()
			SPIN.Parent = self.LuaCharacter.Torso

			Job:Task(MONSTER)
			Job:Task(SPIN)
		end,
	},
	
	["Clutching"] = {
		MoveToCancel = true,

		CustomFunction = function(self, Job, Animation : AnimationTrack)
			local VelocityObject = self:Velocity()
			VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 50000
			VelocityObject.Settings.Controllable = true
			VelocityObject.Settings.Z = 6.5
			VelocityObject.Settings.NeedsVelocityAttribute = true
			VelocityObject:Fire()

			Job:Task(VelocityObject)

			local Pistol : typeof(script.Clutching.Handle) = Job:Task(script.Clutching.Handle:Clone())

			Job:Task(task.delay(2.35, function()
				Pistol.Motor6D.Part0 = self.LuaCharacter.RightArm
				Pistol.Parent = self.LuaCharacter.Model
			end))

			Job:Task(Animation.DidLoop:Connect(function()
				Pistol.Motor6D.Part0 = nil
				Pistol.Anchored = true
				Pistol.Parent = nil

				Job:Task(task.delay(2.35, function()
					Pistol.Anchored = false
					Pistol.Motor6D.Part0 = self.LuaCharacter.RightArm
					Pistol.Parent = self.LuaCharacter.Model
				end))
			end))
		end,
	},

	["Natsuki"] = {
		CustomFunction = function(self, Job, Animation : AnimationTrack)
			self:DivideSpeed(25)

			Job:Task(function()
				self:TimesSpeed(25)
			end)

			local LeftHand : typeof(script.Natsuki.LeftHand) = Job:Task(script.Natsuki.LeftHand:Clone())
			local RightHand : typeof(script.Natsuki.RightHand) = Job:Task(script.Natsuki.RightHand:Clone())

			for _, Item in ipairs(LeftHand:GetChildren()) do
				if Item:IsA("BasePart") then
					Item.Color = self.LuaCharacter.LeftArm.Color
				end
			end

			for _, Item in ipairs(RightHand:GetChildren()) do
				if Item:IsA("BasePart") then
					Item.Color = self.LuaCharacter.RightArm.Color
				end
			end

			LeftHand.Weld.Part0 = self.LuaCharacter.LeftArm
			RightHand.Weld.Part0 = self.LuaCharacter.RightArm

			LeftHand.Parent = self.LuaCharacter.Model
			RightHand.Parent = self.LuaCharacter.Model

			Job:Task(Animation:GetMarkerReachedSignal("pause"):Once(function()
				Animation:AdjustSpeed(0)
			end))
		end,
	},

	["The Fool"] = {
		CustomFunction = function(self, Job, Animation : AnimationTrack)
			self:DivideSpeed(25)

			local Chair : typeof(script.Chair.Model) = Job:Task(script.Chair.Model:Clone())

			local Particle : typeof(script.Chair.particule) = Job:Task(script.Chair.particule:Clone())
			Particle.Motor6D.Part0 = self.LuaCharacter.RootPart

			local Anim : AnimationTrack

			local Weld = Instance.new("Motor6D")
			Weld.Part0 = self.LuaCharacter.RootPart
			Weld.Part1 = Chair.MAINPart
			Weld.C0 = CFrame.new(0.015, 1.269, 3.272) * CFrame.Angles(math.rad(90), math.rad(180), 0)
			Weld.Parent = self.LuaCharacter.RootPart

			Particle.Parent = workspace.Visuals
			Chair.Parent = self.LuaCharacter.Model

			Job:Task(Animation.Stopped:Connect(function()
				Anim = self.LuaCharacter.Humanoid:LoadAnimation(script.Chair.Idle)
				Anim:Play()
			end))

			Job:Task(function()
				self:TimesSpeed(25)

				if Anim and Anim.IsPlaying then
					Anim:Stop()
				end

				Chair:Destroy()
				Weld:Destroy()
			end)
		end,
	},

	["Cat Boogie"] = {
		Music = {
			Id = 132000070796165,
			Volume = 0.5
		},

		CustomFunction = function(self, Job)
			self:DivideSpeed(25)

			Job:Task(function()
				self:TimesSpeed(25)
			end)
		end,
	},

	["Gambler"] = {
		Music = {
			Id = 74986212451237, --jjs copy
			Volume = 0.5,
		},

		CustomFunction = function(self, Job)
			self:DivideSpeed(10)
			self.LuaPlayer.Replication:FireReliableVFX("Emotes/Gambler", "Add", self.LuaCharacter.Model)

			Job:Task(function()
				self.LuaPlayer.Replication:FireReliableVFX("Emotes/Gambler", "Remove", self.LuaCharacter.Model)
				self:TimesSpeed(10)
			end)
		end,
	},

	["Winner"] = {
		CustomFunction = function(self, Job, Animation : AnimationTrack)
			self:DivideSpeed(25)

			local LeftHand : typeof(script.Natsuki.LeftHand) = Job:Task(script.Natsuki.LeftHand:Clone())
			local RightHand : typeof(script.Natsuki.RightHand) = Job:Task(script.Natsuki.RightHand:Clone())

			for _, Item in ipairs(LeftHand:GetChildren()) do
				if Item:IsA("BasePart") then
					Item.Color = self.LuaCharacter.LeftArm.Color
				end
			end

			for _, Item in ipairs(RightHand:GetChildren()) do
				if Item:IsA("BasePart") then
					Item.Color = self.LuaCharacter.RightArm.Color
				end
			end

			LeftHand.Weld.Part0 = self.LuaCharacter.LeftArm
			RightHand.Weld.Part0 = self.LuaCharacter.RightArm

			LeftHand.Parent = self.LuaCharacter.Model
			RightHand.Parent = self.LuaCharacter.Model

			Job:Task(function()
				self:TimesSpeed(25)
			end)

			Job:Task(Animation:GetMarkerReachedSignal("pause"):Once(function()
				Animation:AdjustSpeed(0)
			end))
		end,
	},

	["Solo"] = {
		CustomFunction = function(self, Job)
			self:DivideSpeed(10)

			Job:Task(function()
				self:TimesSpeed(10)
			end)
		end,
	},

	["Shake"] = {
		AnimationSpeed = 0.925,

		CustomFunction = function(self, Job)
			self:DivideSpeed(10)

			Job:Task(function()
				self:TimesSpeed(10)
			end)
		end,
	},

	["Wait"] = {
		CustomFunction = function(self, Job)
			self:DivideSpeed(10)

			Job:Task(function()
				self:TimesSpeed(10)
			end)
		end,
	},

	["PLEASE I NEED THIS"] = {
		CustomFunction = function(self, Job, Animation : AnimationTrack)
			self:DivideSpeed(20)

			Animation.Stopped:Once(function()
				Job:Clean()
			end)

			Job:Task(function()
				self:TimesSpeed(20)
			end)
		end,
	},

	["I AM THE ALPHA"] = {
		CustomFunction = function(self, Job, Animation : AnimationTrack)
			self:DivideSpeed(20)

			Job:Task(Animation:GetMarkerReachedSignal("pause"):Once(function()
				Animation:AdjustSpeed(0)
			end))

			Job:Task(function()
				self:TimesSpeed(20)
			end)
		end,

	},

	["Alpha"] = {
		Music = {
			Id = 9120789596,
			PlaybackRegion = NumberRange.new(0.2, 60000),
			Volume = 1,
		},

		CustomFunction = function(self, Job)
			self:DivideSpeed(1000)

			Job:Task(function()
				self:TimesSpeed(1000)
			end)
		end,
	},

	["Doodle"] = {
		Music = {
			Id = 73989056587816,
			PlaybackRegion = NumberRange.new(0.2, 60000),
			Volume = 0.6,
		},

		CustomFunction = function(self, Job)
			self:DivideSpeed(1000)

			local LeftHand : typeof(script.Natsuki.LeftHand) = Job:Task(script.Natsuki.LeftHand:Clone())
			local RightHand : typeof(script.Natsuki.RightHand) = Job:Task(script.Natsuki.RightHand:Clone())

			for _, Item in ipairs(LeftHand:GetChildren()) do
				if Item:IsA("BasePart") then
					Item.Color = self.LuaCharacter.LeftArm.Color
				end
			end

			for _, Item in ipairs(RightHand:GetChildren()) do
				if Item:IsA("BasePart") then
					Item.Color = self.LuaCharacter.RightArm.Color
				end
			end

			LeftHand.Weld.Part0 = self.LuaCharacter.LeftArm
			RightHand.Weld.Part0 = self.LuaCharacter.RightArm

			LeftHand.Parent = self.LuaCharacter.Model
			RightHand.Parent = self.LuaCharacter.Model

			Job:Task(function()
				self:TimesSpeed(1000)
			end)
		end,
	},

	["Delicious"] = {
		CustomFunction = function(self, Job, Animation : AnimationTrack)
			local Tongue = Job:Task(script.Delicious.touunge:Clone())
			Tongue.Weld.Part0 = self.LuaCharacter.Head
			Tongue.Parent = self.LuaCharacter.Model

			Animation.Stopped:Once(function()
				Job:Clean()
			end)
		end,
	},

	["I Understand"] = {
		CustomFunction = function(self, Job, Animation : AnimationTrack)
			self:DivideSpeed(5)

			Animation:AdjustSpeed(0.65)

			Animation.Stopped:Once(function()
				Job:Clean()
			end)

			Job:Task(function()
				self:TimesSpeed(5)
			end)
		end,
	},

	["Flight"] = {
		Music = {
			Id = 121867697991931,
			Volume = 0.85,
			DontLoopAudio = true
		},

		CustomFunction = function(self, Job, Animation : AnimationTrack)
			local Tongue = Job:Task(script.Delicious.touunge:Clone())
			Tongue.Weld.Part0 = self.LuaCharacter.Head
			Tongue.Parent = self.LuaCharacter.Model

			Animation.Stopped:Once(function()
				Job:Clean()
			end)
		end,
	},

	["RUN"] = {
		Music = {
			Id = 91137003214578,
			Volume = 3,
		},

		MoveToCancel = true,

		CustomFunction = function(self, Job, Animation : AnimationTrack)
			local VelocityObject = self:Velocity()
			VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 50000
			VelocityObject.Settings.Controllable = true
			VelocityObject.Settings.Z = 20
			VelocityObject.Settings.NeedsVelocityAttribute = true
			VelocityObject:Fire()

			Job:Task(VelocityObject)
		end,
	},

	["L"] = {
		Music = {
			Id = 1837432993,
			PlaybackRegion = NumberRange.new(0.2, 60000),
			Volume = 0.7,
		},

		CustomFunction = function(self, Job)
			self:DivideSpeed(10)

			Job:Task(function()
				self:TimesSpeed(10)
			end)
		end,
	},

	["Egoist Dance"] = {
		CustomFunction = function(self, Job)
			self:DivideSpeed(10)

			Job:Task(function()
				self:TimesSpeed(10)
			end)
		end,
	},

	["Samurai"] = {
		AnimationSpeed = 0.985,

		CustomFunction = function(self, Job)
			self:DivideSpeed(10)

			Job:Task(function()
				self:TimesSpeed(10)
			end)
		end,
	},
	
	["Lord Of The Hammer"] = {
		CustomFunction = function(self, Job)
			self:DivideSpeed(20)
			
			local Hammer = Job:Task(script["Lord Of The Hammer"]["Hammer Of Justice"]:Clone())
			Hammer.Weld.Part0 = self.LuaCharacter.LeftArm
			Hammer.Parent = self.LuaCharacter.Model
			
			local VelocityObject = self:Velocity()
			VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 50000
			VelocityObject.Settings.Controllable = true
			VelocityObject.Settings.Z = 20
			VelocityObject.Settings.NeedsVelocityAttribute = true
			VelocityObject:Fire()

			Job:Task(VelocityObject)
			
			Job:Task(function()
				self:TimesSpeed(20)
			end)
		end,
	},
	
	--["Runaway"] = {
	--	CustomFunction = function(self, Job)
	--		self:DivideSpeed(1000)
			
	--		self.LuaCharacter.Humanoid.AutoRotate = false
			
			
	--		Job:Task(function()
	--			self:TimesSpeed(1000)
	--			self.LuaCharacter.Humanoid.AutoRotate = true
	--		end)
	--	end,
	--},


	["Smooth Criminal"] = {
		CustomFunction = function(self, Job)
			self:DivideSpeed(10)

			local Accessory =script.SmoothCriminalFedora:Clone()
			self.LuaCharacter.Humanoid:AddAccessory(Accessory)

			Job:Task(Accessory)

			Job:Task(function()
				self:TimesSpeed(10)
			end)
		end,
	},

	["Jet Set"] = {
		CustomFunction = function(self, Job)
			self:DivideSpeed(5)

			Job:Task(function()
				self:TimesSpeed(5)
			end)
		end,
	},

	["Chicken"] = {
		CustomFunction = function(self, Job)
			self:DivideSpeed(10)
			self:StackState("CannotDrawWeapon", true)

			local assets = replicatedStorage.emotes.Chicken

			local starttrack : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(assets.Start)
			starttrack:Play(0,10,1)

			Job:Task(starttrack:GetMarkerReachedSignal("start"):Once(function()
				CharacterTransparency(self.LuaCharacter.Model, 1)

				Job:Task(function()
					CharacterTransparency(self.LuaCharacter.Model, 0)
				end)

				local chicken = assets.Chicken:Clone()
				chicken.Parent = self.LuaCharacter.RootPart

				local m = assets.Handle:Clone()
				m.Part0 = self.LuaCharacter.RootPart
				m.Part1 = chicken.Handle
				m.Parent = self.LuaCharacter.RootPart

				chicken.Handle.wood_plank_break4:Play()
				chicken.Handle["Chicken call"]:Play()
				chicken.Handle["Chicken Song"]:Play()

				local fx = assets.ChickenTransforms:Clone()
				fx.CFrame = self.LuaCharacter.RootPart.CFrame
				fx.Parent = self.LuaCharacter.Model

				for _,v in ipairs(fx:GetDescendants()) do
					if v:IsA("ParticleEmitter") then
						v:Emit(v:GetAttribute("EmitCount"))
					end
				end

				task.delay(5, fx.Destroy, fx)

				Job:Task(function()
					chicken:Destroy()
					fx:Destroy()
					m:Destroy()
				end)
			end))

			Job:Task(task.delay(starttrack.Length - 0.1, function()
				local endtrack:AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(assets.Loop)
				endtrack:Play(0,10,1)

				Job:Task(function()
					endtrack:Stop()
					endtrack:Destroy()
					endtrack = nil
				end)
			end))

			Job:Task(function()
				starttrack:Stop()
				starttrack:Destroy()
				starttrack = nil

				self:StackState("CannotDrawWeapon", false)
				self:TimesSpeed(10)
			end)
		end,
	},
	
	["Bnuy"] = {
		CustomFunction = function(self, Job)
			self:DivideSpeed(10)
			self:StackState("CannotDrawWeapon", true)

			local assets = replicatedStorage.emotes.Bnuy

			local starttrack : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(assets.Start)
			starttrack:Play(0,10,1)

			Job:Task(starttrack:GetMarkerReachedSignal("form"):Once(function()
				CharacterTransparency(self.LuaCharacter.Model, 1)

				Job:Task(function()
					CharacterTransparency(self.LuaCharacter.Model, 0)
				end)

				local bnuy = assets.Bnuy:Clone()
				bnuy.Name = "rabbit" -- For animation
				bnuy.Weld.Part0 = self.LuaCharacter.RootPart
				bnuy.Parent = self.LuaCharacter.Model
				Job:Task(bnuy)
			end))
			
			Job:Task(starttrack:GetMarkerReachedSignal("idle"):Once(function()
				local endtrack:AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(assets.Loop)
				endtrack:Play(0,10,1)

				Job:Task(function()
					endtrack:Stop()
					endtrack:Destroy()
					endtrack = nil
				end)
			end))

			Job:Task(function()
				starttrack:Stop()
				starttrack:Destroy()
				starttrack = nil

				self:StackState("CannotDrawWeapon", false)
				self:TimesSpeed(10)
			end)
		end,
	},

	["Smile"] = {
		Music = {
			Id = 108019706922239,
			Volume = 1.5
		},

		CustomFunction = function(self, Job)
			self:DivideSpeed(10)

			Job:Task(function()
				self:TimesSpeed(10)
			end)
		end,
	},
	
	["Do"] = {
		CustomFunction = function(self, Job)
			self:DivideSpeed(10)

			Job:Task(function()
				self:TimesSpeed(10)
			end)
		end,
	},

	["Lucky"] = {
		CustomFunction = function(self, Job, Animation : AnimationTrack)
			self:DivideSpeed(10)

			Job:Task(Animation.Stopped:Once(function()
				Job:Destroy()
			end))

			Job:Task(function()
				self:TimesSpeed(10)
			end)
		end,
	},
	
	["IT'S YOU!?"] = {
		CustomFunction = function(self, Job, Animation : AnimationTrack)
			self:DivideSpeed(20)
			
			local Vocal = replicatedStorage.emotes["IT'S YOU!?"].Vocal:Clone()
			local Cloth = replicatedStorage.emotes["IT'S YOU!?"].Cloth:Clone()
			
			Vocal.Parent = self.LuaCharacter.Head
			Cloth.Parent = self.LuaCharacter.Torso
			
			Job:Task(Vocal)
			Job:Task(Cloth)
			
			Vocal:Play()
			Cloth:Play()
			
			Job:Task(Animation.Stopped:Once(function()
				Job:Destroy()
			end))

			Job:Task(function()
				self:TimesSpeed(20)
			end)
		end,
	},

	["Rat"] = {
		CustomFunction = function(self, Job)
			self:DivideSpeed(10)

			Job:Task(function()
				self:TimesSpeed(10)
			end)
		end,
	},

	["Worm"] = {
		CustomFunction = function(self, Job, Animation : AnimationTrack)
			self:DivideSpeed(50)

			Job:Task(Animation.Stopped:Once(function()
				Job:Destroy()
			end))

			Job:Task(function()
				self:TimesSpeed(50)
			end)
		end,
	},

	["Pink Fluffy Unicorns"] = {
		Music = {
			Id = 83613357875714,
			Volume = 0.7,
			PlaybackRegion = NumberRange.new(1.25, 96),
			DontLoopAudio = false
		},

		CustomFunction = function(self, Job, Animation : AnimationTrack)
			local Assets = replicatedStorage.emotes.Unicorn

			local Unicorn = Assets.Unicorn:Clone()
			Unicorn.Parent = self.LuaCharacter.RootPart

			local m = Assets.Handle:Clone()
			m.Part0 = self.LuaCharacter.Torso
			m.Part1 = Unicorn.Handle
			m.Parent = self.LuaCharacter.Torso

			local VelocityObject = self:Velocity()
			VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 50000
			VelocityObject.Settings.Controllable = true
			VelocityObject.Settings.Z = 5
			VelocityObject.Settings.NeedsVelocityAttribute = true
			VelocityObject:Fire()

			Job:Task(VelocityObject)

			Job:Task(function()
				Unicorn:Destroy()
				m:Destroy()
			end)
		end,
	},

	["TGY7AWDPJOKIHGFIUFDGOIJKLDHBUISEIUYGVBKUHBGHBN"] = {},

	["Thumbs Up"] = {
		CustomFunction = function(self, Job, Animation : AnimationTrack)
			self:DivideSpeed(20)

			--local LeftHand : typeof(script.Natsuki.LeftHand) = Job:Task(script.Natsuki.LeftHand:Clone())
			local RightHand : typeof(script.Natsuki.RightHand) = Job:Task(script.Natsuki.RightHand:Clone())

			--for _, Item in ipairs(LeftHand:GetChildren()) do
			--	if Item:IsA("BasePart") then
			--		Item.Color = self.LuaCharacter.LeftArm.Color
			--	end
			--end

			for _, Item in ipairs(RightHand:GetChildren()) do
				if Item:IsA("BasePart") then
					Item.Color = self.LuaCharacter.RightArm.Color
				end
			end

			--LeftHand.Weld.Part0 = self.LuaCharacter.LeftArm
			RightHand.Weld.Part0 = self.LuaCharacter.RightArm

			--LeftHand.Parent = self.LuaCharacter.Model
			RightHand.Parent = self.LuaCharacter.Model

			Job:Task(function()
				self:TimesSpeed(20)
			end)

			Job:Task(Animation:GetMarkerReachedSignal("pause"):Once(function()
				Animation:AdjustSpeed(0)
			end))
		end,
	},

	["Thumbs Down"] = {
		CustomFunction = function(self, Job, Animation : AnimationTrack)
			self:DivideSpeed(20)

			--local LeftHand : typeof(script.Natsuki.LeftHand) = Job:Task(script.Natsuki.LeftHand:Clone())
			local RightHand : typeof(script.Natsuki.RightHand) = Job:Task(script.Natsuki.RightHand:Clone())

			--for _, Item in ipairs(LeftHand:GetChildren()) do
			--	if Item:IsA("BasePart") then
			--		Item.Color = self.LuaCharacter.LeftArm.Color
			--	end
			--end

			for _, Item in ipairs(RightHand:GetChildren()) do
				if Item:IsA("BasePart") then
					Item.Color = self.LuaCharacter.RightArm.Color
				end
			end

			--LeftHand.Weld.Part0 = self.LuaCharacter.LeftArm
			RightHand.Weld.Part0 = self.LuaCharacter.RightArm

			--LeftHand.Parent = self.LuaCharacter.Model
			RightHand.Parent = self.LuaCharacter.Model

			Job:Task(function()
				self:TimesSpeed(20)
			end)
		end,
	},

	["The Mug"] = {
		CustomFunction = function(self, Job, Animation : AnimationTrack)
			self:DivideSpeed(1000)
			self.LuaCharacter.Humanoid.AutoRotate = false

			local Mug : typeof(script["The Mug"].Mug) = Job:Task(script["The Mug"].Mug:Clone())
			Mug.Mug.Weld.Part0 = self.LuaCharacter.RootPart
			Mug.Parent = self.LuaCharacter.Model

			Job:Task(Mug)

			Job:Task(function()
				self:TimesSpeed(1000)
				self.LuaCharacter.Humanoid.AutoRotate = true
			end)

			Job:Task(Animation.Stopped:Once(function()
				Job:Destroy()
			end))
		end,
	},
	
	["Requiem"] = {
		CustomFunction = function(self, Job)
			self:DivideSpeed(10)

			Job:Task(function()
				self:TimesSpeed(10)
			end)
		end,
	},

	["Tuff Laughs"] = {
		CustomFunction = function(self, Job, Animation : AnimationTrack)
			self:DivideSpeed(1.5)

			Job:Task(function()
				self:TimesSpeed(1.5)
			end)
			
			Job:Task(Animation.Stopped:Connect(function()
				Job:Destroy()
			end))
		end,
	},

	["Cancun"] = {
		SyncMusicWithAnimationLoop = true,
		
		CustomFunction = function(self, Job)
			self:DivideSpeed(50)

			Job:Task(function()
				self:TimesSpeed(50)
			end)
		end,
	},
	
	["Miohonda"] = {
		SyncMusicWithAnimationLoop = true,

		CustomFunction = function(self, Job)
			self:DivideSpeed(50)

			Job:Task(function()
				self:TimesSpeed(50)
			end)
		end,
	},
	
	["Dance Of Peace"] = {
		CustomFunction = function(self, Job)
			local Loop1 : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes["Dance Of Peace"].Loop1)
			local Loop2 : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes["Dance Of Peace"].Loop2)
			
			Loop1:Play()
			
			Loop1.DidLoop:Once(function()
				Loop1:Stop(0)
				Loop2:Play(0)
			end)
	
			self:DivideSpeed(100)

			Job:Task(function()
				Loop1:Destroy()
				Loop2:Destroy()
				
				Loop1:Stop()
				Loop2:Stop()
				
				self:TimesSpeed(100)
			end)
		end,
	},
	
	["I'm A Mystery"] = {
		--SyncMusicWithAnimationLoop = true,
		
		CustomFunction = function(self, Job)
			self:DivideSpeed(100)
			self.LuaPlayer.Replication:FireReliableVFX("Emotes/I'm A Mystery", "Start", self.LuaCharacter.Model)

			Job:Task(function()
				self:TimesSpeed(100)
			end)
		end,
	},
	
	["Soda Pop"] = {
		SyncMusicWithAnimationLoop = true,

		CustomFunction = function(self, Job)
			self:DivideSpeed(50)

			Job:Task(function()
				self:TimesSpeed(50)
			end)
		end,
	},
	
	["Miku"] = {
		StopAfterAnimationStop = true,
		
		CustomFunction = function(self, Job)
			self:DivideSpeed(50)
			
			--local Left = script.Miku.Left:Clone()
			--Left.Attachment.Trail.Color = ColorSequence.new(self.LuaCharacter.LeftArm.Color)
			--Left.Attachment.Trail.Attachment0 = Left
			--Left.Attachment.Trail.Attachment1 = Left.Attachment
			
			--local Right = script.Miku.Right:Clone()
			--Right.Attachment.Trail.Color = ColorSequence.new(self.LuaCharacter.RightArm.Color)
			--Right.Attachment.Trail.Attachment0 = Right
			--Right.Attachment.Trail.Attachment1 = Right.Attachment
			
			--Left.Parent = self.LuaCharacter.LeftArm
			--Right.Parent = self.LuaCharacter.RightArm
			
			--Job:Task(Left)
			--Job:Task(Right)
			
			Job:Task(function()
				self:TimesSpeed(50)
			end)
		end,
	},
	
	["Prince Of JSD"] = {
		SyncMusicWithAnimationLoop = true,

		CustomFunction = function(self, Job)
			self:DivideSpeed(50)

			Job:Task(function()
				self:TimesSpeed(50)
			end)
		end,
	},
	
	["Jersey Joe"] = {
		SyncMusicWithAnimationLoop = true,
		DontLoopAudio = true,
		
		Collab = {
			ObjectText = "Jersey Joe",
			ActionText = "Join The Edit",

			Limit = 2,

			Function2 = function(self, Data : {})
				local JoinedCombat = Data.JoinedCombat
				local JoinedJob = Data.JoinedJob
				local JoinedTable = Data.JoinedTable
				local MainAnimation = Data.MainAnimation

				JoinedJob:Task(JoinedCombat.LuaCharacter:StopAutoRotate())
				JoinedCombat:DivideSpeed(50)

				local Side = (Utility.TableCount(JoinedTable) == 0 and "Left" or "Right")
				local Anim : AnimationTrack = JoinedCombat.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes["Jersey Joe"][Side])
				
				if Side == "Left" then
					JoinedCombat.LuaCharacter.Model:PivotTo(self:GetSimulatedRoot().CFrame * CFrame.new(4.5, 0, 2))
				else
					JoinedCombat.LuaCharacter.Model:PivotTo(self:GetSimulatedRoot().CFrame * CFrame.new(-4.5, 0, 2))
				end
				
				Anim:Play()
				Anim.TimePosition = MainAnimation.TimePosition
				
				JoinedJob:Task(function()
					JoinedCombat:TimesSpeed(50)
					Anim:Stop()
				end)
			end,
		},

		CustomFunction = function(self, Job)
			self:DivideSpeed(50)
			Job:Task(self.LuaCharacter:StopAutoRotate())

			Job:Task(function()
				self:TimesSpeed(50)
			end)
		end,
	},
	
	["Stars"] = {
		SyncMusicWithAnimationLoop = true,
		DontLoopAudio = true,

		Collab = {
			StopAnimationWhenPlayerJoins = true,
			
			ObjectText = "Stars",
			ActionText = "Join",

			Limit = 1,

			Function2 = function(self, Data : {})
				local JoinedCombat = Data.JoinedCombat
				local JoinedJob = Data.JoinedJob
				local MainJob = Data.MainJob
				local MainAnimation = Data.MainAnimation

				JoinedJob:Task(JoinedCombat.LuaCharacter:StopAutoRotate())
				JoinedJob:Task(self.LuaCharacter:StopAutoRotate())

				self.LuaCharacter:SetCollisionGroup("NoPlayerCollision")
				JoinedCombat.LuaCharacter:SetCollisionGroup("NoPlayerCollision")

				self:DivideSpeed(200)
				JoinedCombat:DivideSpeed(200)

				local GuyAnim : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes["Stars"].Guy)
				local GirlAnim : AnimationTrack = JoinedCombat.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes["Stars"].Girl)

				JoinedCombat.LuaCharacter.Model:PivotTo(self:GetSimulatedRoot().CFrame * CFrame.new(0, 0, -4.175) * CFrame.Angles(0, math.pi, 0))

				GuyAnim:Play()
				GirlAnim:Play()
				
				JoinedJob:Task(GuyAnim.Stopped:Once(function()
					JoinedJob:Destroy()
				end))
				
				JoinedJob:Task(GirlAnim.Stopped:Once(function()
					JoinedJob:Destroy()
				end))

				JoinedJob:Task(function()
					self.LuaCharacter:SetCollisionGroup("Player")
					JoinedCombat.LuaCharacter:SetCollisionGroup("Player")
					
					self:TimesSpeed(200)
					GuyAnim:Stop()
					
					JoinedCombat:TimesSpeed(200)
					GirlAnim:Stop()
				end)
			end,
		},

		CustomFunction = function(self, Job)
			self:DivideSpeed(50)

			Job:Task(function()
				self:TimesSpeed(50)
			end)
		end,
	},
	
	["Spot"] = {
		SyncMusicWithAnimationLoop = true,
		
		CustomFunction = function(self, Job)
			self:DivideSpeed(50)

			Job:Task(function()
				self:TimesSpeed(50)
			end)
		end,
	},
	
	["Erased"] = {
		CustomFunction = function(self, Job, Animation : AnimationTrack)
			if self.LuaCharacter.Model:FindFirstChild("Butterfly") then
				self.LuaCharacter.Model["Butterfly"]:Destroy()
				self.LuaPlayer.Replication:FireReliableVFX("Emotes/Erased", "Stop", self.LuaCharacter.Model, true)
			end
			
			self:DivideSpeed(50)
			
			local Duration = 97
			
			local StartedLoop = false
			
			local Idle : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes.Erased.Idle)
			Idle.Priority = Enum.AnimationPriority.Core
			
			local Butterfly = script.Erased["Butterfly"]:Clone()
			Butterfly.Weld.Part0 = self.LuaCharacter.RootPart
			Butterfly.Parent = self.LuaCharacter.Model
			
			local function Clean(Cancelled : Bolean)
				self.LuaPlayer.Replication:FireReliableVFX("Emotes/Erased", "Stop", self.LuaCharacter.Model, Cancelled)
				
				if not Cancelled then
					EffectUtility.Toggle(Butterfly, false)
					
					TweenService:Create(Butterfly, TweenInfo.new(1), {Transparency = 1}):Play()
					task.wait(1)
				end
				
				Butterfly:Destroy()
				
				Idle:Stop()
				Idle:Destroy()
				Idle = nil
			end
			
			self.LuaPlayer.Replication:FireReliableVFX("Emotes/Erased", "Start", self.LuaCharacter.Model)
		
			Job:Task(Animation:GetMarkerReachedSignal("End"):Connect(function()
				StartedLoop = true
				
				Animation:Stop()
				Idle:Play()
				
				self:TimesSpeed(50)
				
				Job:Task(task.delay(Duration, function()
					Clean()
				end))
			end))

			Job:Task(task.delay(0.7, function()
				Butterfly.Body.Trail1.Enabled = true
				Butterfly.Body.Trail2.Enabled = true
			end))
			
			Job:Task(function()
				if not StartedLoop then
					self:TimesSpeed(50)
					Clean(true)
				end
				
				self.LuaPlayer.Replication:FireReliableVFXToSelf("Emotes/Erased", "ToggleBars", false)
			end)
			
			self.LuaPlayer.Replication:FireReliableVFXToSelf("Emotes/Erased", "ToggleBars", true)
		end,
	},
	
	["Absolute Banger"] = {
		CustomFunction = function(self, Job)
			self:DivideSpeed(50)

			Job:Task(function()
				self:TimesSpeed(50)
			end)
		end,
	},
	
	["Whisk"] = {
		CustomFunction = function(self, Job)
			self:DivideSpeed(50)

			Job:Task(function()
				self:TimesSpeed(50)
			end)
		end,
	},
	
	["Pop Step"] = {
		SyncMusicWithAnimationLoop = true,
		
		CustomFunction = function(self, Job)
			self:DivideSpeed(50)

			Job:Task(function()
				self:TimesSpeed(50)
			end)
		end,
	},

	["Jordan Mobile"] = {
		CustomFunction = function(self, Job)
			--local IsBinxyWinxy = not self.LuaPlayer.IsNPC and (self.LuaPlayer.Player.UserId == 242509995 or self.LuaPlayer.Player.UserId == 7207821215)
			self.LuaCharacter.Humanoid.HipHeight = 2.25

			Job:Task(function()
				self.LuaCharacter.Humanoid.HipHeight = 0
			end)

			local VelocityObject = self:Velocity()
			VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 50000
			VelocityObject.Settings.Controllable = true
			VelocityObject.Settings.Z = 12.5 --IsBinxyWinxy and 50 or 12.5
			VelocityObject.Settings.NeedsVelocityAttribute = true
			VelocityObject:Fire()

			Job:Task(VelocityObject)

			local Car = Job:Task(script["Jordan Mobile"].Flight:Clone())
			Car.Weld.Part0 = self.LuaCharacter.RootPart
			Car.Parent = self.LuaCharacter.Model

			local Tongue = Job:Task(script["Delicious"].touunge:Clone())
			Tongue.Weld.Part0 = self.LuaCharacter.Head
			Tongue.Parent = self.LuaCharacter.Model

			Job:Task(Car)
			Job:Task(Tongue)

			--if IsBinxyWinxy then
			--	local Hitbox = self.Hitbox:Create()
			--	Hitbox.Params.Offset = CFrame.new(0, 0, -6)
			--	Hitbox.Params.Size = Vector3.new(10, 10, 13)

			--	Job:Task(self.Hitbox:ClientSidedDestructionLoop(Hitbox.Params.Offset, Hitbox.Params.Size, 2))

			--	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			--		self:Afflict(VictimLuaPlayer, {
			--			DontBypassIFrames = {},
			--			BreakBlock = true,
			--			Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 75 + Vector3.yAxis * 15, 0.1},
			--			Ragdoll = 1.5,
			--			Damage = 1,
			--		})

			--		if Car and Car.Parent ~= nil then
			--			Car.RootPart.Hit:Play()
			--		end

			--		task.delay(0.5, Hitbox.RemoveHumanoid, Hitbox, VictimLuaPlayer.Character.Humanoid)
			--	end)

			--	Hitbox:BeginCast()

			--	Job:Task(function()
			--		Hitbox:EndCast()
			--		Hitbox:Destroy()
			--	end)
			--end
		end,
	},
	
	["Asgore Behind The Wheel"] = {
		CustomFunction = function(self, Job)
			--self.LuaCharacter.Humanoid.HipHeight = 2.25

			--Job:Task(function()
			--	self.LuaCharacter.Humanoid.HipHeight = 0
			--end)
			
			local Player : Player = self.LuaCharacter.LuaPlayer.Player
			
			local speed = false --(Player.UserId == game.PrivateServerOwnerId)

			local VelocityObject = self:Velocity()
			VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 50000
			VelocityObject.Settings.Controllable = true
			VelocityObject.Settings.Z = speed and 95 or 12.5
			VelocityObject.Settings.NeedsVelocityAttribute = true
			VelocityObject:Fire()

			Job:Task(VelocityObject)

			local Car = Job:Task(script.AsgoreCar.Jeep:Clone())
			Car.Weld.Part0 = self.LuaCharacter.RootPart
			Car.Parent = self.LuaCharacter.Model

			local Can = Job:Task(script.AsgoreCar.Cola:Clone())
			Can.Weld.Part0 = self.LuaCharacter.LeftArm
			Can.Parent = self.LuaCharacter.Model

			Job:Task(Car)
			Job:Task(Can)
			
			if speed then
				local Hitbox = self.Hitbox:Create()
				Hitbox.Params.Offset = CFrame.new(0, 0, -8)
				Hitbox.Params.Size = Vector3.new(10, 10, 14)

				Job:Task(self.Hitbox:ClientSidedDestructionLoop(Hitbox.Params.Offset, Hitbox.Params.Size, 2))

				Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
					self:Afflict(VictimLuaPlayer, {
						DontBypassIFrames = {},
						BreakBlock = true,
						Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 75 + Vector3.yAxis * 15, 0.1},
						Ragdoll = 1.5,
						Damage = 1,
					})

					task.delay(0.5, Hitbox.RemoveHumanoid, Hitbox, VictimLuaPlayer.Character.Humanoid)
				end)

				Hitbox:BeginCast()

				Job:Task(function()
					Hitbox:EndCast()
					Hitbox:Destroy()
				end)
			end
		end,
	},

	["Locked In"] = {
		CustomFunction = function(self, Job, Animation : AnimationTrack)
			self:DivideSpeed(10)

			local AnimationLength = 4 + 1/3;
			local AudioLength = 8.5222445;
			
			local Speed = (AnimationLength / AudioLength) * 2;
			
			Job:Task(Animation.Stopped:Connect(function()
				Speed *= -1;
				Animation:Play(0.1, 1, Speed);
			end))

			self.LuaPlayer.Replication:FireReliableVFX("Emotes/Locked In", "Start", self.LuaPlayer.Player)

			Job:Task(function()
				self.LuaPlayer.Replication:FireReliableVFX("Emotes/Locked In", "Remove", self.LuaPlayer.Player)
				self:TimesSpeed(10)
			end)
		end,
	},

	["Cupid"] = {},
	["Muffin Fail"] = {
		StopAfterAnimationStop = true,
		
		CustomFunction = function(self, Job)
			self:DivideSpeed(5)

			self.LuaCharacter.Torso.CanCollide = false
			self.LuaCharacter.RootPart.CanCollide = true

			Job:Task(function()
				self.LuaCharacter.Torso.CanCollide = true
				self.LuaCharacter.RootPart.CanCollide = false
				
				self:TimesSpeed(5)
			end)
		end,
	},

	["Get Jiggy"] = {
		Collab = {
			ObjectText = "Get Jiggy",
			ActionText = "Join",

			TeleportOnEmoteEnded = true,

			Function = function(self, TargetCombat, _, JoinedJob, UserAnimation : AnimationTrack)
				JoinedJob:Task(TargetCombat.LuaCharacter:StopAutoRotate())

				self.LuaCharacter:SetCollisionGroup("NoPlayerCollision")
				TargetCombat.LuaCharacter:SetCollisionGroup("NoPlayerCollision")
				
				TargetCombat:DivideSpeed(1000)
				TargetCombat.LuaCharacter.RootPart.CFrame = self:GetSimulatedRoot().CFrame

				local Anim : AnimationTrack = TargetCombat.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes["Get Jiggy"].Duo)
				Anim:Play()
				Anim.TimePosition = UserAnimation.TimePosition

				JoinedJob:Task(function()
					if not self:GetState("Grabbed") then
						self.LuaCharacter:SetCollisionGroup("Player")
					end
					
					if not TargetCombat:GetState("Grabbed") then
						TargetCombat.LuaCharacter:SetCollisionGroup("Player")
					end
					
					TargetCombat:TimesSpeed(1000)
					Anim:Stop()
				end)
			end,
		},

		CustomFunction = function(self, Job)
			Job:Task(self.LuaCharacter:StopAutoRotate())
			self:DivideSpeed(1000)

			Job:Task(function()
				self:TimesSpeed(1000)
			end)
		end,
	},

	["Conga"] = {
		Collab = {
			Limit = -1,

			ObjectText = "Conga",
			ActionText = "Join",

			Function = function(self, TargetCombat, MainJob, JoinedJob, UserAnimation : AnimationTrack)
				local Anim : AnimationTrack = TargetCombat.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes.Conga)

				local VelocityObject = TargetCombat:Velocity()
				VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 50000
				VelocityObject.Settings.Controllable = true
				VelocityObject.Settings.Z = 6.5
				VelocityObject.Settings.NeedsVelocityAttribute = true
				VelocityObject:Fire()

				--task.spawn(function()
				--	for Index, VictimLuaPlayer in ipairs(Joined) do
				--		local hrp = VictimLuaPlayer.Character.RootPart

				--		if hrp then
				--			local baseCFrame

				--			if Index == 1 then
				--				baseCFrame = hrp.CFrame
				--			else
				--				local prevHRP = Joined[Index - 1].Character.RootPart
				--				baseCFrame = prevHRP and prevHRP.CFrame
				--			end

				--			if baseCFrame then
				--				local targetPosition = baseCFrame.Position - baseCFrame.LookVector * (5) -- spacing
				--				local newCFrame = CFrame.new(targetPosition, baseCFrame.Position)
				--				hrp.CFrame = newCFrame
				--			end
				--		end
				--	end
				--end)

				Anim:Play()
				Anim.TimePosition = UserAnimation.TimePosition

				JoinedJob:Task(function()
					VelocityObject:Destroy()
					Anim:Stop()
				end)
			end,
		},

		CustomFunction = function(self, Job)
			local VelocityObject = self:Velocity()
			VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 50000
			VelocityObject.Settings.Controllable = true
			VelocityObject.Settings.Z = 6.5
			VelocityObject.Settings.NeedsVelocityAttribute = true
			VelocityObject:Fire()

			Job:Task(VelocityObject)
		end,
	},
	
	["Rock Paper Scissors"] = {
		Collab = {
			ObjectText = "Rock Paper Scissors",
			ActionText = "Challenge",
			
			Limit = 1,

			Function = function(self, TargetCombat, MainJob, JoinedJob, UserAnimation : AnimationTrack)
				UserAnimation:Stop()
				
				JoinedJob:Task(CreateHands(true, true, self.LuaCharacter))
				JoinedJob:Task(CreateHands(true, true, TargetCombat.LuaCharacter))
				
				-- Face Users
				JoinedJob:Task(TargetCombat.LuaCharacter:StopAutoRotate())
				
				self.LuaCharacter.LuaPlayer.Replication:FireReliableVFX("Emotes/FacePart", "Face", self.LuaCharacter.Model, TargetCombat.LuaCharacter.RootPart, 0.4)
				TargetCombat.LuaCharacter.LuaPlayer.Replication:FireReliableVFX("Emotes/FacePart", "Face", TargetCombat.LuaCharacter.Model, self.LuaCharacter.RootPart, 0.4)
				
				local UserNum = math.random(1, 3)
				local DuoNum = math.random(1, 3)
			
				local UserAnim : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes["Rock Paper Scissors"][`{UserNum}`])
				UserAnim:Play()
				
				local UserSound = JoinedJob:Task(script.RPS.Start:Clone())
				UserSound.Parent = self.LuaCharacter.RootPart
				UserSound:Play()
				
				local TargetSound = JoinedJob:Task(script.RPS.Start:Clone())
				TargetSound.Parent = TargetCombat.LuaCharacter.RootPart
				TargetSound:Play()
				
				TargetCombat:DivideSpeed(10)
				
				local DuoAnim : AnimationTrack = TargetCombat.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes["Rock Paper Scissors"][`{DuoNum}`])
				DuoAnim:Play()
				
				DuoAnim.TimePosition = UserAnim.TimePosition
				
				JoinedJob:Task(task.delay(1.65, function()
					if UserNum ~= DuoNum then
						if (UserNum - DuoNum) % 3 == 1 then
							self.LuaCharacter.LuaPlayer.Replication:FireReliableVFX("Emotes/Rock Paper Scissors", "Result", self.LuaCharacter.Model, TargetCombat.LuaCharacter.Model)
						else
							self.LuaCharacter.LuaPlayer.Replication:FireReliableVFX("Emotes/Rock Paper Scissors", "Result", TargetCombat.LuaCharacter.Model, self.LuaCharacter.Model)
						end
					end
				end))
				
				JoinedJob:Task(UserAnim.Ended:Connect(function()
					JoinedJob:Destroy()
					MainJob:Destroy()
				end))
		
				JoinedJob:Task(function()
					UserAnim:Stop()
					DuoAnim:Stop()
					
					TargetCombat:TimesSpeed(10)
				end)
			end,
		},

		CustomFunction = function(self, Job)
			self:DivideSpeed(10)
			Job:Task(self.LuaCharacter:StopAutoRotate())

			Job:Task(function()
				self:TimesSpeed(10)
			end)
		end,
	},
	
	["Gang Dance"] = {
		Collab = {
			ObjectText = "Gang Dance",
			ActionText = "Join",

			Limit = -1,

			Function = function(self, TargetCombat, MainJob, JoinedJob, UserAnimation : AnimationTrack)
				TargetCombat:DivideSpeed(10)
				local Anim : AnimationTrack = TargetCombat.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes["Gang Dance"])
				Anim:Play()
				Anim.TimePosition = UserAnimation.TimePosition

				JoinedJob:Task(function()
					Anim:Stop()

					TargetCombat:TimesSpeed(10)
				end)
			end,
		},

		CustomFunction = function(self, Job)
			self:DivideSpeed(10)
			
			local StartSound : Sound = Job:Task(script["Gang Dance"].Start:Clone())
			StartSound.Parent = self.LuaCharacter.RootPart
			StartSound:Play()
			
			Job:Task(StartSound.Ended:Connect(function()
				local LoopSound : Sound = Job:Task(script["Gang Dance"].Loop:Clone())
				LoopSound.Parent = self.LuaCharacter.RootPart
				LoopSound:Play()
			end))

			Job:Task(function()
				self:TimesSpeed(10)
			end)
		end,
	},
	
	["Mic Up"] = {
		CustomFunction = function(self, Job)
			self:DivideSpeed(10)
			
			local Mic = Job:Task(script["Mic Up"].Microphone:Clone())
			Mic.Weld.Part0 = self.LuaCharacter.RightArm
			Mic.Parent = self.LuaCharacter.Model
			
			local Player = self.LuaPlayer.Player
			local Character = self.LuaCharacter.Model
			
			self.LuaPlayer.Replication:FireReliableVFX("Emotes/Mic Up", "Start", self.LuaPlayer.Player, self.LuaCharacter.Model)
			
			--local OriginalInput : AudioDeviceInput = Player:FindFirstChild("AudioDeviceInput")
			--if OriginalInput then
			--	-- OriginalInput.Muted = true
			--	local Wires = {}

			--	-- Create New Input
			--	local Input = Instance.new("AudioDeviceInput")
			--	Input.Name = "MicUp Input"
			--	Input.Parent = Player
			--	Input.Player = Player

			--	local Effect = Instance.new("AudioReverb")
			--	Effect.ReferenceFrequency = 8000
			--	Effect.DecayRatio = 10
			--	Effect.LowShelfGain = 10
			--	Effect.DecayTime = 2.3
			--	Effect.Parent = Input

			--	table.insert(Wires, Wire(Input, Effect))

			--	local Emitter = Instance.new("AudioEmitter")
			--	Emitter.Name = "MicUp Emitter"
			--	Emitter.Parent = Character
			--	Emitter.AudioInteractionGroup = `MicUp`

			--	table.insert(Wires, Wire(Effect, Emitter))
				
			--	Job:Task(function()
			--		for _, Wire in Wires do
			--			Wire:Destroy()
			--		end
					
			--		Emitter:Destroy()
			--		Input:Destroy()
			--		Effect:Destroy()
			--	end)
				
				
			--end

			Job:Task(function()
				self:TimesSpeed(10)
			end)
		end,
	},
	
	["Electro"] = {
		CustomFunction = function(self, Job)
			self:DivideSpeed(10)
			
			self.LuaPlayer.Replication:FireReliableVFX("Emotes/Electro", "Add", self.LuaCharacter.Model)
			Job:Task(function()
				self:TimesSpeed(10)
				self.LuaPlayer.Replication:FireReliableVFX("Emotes/Electro", "Remove", self.LuaCharacter.Model)
			end)
		end,
	},
	
	["Write"] = {
		CustomFunction = function(self, Job, Animation : AnimationTrack)
			self:DivideSpeed(10)

			local Pen = Job:Task(script.Write.pe:Clone())
			Pen.PENN.Weld.Part0 = self.LuaCharacter.RightArm
			Pen.Parent = self.LuaCharacter.Model
			
			local Paper = Job:Task(script.Write.Part:Clone())
			Paper.Weld.Part0 = self.LuaCharacter.LeftArm
			Paper.Parent = self.LuaCharacter.Model
			
			local LoopAnim : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes.Write.Loop)
			local FinishAnim : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes.Write.Done)
			
			local LoopSound = Job:Task(script.Write.Sounds.Loop:Clone())
			LoopSound.Parent = self.LuaCharacter.RootPart
			
			Job:Task(Animation:GetMarkerReachedSignal("finish"):Connect(function()
				LoopAnim:Play(0)
				
				Job:Task(function()
					LoopAnim:Stop(0)
				end)
				
				self.LuaPlayer.Replication:FireReliableVFXToSelf("Emotes/Write", "Start", self.LuaCharacter.Model)
				LoopSound:Play()
			end))

			--local StrCheck = Type.string():length(0, 128)
			
			local Connection; Connection = Job:Task(connect(network.finishWriting, function(Text, Player)
				--Text = StrCheck:cast(StrCheck);

				if Player == self.LuaPlayer.Player and typeof(Text) == "string" then
					Text = string.sub(Text, 1, 200)
					Connection:Disconnect()
					LoopSound:Stop()
					
					local ShowSound = Job:Task(script.Write.Sounds.Reveal:Clone())
					ShowSound.Parent = self.LuaCharacter.RootPart
					ShowSound:Play()
					
					task.spawn(function()
						if Text ~= "" then
							local Success, Result = pcall(Chat.FilterStringForBroadcast, Chat, Text, Player)

							if Success then
								Paper.Front.Paper.TextLabel.Text = Result
							else
								Paper.Front.Paper.TextLabel.Text = "😶"
								warn(Result)
							end
						end
					end)

					Pen:Destroy()
					LoopAnim:Stop(0)
					FinishAnim:Play(0)
					
					Job:Task(FinishAnim:GetMarkerReachedSignal("finish"):Connect(function()
						FinishAnim:AdjustSpeed(0)
					end))
					
					Job:Task(function()
						FinishAnim:Stop()
					end)
				end
			end))
			
			Job:Task(function()
				self:TimesSpeed(10)
			end)
		end,
	},
	
	["Lonely Lonely"] = {
		CustomFunction = function(self, Job, Animation : AnimationTrack)
			self:HideUI(true)
			self:DivideSpeed(100)
			
			Job:Task(self.LuaCharacter:StopAutoRotate())
			
			self.LuaPlayer.Replication:FireReliableVFXToSelf("Emotes/Lonely Lonely", "Start", self.LuaCharacter.Model)
			Job:Task(CreateHands(true, true, self.LuaCharacter, script.FixedHands))
			
			local Pizza = Job:Task(script["Lonely Lonely"].Pizza:Clone())
			Pizza.Weld.Part0 = self.LuaCharacter.Head
			Pizza.Parent = self.LuaCharacter.Model

			Job:Task(function()
				self:TimesSpeed(100)
				self:HideUI(false)
			end)
		end,
	},
	
	["Handshake"] = {
		Collab = {
			StopAnimationWhenPlayerJoins = true,

			ObjectText = "Dap up",
			ActionText = "Join",

			Limit = 1,

			Function2 = function(self, Data : {})
				local JoinedCombat = Data.JoinedCombat
				local JoinedJob = Data.JoinedJob
				local MainJob = Data.MainJob
				local MainAnimation = Data.MainAnimation
				
				if MainAnimation.IsPlaying then
					MainAnimation:Stop()
				end

				self.LuaCharacter:SetCollisionGroup("NoPlayerCollision")
				JoinedCombat.LuaCharacter:SetCollisionGroup("NoPlayerCollision")

				MainJob:Task(self.LuaCharacter:StopAutoRotate())
				JoinedJob:Task(JoinedCombat.LuaCharacter:StopAutoRotate())

				local UserAnim : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes["Handshake"].User)
				local FriendAnim : AnimationTrack = JoinedCombat.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes["Handshake"].Friend)

				JoinedCombat.LuaCharacter.Model:PivotTo(self:GetSimulatedRoot().CFrame * CFrame.new(0.2, 0, -5.13) * CFrame.Angles(0, math.pi, 0))
				JoinedCombat:DivideSpeed(200)

				UserAnim:Play()
				FriendAnim:Play()

				MainJob:Task(function()
					self.LuaCharacter:SetCollisionGroup("Player")
					UserAnim:Stop()
				end)
				
				JoinedJob:Task(function()
					JoinedCombat.LuaCharacter:SetCollisionGroup("Player")
					JoinedCombat:TimesSpeed(200)
					FriendAnim:Stop()
				end)
			end,
		},

		CustomFunction = function(self, Job)
			self:DivideSpeed(200)

			Job:Task(function()
				self:TimesSpeed(200)
			end)
		end,
	},
	
	["The Cruler"] = {
		CustomFunction = function(self, Job)
			local Trail = script["The Cruler"].Template
			
			local VelocityObject = self:Velocity()
			VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 50000
			VelocityObject.Settings.Controllable = true
			VelocityObject.Settings.Z = 17.5
			VelocityObject:Fire()

			Job:Task(VelocityObject)
			
			local SoundFolder = replicatedStorage.emotes["The Cruler"]
			local Sound = Job:Task(SoundFolder:FindFirstChild(if self.LuaCharacter.Combat.InCombat then "Combat" else "Passive"):Clone())
			Sound.Parent = self.LuaCharacter.RootPart
			Sound:Play()

			for _, LimbName in {"LeftArm", "RightArm", "LeftLeg", "RightLeg"} do
				local Limb = self.LuaCharacter[LimbName]
				
				if not Limb then
					continue
				end
				
				local TrailClone = Job:Task(Trail:Clone())
				TrailClone.Weld.Part0 = Limb
				TrailClone.Parent = workspace.Visuals
			end
		end,
	},
	
	["Believe"] = {
		CustomFunction = function(self, Job, Animation : AnimationTrack)
			Job:Task(CreateHands(true, true, self.LuaCharacter))
			local Speed = 10
			
			self:DivideSpeed(Speed)
			
			local LoopTrack : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes.Believe.Loop)
			local VFX = script.Believe.Attachment:Clone()
			local Brightness = VFX.PointLight.Brightness
			
			VFX.PointLight.Brightness = 0
			
			Job:Task(Animation:GetMarkerReachedSignal("finished"):Once(function()
				LoopTrack:Play(0.15)
				VFX.Parent = self.LuaCharacter.RootPart
				TweenService:Create(VFX.PointLight, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
					Brightness = Brightness
				}):Play()
			end))
			
			Job:Task(function()
				Animation:Stop(0)
				LoopTrack:Stop(0)
				VFX:Destroy()
				self:TimesSpeed(Speed)
			end)
		end,
	},
	
	["Scary Emote"] = {
		CustomFunction = function(self, Job, Animation : AnimationTrack)
			local Application = Job:Task(script["Scary Emote"].JOB:Clone())
			local M6D = Job:Task(Application.JOB)
			M6D.Part0 = self.LuaCharacter.RightArm
			M6D.Parent = self.LuaCharacter.RightArm
			Application.Parent = workspace.Visuals
			
			Job:Task(Animation.Stopped:Once(function()
				Job:Destroy()
			end))
			
			Job:Task(function()
				if Application then
					Application:Destroy()
				end
				
				if M6D then
					M6D:Destroy()
				end
			end)
		end,
	},
	
	["Jitter Bugging"] = {
		Collab = {
			ObjectText = "Jitter their bug?",
			ActionText = "Join",

			TeleportOnEmoteEnded = true,

			Function = function(self, TargetCombat, _, JoinedJob, UserAnimation : AnimationTrack)
				JoinedJob:Task(TargetCombat.LuaCharacter:StopAutoRotate())

				self.LuaCharacter:SetCollisionGroup("NoPlayerCollision")
				TargetCombat.LuaCharacter:SetCollisionGroup("NoPlayerCollision")

				TargetCombat:DivideSpeed(1000)
				TargetCombat.LuaCharacter.RootPart.CFrame = self:GetSimulatedRoot().CFrame * CFrame.new(-5.445, 0, 0)

				local Anim : AnimationTrack = TargetCombat.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes["Jitter Bugging"].Duo)
				Anim:Play()
				
				task.spawn(function()
					while not UserAnimation.TimePosition and Anim.IsPlaying do
						task.wait()
					end
					
					Anim.TimePosition = UserAnimation.TimePosition
					
					print(UserAnimation.TimePosition - Anim.TimePosition)
				end)

				JoinedJob:Task(function()
					if not self:GetState("Grabbed") then
						self.LuaCharacter:SetCollisionGroup("Player")
					end

					if not TargetCombat:GetState("Grabbed") then
						TargetCombat.LuaCharacter:SetCollisionGroup("Player")
					end

					TargetCombat:TimesSpeed(1000)
					Anim:Stop()
				end)
			end,
		},

		CustomFunction = function(self, Job)
			Job:Task(self.LuaCharacter:StopAutoRotate())
			self:DivideSpeed(1000)

			Job:Task(function()
				self:TimesSpeed(1000)
			end)
		end,
	},
	
	["Mesmerizer"] = {
		Collab = {
			ObjectText = "Are you a backupdancer?",
			ActionText = "Join",

			TeleportOnEmoteEnded = true,

			Function = function(self, TargetCombat, _, JoinedJob, UserAnimation : AnimationTrack)
				JoinedJob:Task(TargetCombat.LuaCharacter:StopAutoRotate())

				self.LuaCharacter:SetCollisionGroup("NoPlayerCollision")
				TargetCombat.LuaCharacter:SetCollisionGroup("NoPlayerCollision")

				TargetCombat:DivideSpeed(1000)
				TargetCombat.LuaCharacter.RootPart.CFrame = self:GetSimulatedRoot().CFrame * CFrame.new(-6, 0, 0)

				local Anim : AnimationTrack = TargetCombat.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes.Mesmerizer.Duo)
				Anim:Play()

				task.spawn(function()
					while not UserAnimation.TimePosition and Anim.IsPlaying do
						task.wait()
					end

					Anim.TimePosition = UserAnimation.TimePosition
				end)

				JoinedJob:Task(function()
					if not self:GetState("Grabbed") then
						self.LuaCharacter:SetCollisionGroup("Player")
					end

					if not TargetCombat:GetState("Grabbed") then
						TargetCombat.LuaCharacter:SetCollisionGroup("Player")
					end

					TargetCombat:TimesSpeed(1000)
					Anim:Stop()
				end)
			end,
		},

		CustomFunction = function(self, Job)
			Job:Task(self.LuaCharacter:StopAutoRotate())
			self:DivideSpeed(1000)

			Job:Task(function()
				self:TimesSpeed(1000)
			end)
		end,
	},
	
	["Destruction"] = {
		CustomFunction = function(self, Job, Animation : AnimationTrack)
			local Speed = 50

			self:DivideSpeed(Speed)

			local LoopTrack : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes["Destruction"].Idle)
			
			Job:Task(task.delay(65/60, function()
				local Reference = Job:Task(Instance.new("Configuration"))
				Reference.Name = "_jjkpotential-screeneffect-refference"
				Reference.Parent = workspace.Visuals
				
				self.LuaPlayer.Replication:FireReliableVFXToSelf("Emotes/Potential", "Start", Reference)
			end))
			
			Job:Task(task.delay(85/60, function()
				for _, Child in AddJJKPotentialVFX(self.LuaCharacter.Model, "Mahito") do
					Job:Task(Child)
				end
			end))
			
			Job:Task(task.delay((125/60)-0.15, function()
				LoopTrack:Play(0.15)
			end))

			Job:Task(function()
				Animation:Stop(0)
				LoopTrack:Stop(0)
				self:TimesSpeed(Speed)
			end)
		end,
	},
	
	["Justice"] = {
		CustomFunction = function(self, Job, Animation : AnimationTrack)
			local Speed = 50

			self:DivideSpeed(Speed)

			local LoopTrack : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes.Justice.Idle)
			
			Job:Task(task.delay(100/60, function()
				local Reference = Job:Task(Instance.new("Configuration"))
				Reference.Name = "_jjkpotential-screeneffect-refference"
				Reference.Parent = workspace.Visuals

				self.LuaPlayer.Replication:FireReliableVFXToSelf("Emotes/Potential", "Start", Reference)
				
				for _, Child in AddJJKPotentialVFX(self.LuaCharacter.Model, "Itadori") do
					Job:Task(Child)
				end
			end))
			
			Job:Task(task.delay((125/60)-0.15, function()
				LoopTrack:Play(0.15)
			end))

			Job:Task(function()
				Animation:Stop(0)
				LoopTrack:Stop(0)
				self:TimesSpeed(Speed)
			end)
		end,
	},
	
	["Partnership"] = {
		CustomFunction = function(self, Job, Animation : AnimationTrack)
			local Speed = 50
			
			self:DivideSpeed(Speed)
			
			local LoopTrack : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes.Partnership.Idle)
			
			Job:Task(task.delay(25/60, function()
				local Reference = Job:Task(Instance.new("Configuration"))
				Reference.Name = "_jjkpotential-screeneffect-refference"
				Reference.Parent = workspace.Visuals
				
				self.LuaPlayer.Replication:FireReliableVFXToSelf("Emotes/Potential", "Start", Reference)
			end))
			
			Job:Task(task.delay(40/60, function()
				for _, Child in AddJJKPotentialVFX(self.LuaCharacter.Model, "Todo") do
					Job:Task(Child)
				end
			end))
			
			Job:Task(task.delay((59/60)-0.15, function()
				LoopTrack:Play(0.15)
			end))

			Job:Task(function()
				Animation:Stop(0)
				LoopTrack:Stop(0)
				self:TimesSpeed(Speed)
			end)
		end,
	},
	
	["Who is you?"] = {
		MoveToCancel = true,

		CustomFunction = function(self, Job, Animation : AnimationTrack)
			local VelocityObject = self:Velocity()
			VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 50000
			VelocityObject.Settings.Controllable = true
			VelocityObject.Settings.Z = 2.5
			VelocityObject.Settings.NeedsVelocityAttribute = true
			VelocityObject:Fire()

			Job:Task(VelocityObject)
		end,
	},
	
	["Thinker"] = {
		CustomFunction = function(self, Job, Animation : AnimationTrack)
			local Speed = 50

			self:DivideSpeed(Speed)

			local LoopTrack : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes.Thinker.Idle)
			
			Job:Task(self.LuaCharacter:StopAutoRotate())
			
			Job:Task(task.delay(0.5, function()
				local Rock : typeof(script.Thinker.Rock) = Job:Task(script.Thinker.Rock:Clone())
				Rock.Join.Part0 = self.LuaCharacter.RootPart
				
				local Result = workspace:Raycast(self.LuaCharacter.RootPart.Position + vector.create(0, 2, 0), vector.create(0, -20, 0),  Utility.VisualParams)
				
				if (Result and Result.Instance) then
					Rock.Material = Result.Material or Result.Instance.Material
					Rock.Color = Result.Instance.Color
					
					for _, Texture in Result.Instance:GetChildren() do
						if not Texture:IsA("Texture") then
							continue
						end
						
						Texture:Clone().Parent = Rock
					end
				end
				
				Rock.Parent = workspace.Visuals
			end))

			Job:Task(task.delay((97/60)-0.15, function()
				LoopTrack:Play(0.15)
			end))

			Job:Task(function()
				Animation:Stop(0)
				LoopTrack:Stop(0)
				self:TimesSpeed(Speed)
			end)
		end,
	},
	
	["Your Idol"] = {
		CustomFunction = function(self, Job, Animation : AnimationTrack)
			self:DivideSpeed(50)

			local LoopTrack : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes["Your Idol"].Loop)

			Job:Task(task.delay((1141/60)-0.15, function()
				LoopTrack:Play(0.15)
			end))

			Job:Task(function()
				Animation:Stop(0)
				LoopTrack:Stop(0)
				self:TimesSpeed(50)
			end)
		end,
	},
	
	["Super Saiyan"] = {
		CustomFunction = function(self, Job, Animation : AnimationTrack)
			local Speed = 200
			local Duration = 30
			
			---------------------------------------------------------------------------
			
			local function get_max_lifetime(item : Instance | {})
				if typeof(item) == "Instance" and item:GetAttribute("Lifetime") then
					return item:GetAttribute("Lifetime")
				else
					local max_lifetime = 0

					local directory = if typeof(item) == "Instance" then item:GetDescendants() else item

					for _, emitter in directory do
						if typeof(emitter) ~= "Instance" then
							continue
						end

						if not emitter:IsA("ParticleEmitter") then
							continue
						end

						local emitter_attributes = emitter:GetAttributes()

						local emit_duration = emitter_attributes["EmitDuration"] or 0
						local emit_delay =  emitter_attributes["EmitDelay"] or 0
						local lifetime = (emitter.Lifetime.Max + emit_duration + emit_delay) / emitter.TimeScale

						if emitter_attributes["Lifetime"] then
							lifetime = math.max(lifetime, emitter_attributes["LifeTime"])
						end

						if max_lifetime < lifetime and lifetime < 1e999 then
							max_lifetime = lifetime
						end
					end

					return max_lifetime
				end
			end
			
			local function Toggle(Holder : Instance, Value : boolean)
				if Holder:IsA("ParticleEmitter") or Holder:IsA("Trail") or Holder:IsA("Beam") or Holder:IsA("PointLight") then
					Holder.Enabled = Value
				end
				
				for _, Item in ipairs(Holder:GetDescendants()) do
					if Item:IsA("ParticleEmitter") or Item:IsA("Trail") or Item:IsA("Beam") or Item:IsA("PointLight") then
						Item.Enabled = Value
					end
				end
			end

			local function Clean()
				for _, Effect in self.LuaCharacter.Model:GetDescendants() do
					if not CollectionService:HasTag(Effect, "SuperSaiyanEmoteAura") then
						continue
					end
					
					CollectionService:RemoveTag(Effect, "SuperSaiyanEmoteAura")
					
					if Effect:IsA("Highlight") then
						TweenService:Create(Effect, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
							FillTransparency = 1
						}):Play()
						
						self.Job:Task(task.delay(0.25, Effect.Destroy, Effect))
					elseif Effect:IsA("Sound") then
						TweenService:Create(Effect, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
							Volume = 0
						}):Play()

						self.Job:Task(task.delay(0.25, Effect.Destroy, Effect))
					else
						Toggle(Effect, false)
						task.delay(get_max_lifetime({Effect}), Effect.Destroy, Effect)
					end
				end
			end
			
			Clean()
			
			self:DivideSpeed(Speed)
			
			local SFX = script["Super Saiyan"].Theme:Clone()
			CollectionService:AddTag(SFX, "SuperSaiyanEmoteAura")
			SFX.Parent = self.LuaCharacter.RootPart
			
			self.LuaPlayer.Replication:FireReliableVFX("Emotes/Super Saiyan", "Start", self.LuaCharacter.Model)
			
			local SetAura = false
			
			Job:Task(Animation:GetMarkerReachedSignal("Aura"):Once(function()
				SetAura = true
				
				SFX:Play()
				
				local AuraHolder = script["Super Saiyan"].Aura
				
				for _, Part in AuraHolder:GetChildren() do
					if not self.LuaCharacter.Model:FindFirstChild(Part.Name) then
						continue
					end
					
					for _, Item in Part:GetChildren() do
						local Clone = Item:Clone()
						CollectionService:AddTag(Clone, "SuperSaiyanEmoteAura")
						
						if table.find(EnableAble, Clone.ClassName) then
							Clone.Enabled = true
						end
						
						for _, PossibleEffect in Clone:GetDescendants() do
							if not table.find(EnableAble, PossibleEffect.ClassName) then
								continue
							end
							
							PossibleEffect.Enabled = true
						end
						
						Clone.Parent = self.LuaCharacter.Model:FindFirstChild(Part.Name)
					end
				end
				
				for _, Item in self.LuaCharacter.Model:GetChildren() do
					
					if (Item:IsA("Accessory") and Item.AccessoryType == Enum.AccessoryType.Hair) then
						local Highlight = script["Super Saiyan"].HairHighlight:Clone()
						Highlight.Enabled = true
						Highlight.Adornee = Item.Handle
						CollectionService:AddTag(Highlight, "SuperSaiyanEmoteAura")
						Highlight.Parent = Item.Handle
					end
					
				end
			end))
			
			Job:Task(Animation.Ended:Once(function()
				Job:Destroy()
			end))
			
			local Reference = Instance.new("Configuration")
			Reference.Name = "SuperSaiyanEmoteAuraReference"
			CollectionService:AddTag(Reference, "SuperSaiyanEmoteAura")
			Reference.Parent = self.LuaCharacter.Model
			
			Job:Task(function()
				self:TimesSpeed(Speed)
				
				if not SetAura then
					Reference:Destroy()
					SFX:Destroy()
				end
			end)
			
			self.Job:Task(task.delay(Duration, function()
				if not (Reference ~= nil and Reference:IsDescendantOf(self.LuaCharacter.Model)) then
					return
				end
				
				Clean()
			end))
		end,
	},
	
	["Crashout"] = {
		CustomFunction = function(self, Job, Animation : AnimationTrack)
			local Speed = 100

			self:DivideSpeed(Speed)

			local LoopTrack : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes.Crashout.Idle)

			--Job:Task(self.LuaCharacter:StopAutoRotate())
			
			local SFX = Job:Task(script.Crashout.Start:Clone())
			SFX.Parent = self.LuaCharacter.RootPart
			SFX:Play()
			
			Job:Task(task.delay((160/60)-0.15, function()
				LoopTrack:Play(0.15)

				local VFXPart = Job:Task(script.Crashout.WeldedAura:Clone())
				VFXPart.Join.Part0 = self.LuaCharacter.RootPart
				VFXPart.Parent = workspace.Visuals

				for _, Item in VFXPart:GetDescendants() do
					if Item:IsA("ParticleEmitter") or Item:IsA("Trail") or Item:IsA("Beam") or Item:IsA("PointLight") then
						Item.Enabled = true
					end
				end

				for _, PartName in {"Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"} do
					Job:Task(script.Crashout.SmokeBack:Clone()).Parent = self.LuaCharacter[PartName]
				end

				local EyeAura = Job:Task(script.Crashout.Head.Eye:Clone())
				EyeAura.Parent = self.LuaCharacter.Head

				local Reference = Job:Task(Instance.new("Configuration"))
				Reference.Name = "_crashout-screeneffect-refference"
				Reference.Parent = workspace.Visuals

				self.LuaPlayer.Replication:FireReliableVFXToSelf("Emotes/Potential", "Start", Reference, true)
				
				local Theme = Job:Task(script.Crashout.Theme:Clone())
				Theme.Parent = self.LuaCharacter.RootPart
				Theme:Play()
			end))

			Job:Task(function()
				Animation:Stop(0)
				LoopTrack:Stop(0)
				self:TimesSpeed(Speed)
			end)
		end,
	},
	
	["Static-Estatic!"] = BasicEmote({SyncMusicWithAnimationLoop = true}),
	
	["Niko"] =  BasicEmote({Speed = 25, NatsukiHands = true}),
	["Boppin"] =  BasicEmote({Speed = 20}),
	["On Fire"] =  BasicEmote({
		Speed = 20,
		
		Callback = function(self, Job)
			local SFX : Sound = Job:Task(script["On Fire"].Start:Clone())
			SFX.Parent = self.LuaCharacter.RootPart

			local Loop = Job:Task(script["On Fire"].Loop:Clone())
			Loop.Parent = self.LuaCharacter.RootPart

			SFX:Play()

			Job:Task(task.delay(SFX.TimeLength, function()
				Loop:Play()
			end))
		end,
	}),
	--["Haywire"] =  BasicEmote({Speed = 20}),
	--["Gold Digger"] =  BasicEmote({Speed = 20}),
	--["Poke Dance"] =  BasicEmote({Speed = 20}),
	["PNG"] =  BasicEmote({Speed = 20}),
	--["Get It Now"] =  BasicEmote({Speed = 20}),
	
	["Sherma"] = {
		CustomFunction = function(self, Job, Animation : AnimationTrack)
			self:DivideSpeed(25)

			Job:Task(function()
				self:TimesSpeed(25)
			end)

			local Tools = Job:Task(script.Sherma.sherma:Clone())
			Tools.Baton.Weld.Part0 = self.LuaCharacter.RightArm
			Tools.Pin.Weld.Part0 = self.LuaCharacter.LeftArm
			Tools.Parent = self.LuaCharacter.Model
		end,
	},
	
	["Democracy Walk"] = {
		MoveToCancel = true,

		CustomFunction = function(self, Job, Animation : AnimationTrack)
			local VelocityObject = self:Velocity()
			VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 50000
			VelocityObject.Settings.Controllable = true
			VelocityObject.Settings.Z = 7
			VelocityObject.Settings.NeedsVelocityAttribute = true
			VelocityObject:Fire()

			Job:Task(VelocityObject)
		end,
	},
	
	["Metro"] = BasicEmote({
		Callback = function(self, Job, Animation)
			local LoopTrack : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes["Metro"].Idle)
			--LoopTrack.Looped = false
			
			Job:Task(Animation:GetMarkerReachedSignal("End"):Once(function()
				local SFX = Job:Task(script.Metro.Loop:Clone())
				SFX.Parent = self.LuaCharacter.RootPart
				SFX:Play()
				
				if not SFX.IsLoaded then
					SFX.Loaded:Wait()
				end
				
				Animation:Stop(0.4)
				LoopTrack:Play(0.4, 1, 1.18)
				
				--Job:Task(task.spawn(function()
				--	while not Job.Destroyed do
				--		task.wait(0.7)

				--		LoopTrack:Stop(0.001)
				--		LoopTrack:Play(0.001)
				--	end
				--end))
			end))

			Job:Task(function()
				LoopTrack:Stop(0)
			end)
		end,
		
		Speed = 18
	}),
	
	["Idol V2"] = {
		StopAfterAnimationStop = true,	

		CustomFunction = function(self, Job)
			Job:Task(self.LuaCharacter:StopAutoRotate())
			self:DivideSpeed(50)
			self.LuaPlayer.Replication:FireReliableVFX("Emotes/Idol V2", "Start", self.LuaCharacter.Model)

			Job:Task(function()
				self:TimesSpeed(50)
			end)
		end,
	},
	
	["Piggy Back"] = {
		Collab = {
			StopAnimationWhenPlayerJoins = true,

			ObjectText = "Want a lift?",
			ActionText = "Get On",

			Limit = 1,
			
			Function2 = function(self, Data)
				local JoinedCombat = Data.JoinedCombat
				local JoinedJob = Data.JoinedJob
				local MainJob = Data.MainJob
				local MainAnimation = Data.MainAnimation
				
				self.LuaCharacter:SetCollisionGroup("NoPlayerCollision")
				
				JoinedCombat.LuaCharacter:SetCollisionGroup("NoPlayerCollision")
				JoinedJob:Task(JoinedCombat.LuaCharacter:StopAutoRotate())
				JoinedCombat:DivideSpeed(200)
				
				network.grabSet.sendToAll({ part = JoinedCombat.LuaCharacter.RootPart, boundTo = self.LuaCharacter.RootPart, offset = CFrame.identity })
				
				local AcceptedUser : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes["Piggy Back"].AcceptedUser)
				local AcceptedFriend : AnimationTrack = JoinedCombat.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes["Piggy Back"].AcceptedFriend)

				local UserLoop : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes["Piggy Back"].LoopUser)
				local FriendLoop : AnimationTrack = JoinedCombat.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes["Piggy Back"].LoopFriend)
				
				local Thread = task.delay(45/60, function()
					UserLoop:Play(1/12)
					FriendLoop:Play(1/12)

					local VelocityObject = self:Velocity()
					VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 50000
					VelocityObject.Settings.Controllable = true
					VelocityObject.Settings.Z = 17.5
					VelocityObject:Fire()

					MainJob:Task(VelocityObject)

					local Sound = MainJob:Task(script["Piggy Back"].Loop:Clone())
					Sound.Parent = self.LuaCharacter.RootPart
					Sound:Play()

					MainJob:Task(UserLoop.Stopped:Once(function()
						MainJob:Destroy()
					end))
					
					MainJob:Task(FriendLoop.Stopped:Once(function()
						MainJob:Destroy()
					end))
				end)
				
				MainJob:Task(Thread)
				JoinedJob:Task(Thread)
				
				MainJob:Task(function()
					if not self:GetState("Grabbed") then
						self.LuaCharacter:SetCollisionGroup("Player")
					end
					
					AcceptedUser:Stop()
					UserLoop:Stop()
				end)
				
				JoinedJob:Task(function()
					if not JoinedCombat:GetState("Grabbed") then
						JoinedCombat.LuaCharacter:SetCollisionGroup("Player")
						network.grabDetach.sendToAll(JoinedCombat.LuaCharacter.RootPart)
					end
					
					JoinedCombat:TimesSpeed(200)
					AcceptedFriend:Stop()
					FriendLoop:Stop()
				end)
				
				AcceptedUser:Play()
				AcceptedFriend:Play()
			end,
		},
		
		CustomFunction = function(self, Job)
			self:DivideSpeed(200)

			Job:Task(function()
				self:TimesSpeed(200)
			end)
		end,
	},
	
	["Machine Love"] = BasicEmote({SyncMusicWithAnimationLoop = true}),
	
	["Go to sleeeeeeeeeeeeep"] = BasicEmote({Speed = 25, NatsukiHands = true}),
	
	["Obama"] = BasicEmote({SyncMusicWithAnimationLoop = true}),
	
	["Just Sit"] = BasicEmote({
		Speed = 200,
		
		Callback = function(self, Job, Animation)
			local LoopTrack : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes["Just Sit"].Idle)
			
			Job:Task(Animation:GetMarkerReachedSignal("End"):Once(function()
				LoopTrack:Play(0.15)
			end))
			
			Job:Task(function()
				LoopTrack:Stop(0)
			end)
		end,
	}),
	
	["PUT IT ONG"] = BasicEmote({
		Speed = 200,

		Callback = function(self, Job, Animation)
			local SFX : Sound = Job:Task(script["PUT IT ONG"].Start:Clone())
			SFX.Parent = self.LuaCharacter.RootPart
			
			local Loop = Job:Task(script["PUT IT ONG"].Theme:Clone())
			Loop.Parent = self.LuaCharacter.RootPart
			
			SFX:Play()
			
			Job:Task(task.delay(0.9, function()
				Loop:Play()
			end))
			
			local Shotgun = Job:Task(script["PUT IT ONG"]["Remington 870"]:Clone())
			local Join = Job:Task(Shotgun.Join)
			Join.Part0 = self.LuaCharacter.LeftArm
			Shotgun.Parent = workspace.Visuals
			Join.Parent = Join.Part0
			
			Job:Task(task.delay(1, function()
				local VelocityObject = self:Velocity()
				VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 50000
				VelocityObject.Settings.Controllable = true
				VelocityObject.Settings.Z = 10
				VelocityObject:Fire()
				
				Job:Task(VelocityObject)
			end))
			
			local LoopTrack : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes["PUT IT ONG"].Idle)

			Job:Task(Animation:GetMarkerReachedSignal("End"):Once(function()
				LoopTrack:Play(0.15)
			end))

			Job:Task(function()
				LoopTrack:Stop(0)
			end)
		end,
	}),
	
	["Starman"] = BasicEmote({
		Speed = 200,

		Callback = function(self, Job, Animation)
			local LoopTrack : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes.Starman.Idle)

			Job:Task(Animation:GetMarkerReachedSignal("End"):Once(function()
				LoopTrack:Play(0.15)
			end))

			Job:Task(function()
				LoopTrack:Stop(0)
			end)
			
			Job:Task(Animation:GetMarkerReachedSignal("Effect"):Once(function()
				self.LuaPlayer.Replication:FireReliableVFX("Global/ClientEmit", "At", self.LuaCharacter.RootPart.CFrame, replicatedStorage.emotes._StarmanEffect.Emit)
				
				local VFXPart = Job:Task(script.Starman.Toggle:Clone())
				VFXPart.Join.Part0 = self.LuaCharacter.RootPart
				VFXPart.Parent = workspace.Visuals
				
				for _, Item in VFXPart:GetDescendants() do
					if Item:IsA("ParticleEmitter") or Item:IsA("Trail") or Item:IsA("Beam") or Item:IsA("PointLight") then
						Item.Enabled = true
					end
				end
			end))
		end,
	}),
	
	["Standing Next To You"] = BasicEmote({SyncMusicWithAnimationLoop = true}),
	
	["Gon"] = BasicEmote({
		Speed = 200,
		NoStand = true,
		Callback = function(self, Job, Animation)
			local VFXPart = Job:Task(script.Gon.Root:Clone())
			VFXPart.Join.Part0 = self.LuaCharacter.RootPart
			VFXPart.Parent = workspace.Visuals

			for _, Item in VFXPart:GetDescendants() do
				if Item:IsA("ParticleEmitter") or Item:IsA("Trail") or Item:IsA("Beam") or Item:IsA("PointLight") then
					Item.Enabled = true
				end
			end
		end,
	}),
	
	["Criss-Cross Applesauce"] = BasicEmote({
		Speed = 200,

		Callback = function(self, Job, Animation)
			local LoopTrack : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes["Criss-Cross Applesauce"].Idle)

			Job:Task(Animation:GetMarkerReachedSignal("End"):Once(function()
				LoopTrack:Play(0.15)
			end))

			Job:Task(function()
				LoopTrack:Stop(0)
			end)
		end,
	}),
	
	["Doakes"] = BasicEmote({
		Speed = 200,

		Callback = function(self, Job, Animation)
			local VelocityObject = self:Velocity()
			VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 50000
			VelocityObject.Settings.Controllable = true
			VelocityObject.Settings.Z = 6
			VelocityObject:Fire()
			
			Job:Task(VelocityObject)
		end,
		
		NoStand = true,
	}),
	
	["Sofa"] = BasicEmote({
		Speed = 200,
		LockRotation = true,
		
		Callback = function(self, Job, Animation)
			self.LuaCharacter:SetCollisionGroup("NoPlayerCollision")
			
			for _, Child in script.Sofa:GetChildren() do
				local Clone = Job:Task(Child:Clone())
				local Join = Job:Task(Clone:FindFirstChild("Join", true))
				Join.Name = Join.Part1.Name
				Join.Part0 = self.LuaCharacter.RootPart
				Join.Parent = self.LuaCharacter.RootPart
				Clone.Parent = workspace.Visuals
			end
			
			local LoopTrack : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes.Sofa.User)

			Job:Task(task.delay(100/60, function()
				LoopTrack:Play(0.15)
			end))

			Job:Task(function()
				LoopTrack:Stop(0)
				
				if not self:GetState("Grabbed") then
					self.LuaCharacter:SetCollisionGroup("Player")
				end
			end)
			
			local Folder = Job:Task(Instance.new("Folder"))
			Folder.Name = `{self.LuaCharacter.Model.Name}_SofaEmoteReference`
			
			for Index = 1, 4 do
				Folder:SetAttribute(`Friend{Index}`, false)
			end
			
			Folder.Parent = workspace.Visuals
		end,
		
		Collab = {
			ObjectText = "Are you unemployed?",
			ActionText = "Join the boys, not a yacutzi tho 😂😂😂",

			Limit = 4,
			
			UsesSigmaFolderMethod = true,

			Function2 = function(self, Data : {})
				local JoinedCombat = Data.JoinedCombat
				local MainJob = Data.MainJob
				local JoinedJob = Data.JoinedJob
				local JoinedTable = Data.JoinedTable
				local MainAnimation = Data.MainAnimation
				
				JoinedCombat.LuaCharacter:SetCollisionGroup("NoPlayerCollision")
				JoinedJob:Task(JoinedCombat.LuaCharacter:StopAutoRotate())
				JoinedCombat:DivideSpeed(50)
				
				local Folder = workspace.Visuals:FindFirstChild(`{self.LuaCharacter.Model.Name}_SofaEmoteReference`)
				
				local FriendIndex = 1
				
				for Index = 1, 4 do
					if Folder:GetAttribute(`Friend{Index}`) then
						continue
					end
					
					FriendIndex = Index
					Folder:SetAttribute(`Friend{FriendIndex}`, true)
					
					break
				end
				
				local Anim : AnimationTrack = JoinedCombat.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes.Sofa[`Friend{FriendIndex}`])

				JoinedCombat.LuaCharacter:Anchor(true, true)
				JoinedCombat.LuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame)
				
				network.grabSet.sendToAll({ part = JoinedCombat.LuaCharacter.RootPart, boundTo = self.LuaCharacter.RootPart, offset = CFrame.identity })

				Anim:Play()
				Anim.TimePosition = MainAnimation.TimePosition

				JoinedJob:Task(function()
					JoinedCombat.LuaCharacter:Anchor(false)
					
					if not JoinedCombat:GetState("Grabbed") then
						JoinedCombat.LuaCharacter:SetCollisionGroup("Player")
						network.grabDetach.sendToAll(JoinedCombat.LuaCharacter.RootPart)
					end
					
					JoinedCombat:TimesSpeed(50)
					Anim:Stop()
					
					if Folder then
						Folder:SetAttribute(`Friend{FriendIndex}`, false)
					end
				end)
			end,
		},
	}),
	
	["Jevil Chaos"] = BasicEmote({}),
	
	["Hug"] = BasicEmote({
		Callback = function(self, Job, Animation)
			local LoopTrack : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes.Hug.StartIdle)

			Job:Task(Animation:GetMarkerReachedSignal("End"):Once(function()
				LoopTrack:Play(0.15)
			end))

			Job:Task(function()
				LoopTrack:Stop(0)
			end)
			
			local Folder = Job:Task(Instance.new("Folder"))
			Folder.Name = `{self.LuaCharacter.Model.Name}_HugLoop`
			Folder.Parent = workspace.Visuals
			
			Job:Task(Folder.Destroying:Once(function()
				LoopTrack:Stop(0)
			end))
		end,
		
		Collab = {
			StopAnimationWhenPlayerJoins = true,

			ObjectText = "Need a hug?",
			ActionText = "Bring it in",

			Limit = 1,

			Function2 = function(self, Data)
				local JoinedCombat = Data.JoinedCombat
				local JoinedJob = Data.JoinedJob
				local MainJob = Data.MainJob
				local MainAnimation = Data.MainAnimation

				self.LuaCharacter:SetCollisionGroup("NoPlayerCollision")

				JoinedCombat.LuaCharacter:SetCollisionGroup("NoPlayerCollision")
				JoinedJob:Task(JoinedCombat.LuaCharacter:StopAutoRotate())
				JoinedCombat:DivideSpeed(200)

				network.grabSet.sendToAll({ part = JoinedCombat.LuaCharacter.RootPart, boundTo = self.LuaCharacter.RootPart, offset = CFrame.identity })

				local AcceptedUser : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes.Hug.InitUser)
				local AcceptedFriend : AnimationTrack = JoinedCombat.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes.Hug.InitTarget)

				local UserLoop : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes.Hug.UserLoop)
				local FriendLoop : AnimationTrack = JoinedCombat.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes.Hug.TargetLoop)

				local Thread = task.delay(45/60, function()
					UserLoop:Play(1/12)
					FriendLoop:Play(1/12)
					
					MainJob:Task(UserLoop.Stopped:Once(function()
						MainJob:Destroy()
					end))

					MainJob:Task(FriendLoop.Stopped:Once(function()
						MainJob:Destroy()
					end))
				end)

				MainJob:Task(Thread)
				JoinedJob:Task(Thread)

				MainJob:Task(function()
					if not self:GetState("Grabbed") then
						self.LuaCharacter:SetCollisionGroup("Player")
					end

					AcceptedUser:Stop()
					UserLoop:Stop()
				end)

				JoinedJob:Task(function()
					if not JoinedCombat:GetState("Grabbed") then
						JoinedCombat.LuaCharacter:SetCollisionGroup("Player")
						network.grabDetach.sendToAll(JoinedCombat.LuaCharacter.RootPart)
					end

					JoinedCombat:TimesSpeed(200)
					AcceptedFriend:Stop()
					FriendLoop:Stop()
				end)
				
				local Folder = workspace.Visuals:FindFirstChild(`{self.LuaCharacter.Model.Name}_HugLoop`)
				
				if Folder then
					Folder:Destroy()
				end

				AcceptedUser:Play()
				AcceptedFriend:Play()
			end,
		},
	}),
	
	["Golden"] = {
		--SyncMusicWithAnimationLoop = true,
		--DontLoopAudio = true,

		Collab = {
			ObjectText = "Golden",
			ActionText = "Join",

			Limit = 2,

			Function2 = function(self, Data : {})
				local JoinedCombat = Data.JoinedCombat
				local JoinedJob = Data.JoinedJob
				local JoinedTable = Data.JoinedTable
				local MainAnimation : AnimationTrack = Data.MainAnimation
				
				if MainAnimation.IsPlaying then
					JoinedCombat.LuaCharacter:SetCollisionGroup("NoPlayerCollision")
					JoinedJob:Task(JoinedCombat.LuaCharacter:StopAutoRotate())
					JoinedCombat:DivideSpeed(200)

					local Side = (Utility.TableCount(JoinedTable) == 0 and "Left" or "Right")
					local Anim : AnimationTrack = JoinedCombat.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes["Golden"][Side])

					JoinedCombat.LuaCharacter.Model:PivotTo(self:GetSimulatedRoot().CFrame)

					Anim:Play()
					Anim.TimePosition = MainAnimation.TimePosition
					
					local LoopAnim : AnimationTrack
					LoopAnim = JoinedCombat.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes["Golden"][`{Side} Loop`])
					
					JoinedJob:Task(MainAnimation:GetMarkerReachedSignal("End"):Connect(function()
						Anim:Stop(0)
						LoopAnim:Play(0)
					end))

					JoinedJob:Task(function()
						JoinedCombat:TimesSpeed(200)
						Anim:Stop()
						JoinedCombat.LuaCharacter:SetCollisionGroup("Player")
						
						if LoopAnim and LoopAnim.IsPlaying then
							LoopAnim:Stop(0)
						end
					end)
				end
			end,
		},

		CustomFunction = function(self, Job, Animation : AnimationTrack)
			self:DivideSpeed(200)
			Job:Task(self.LuaCharacter:StopAutoRotate())
			
			local Anim
			Anim = self.LuaCharacter.Humanoid:LoadAnimation(replicatedStorage.animations.Emotes.Golden["Start Loop"])
			
			Job:Task(Animation:GetMarkerReachedSignal("End"):Connect(function()
				Anim:Play()
			end))
			
			Job:Task(function()
				self:TimesSpeed(200)
				if Anim and Anim.IsPlaying then
					Anim:Stop(0)
				end
			end)
		end,
	},
	
	["Famous"] = BasicEmote({SyncMusicWithAnimationLoop = true, LockRotation = true}), 
	
	["Flop"] = BasicEmote({SyncMusicWithAnimationLoop = true}),
	
	["SixSeven"] = BasicEmote({
		Callback = function(self, Job, Animation)
			local Six = Job:Task(script.SixSeven.six:Clone())
			Six.Parent = self.LuaCharacter.Model
			
			local Seven = Job:Task(script.SixSeven.seven:Clone())
			Seven.Parent = self.LuaCharacter.Model
			
			Six.six.Part0 = self.LuaCharacter.Model["Right Arm"]
			Seven.seven.Part0 = self.LuaCharacter.Model["Left Arm"]
		end,
	}),
	
	--[[["StrikeATaunt"] = BasicEmote({
		Callback = function(self, Job, Animation)
			local Items = Job:Task(script.StrikeATaunt.Items:Clone())
			Items.Parent = self.LuaCharacter.Model
			
			print(Items)
			
			Items["Metal Bat"].Grip.Grip.Part0 = self.LuaCharacter["Right Arm"]
			Items["Metal Bat"].Grip.Grip.Part1 = Items["Metal Bat"].Grip
			Items["Metal Bat"].Grip.Grip.Parent = self.LuaCharacter["Right Arm"]
			
			Items["Bloxy Cola"]["Bloxy Cola"].Part0 = self.LuaCharacter["Right Arm"]
			Items["Bloxy Cola"]["Bloxy Cola"].Part1 = Items["Bloxy Cola"]
			Items["Bloxy Cola"]["Bloxy Cola"].Parent = self.LuaCharacter["Right Arm"]
			
			Items["Fried Chicken Bucket"]["Fried Chicken Bucket"].Part0 = self.LuaCharacter["Right Arm"]
			Items["Fried Chicken Bucket"]["Fried Chicken Bucket"].Part1 = Items["Fried Chicken Bucket"]
			Items["Fried Chicken Bucket"]["Fried Chicken Bucket"].Parent = self.LuaCharacter["Right Arm"]
			
			Items.Gun.Gun.Part0 = self.LuaCharacter["Right Arm"]
			Items.Gun.Gun.Part1 = Items.Gun
			Items.Gun.Gun.Parent = self.LuaCharacter["Right Arm"]
			
			Items.Football.Football.Part0 = self.LuaCharacter["Left Arm"]
			Items.Football.Football.Part1 = Items.Football
			Items.Football.Football.Parent = self.LuaCharacter["Left Arm"]
			
			Items.Guitar.Shaft.Shaft.Part0 = self.LuaCharacter["Left Arm"]
			Items.Guitar.Shaft.Shaft.Part1 = Items.Guitar.Shaft
			Items.Guitar.Shaft.Shaft.Parent = self.LuaCharacter["Left Arm"]
			
			Items["Fried Chicken"]["Fried Chicken"].Part0 = self.LuaCharacter["Left Arm"]
			Items["Fried Chicken"]["Fried Chicken"].Part1 = Items["Fried Chicken"]
			Items["Fried Chicken"]["Fried Chicken"].Parent = self.LuaCharacter["Left Arm"]
			
			Items.Pogo.Pogo.Part0 = self.LuaCharacter["Right Leg"]
			Items.Pogo.Pogo.Part1 = Items.Pogo
			Items.Pogo.Pogo.Parent = self.LuaCharacter["Right Leg"]
			
			Items.Skateboard.Skateboard.Part0 = self.LuaCharacter["Right Leg"]
			Items.Skateboard.Skateboard.Part1 = Items.Skateboard
			Items.Skateboard.Skateboard.Parent = self.LuaCharacter["Right Leg"]
		end,
	}),]]
	
	["Eye Of Rah"] = {
		CustomFunction = require( script["Eye Of Rah"] )
	},
	
	["Shadowbox"] = {
		Collab = {
			ObjectText = "Shadowbox",
			ActionText = "Challenge",

			Limit = 1,

			Function = function(self, TargetCombat, MainJob, JoinedJob, UserAnimation : AnimationTrack)
				local function PlayAnimation(LuaPlayer, Role : String, Direction : String)
					local Animation : AnimationTrack = LuaPlayer.Character.Animator:LoadAnimation(replicatedStorage.animations.Emotes.Shadowbox[Role][Direction])
					Animation:Play()
					
					return Animation
				end
				
				local function GetChoices(LeaderLuaPlayer, FollowerLuaPlayer, Directions: Table)
					local Bindable = EventService.new()

					LeaderLuaPlayer.Replication:FireReliableVFXToSelf("Emotes/Shadowbox", "ChooseDirection", Directions, true)
					FollowerLuaPlayer.Replication:FireReliableVFXToSelf("Emotes/Shadowbox", "ChooseDirection", Directions, false)

					local LeaderChoice = nil
					local FollowerChoice = nil

					if LeaderLuaPlayer.IsNPC then
						LeaderChoice = Directions[math.random(1, #Directions)]
					end
					
					if FollowerLuaPlayer.IsNPC then
						FollowerChoice = Directions[math.random(1, #Directions)]
					end

					local ReceiveConnection
					ReceiveConnection = JoinedJob:Task(connect(network.chooseDirection, function(ChosenDirection, Player)
						if not LeaderLuaPlayer.IsNPC and Player == LeaderLuaPlayer.Player then
							LeaderChoice = ChosenDirection
							
						elseif not FollowerLuaPlayer.IsNPC and Player == FollowerLuaPlayer.Player then
							if ChosenDirection == "Up" or ChosenDirection == "Down" then
								FollowerChoice = ChosenDirection
								
							elseif ChosenDirection == "Right" then -- Flip directions (since the players are facing each other)
								FollowerChoice = "Left"
								
							elseif ChosenDirection == "Left" then
								FollowerChoice = "Right"
							end
						end

						if LeaderChoice and FollowerChoice then
							ReceiveConnection:Disconnect()
							Bindable:Fire()
						end
					end))

					-- Yield until both choices are received
					Bindable:Wait()
					Bindable:Destroy()
					
					return { Leader = LeaderChoice, Follower = FollowerChoice }
				end


				
				
				-- Face Users
				JoinedJob:Task(TargetCombat.LuaCharacter:StopAutoRotate())

				self.LuaCharacter.LuaPlayer.Replication:FireReliableVFX("Emotes/FacePart", "Face", self.LuaCharacter.Model, TargetCombat.LuaCharacter.RootPart, 0.4)
				TargetCombat.LuaCharacter.LuaPlayer.Replication:FireReliableVFX("Emotes/FacePart", "Face", TargetCombat.LuaCharacter.Model, self.LuaCharacter.RootPart, 0.4)
				
				self.LuaPlayer.Replication:FireReliableVFXToSelf("Emotes/Shadowbox", "Setup", self.LuaCharacter.Model)
				TargetCombat.LuaCharacter.LuaPlayer.Replication:FireReliableVFXToSelf("Emotes/Shadowbox", "Setup", self.LuaCharacter.Model)
				
				TargetCombat:DivideSpeed(10)

				local DuoAnim : AnimationTrack = TargetCombat.LuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Emotes.Shadowbox.Idle)
				-- DuoAnim.Priority = Enum.AnimationPriority.Idle
				DuoAnim:Play()
				
				-- the reason for the hihlights not working sometimes is cuz we start reaching the highlight limit cuz we keep leaving them enabled in replicated storage and theres a limit of 31
				-- that limit is so dumb
				-------------------------[ Main ]-------------------------
				
				
				JoinedJob:Task(function()
					DuoAnim:Stop()
					TargetCombat:TimesSpeed(10)
				end)
				
				local function StartMatch(LeaderLuaPlayer, FollowerLuaPlayer)
					local AvailableDirections = {"Up", "Down", "Left", "Right"}
					local SequenceHistory = {}

					-- Start
					for Round = 1, 3 do
						if #AvailableDirections <= 1 then
							break
						end

						-- Get choices from both players
						local Choices = GetChoices(LeaderLuaPlayer, FollowerLuaPlayer, AvailableDirections)
						local LeaderChoice = Choices.Leader
						local FollowerChoice = Choices.Follower

						-- Play the entire sequence (all previous choices + current choice)
						for _, Direction in ipairs(SequenceHistory) do
							local anim1 = PlayAnimation(LeaderLuaPlayer, "Leader", Direction)
							local anim2 = PlayAnimation(FollowerLuaPlayer, "Follower", Direction)

							task.wait(0.901)
							
							--anim1:Stop()
							--anim2:Stop()
						end
						
						local anim3 = PlayAnimation(LeaderLuaPlayer, "Leader", LeaderChoice)
						local anim4 = PlayAnimation(FollowerLuaPlayer, "Follower", FollowerChoice)
						
						-- Only add to sequence if they match
						table.insert(SequenceHistory, LeaderChoice)
						
						-- Check if both players chose the same direction FIRST
						if LeaderChoice == FollowerChoice then
							-- Remove the chosen direction from available directions
							table.remove(AvailableDirections, table.find(AvailableDirections, LeaderChoice))

							-- Show success effect
							self.LuaPlayer.Replication:FireReliableVFX("Global/Highlight", "HighlightEffect", LeaderLuaPlayer.Character.Model, Color3.new(0.133333, 1, 0), 0.4)
							
							task.wait(0.6)
							--anim3:Stop()
						else
							-- Players chose different directions - game over
							self.LuaPlayer.Replication:FireReliableVFX("Global/Highlight", "HighlightEffect", LeaderLuaPlayer.Character.Model, Color3.new(1, 0, 0.0156863), 0.4)
							task.wait(0.6)
							--anim4:Stop()
							task.wait(0.2)
							StartMatch(FollowerLuaPlayer, LeaderLuaPlayer) -- Flip Leader & Follower
							return
						end
					end

					self:Afflict(FollowerLuaPlayer, {
						ExcludeAttempts = true,
						Ragdoll = 2.5,
						Velocity = {self:CalculateUnitDifference(FollowerLuaPlayer) * 40 + Vector3.yAxis * 40, 0.1},
						Damage = 0
					})
					
					JoinedJob:Destroy()
					MainJob:Destroy()
				end
				
				StartMatch(self.LuaPlayer, TargetCombat.LuaCharacter.LuaPlayer)
				----------------------------------------------------------

				--JoinedJob:Task(UserAnim.Ended:Connect(function()
				--	JoinedJob:Destroy()
				--	MainJob:Destroy()
				--end))
			end,
		},
		
		

		CustomFunction = function(self, Job)
			self:DivideSpeed(10)
			Job:Task(self.LuaCharacter:StopAutoRotate())

			Job:Task(function()
				self:TimesSpeed(10)
			end)
		end,
	},
}
