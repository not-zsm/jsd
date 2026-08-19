local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

---------------------------------------------------------------------------------------------

local Player = Players.LocalPlayer;

---------------------------------------------------------------------------------------------

local BuildTools = script.Parent;

local Assets = BuildTools.Assets;
local Bindables = BuildTools.Bindables;
local Remotes = BuildTools.Remotes;

---------------------------------------------------------------------------------------------

local Fruits = require( BuildTools.Fruits );
local Planter = require( BuildTools.Planter );
local Emit = require( BuildTools.Emit );
local FlightHandler = require( BuildTools.FlightHandler );
local CameraAdorn = require( script.CameraAdorn )
local ScreenInterface = require( script.ScreenInterface )
local Message = require( script.Message );
local Velocities = require( script.Velocities );

local AenoirCrater = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility.AenoirCrater )
local Instances = require( ReplicatedStorage.Packages.Instances )
local BufferUtil = require( ReplicatedStorage.Packages.BufferUtil )
local Asset = require( ReplicatedStorage.Packages.Asset )
local Observer = require( ReplicatedStorage.Packages.Observer )
local Maid = require( ReplicatedStorage.Packages.Maid )
local StreamService = require( ReplicatedStorage.Packages.StreamService )
local Signal = require( ReplicatedStorage.Packages.Signal )

local ControlModule = require(Player
	:WaitForChild("PlayerScripts")
	:WaitForChild("PlayerModule")
	:WaitForChild("ControlModule"))

---------------------------------------------------------------------------------------------

local QuarterDegree = math.sqrt(2) / 2;

---------------------------------------------------------------------------------------------

local BuildPersistent = {};
BuildPersistent.__index = BuildPersistent;
BuildPersistent.OnToggled = Bindables.OnToggled.Event;
BuildPersistent.OnDelete = Bindables.OnDelete.Event;
BuildPersistent.Bindables = Bindables;

function BuildPersistent.new()
	local maid = Maid.new();

	local self = setmetatable(
		{
			stream = maid:add(StreamService.new("BuildsProfile", {}));
			skills_stream = maid:add(StreamService.new("CustomSkillsProfile", {})),
			btools_runner = nil;
			shared = nil;
			maid = maid;
			character_maid = maid:limb();
			shared_maid = maid:limb();
			active = false;
			shared_changed = maid:add(Signal.new());
		}, 
		BuildPersistent);
	
	self:initialise();
	
	return self;
end;

function BuildPersistent:set_shared(folder: any)
	local current = self.shared;
	
	if (current ~= folder) then
		self.shared_maid:clean();
		self.shared = folder;
		
		if self.shared then
			self.active = true;
			
			local function descendant_added(child: Instance): ()
				if child:IsA("Sound") then
					child.Playing = false;
				end
			end;
			
			for _, child in folder:GetDescendants() do
				descendant_added(child);
			end;
			
			self.shared_maid:add(folder.DescendantAdded:Connect(descendant_added));
		else
			self.active = false;
		end
		
		self.shared_changed:Fire(folder, current);
	end
end

function BuildPersistent:character_added(character: any)
	self.character_maid:clean();

	local humanoid: Humanoid = character:WaitForChild("Humanoid", 5);
	local seat_maid = Maid.new();
	
	self.character_maid:add(seat_maid);

	humanoid.Seated:Connect(function(value, seat)
		seat_maid:clean()

		if not seat then
			return;
		end;
		
		seat_maid:add(humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
			local move_vector: Vector3 = ControlModule:GetMoveVector();
			
			Remotes.Input.SeatMove:FireServer(move_vector);
		end))
		
		seat_maid:add(UserInputService.InputBegan:Connect(function(input, processed)
			if processed then return end;
			
			if (input.KeyCode == Enum.KeyCode.Unknown) then
				Remotes.Input.SeatKeyDown:FireServer(input.UserInputType)
			else
				Remotes.Input.SeatKeyDown:FireServer(input.KeyCode)
			end
		end))

		seat_maid:add(UserInputService.InputEnded:Connect(function(input, processed)
			if processed then return end;

			if (input.KeyCode == Enum.KeyCode.Unknown) then
				Remotes.Input.SeatKeyUp:FireServer(input.UserInputType)
			else
				Remotes.Input.SeatKeyUp:FireServer(input.KeyCode)
			end
		end));
	end);
