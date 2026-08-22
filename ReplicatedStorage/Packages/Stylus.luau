
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

local Instances = require( "./Instances" )
local Math = require( "./Math" )
local Table = require( "./Table" )
local Maid = require( "./Maid" )
local Signal = require( "./Signal" )

local Checkbox = require( script.StylusBase.Checkbox )
local Stringbox = require( script.StylusBase.Stringbox )
local Instancebox = require( script.StylusBase.Instancebox )
local Colorbox = require( script.StylusBase.Colorbox )
local Sliderbox = require( script.StylusBase.Sliderbox )
local Musicbox = require( script.StylusBase.Musicbox )
local StylusBase = require( script.StylusBase )

------------------------------------------------------------------------------------

export type StylusBase = StylusBase.StylusBase & any;

export type ClassStylus = {
	__index: ClassStylus;
	
	undo_sprites: {
		undo: string;
		redo: string;
	};
	
	new: () -> Stylus;
	new_checkbox: (self: Stylus, defaults: unknown) -> Checkbox.Checkbox;
	new_stringbox: (self: Stylus, defaults: unknown) -> Stringbox.Stringbox;
	new_instancebox: (self: Stylus, defaults: unknown) -> Instancebox.Instancebox;
	new_colorbox: (self: Stylus, defaults: unknown) -> Colorbox.Colorbox;
	new_sliderbox: (self: Stylus, defaults: unknown) -> Sliderbox.Sliderbox;
	new_musicbox: (self: Stylus, defaults: unknown) -> Musicbox.Musicbox;
	set_tooltip: (self: Stylus, instance: GuiObject, tooltip: string?) -> ();
	set_active_instance_box: (self: Stylus, instance_box: unknown) -> ();
	set_loading_alpha: (self: Stylus, alpha: number, gradient_1: UIGradient, gradient_2: UIGradient) -> ();
	has_active_instance_box: (self: Stylus) -> ();
	give_instance: (self: Stylus, instance: Instance) -> ();
	set_foreground_ui: (self: Stylus, instance: ScreenGui?) -> ();
	unset_foreground_ui: (self: Stylus, instance: ScreenGui) -> ();
	bind_to_foreground_ui: (self: Stylus, instance: ScreenGui, callbacks: any) -> ();
	tween_blur: (self: Stylus, value: number, label: string?) -> ();
	is_hovering_over: (self: Stylus, instance: GuiObject?) -> ();
	is_hovering_over_any: (self: Stylus, instances: {GuiObject}) -> ();
	set_favourite_icon: (self: Stylus, image: ImageLabel, favourited: boolean?, hovering: boolean?) -> ();
	set_rbx_favourite_icon: (self: Stylus, image: ImageLabel, favourited: boolean?, hovering: boolean?) -> ();
	set_checkbox_icon: (self: Stylus, image: ImageLabel, checked: boolean?) -> ();
	set_ribbon_icon: (self: Stylus, image: ImageLabel, class: string) -> ();
	set_sprite_icon: (self: Stylus, image: ImageLabel, class: string) -> ();
	set_gamepad_icon: (self: Stylus, image: ImageLabel, input: Enum.KeyCode) -> ();
	set_expand_icon: (self: Stylus, image: ImageLabel, expanded: boolean) -> ();
	bind_to_resize: (instance: GuiObject, callback: (absolute_size: Vector2) -> ()) -> RBXScriptConnection;
	bind_hover_highlight: (self: Stylus, button: GuiButton, tween_style: any) -> RBXScriptConnection;
};

export type Stylus = typeof(setmetatable({} :: {
	
	foreground_ui: Instance?;
	active_instance_box: any;
	active_instance_box_changed: Signal.Signal<any, boolean>;
	foreground_changed: Signal.Signal<Instance?, Instance?>;
	
}, {} :: ClassStylus));

------------------------------------------------------------------------------------

local Assets = script:WaitForChild("Assets");

