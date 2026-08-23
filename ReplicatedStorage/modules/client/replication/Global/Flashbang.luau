local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CaptureService = game:GetService("CaptureService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer;
local PlayerGui = Player:WaitForChild("PlayerGui");

local EffectUtility = require( ReplicatedStorage.modules.client.replication.EffectUtility )
local AenoirUtil = require( ReplicatedStorage.modules.shared.Utilities.Utility.AenoirUtil )
local AenoirEmit = EffectUtility.AenoirEmit

local Assets = script;

local Flashbang = {};

function Flashbang.flash_capture_loaded(UI: typeof(Assets.FlashbangEffectUI), info: any, content_id: any)
	local Screenshot = Assets.Screenshot.Screenshot:Clone()
	local Lenticular = Assets.Screenshot.ScreenshotLenticular:Clone();
	
	Screenshot.Parent = UI;
	Screenshot.Image = content_id;
	
	if (info.beta < 0.6) then
		Lenticular.Parent = UI;
		Lenticular.Image = content_id;
		
		local tween = TweenService:Create(Lenticular, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			ImageTransparency = math.clamp(0.875 + info.beta * 0.2, 0, 1);
			Rotation = 0;
		})
		tween.Completed:Once(function()
			local tween = TweenService:Create(Lenticular, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 3, true), {
				ImageTransparency = math.clamp(0.95 + info.beta * 0.1, 0, 1);
				Rotation = 1;
			})
			tween.Completed:Once(function()
				local tween = TweenService:Create(Lenticular, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
					ImageTransparency = 1;
				})
				tween:Play();
			end)
			tween:Play();
		end)
		tween:Play();
	end;
	
	local tween = TweenService:Create(Screenshot, TweenInfo.new(1.5 + info.beta, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		ImageTransparency = math.clamp(0.5 + info.beta * 0.6, 0, 1);
	})
	tween.Completed:Once(function()
		local tween = TweenService:Create(Screenshot, TweenInfo.new(6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			ImageTransparency = 1;
		})
		tween:Play();
	end)
	tween:Play();
end