end;

function BuildPersistent:initialise()
	if Player.Character then
		task.spawn(self.character_added, self, Player.Character);
	end;
	
	self.maid:add(Player.CharacterAdded:Connect(function(character)
		self:character_added(character);
	end))
	
	self.maid:add(Player.CharacterRemoving:Connect(function(character)
		self.character_maid:clean();
	end))
	
	self.maid:add(Remotes.ToggleBuildTools.OnClientEvent:Connect(function(value: boolean)
		if value and not self.btools_runner then
			-- This shouldn't happen ...
			if not self.shared then
				self.shared_changed:Wait();
			end;
			
			self:create_gui();

		elseif self.btools_runner then
			self:toggle(value);
		end
	end))
	
	self.maid:add(Remotes.Effects.RemoveVelocity.OnClientEvent:Connect(Velocities.remove))
	self.maid:add(Remotes.Effects.ApplyVelocity.OnClientEvent:Connect(function(id, attachment, velocity, ref_or_axes, ...)
		if typeof(ref_or_axes) == "Instance" then
			local info = ref_or_axes:GetAttributes();
			
			Velocities.apply(id, attachment, velocity, info.Axes, info.MaxForce, info.Duration or info.PushDuration, info.Tapering, info.Aligned);
		else
			Velocities.apply(id, attachment, velocity, ref_or_axes, ...);
		end
	end))

	self.maid:add(Remotes.Effects.CameraShake.OnClientEvent:Connect(function(setting: Configuration)
		local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake );
		local Info = setting:GetAttributes();
		
		CameraShake(Info.Intensity, Info.Speed, Info.FadeIn, Info.FadeOut, Info.PositionInfluence, Info.RotationInfluence);
	end))
	
	self.maid:add(Bindables.Delete.Event:Connect(function()
		self:delete_gui();
	end))
	
	self.maid:add(Remotes.Effects.SpawnEffects.OnClientEvent:Connect(function(source, target, parameters)
		Emit(source, target, nil, parameters);
	end))

	self.maid:add(Remotes.DeleteBuildTools.OnClientEvent:Connect(function()
		Bindables.Delete:Fire();
	end))
	
	local sound_identification = {};
	
	local function remove_sound(id: number): ()
		if sound_identification[id] then
			sound_identification[id]:Destroy();
			sound_identification[id] = nil;
		end;
	end
	
	self.maid:add(Remotes.Effects.SpawnSound.OnClientEvent:Connect(function(sound: Sound, target: Instance, id: number, time_position: number?)
		remove_sound(id);
		
		local clone_sound = sound:Clone();
		clone_sound.Playing = false;
		
		if time_position then
			clone_sound.TimePosition = time_position;
		else
			clone_sound.TimePosition = 0;
		end;
		
		sound_identification[id] = clone_sound;
		
		clone_sound.Ended:Once(function()
			remove_sound(id);
		end);
		
		clone_sound.Parent = target;
		clone_sound:Play();
	end));
	
	self.maid:add(Remotes.Effects.RemoveSound.OnClientEvent:Connect(remove_sound))
	
	self.maid:add(Remotes.Effects.SpawnCrater.OnClientEvent:Connect(function(coordinate: CFrame, crater_params: any)
		if typeof(crater_params) == "Instance" then
			crater_params = crater_params:GetAttributes();
		end;
		
		local encode_params = {
			adornee = workspace.Terrain,
			offset = coordinate,
			rotation_angle = {
				crater_params.RotationX,
				crater_params.RotationY,
			},
			fade_out_time = crater_params.Lifetime,
			[string.lower(crater_params.CraterType)] = {
				count = crater_params.Count,
				angle = crater_params.Angle,
				size = crater_params.Size,
				variance = crater_params.Variance,
				magnitude_variance = crater_params.PointVariance,
				rate = crater_params.Rate,
				radius = crater_params.Radius,
				depth = crater_params.Depth,
			};
		};
		
		local crater = AenoirCrater.new(encode_params);
		crater:start( crater_params.Lifetime );
	end))
	
	self.maid:add(Remotes.Effects.SpawnScreen.OnClientEvent:Connect(function(info: any)
		local screen = Assets.Screen:Clone();
		screen.Icon.Image = Asset.get_decal_id(info.image);
		screen.Parent = Player.PlayerGui;
		
		local audio = Instance.new("Sound");
		audio.SoundId = Asset.get_rbx_asset(info.sound_id);
		audio.Volume = info.volume or 2;
		audio.Parent = screen;
		audio:Play();
		
		if info.duration and info.duration > 0 then
			task.wait(info.duration);
		end;
		
		local tween_info = TweenInfo.new(info.fade_out or 0.25, Enum.EasingStyle.Linear);
		local tween = TweenService:Create(screen.Icon, tween_info, {ImageTransparency = 1});
		
		tween.Completed:Once(function()
			if info.lasting and info.lasting > 0 then
				task.wait(info.lasting);
			end;
			
			screen:Destroy();
		end);
		
		tween:Play();
	end))
	
	do
		local camera_adorn = CameraAdorn.new();
		
		self.maid:add(Remotes.Effects.UnadornCamera.OnClientEvent:Connect(function(identifier: Instance)
			camera_adorn:remove(identifier);
		end))
		
		self.maid:add(Remotes.Effects.AdornCamera.OnClientEvent:Connect(function(adorn: Instance, identifier: Instance, unlock_rotation: boolean, unlock_pan: boolean, easing_buffer: buffer)
			local packet = BufferUtil.new(easing_buffer);
			local tween_info = BufferUtil.read_tween_info(packet);
			local field_of_view = BufferUtil.read_f32(packet);
			
			camera_adorn:add(identifier, adorn, tween_info, field_of_view, unlock_rotation, unlock_pan);
		end))
	end;
	
	do
		local active = {};
		
		self.maid:add(Remotes.Effects.RemoveInterfaces.OnClientEvent:Connect(function(single: boolean, modifier: Instance)
			
			if not single then
				for identifier, interface in active do
					interface:destroy();
				end;
				
				table.clear(active);
				
			elseif modifier then
				local identifier = modifier:GetAttribute("Identifier");
				
				if identifier then
					local interface = active[identifier];

					if interface then
						interface:destroy();
						active[identifier] = nil;
					end;
				end;
			end;
		end));
		
		self.maid:add(Remotes.Effects.ScreenInterface.OnClientEvent:Connect(function(modifier: Instance)
			if not modifier then return end;
			
			local data = modifier:GetAttributes();
			
			if data.Identifier then
				local interface = active[data.Identifier];
				
				if not interface then
					interface = ScreenInterface.new(data.Identifier);
					active[data.Identifier] = interface;
					-- Will never be removed on its own, this is intentional.
				end;
				
				if not table.find(interface.modifiers, modifier) then
					table.insert(interface.modifiers, modifier);
				end;
				
				interface:update(data);
			end;
		end));
	end;
	
	self.maid:add(Remotes.Effects.UniversalTween.OnClientEvent:Connect(function(instance: Instance, value: any, easing_buffer: buffer)
		if not instance then return end;
		
		local packet = BufferUtil.new(easing_buffer);
		local tween_info = BufferUtil.read_tween_info(packet);
		local property = BufferUtil.read_string(packet, packet.size - packet.cursor);
		
		local tween = TweenService:Create(instance, tween_info, { [property] = value })
		tween:Play();
	end));
	
	self.maid:add(Remotes.Effects.MotorTween.OnClientEvent:Connect(function(motor6d: Motor6D, packet: buffer | CFrame)
		if not motor6d then return end;
		
		if typeof(packet) == "buffer" then
			local packet = BufferUtil.new(packet);
			local coordinate = BufferUtil.read_cframe(packet);
			local tween_info = BufferUtil.read_tween_info(packet);

			local tween = TweenService:Create(motor6d, tween_info, {Transform = coordinate})
			
			tween.Completed:Once(function()
				tween:Destroy();
			end);
			
			tween:Play();
		else
			motor6d.Transform = packet;
		end
	end));

	self.maid:add(Remotes.Operations.Move.OnClientEvent:Connect(function(instances: {PVInstance}, pivots: {CFrame})
		local count = #instances;
		local parts: {BasePart} = table.create(count);
		local cframes: {CFrame} = table.create(count);

		for index, instance in instances do
			if not pivots[index] then
				continue;
			end;
			
			if instance:IsA("Model") then
				--local bounding_origin = instance:GetBoundingBox()
				--local new_pivot = pivots[index] * bounding_origin:ToObjectSpace(instance:GetPivot());
				
				instance:PivotTo(pivots[index]);
				
			elseif instance:IsA("BasePart") then
				parts[index] = instance;
				cframes[index] = pivots[index];
				
			else
				instance.CFrame = pivots[index];
			end
		end

		workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged);
	end));

	self.maid:add(Remotes.Operations.Size.OnClientEvent:Connect(function(instances: {PVInstance}, sizes: {Vector3})
		for index, instance in instances do
			if instance:IsA("BasePart") and sizes[index] then
				instance.Size = sizes[index];
			end;
		end;
	end));

	self.maid:add(Observer.observe_tag("TweenMotor", function(motor: Motor6D)
		motor.Transform = motor:GetAttribute("TargetTransform") or CFrame.identity;
	end))
	
	self.maid:add(Observer.observe_tag("BuildMessage", function(messager: Configuration)
		Message.queue_yield();
		
		local message = Message.new(messager, BuildTools.Assets.Message);
		
		return function()
			message:destroy();
		end
	end))
	
	self:initialise_shared_listeners();
