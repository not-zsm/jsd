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

local Type = require( replicatedStorage.packages.Type )

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
	["Solo"] = {
		CustomFunction = function(self, Job)
			self:DivideSpeed(10)

			Job:Task(function()
				self:TimesSpeed(10)
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

				local GuyAnim : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(replicatedStorage.ass.emotes["Stars"].Guy)
				local GirlAnim : AnimationTrack = JoinedCombat.LuaCharacter.Animator:LoadAnimation(replicatedStorage.ass.emotes["Stars"].Girl)

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
			
			local Idle : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(replicatedStorage.ass.emotes.Erased.Idle)
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
	
	["Write"] = {
		CustomFunction = function(self, Job, Animation : AnimationTrack)
			self:DivideSpeed(10)

			local Pen = Job:Task(script.Write.pe:Clone())
			Pen.PENN.Weld.Part0 = self.LuaCharacter.RightArm
			Pen.Parent = self.LuaCharacter.Model
			
			local Paper = Job:Task(script.Write.Part:Clone())
			Paper.Weld.Part0 = self.LuaCharacter.LeftArm
			Paper.Parent = self.LuaCharacter.Model
			
			local LoopAnim : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(replicatedStorage.ass.emotes.Write.Loop)
			local FinishAnim : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(replicatedStorage.ass.emotes.Write.Done)
			
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
			
			local LoopTrack : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(replicatedStorage.ass.emotes["PUT IT ONG"].Idle)

			Job:Task(Animation:GetMarkerReachedSignal("End"):Once(function()
				LoopTrack:Play(0.15)
			end))

			Job:Task(function()
				LoopTrack:Stop(0)
			end)
		end,
	}),
	
	["Eye Of Rah"] = {
		CustomFunction = require( script["Eye Of Rah"] )
	},
}
