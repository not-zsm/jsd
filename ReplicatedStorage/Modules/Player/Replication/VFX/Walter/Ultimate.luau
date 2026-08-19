local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

----------------------------------------------------------------------------------------------------------------

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )

----------------------------------------------------------------------------------------------------------------

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

----------------------------------------------------------------------------------------------------------------

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local Maid = require( ReplicatedStorage.Packages.Maid )

local AttributeListener = require( ReplicatedStorage.Modules.Player.Replication.Global.AttributeListener )
local RunCameraRig = require( ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig )
local VelocityUtil = require( ReplicatedStorage.Modules.Shared.Game.Velocity.VelocityUtil )

----------------------------------------------------------------------------------------------------------------

local DojyanMeshEmit = require( ReplicatedStorage.Modules.Player.Replication.Global.DojyanMeshEmit )
local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )

--local Effects = script.Effects
--local Meshes = script.Meshes

local Animations = ReplicatedStorage.Animations.Attacks.Global.Ultimate.Walter;

----------------------------------------------------------------------------------------------------------------

OnUltimateStart = function(Model : Model)
	--local Aura = {}

	--for _, Limb in ipairs(script.Aura:GetChildren()) do
	--	for _, VFX in ipairs(Limb:GetChildren()) do
	--		local NewVFX = VFX:Clone()
	--		NewVFX:AddTag("UltimateAura")
	--		NewVFX.Parent = Model[Limb.Name]
	--		NewVFX.Enabled = true
	--		Aura[NewVFX] = true
	--	end
	--end

	--AttributeListener.new(Model, "Ultimate", function()
	--	for VFX in Aura do
	--		VFX.Enabled = false
	--		task.delay(2, VFX.Destroy, VFX)
	--	end

	--	table.clear(Aura)
	--end)
end