local RECT_SIZE = Vector2.new(48, 48);
local RECT_SIZE_RIBBON = Vector2.new(72, 72);
local GAMEPAD_SPRITE_SIZE = Vector2.new(100, 100);
local DUMMY_METHOD = function() end;

local STAR_TEXTURES_THIN = {
	"rbxassetid://8552427135",
	"rbxassetid://8552426623"
}

local STAR_TEXTURES = {
	"rbxassetid://9281670719",
	"rbxassetid://9158926592"
}

local RBX_STAR_TEXTURES = {
	"rbxasset://textures/DeveloperFramework/Favorites/star_filled.png",
	"rbxasset://textures/DeveloperFramework/Favorites/star_stroke.png",
	"rbxasset://textures/DeveloperFramework/Favorites/star_stroke_white.png"
}

local CHECKBOX_TEXTURES = {
	[false] = "",
	[true] = "rbxassetid://5107143552"
}

------------------------------------------------------------------------------------

local Stylus = {} :: ClassStylus;
Stylus.__index = Stylus;
Stylus.undo_sprites = {
	undo = "rbxasset://textures/RoduxDevtools/Undo.png",
	redo = "rbxasset://textures/RoduxDevtools/Redo.png",
};

function Stylus.new()
	local self = setmetatable({}, Stylus);
	
	self.active_instance_box = nil;
	self.active_instance_box_time = -1;
	self.active_instance_box_changed = Signal.new();
	self.foreground_changed = Signal.new();
	
	return self;
end;

function Stylus:new_checkbox(defaults)
	return Checkbox.new(self, defaults);
end

function Stylus:new_stringbox(defaults)
	return Stringbox.new(self, defaults);
end

function Stylus:new_instancebox(defaults)
	return Instancebox.new(self, defaults);
end

function Stylus:new_colorbox(defaults)
	return Colorbox.new(self, defaults);
end

function Stylus:new_sliderbox(defaults)
	return Sliderbox.new(self, defaults);
end

function Stylus:new_musicbox(defaults)
	return Musicbox.new(self, defaults);
end

-- Gives a Gui Instance a hoverable tool-tip that shows when the mouse is in bounds of the given instance.
function Stylus:set_tooltip(instance: GuiObject, tooltip: string?)
	local has_tag =  instance:HasTag("UI-Tooltip");
	
	if tooltip then
		if not has_tag then
			instance:AddTag("UI-Tooltip");
		end;
		
		instance:SetAttribute("Tooltip", tooltip or "");
		
	elseif has_tag then
		instance:RemoveTag("UI-Tooltip");
	end;
end;

function Stylus:set_active_instance_box(instance_box)
	if self.active_instance_box ~= instance_box then
		if self.active_instance_box then
			self.active_instance_box:stop_select(self.active_instance_box.value);
		end;
		
		self.active_instance_box = instance_box;
		self.active_instance_box_time = tick();
		self.active_instance_box_changed:Fire(instance_box, instance_box ~= nil);
	end;
end

function Stylus:set_loading_alpha(alpha: number, gradient_1: UIGradient, gradient_2: UIGradient): ()
	local rotation = -90;
	local min, max = -90 + rotation, 90 + rotation;
	
	gradient_1.Rotation = math.clamp(max - 360 * (alpha - 0.5), min, max) + 2
	gradient_2.Rotation = math.clamp(max - 360 * (alpha - 0.0), min, max)
end

function Stylus:has_active_instance_box()
	return self.active_instance_box ~= nil;
end

function Stylus:give_instance(instance: Instance?): ()
	if self.active_instance_box then
		self.active_instance_box:stop_select(instance);
	end;
end;

function Stylus:give_instance_buffered(instance: Instance?): ()
	if self.active_instance_box and tick() - self.active_instance_box_time > 0.3 then
		self:give_instance(instance);
	end;
end;

function Stylus:set_foreground_ui(instance: ScreenGui?): ()
	local current = self.foreground_ui;
	
	if current ~= instance then
		self.foreground_ui = instance;
		self.foreground_changed:Fire(instance, current);
	end;
end

