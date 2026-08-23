local replicatedStorage = game:GetService("ReplicatedStorage")

local network = require( replicatedStorage.modules.network )
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

----------------------------------------------------------------------------------



local Shared = replicatedStorage.modules.shared
local SharedUtilities = Shared.Utilities

local Animations = replicatedStorage.Animations

----------------------------------------------------------------------------------

local MovementHandler = {}
MovementHandler.__index = MovementHandler

local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )
local EventService = require( replicatedStorage.modules.shared.Utilities.EventService )
local InfoCharacter = require( replicatedStorage.modules.client.character.InfoCharacter )
local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )
local Job = require( replicatedStorage.modules.shared.Utilities.Job )

local Chara_Voicelines = replicatedStorage.modules.client.replication.VFX.Chara.Voicelines

local MovementNames = {"Walk", "WalkBack", "WalkLeft", "WalkRight", "Run"};
local WalkNames = {"Walk", "WalkBack", "WalkLeft", "WalkRight"};

----------------------------------------------------------------------------------

function MovementHandler:OnHumanoidLoaded()
	self:ClearAllAnimations();
	self:LoadAnimations(Animations.Movement);
	
	--for _, Item : (Animation | Folder) in ipairs(Animations.Movement:GetChildren()) do
	--	if Item:IsA("Folder") then
	--		self.Animations[Item.Name] = {}

	--		for _, FolderItem : Animation in ipairs(Item:GetChildren()) do
	--			if FolderItem:IsA("Animation") then
	--				self.Animations[Item.Name][FolderItem.Name] = self.LuaCharacter.Animator:LoadAnimation(FolderItem)

	--				local Animation : AnimationTrack = self.Animations[Item.Name][FolderItem.Name]

	--				if Animation.Animation:GetAttribute("Priority") ~= nil then
	--					Animation.Priority = Enum.AnimationPriority[Animation.Animation:GetAttribute("Priority")]
	--				end
	--			end
	--		end

	--	elseif Item:IsA("Animation") then
	--		self.Animations[Item.Name] = self.LuaCharacter.Animator:LoadAnimation(Item)

	--		local Animation : AnimationTrack = self.Animations[Item.Name]

	--		if Animation.Animation:GetAttribute("Priority") ~= nil then
	--			Animation.Priority = Enum.AnimationPriority[Animation.Animation:GetAttribute("Priority")]
	--		end
	--	end
	--end
	
	self.Running = false
	self.Jumping = false
	self.Moving = false

	self:Unrun()

	--self:SetAsCurrentCharacter(self:UpdateAnimationDirectory());

	self:PlayIdleAnimation()
	self:SetUpFootstepMarker()
	self:SetRunSpeed(self.RunSpeed)

	self.LuaCharacter.Humanoid.StateChanged:Connect(function(OldState, NewState)
		--if NewState == Enum.HumanoidStateType.Seated then
		--	self:Sit(true)

		--elseif OldState == Enum.HumanoidStateType.Seated then
		--	self:Sit(false)
		--end

		--if (NewState == Enum.HumanoidStateType.Freefall or NewState == Enum.HumanoidStateType.Jumping) and not self.Jumping then
		--	self:Jump(true)

		if (NewState == Enum.HumanoidStateType.Landed or NewState == Enum.HumanoidStateType.Physics) and self.Jumping then
			self:Jump(false)
		end
	end)

	self.LuaCharacter.Humanoid.Seated:Connect(function(Value : boolean)
		self:Sit(Value)
	end)

	self.LuaCharacter.Humanoid.Running:Connect(function(Speed : number)
		self.HumanoidSpeed = Speed
	end)

	self.LuaCharacter.Humanoid.Jumping:Connect(function(Active : boolean)
		if Active then
			self:Jump(true)
		end
	end)

	local UnflungCFrame = CFrame.identity

	local UnflingTime = os.clock()
	local DetectFlingTime = os.clock()

	local PreviousPosition = self.LuaCharacter.RootPart.Position

	self.LuaCharacter.HumanoidJob:Task(RunService.PostSimulation:Connect(function()
		if not self.LuaCharacter.HumanoidAlive then return end

		local Character : Model = self.LuaCharacter.Model
		local RootPart : BasePart = self.LuaCharacter.RootPart
		local Velocity : Vector3 = RootPart.AssemblyLinearVelocity

		if (os.clock() - UnflingTime > 2) then
			UnflungCFrame = RootPart.CFrame
			--print("unfling snapshot")
			UnflingTime = os.clock()
		end

		local Magnitude = (PreviousPosition - RootPart.Position).Magnitude

		if Magnitude > 175
			and Velocity.Magnitude > 50
			and not self.WasFlung 
			and not self.LuaPlayer.Player:GetAttribute("AntiFling_Immunity") 
			and not Character:HasTag("Flying") 
			and not Character:GetAttribute("TransitionDomain") 
		then
			self.WasFlung = true
			
			StarterGui:SetCore("SendNotification", {
				Title = "Anti-Fling",
				Text = "You were flung. Teleporting back to last snapshot.",
				Duration = 2,
			})

			RootPart.Anchored = true
			RootPart.AssemblyLinearVelocity = Vector3.zero
			RootPart.AssemblyAngularVelocity = Vector3.zero
			Character:PivotTo(UnflungCFrame)
			RootPart.Anchored = false

			self.WasFlung = false
		end

		PreviousPosition = RootPart.Position

		--if (os.clock() - DetectFlingTime > 0.25) then

		--	--print("detect for fling")

		--	--local Magnitude = (PreviousPosition - RootPart.Position).Magnitude
		--	--if Magnitude > 100 and not self.WasFlung and not self.LuaPlayer.Player:GetAttribute("AntiFling_Immunity") then

		--	if Velocity.Magnitude >= 1000 and not self.WasFlung and not self.LuaPlayer.Player:GetAttribute("AntiFling_Immunity") then
		--		self.WasFlung = true

		--		--print("was flung, teleport them back to unfling snapshot")

		--		StarterGui:SetCore("SendNotification", {
		--			Title = "Anti-Fling",
		--			Text = "You were flung. Teleporting back to last snapshot.",
		--			Duration = 2,
		--		})

		--		RootPart.Anchored = true
		--		RootPart.AssemblyLinearVelocity = Vector3.zero
		--		RootPart.AssemblyAngularVelocity = Vector3.zero
		--		Character:PivotTo(UnflungCFrame)
		--		RootPart.Anchored = false

		--		self.WasFlung = false
		--	end

		--	PreviousPosition = RootPart.Position
		--	DetectFlingTime = os.clock()
		--end

	end))

	local function AddHandler(Name : string)
		local HandlersFolder = script:WaitForChild("Handlers")
		local Handler = HandlersFolder:FindFirstChild(Name)

		if Handler and Handler:IsA("ModuleScript") then
			local Function = require(Handler)
			local CleanUp = Function(self)

			self.LuaCharacter.HumanoidJob:Task(CleanUp)
		end
	end
	
	if self.Combat.CurrentCharacter then
		AddHandler(self.Combat.CurrentCharacter)
	else
		self.Combat.CurrentCharacterChanged:Once(AddHandler)
	end