function Flashbang.create_flash(info)
	if (info.distance > info.range or Player:GetAttribute("Epileptic_Mode")) then
		return;
	end;
	
	info.beta = math.clamp(math.map(info.distance, info.inner_range, info.range, 0, 1), 0, 1);

	local UI = Assets.FlashbangEffectUI:Clone();
	
	if info.position then
		local function update_on_screen_position(dt: number)
			if not UI:FindFirstChild("MidFlash") then return end;
			
			local position, in_bounds = workspace.CurrentCamera:WorldToViewportPoint(info.position);
			UI.MidFlash.Position = UDim2.fromOffset(position.X, position.Y)
		end
		
		local connection = RunService.PreRender:Connect(update_on_screen_position);
		task.spawn(update_on_screen_position, 0);
		
		UI.MidFlash.ImageTransparency = 0;
		UI.MidFlash.Visible = true;
		
		local tween = TweenService:Create(UI.MidFlash, TweenInfo.new(4, Enum.EasingStyle.Circular, Enum.EasingDirection.Out), {ImageTransparency = 1})
		tween:Play()

		local position, in_bounds = workspace.CurrentCamera:WorldToViewportPoint(info.position);
		local depth_scale = 1 - math.clamp(math.map(position.Z, 0, info.range, 0, 1), 0, 1);
		
		local tween = TweenService:Create(UI.MidFlash.UIScale, TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Scale = 40 * depth_scale })
		tween:Play()
		
		tween.Completed:Once(function()
			connection:Disconnect();
		end)
	end
	
	if not info.only_screen_effect then
		do
			local Correction = Instance.new("ColorCorrectionEffect");
			Correction.Archivable = false;
			Correction.Brightness = 0;
			Correction.Parent = Lighting;
			
			local tween = TweenService:Create(Correction, TweenInfo.new(0.6, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Brightness = math.clamp(0.3 - info.beta * 0.3, 0, 1)})
			tween:Play()
			tween.Completed:Once(function()
				local tween = TweenService:Create(Correction, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 1, true), {Brightness = (1 - info.beta) * 0.025})
				tween:Play()
				tween.Completed:Wait();
				local tween = TweenService:Create(Correction, TweenInfo.new(2, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut), {Brightness = 0})
				tween:Play()
				tween.Completed:Wait();
				Correction:Destroy();
			end)
		end;
		
		do
			local Blur = Instance.new("BlurEffect")
			Blur.Archivable = false;
			Blur.Size = 0;
			Blur.Parent = Lighting;
			
			local tween = TweenService:Create(Blur, TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = (1 - info.beta) * 10})
			tween:Play()
			tween.Completed:Once(function()
				local tween = TweenService:Create(Blur, TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut, 1, true), {Size = (1 - info.beta) * 16})
				tween:Play()
				tween.Completed:Wait();
				local tween = TweenService:Create(Blur, TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut), {Size = 0})
				tween:Play()
				tween.Completed:Wait();
				Blur:Destroy();
			end)
		end;
		
		do
			local Flash = Assets.Flash.Flashbang:Clone();
			Flash.Archivable = false;
			Flash.Volume = (1 - info.beta) * 0.5
			Flash.Parent = UI;
			Flash:Play();
			
			local Ring = Assets.Flash.Ring:Clone();
			Ring.Archivable = false;
			Ring.Volume = (1 - info.beta) * 1
			Ring.Parent = UI;
			Ring:Play();
			
			if not info.no_lobotomy then
				local Lobotomy = Assets.Flash.Lobotomy:Clone();
				Lobotomy.Archivable = false;
				Lobotomy.Volume = 0.2
				Lobotomy.PlaybackSpeed = Random.new():NextNumber(0.9, 1.25)
				Lobotomy.Parent = UI;
				Lobotomy:Play();
			end
			
			--if math.random(1, 5) == 1 then
			--	local Lobotomy = Assets.Flash.Lobotomy:Clone();
			--	Lobotomy.Archivable = false;
			--	Lobotomy.Volume = 0.2
			--	Lobotomy.PlaybackSpeed = Random.new():NextNumber(0.9, 1.25)
			--	Lobotomy.Parent = UI;
			--	Lobotomy:Play();
			--end
			
			TweenService:Create(Flash, TweenInfo.new(5, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {Volume = 0}):Play();

			local tween = TweenService:Create(UI.FlashLong, TweenInfo.new(0.1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
				BackgroundTransparency = math.clamp(0.7 + info.beta * 0.3, 0, 1);
			})
			tween.Completed:Once(function()
				local tween = TweenService:Create(UI.FlashLong, TweenInfo.new(8, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {
					BackgroundTransparency = 1;
				})
				tween:Play();
			end)
			tween:Play();

			local tween = TweenService:Create(UI.Flash, TweenInfo.new(0.05, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
				BackgroundTransparency = math.clamp(0.25 + info.beta ^ 0.5 * 2, 0, 1);
			})
			tween:Play();
			tween.Completed:Once(function()
				local tween = TweenService:Create(UI.Flash, TweenInfo.new(2, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut), {
					BackgroundTransparency = 1;
				})
				tween:Play();
			end)

			local tween = TweenService:Create(UI.Vignette, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 4, true), {
				ImageTransparency = math.clamp(0.8 + info.beta * 0.2, 0, 1);
			})
			tween:Play();
		end
	end;
	
	UI.Enabled = true;
	UI.Archivable = false;
	UI.Parent = PlayerGui;
	
	-- ahhhhhhhhhhhhhhhhhhhhhhh
	task.delay(15, UI.Destroy, UI);
	
	if not info.only_screen_effect then
		CaptureService:CaptureScreenshot(function(content_id)
			Flashbang.flash_capture_loaded(UI, info, content_id);
		end)
	end;
	
	return UI;
end

table.freeze(Flashbang);

return Flashbang;