function Stylus:unset_foreground_ui(instance: ScreenGui): ()
	if self.foreground_ui == instance then
		self:set_foreground_ui(nil);
	end;
end

function Stylus:bind_to_foreground_ui(instance: ScreenGui, callbacks: any): ()
	local open_callback = callbacks.open or callbacks.callback or DUMMY_METHOD;
	local close_callback = callbacks.close or callbacks.callback or DUMMY_METHOD;
	
	if self.foreground_ui == instance then
		task.defer(open_callback);
	end;
	
	return self.foreground_changed:Connect(function(new, last)
		if (new == instance) then
			open_callback();
			
		elseif (last == instance) then
			close_callback();
		end
	end)
end

function Stylus:tween_blur(value: number, label: string?): ()
	if not label then label = "Base" end;
	
	local blur = Lighting:FindFirstChild(`Stylus{label}Blur`);
	
	if not blur then
		blur = Assets.StylusBlur:Clone();
		blur.Name = `Stylus{label}Blur`;
		blur.Archivable = false;
		blur.Parent = Lighting;
	end
	
	local blur_info = TweenInfo.new(0.25);
	local blur_tween = TweenService:Create(blur, blur_info, {Size = value});
	
	if (value ~= 0) then
		task.defer(blur_tween.Play, blur_tween);
	else
		blur_tween:Play();
	end
end

-- Does not work for rotated gui objects. Accounts for Gui Inset.
function Stylus:is_hovering_over(instance: GuiObject?)
	if not instance then
		return false;
	end;
	
	local position = UserInputService:GetMouseLocation() - GuiService:GetGuiInset();
	local top_corner = instance.AbsolutePosition;
	local bottom_corner = top_corner + instance.AbsoluteSize;
	
	return Math.InBounds(position, top_corner.X, top_corner.Y, bottom_corner.X, bottom_corner.Y);
end

-- Does not work for rotated gui objects. Accounts for Gui Inset.
function Stylus:is_hovering_over_any(instances: {GuiObject})
	local position = UserInputService:GetMouseLocation() - GuiService:GetGuiInset();
	
	for _, instance in instances do
		local top_corner = instance.AbsolutePosition;
		local bottom_corner = top_corner + instance.AbsoluteSize;
		
		if Math.InBounds(position, top_corner.X, top_corner.Y, bottom_corner.X, bottom_corner.Y) then
			return true;
		end;
	end;
	
	return false;
end

function Stylus:set_favourite_icon(image: ImageLabel, favourited: boolean?, hovering: boolean?): ()
	if favourited then
		image.Image = STAR_TEXTURES[1];
		
		if hovering then
			image.ImageColor3 = Color3.fromRGB(193, 145, 49);
		else
			image.ImageColor3 = Color3.fromRGB(255, 197, 97);
		end
	else
		image.Image = STAR_TEXTURES[2];
		
		if hovering then
			image.ImageColor3 = Color3.fromRGB(255, 192, 65);
		else
			image.ImageColor3 = Color3.fromRGB(255, 255, 255);
		end
	end
end

function Stylus:set_rbx_favourite_icon(image: ImageLabel, favourited: boolean?, hovering: boolean?): ()
	if favourited then
		image.Image = RBX_STAR_TEXTURES[1];
	else
		if hovering then
			image.Image = RBX_STAR_TEXTURES[2];
		else
			image.Image = RBX_STAR_TEXTURES[3];
		end
	end
end

function Stylus:set_checkbox_icon(image: ImageLabel, checked: boolean?): ()
	if checked then
		image.Image = CHECKBOX_TEXTURES[true];
	else
		image.Image = CHECKBOX_TEXTURES[false];
	end
	
	image.ScaleType = Enum.ScaleType.Fit;
end

function Stylus:set_ribbon_icon(image: ImageLabel, class: string): ()
	local RibbonSprites = require( script.RibbonSprites );
	
	local offset = RibbonSprites[class];

	image.Image = "rbxassetid://100623515641333";
	
	if offset then
		image.ImageRectSize = RECT_SIZE_RIBBON;
		image.ImageRectOffset = offset;
	else
		image.ImageRectSize = Vector2.zero;
		image.ImageRectOffset = Vector2.zero;
	end