end;

function MovementHandler:OnCharacterReady(Info : {})
	if self.HasCharacterLoaded then return end;
	self.HasCharacterLoaded = true;

	if (Info.StandName ~= nil) then
		self:InitStand();
	end;
end;

function MovementHandler:LoadAnimations(Folder: Instance)
	local function AddAnimation(CurrentTable, Item: Instance, Track : AnimationTrack)
		local Priority = Track.Animation:GetAttribute("Priority")
		CurrentTable[Item.Name] = Track

		if Priority then
			Track.Priority = Enum.AnimationPriority[Priority]
		end
	end

	local function Iterate(CurrentTable, CurrentFolder)
		for Index, Item : (Animation | Folder) in ipairs(CurrentFolder:GetChildren()) do
			if Item:IsA("Animation") then
				AddAnimation(CurrentTable, Item, self.LuaCharacter.Animator:LoadAnimation(Item))

			elseif Item:IsA("Folder") then
				CurrentTable[Item.Name] = {}
				Iterate(CurrentTable[Item.Name], Item)
			end
		end
	end

	Iterate(self.Animations, Folder);
end;

function MovementHandler:StopAllAnimations()
	local function IterateRemove(Animation : (Animation | {}))
		if typeof(Animation) == "table" then
			for _, Value in Animation do
				IterateRemove(Value);
			end;
		else
			Animation:Stop();
			Animation:Destroy();
		end;
	end;

	IterateRemove(self.Animations);
end

function MovementHandler:ClearAllAnimations(): ()
	--local function IterateRemove(Animation)
	--	if typeof(Animation) == "table" then
	--		for _, Value in Animation do
	--			IterateRemove(Value);
	--		end;
	--	else
	--		Animation:Stop();
	--		Animation:Destroy();
	--	end;
	--end;

	--IterateRemove(self.Animations);

	self:StopAllAnimations()
	table.clear(self.Animations);