return {
	OnUltimateStart = OnUltimateStart,
	
	Start = function(Model : Model, TwelveFriends)
		local Retrieved = AnimationRetriever.new(Model, Animations.Start)
		if (Retrieved == nil) then return end
		
		local Job = Retrieved.Job;
		local Animation = Retrieved.Animation;
		local RootPart = Retrieved.RootPart;
		local IsMainPlayer = LocalPlayer == Players:GetPlayerFromCharacter(Model) 
		local CurrentCamera = workspace.CurrentCamera;
		
		if IsMainPlayer then
			local function CreateTaskDelay(Frame : number, Callback : () -> ())
				return Job:Task(task.delay((Frame / 60) / Animation.Speed, Callback))
			end;
			
			local function GetFrameWait(Frames: number): number
				return (Frames / 60) / Animation.Speed
			end
			
			local WorldPlace = CFrame.new( 1062, 3005, 0); -- This position isn't important it just needs to be away from the map
			local Holder = Job:Task(Instance.new("Model"));
			
			local Classroom = Job:Task(script.Classroom:Clone());
			Classroom.Parent = Holder;
			
			local Camera : Model = Job:Task(script.Camera:Clone())
			Camera.Parent = Holder;
			
			Model.Archivable = true;
			
			local WalterDecoy = Model:Clone();
			WalterDecoy:PivotTo( CFrame.new(13.8, -0.065, -1.75) * CFrame.Angles(0, math.rad(90), 0) );
			WalterDecoy.Parent = Holder;
			
			local WalterRoot = WalterDecoy.HumanoidRootPart;
			
			Model.Archivable = false;
			
			for StudentNum, Id in TwelveFriends do
				local Student = Job:Task(script.Student:Clone());
				Student:PivotTo( CFrame.new(3.8, -0.065, -1.75) * CFrame.Angles(0, math.rad(-90), 0)  )
				Student.Parent = Holder;
				
				task.defer(function()
					local StudentAnimation = Student.Humanoid.Animator:LoadAnimation(Animations.Students[tostring(StudentNum)]);
					StudentAnimation:Play(0, 1, Animation.Speed);
					StudentAnimation.TimePosition = Animation.TimePosition;
					
					local Success, Description = pcall(Players.GetHumanoidDescriptionFromUserId, Players, tonumber(Id))

					if Success and Description and Student:IsDescendantOf(workspace) and not Job.Destroyed then
						Student.Humanoid:ApplyDescription(Description);
					end;
				end);
			end;
			
			script.UltimateSFX.Volume = 0.75;
			script.UltimateSFX.PlaybackSpeed = Animation.Speed;
			script.UltimateSFX:Play();
			
			Holder:PivotTo(WorldPlace);
			Holder.Name = "WalterUltimate";
			Holder.Parent = workspace.Visuals;
			
			EffectUtility.Weld(Camera, WalterRoot);
			
			local ScreenCover = script.ScreenCover:Clone();
			ScreenCover.Enabled = true;
			ScreenCover.Vignette.BackgroundTransparency = 0;
			ScreenCover.Parent = LocalPlayer.PlayerGui;
			
			TweenService:Create(ScreenCover.Vignette, TweenInfo.new(GetFrameWait(40), Enum.EasingStyle.Linear), {BackgroundTransparency = 1}):Play();
			
			local DecoyAnimation : AnimationTrack = WalterDecoy.Humanoid.Animator:LoadAnimation(Animations.Start)
			DecoyAnimation:Play(0, 1, Animation.Speed);
			DecoyAnimation.TimePosition = Animation.TimePosition
			
			local CameraAnimation : AnimationTrack = Camera.AnimationController.Animator:LoadAnimation(Animations.Camera)
			CameraAnimation:Play(0, 1, Animation.Speed);

			Job:Task(Yuki_FOV.AnimateWithMoonFile(ReplicatedStorage.FOVFiles["Walter Ultimate"]))

			local CleanupCamera = Job:Task(RunCameraRig(WalterRoot, Camera, nil, {
				DontSaveCameraPosition = true,
				DontDoTransition = true,
				DontDeleteRigOnClean = true,
			}));
			
			do
				CreateTaskDelay(420, function()
					TweenService:Create(ScreenCover.Vignette, TweenInfo.new(GetFrameWait(10), Enum.EasingStyle.Linear), {BackgroundTransparency = 0}):Play();
				end);
				
				CreateTaskDelay(440, function()
					TweenService:Create(ScreenCover.Vignette, TweenInfo.new(GetFrameWait(10), Enum.EasingStyle.Linear), {BackgroundTransparency = 1, ImageTransparency = 0}):Play();
				end)
				
				CreateTaskDelay(653, function()
					TweenService:Create(ScreenCover.Vignette, TweenInfo.new(GetFrameWait(674 - 653), Enum.EasingStyle.Linear), {BackgroundTransparency = 0, ImageTransparency = 0}):Play();
				end)
			end;
			
			CameraAnimation.Stopped:Once(function()
				--CurrentCamera.CFrame = CFrame.lookAlong(CurrentCamera.CFrame.LookVector, RootPart.CFrame.LookVector)
				Camera:Destroy();
				
				local Tween = TweenService:Create(script.UltimateSFX, TweenInfo.new(1, Enum.EasingStyle.Quad), {Volume = 0})
				Tween:Play();
				Tween.Completed:Once(function()
					script.UltimateSFX:Stop();
				end);
				
				task.wait(0.2);
				local Tween = TweenService:Create(ScreenCover.Vignette, TweenInfo.new(GetFrameWait(100), Enum.EasingStyle.Quad), {BackgroundTransparency = 1, ImageTransparency = 1})
				Tween:Play();
				Tween.Completed:Wait();
				
				ScreenCover:Destroy();
			end)

			Job:Task(Animation:GetMarkerReachedSignal("BackToReality"):Connect(function()
				CleanupCamera();
				
				Job:Task(RunCameraRig(RootPart, Camera, nil, {
					DontSaveCameraPosition = true,
					DontDoTransition = true,
					DontDeleteRigOnClean = true,
				}))
			end))
		end;
	end,
}