end

function BuildPersistent:initialise_shared_listeners()
	local function child_added(child: Instance)
		if (child.Name == "Shared") then
			self:set_shared(child);
		end
	end

	local function child_removed(child: Instance)
		if (child == self.shared) then
			self:set_shared(nil);
		end
	end

	for _, child in BuildTools:GetChildren() do
		child_added(child);
	end;

	BuildTools.ChildRemoved:Connect(child_removed);
	BuildTools.ChildAdded:Connect(child_added);
end

function BuildPersistent:create_virtual_client(GUI: any)
	local client = script.BTools:Clone();
	client.GUI.Value = GUI;
	client.Parent = Player.PlayerScripts;

	return client;
end

function BuildPersistent:create_gui()
	if self.active and not self.btools_runner then
		local gui = self.shared.UI.BuildTools:Clone();
		gui.Parent = Player.PlayerGui;

		self.btools_runner = self:create_virtual_client(gui);
		self.btools_binding = self.btools_runner:FindFirstChild("GUI");

		self.btools_runner.Destroying:Once(function()
			self:delete_gui();
		end)
	end
end

function BuildPersistent:delete_gui()
	if self.btools_binding then
		self.btools_binding.Value = nil;

		self.btools_runner = nil;
		self.btools_binding = nil;
	end
end

function BuildPersistent:toggle(value: boolean)
	Bindables.Toggle:Fire(value);
end;

function BuildPersistent:delete()
	Bindables.Delete:FIre();
end

---------------------------------------------------------------------------------------------

return BuildPersistent.new();