end;

function MovementHandler:Sit(Value : boolean)
	if Value then
		self.Combat.EnabledStack:Add()
		self.Animations.Sit:Play()
		self:StopIdleAnimation()
	else
		self.Animations.Sit:Stop()
		self.Combat.EnabledStack:Subtract()
	end
end

--local Observer = require( replicatedStorage.modules.shared.Utilities.Observer )

function MovementHandler:InitStand()
	local function Setup(Stand : Model)
		self.Stand = Stand

		self.StandHumanoid = self.Stand:WaitForChild("Humanoid", 2)
		self.StandAnimator = self.StandHumanoid:WaitForChild("Animator", 2)

		self.StandAnimations = {}

		local CurrentCharacter = self.Combat:GetCurrentCharacter();
		local CharacterInfo = InfoCharacter.GetCharacterInfo(CurrentCharacter);

		assert(CharacterInfo, "No character info");

		for _, Item : (Animation | Folder) in ipairs(replicatedStorage.Animations.Attacks[CurrentCharacter][CharacterInfo.StandName]:GetChildren()) do
			if Item:IsA("Animation") then
				local Track = self.StandAnimator:LoadAnimation(Item)

				if Item:GetAttribute("Priority") then
					Track.Priority = Enum.AnimationPriority[Item:GetAttribute("Priority")]
				end

				self.StandAnimations[Item.Name] = Track
			end
		end

		if self.StandAnimations.Idle then
			self.StandAnimations.Idle:Play(0)
		end
	end

	local Stand : Model? = self.LuaCharacter.Model:FindFirstChild("Stand")

	if Stand then
		Setup(Stand)
	else
		self.LuaCharacter.Model.ChildAdded:Connect(function(Child : Model?)
			if Child:IsA("Model") and Child.Name == "Stand" then
				Setup(Child)
			end
		end)
	end

	--local CleanObserve; CleanObserve = Observer("StarPlatinum", function(Stand : Model)
	--	self.Stand = Stand

	--	self.StandHumanoid = self.Stand:WaitForChild("Humanoid", 2)
	--	self.StandAnimator = self.StandHumanoid:WaitForChild("Animator", 2)

	--	self.StandAnimations = {}

	--	RunService.PostSimulation:Wait()

	--	for _, Item : (Animation | Folder) in ipairs(replicatedStorage.Animations.Attacks["Stardust Crusader"]["Star Platinum"]:GetChildren()) do
	--		if Item:IsA("Animation") then
	--			local Track = self.StandAnimator:LoadAnimation(Item)

	--			if Item:GetAttribute("Priority") then
	--				Track.Priority = Enum.AnimationPriority[Item:GetAttribute("Priority")]
	--			end

	--			self.StandAnimations[Item.Name] = Track
	--		end
	--	end

	--	RunService.PostSimulation:Wait()

	--	if self.StandAnimations.Idle then
	--		self.StandAnimations.Idle:Play(0)
	--	end

	--	CleanObserve()
	--end)

	--local Stand : Model? = self.LuaCharacter.Model:WaitForChild("Stand", 3)

	--if Stand then
	--	self.Stand = Stand

	--	self.StandHumanoid = self.Stand:WaitForChild("Humanoid", 2)
	--	self.StandAnimator = self.StandHumanoid:WaitForChild("Animator", 2)

	--	self.StandAnimations = {}

	--	RunService.PostSimulation:Wait()

	--	for _, Item : (Animation | Folder) in ipairs(replicatedStorage.Animations.Attacks["Stardust Crusader"]["Star Platinum"]:GetChildren()) do
	--		if Item:IsA("Animation") then
	--			local Track = self.StandAnimator:LoadAnimation(Item)

	--			if Item:GetAttribute("Priority") then
	--				Track.Priority = Enum.AnimationPriority[Item:GetAttribute("Priority")]
	--			end

	--			self.StandAnimations[Item.Name] = Track
	--		end
	--	end

	--	RunService.PostSimulation:Wait()

	--	if self.StandAnimations.Idle then
	--		self.StandAnimations.Idle:Play(0)
	--	end
	--end
end

function MovementHandler:Jump(Value : boolean)
	if Value ~= self.Jumping then

		if Value then
			self:StopIdleAnimation()
			self.Animations.Jump:Play()
			self:SetRunSpeed(0.5)
		else
			self:PlayIdleAnimation()
			self.Animations.Jump:Stop()
			self:SetRunSpeed(self.RunSpeed)
		end

		self.Jumping = Value
	end