end

function Stylus:set_sprite_icon(image: ImageLabel, class: string): ()
	local IconSprites = require( script.IconSprites )
	
	local offset = IconSprites[class];
	local rect_size = RECT_SIZE;
	local asset = "rbxassetid://118192440345523" -- "rbxassetid://18915791990";
	
	if typeof(offset) == "string" then
		return self:set_sprite_icon(image, offset);
		
	elseif typeof(offset) == "number" then
		asset = `rbxassetid://{offset}`;
		offset = Vector2.zero;
		rect_size = Vector2.zero;
		
	elseif not offset then
		offset = IconSprites.BasePlate;
	end
	
	image.Image = asset;
	image.ImageRectSize = rect_size;
	image.ImageRectOffset = offset;
end

function Stylus:set_gamepad_icon(image: ImageLabel, input: Enum.KeyCode): ()
	local GamepadSprites = require( script.GamepadSprites )
	
	local offset = GamepadSprites[input];
	
	image.Image = "rbxassetid://14906517717";
	
	if offset then
		image.ImageRectSize = GAMEPAD_SPRITE_SIZE;
		image.ImageRectOffset = offset;
	else
		image.ImageRectSize = Vector2.zero;
		image.ImageRectOffset = Vector2.zero;
	end
end

function Stylus:set_expand_icon(image: ImageLabel, expanded: boolean): ()
	if expanded then
		image.Image = "rbxassetid://13553867977"
	else
		image.Image = "rbxassetid://6417985472";
	end
	
	--image.Image = "rbxasset://textures/ui/ExpandArrowSheet.png";
	--image.ImageRectSize = Vector2.new(21, 21);
	--image.ImageRectOffset = Vector2.new(if expanded then 21 else 0, 0);
end

function Stylus.bind_to_resize(instance, callback)
	task.spawn(callback, instance.AbsoluteSize);
	
	return instance:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		callback(instance.AbsoluteSize);
	end)
end

local DefaultHoverTweenStyle = { 
	Info = TweenInfo.new(0.1), 
	Transparency = Assets.HoverHighlight.BackgroundTransparency ,
	Color = Assets.HoverHighlight.BackgroundColor3 ,
	DownColor = Color3.fromRGB(196, 196, 196),
};
DefaultHoverTweenStyle.__index = DefaultHoverTweenStyle;

function Stylus:bind_hover_highlight(button: GuiButton, tween_style: any): RBXScriptConnection
	if not tween_style then
		tween_style = {};
	end;
	setmetatable(tween_style, DefaultHoverTweenStyle);
	
	local is_button = button:IsA("GuiButton");
	local transparency = tween_style.Transparency;
	
	return button.MouseEnter:Connect(function()
		local maid = Maid.light();
		
		local hover_highlight = Assets.HoverHighlight:Clone();
		hover_highlight.BackgroundTransparency = 1;
		hover_highlight.BackgroundColor3 = tween_style.Color;
		hover_highlight.Parent = button;
		
		TweenService:Create(hover_highlight, tween_style.Info, {BackgroundTransparency = transparency}):Play()
		
		if is_button then
			maid:add(button.MouseButton1Down:Connect(function()
				hover_highlight.BackgroundColor3 = tween_style.DownColor;
			end))

			maid:add(button.MouseButton1Up:Connect(function()
				hover_highlight.BackgroundColor3 = tween_style.Color;
			end))
		end;
		
		maid:add(button.MouseLeave:Once(function()
			maid:destroy();
			
			local fade_out = TweenService:Create(hover_highlight, tween_style.Info, {BackgroundTransparency = 1})
			
			fade_out.Completed:Once(function()
				hover_highlight:Destroy();
			end);
			
			fade_out:Play()
		end))
	end)
end

table.freeze(Stylus);

return Stylus.new();