end

function MovementHandler:StartMoving()
	if self.Moving then return end

	self:StopIdleAnimation()

	local UltAnimations = self:GetUltimateAnimations()
	local InUlt = (UltAnimations and self.Combat:IsInUltimate())
	
	local DefaultWalk : AnimationTrack = self:GetAnimation("Walk")
	local DefaultWalkBack : AnimationTrack = self:GetAnimation("WalkBack")
	local DefaultWalkLeft : AnimationTrack = self:GetAnimation("WalkLeft")
	local DefaultWalkRight : AnimationTrack = self:GetAnimation("WalkRight")
	
	local Walk : AnimationTrack = InUlt and (UltAnimations.Walk or DefaultWalk) or DefaultWalk
	local WalkBack : AnimationTrack = InUlt and (UltAnimations.WalkBack or DefaultWalkBack) or DefaultWalkBack
	local WalkLeft : AnimationTrack = InUlt and (UltAnimations.WalkLeft or DefaultWalkLeft) or DefaultWalkLeft
	local WalkRight : AnimationTrack = InUlt and (UltAnimations.WalkRight or DefaultWalkRight) or DefaultWalkRight

	if not Walk.IsPlaying then Walk:Play(0.4) end
	if not WalkBack.IsPlaying then WalkBack:Play(0.4) end
	if not WalkLeft.IsPlaying then WalkLeft:Play(0.4) end
	if not WalkRight.IsPlaying then WalkRight:Play(0.4) end

	self.Moving = true
end

function MovementHandler:StopMoving()
	if not self.Moving then return end

	self.Moving = false

	local Walk : AnimationTrack = self:GetAnimation("Walk")
	local WalkBack : AnimationTrack = self:GetAnimation("WalkBack")
	local WalkLeft : AnimationTrack = self:GetAnimation("WalkLeft")
	local WalkRight : AnimationTrack = self:GetAnimation("WalkRight")

	local UltAnimations = self:GetUltimateAnimations()
	
	if UltAnimations then
		if UltAnimations.Walk and UltAnimations.Walk.IsPlaying then Walk:Stop() end
		if UltAnimations.WalkBack and UltAnimations.WalkBack.IsPlaying then WalkBack:Stop() end
		if UltAnimations.WalkLeft and UltAnimations.WalkLeft.IsPlaying then WalkLeft:Stop() end
		if UltAnimations.WalkRight and UltAnimations.WalkRight.IsPlaying then WalkRight:Stop() end
	end
	
	if Walk.IsPlaying then Walk:Stop() end
	if WalkBack.IsPlaying then WalkBack:Stop() end
	if WalkLeft.IsPlaying then WalkLeft:Stop() end
	if WalkRight.IsPlaying then WalkRight:Stop() end

	if not self.Jumping and not self.Emoting and not self.LuaCharacter:IsFlyingOrSitting() then
		self:PlayIdleAnimation()
	end
end

function MovementHandler:GetAnimationDirectory()
	return self.Animations and (self.Animations[self.Directory] or self.Animations.Default)
end

function MovementHandler:GetAnimation(Name : string)
	local Animations = self:GetAnimationDirectory()

	if Animations and Animations[Name] then
		return Animations[Name]
	else
		if self.Animations and self.Animations[Name] then
			return self.Animations[Name]
		end
	end

	return nil
end

--function MovementHandler:GetAnimations(Name : string)
--	local Animations = self:GetAnimationDirectory()

--	if Animations then
--		return Animations
--	else
--		if self.Animations then
--			return self.Animations
--		end
--	end

--	return nil
--end

function MovementHandler:GetUltimateAnimations()
	local Animations = self:GetAnimationDirectory()

	if Animations and Animations.Ultimate then
		return Animations.Ultimate
	end

	return nil
end

function MovementHandler:PlayIdleAnimation(Fade : number, Weight : number, Speed : number)
	if self.Moving then return end

	local UltAnimations = self:GetUltimateAnimations()

	if self.Combat:IsInUltimate() and UltAnimations then
		local Idle : AnimationTrack = UltAnimations.Idle

		if Idle then
			if Speed then
				Idle:Play(Fade, Weight, Speed + (Idle.Animation:GetAttribute("Speed") or 0))
			else
				Idle:Play(Fade, Weight, Idle.Animation:GetAttribute("Speed") or 1)
			end

			local CurrentCharacter = self.Combat:GetCurrentCharacter()

			if CurrentCharacter == "Chara" then
				self.IdleJob:Task(Idle:GetMarkerReachedSignal("laugh"):Connect(function()
					if self.Combat:GetState("Attacking") or self.Combat:GetState("Stunned") or self.Combat:GetState("Ragdolled") then
						return
					end

					local SFX = EffectUtility.AddSFX(Chara_Voicelines.Laughs.Idle_Ult, self.LuaCharacter.Head)
					task.delay(4, SFX.Destroy, SFX)
				end))
			end
		end
	else
		local Idle : AnimationTrack = self:GetAnimation("Idle")

		if Idle and not Idle.IsPlaying then
			if Speed then
				Idle:Play(Fade, Weight, Speed + (Idle.Animation:GetAttribute("Speed") or 0))
			else
				Idle:Play(Fade, Weight, Idle.Animation:GetAttribute("Speed") or 1)
			end
		end
	end
end

function MovementHandler:StopIdleAnimation(...)
	local UltAnimations = self:GetUltimateAnimations()

	if UltAnimations then
		UltAnimations.Idle:Stop(...)
	end

	local Idle : AnimationTrack = self:GetAnimation("Idle")
	
	if Idle and Idle.IsPlaying then
		Idle:Stop(...)
	end
	
	self.IdleJob:Clean()
end

function MovementHandler:SetUpFootstepMarker()
	if self.FootstepMarker then
		self.FootstepMarker:Disconnect()
		self.FootstepMarker = nil
	end

	--if self.Animations[self.Directory].LowHPRun then
	--	self.FootstepMarker = self.LuaCharacter.HumanoidJob:Task(self.Animations[self.Directory].LowHPRun:GetMarkerReachedSignal("footstep"):Connect(function(Type : string)
	--		if self.LuaCharacter.Humanoid.WalkSpeed >= 5 and self.LuaCharacter.Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
	--			local Foot = (Type == "left" and self.LuaCharacter.LeftLeg or self.LuaCharacter.RightLeg)

	--			if workspace:GetAttribute("Rain") and not self.LuaPlayer.Player:GetAttribute("UnderRoof") then

	--				local Raycast = workspace:Raycast(Foot.Position, Vector3.yAxis * -5, Utility.VisualParams)

	--				if (Raycast ~= nil) then
	--					EffectUtility.EmitEffects(script.Splash, workspace.Terrain, Raycast.Position)
	--				end

	--				EffectUtility.EmitEffects(script.WetFootstep, Foot)

	--			elseif self.LuaCharacter.Humanoid.FloorMaterial == Enum.Material.Grass then
	--				EffectUtility.EmitEffects(script.GrassFootstep, Foot)

	--			else
	--				EffectUtility.EmitEffects(script.Footstep, Foot)
	--			end
	--		end
	--	end))
	--end

	local Run : AnimationTrack = self:GetAnimation("Run")

	if Run then
		self.FootstepMarker = self.LuaCharacter.HumanoidJob:Task(Run:GetMarkerReachedSignal("footstep"):Connect(function(Type : string)
			if self.LuaCharacter.Humanoid.WalkSpeed >= 5 and self.LuaCharacter.Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
				local Foot = (Type == "left" and self.LuaCharacter.LeftLeg or self.LuaCharacter.RightLeg)

				if workspace:GetAttribute("Rain") and not self.LuaPlayer.Player:GetAttribute("UnderRoof") then

					local Raycast = workspace:Raycast(Foot.Position, Vector3.yAxis * -5, Utility.VisualParams)

					if (Raycast ~= nil) then
						EffectUtility.EmitEffects(script.Splash, workspace.Terrain, Raycast.Position)
					end

					EffectUtility.EmitEffects(script.WetFootstep, Foot)

				elseif self.LuaCharacter.Humanoid.FloorMaterial == Enum.Material.Grass then
					EffectUtility.EmitEffects(script.GrassFootstep, Foot)

				else
					EffectUtility.EmitEffects(script.Footstep, Foot)
				end
			end
		end))
	end
end


function MovementHandler:SetRunSpeed(Value : number)
	local Animation

	local LowHPRun : AnimationTrack = self:GetAnimation("LowHPRun")
	
	local UltAnimations = self:GetUltimateAnimations()
	local InUlt = (UltAnimations and self.Combat:IsInUltimate())
	
	local DefaultRun : AnimationTrack = self:GetAnimation("Run")
	local Run : AnimationTrack = InUlt and (UltAnimations.Run or DefaultRun) or DefaultRun
	
	--local Run : AnimationTrack = self:GetAnimation("Run")

	if LowHPRun and self.LuaCharacter.Humanoid.Health <= 25 then
		Animation = LowHPRun
	else
		Animation = Run
	end

	if Animation and Animation.Animation and Animation.Animation:GetAttribute("SpeedMultiplier") then
		self.CurrentRunSpeed = Value * Animation.Animation:GetAttribute("SpeedMultiplier")
	else
		self.CurrentRunSpeed = Value
	end

	if Animation and Animation.Speed ~= self.CurrentRunSpeed then
		Animation:AdjustSpeed(self.CurrentRunSpeed)
	end
end


function MovementHandler:_Init()
	self:UpdateAnimationDirectory()

	self.Combat:GetStateChanged("Run"):Connect(function()
		if not self.Combat:GetState("Run") then
			self:Unrun()
		end
	end)

	self.Combat:GetStateChanged("M1ing"):Connect(function()
		if self.CurrentCharacterInfo and not self.CurrentCharacterInfo.StandName then -- hard coded -- fixed 👍
			if self.Combat:GetState("M1ing") then
				self:StopIdleAnimation(0.25)
			else
				self:PlayIdleAnimation(0.25)
			end
		end
	end)

	self.Combat:GetStateChanged("Emoting"):Connect(function()
		self.Emoting = self.Combat:GetState("Emoting")

		if self.Emoting then
			self:StopIdleAnimation()

		elseif not self.Emoting and not self.Moving then
			self:PlayIdleAnimation()
		end
	end)

	self.Combat.CurrentCharacterChanged:Connect(function(Name : string)
		self.HasCharacterLoaded = false;
		
		local CharacterInfo = InfoCharacter.GetCharacterInfo(Name);
		
		if CharacterInfo then
			self:OnCharacterReady(CharacterInfo);
		end;
	end);
	
	RunService:BindToRenderStep("Running", Enum.RenderPriority.Camera.Value + 3, function()
		if not self.LuaCharacter.HumanoidAlive then return end

		self.HumanoidDirection = self.LuaCharacter.RootPart.CFrame:VectorToObjectSpace(self.LuaCharacter.Humanoid.MoveDirection)

		--local Walk : AnimationTrack = self:GetAnimation("Walk")
		--local WalkBack : AnimationTrack = self:GetAnimation("WalkBack")
		--local WalkLeft : AnimationTrack = self:GetAnimation("WalkLeft")
		--local WalkRight : AnimationTrack = self:GetAnimation("WalkRight")
		
		local UltAnimations = self:GetUltimateAnimations()
		local InUlt = (UltAnimations and self.Combat:IsInUltimate())

		local DefaultWalk : AnimationTrack = self:GetAnimation("Walk")
		local DefaultWalkBack : AnimationTrack = self:GetAnimation("WalkBack")
		local DefaultWalkLeft : AnimationTrack = self:GetAnimation("WalkLeft")
		local DefaultWalkRight : AnimationTrack = self:GetAnimation("WalkRight")
		local DefaultRun : AnimationTrack = self:GetAnimation("Run")

		local Walk : AnimationTrack = InUlt and (UltAnimations.Walk or DefaultWalk) or DefaultWalk
		local WalkBack : AnimationTrack = InUlt and (UltAnimations.WalkBack or DefaultWalkBack) or DefaultWalkBack
		local WalkLeft : AnimationTrack = InUlt and (UltAnimations.WalkLeft or DefaultWalkLeft) or DefaultWalkLeft
		local WalkRight : AnimationTrack = InUlt and (UltAnimations.WalkRight or DefaultWalkRight) or DefaultWalkRight
		local Run : AnimationTrack = InUlt and (UltAnimations.Run or DefaultRun) or DefaultRun

		-- 🥀
		if not InUlt and UltAnimations then
			for _, Name in MovementNames do
				local Animation: AnimationTrack = UltAnimations[Name];
				
				if Animation and Animation.IsPlaying then
					Animation:Stop();
				end;
			end;
		end;

		if Walk then
			Walk:AdjustWeight(math.clamp(-self.HumanoidDirection.Z, 0.001, 1))
		end

		if WalkBack then
			WalkBack:AdjustWeight(math.clamp(self.HumanoidDirection.Z, 0.001, 1))
		end

		if WalkLeft then
			WalkLeft:AdjustWeight(math.clamp(-self.HumanoidDirection.X, 0.001, 1))
		end

		if WalkRight then
			WalkRight:AdjustWeight(math.clamp(self.HumanoidDirection.X, 0.001, 1))
		end

		local CurrentSpeed : number = self.Jumping and 1 or (self.HumanoidSpeed / 12)

		if Walk and Walk.Speed ~= CurrentSpeed then
			Walk:AdjustSpeed(CurrentSpeed)

			if WalkLeft then
				WalkLeft:AdjustSpeed(CurrentSpeed)
			end

			if WalkRight then
				WalkRight:AdjustSpeed(CurrentSpeed)
			end
		end

		if WalkBack and WalkBack.Speed ~= -CurrentSpeed then
			WalkBack:AdjustSpeed(-CurrentSpeed)
		end

		local SpeedGoal = self.Jumping and self.CurrentRunSpeed or self.CurrentRunSpeed * (self.HumanoidSpeed / 28)

		if Run and Run.Speed ~= SpeedGoal then
			Run:AdjustSpeed(SpeedGoal)
		end

		if not self.LuaCharacter:IsFlyingOrSitting() and self.HumanoidSpeed > 5 and not self.Emoting then

			if not self.Jumping then
				local MoveVector : Vector3 = self.LuaCharacter:GetMoveVector()
				local Magnitude = MoveVector.Magnitude

				if (not self.Moving and Magnitude > 0.1) then
					self:StartMoving()

				elseif (Magnitude < 0.1 and self.Moving) then
					self:StopMoving()
				end
			end

			local Moving = self.LuaCharacter:CheckIfMovingForward()

			if (Moving and not self.Running) then
				self:Run()

			elseif (not Moving and self.Running) then
				self:Unrun()
			end
		else
			self:Unrun()
			self:StopMoving()
		end
	end)

	self.LuaPlayer.Replication.Attributes:GetAttributeChangedSignal("Ultimate"):Connect(function()
		local InUltimate = self.Combat:IsInUltimate()
		local UltAnimations = self:GetUltimateAnimations()

		if UltAnimations then
			
			if InUltimate then
				local Idle : AnimationTrack = self:GetAnimation("Idle")

				if Idle and Idle.IsPlaying then
					Idle:Stop(0)
				end
			else
				if UltAnimations.Idle and UltAnimations.Idle.IsPlaying then
					UltAnimations.Idle:Stop(0)
				end
				
				if self.Moving then
					for _, Name in WalkNames do
						local UltAnimation: AnimationTrack = UltAnimations[Name];

						if UltAnimation and UltAnimation.IsPlaying then
							UltAnimation:Stop();
						end;
						
						local DefaultAnimation: AnimationTrack = self:GetAnimation(Name);
						
						if DefaultAnimation and not DefaultAnimation.IsPlaying then
							DefaultAnimation:Play(0)
						end
					end;
				end
			end
			
			self:PlayIdleAnimation(0)
			self:SetRunSpeed(self.RunSpeed)
			
			if not InUltimate then
				local Run : AnimationTrack? = self:GetAnimation("Run")

				if Run and not Run.IsPlaying and self.Running then
					Run:Play(0.1, 1, self.CurrentRunSpeed)
				end
			end
		end
	end)

	local function Update()
		self:StopAllAnimations()
		self:UpdateAnimationDirectory()
		self:SetUpFootstepMarker()
		self:PlayIdleAnimation()
		self:SetRunSpeed(self.RunSpeed)

		local Run : AnimationTrack? = self:GetAnimation("Run")

		if Run and not Run.IsPlaying and self.Running then
			Run:Play(0.1, 1, self.CurrentRunSpeed)
		end
	end

	network.itemAnimations.listen(function(Name : string)
		self.CurrentItem = Name
		Update()
	end)

	if self.Combat.CurrentCharacter then
		Update()
	end
	
	self.Combat.CurrentCharacterChanged:Connect(Update)

	--self.LuaPlayer.Replication.Attributes:GetAttributeChangedSignal("CurrentCharacter"):Connect(function()
	--for _, Item in self.Animations do
	--	if typeof(Item) == "table" then
	--		for _, Animation in Item do
	--			Animation:Stop()
	--		end
	--	end
	--end

	--local Idle : AnimationTrack = self:GetAnimation("Idle")

	--if Idle and Idle.IsPlaying then
	--	Idle:Stop()
	--end

	--self:UpdateAnimationDirectory()
	--self:SetUpFootstepMarker()
	--self:PlayIdleAnimation()
	--self:SetRunSpeed(self.RunSpeed)

	--if self:GetCurrentCharacter() == "Stardust Crusader" then
	--	print("current char update so init stand")
	--	task.spawn(self.InitStand, self)
	--end

	--local Run : AnimationTrack = self:GetAnimation("Run")

	--if not Run.IsPlaying and self.Running then
	--	Run:Play(0.1, 1, self.CurrentRunSpeed)
	--end
	--end)
end

--function MovementHandler:SetAsCurrentCharacter(Character: string)
--	self.CurrentCharacter = Character;
--	self.CurrentCharacterInfo = InfoCharacter.GetCharacterInfo(Character);
--end;

--function MovementHandler:GetCurrentCharacter()
--	return self.CurrentItem or self.Combat.CurrentCharacter or "Default" --self.LuaPlayer.Replication.Attributes:GetAttribute("CurrentCharacter") or "Default"
--end

function MovementHandler:UpdateAnimationDirectory()
	--local Item = self.LuaCharacter.Model:FindFirstChildOfClass("Tool")
	--if Item then
	--	if self.Animations[Item.Name] then
	--		self.Directory = Item.Name
	--		return Item.Name
	--	end
	--end

	local Directory = self.Combat:GetCurrentCharacter()

	if (self.Animations[Directory] == nil) then
		self.Directory = "Default"
	else
		self.Directory = Directory
	end

	return Directory
end

function MovementHandler:Run()
	if (self.Running or not self.Combat:GetState("Run") or self.LuaCharacter.Humanoid:GetState() == Enum.HumanoidStateType.Climbing) or workspace:GetAttribute("IsRankedLobby") then 
		return 
	end

	self.Running = true

	--local Run : AnimationTrack = self:GetAnimation("Run")
	
	local UltAnimations = self:GetUltimateAnimations()
	local InUlt = (UltAnimations and self.Combat:IsInUltimate())

	local DefaultRun : AnimationTrack = self:GetAnimation("Run")
	local LowHPRun : AnimationTrack = self:GetAnimation("LowHPRun")

	local Run : AnimationTrack = InUlt and (UltAnimations.Run or DefaultRun) or DefaultRun
	
	if self.LuaCharacter.Humanoid.Health <= 25 and LowHPRun then
		if not LowHPRun.IsPlaying then
			LowHPRun:Play(0.1, 1, self.CurrentRunSpeed)
		end
	else
		if not Run.IsPlaying then
			Run:Play(0.1, 1, self.CurrentRunSpeed)
		end
	end

	if self.Stand and self.StandAnimations and self.StandAnimations.Fly and not self.StandAnimations.Fly.IsPlaying then
		self.StandAnimations.Fly:Play()
	end

	self.LuaCharacter.Humanoid.WalkSpeed *= 1.75
end


function MovementHandler:Unrun()
	if not self.Running then return end

	self.Running = false

	--local Run : AnimationTrack = self:GetAnimation("Run")
	local UltAnimations = self:GetUltimateAnimations()
	local InUlt = (UltAnimations and self.Combat:IsInUltimate())

	local DefaultRun : AnimationTrack = self:GetAnimation("Run")
	local LowHPRun : AnimationTrack = self:GetAnimation("LowHPRun")

	local Run : AnimationTrack = InUlt and (UltAnimations.Run or DefaultRun) or DefaultRun

	if DefaultRun and DefaultRun.IsPlaying then
		DefaultRun:Stop()
	end
	
	if LowHPRun and LowHPRun.IsPlaying then
		LowHPRun:Stop()
	end

	if Run and Run.IsPlaying then
		Run:Stop()
	end

	if self.Stand and self.StandAnimations and self.StandAnimations.Fly and self.StandAnimations.Fly.IsPlaying then
		self.StandAnimations.Fly:Stop()
	end

	self.LuaCharacter.Humanoid.WalkSpeed /= 1.75
end

----------------------------------------------------------------------------------

function MovementHandler.new(LuaCharacter)
	local self = setmetatable({}, MovementHandler)

	self.LuaCharacter = LuaCharacter
	self.Combat = LuaCharacter.Combat
	self.LuaPlayer = LuaCharacter.LuaPlayer

	self.Animations = {}

	self.LastTap = -1
	self.Running = false
	self.Jumping = false

	self.CurrentRunSpeed = 1
	self.OnRunSpeedChanged = EventService.new()

	self.RunSpeed = 1.05
	self.HumanoidSpeed = 1

	self.IdleJob = Job.new()

	self.HumanoidDirection = Vector3.zero

	return self
end

----------------------------------------------------------------------------------

table.freeze(MovementHandler)

return MovementHandler