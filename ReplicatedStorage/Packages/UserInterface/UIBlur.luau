local replicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

-----------------------------------------------------------------------------------------

local Maid = require( replicatedStorage.Packages.Maid )
local Observer = require( replicatedStorage.Packages.Observer )

-----------------------------------------------------------------------------------------

local Player = Players.LocalPlayer;
local PlayerGui = Player:WaitForChild("PlayerGui");

local Offset = 0.01;
local Assets = script:WaitForChild("Assets");

local BaseDOF = Instance.new("DepthOfFieldEffect");
BaseDOF.Name = "ScreenBlurDOF"
BaseDOF.FarIntensity = 0;
BaseDOF.FocusDistance = 0;
BaseDOF.InFocusRadius = 0;
BaseDOF.NearIntensity = 1;

-----------------------------------------------------------------------------------------

export type ClassUIBlur = {
	__index: ClassUIBlur;

	new: (blur: BlurEffect) -> UIBlur;
	destroy: (self: UIBlur) -> ();
	update_ancestry: (self: UIBlur) -> ();
	set_cornered: (self: UIBlur, value: boolean) -> ();
	set_rendered: (self: UIBlur, value: boolean) -> ();
	set_active: (self: UIBlur, value: boolean) -> ();
	get_visible: (self: UIBlur) -> boolean;
	render: (self: UIBlur) -> ();
};

export type UIBlur = typeof(setmetatable({} :: {
	
	maid: Maid.Maid;

	active: boolean;
	destroyed: boolean;
	is_rendered: boolean;
	is_cornered: boolean;
	is_ancestry_valid: boolean;
	
	frame: GuiObject;
	render_name: string;
	stroke_size: number,
	
	plane: typeof(Assets.Plane);
	
	planes: { typeof(Assets.Plane) };
	corners: { typeof(Assets.Corner) };
	
}, {} :: ClassUIBlur));

-----------------------------------------------------------------------------------------

local UIBlur = {} :: ClassUIBlur;
UIBlur.__index = UIBlur;

function UIBlur.new(blur: BlurEffect)
	local maid = Maid.new();
	
	local self = setmetatable(
		{
			maid = maid;
			blur = blur;
			
			active = true;
			destroyed = false;
			is_rendered = false;
			is_cornered = false;
			is_ancestry_valid = false;
			
			render_name = "";
			stroke_size = 0;
			
			planes = {};
			corners = {};
		}, 
		UIBlur);
	
	self.plane = Assets.Plane:Clone();
	self.render_name = `UIBlur:{tostring(self)}`;
	
	local function render_blur()
		self:render();
	end;
	
	self.maid:add(RunService.PreRender:Connect(render_blur))
	
	self:update_ancestry()
	self.maid:add(self.blur.AncestryChanged:Connect(function()
		self:update_ancestry();
	end));
	
	return self;
end;

-----------------------------------------------------------------------------------------

local active_rendered = 0;

local function push_render()
	if active_rendered == 0 then
		BaseDOF.Parent = Lighting;
	end;
	
	active_rendered += 1;
end

local function pop_render()
	if active_rendered >= 1 then
		active_rendered -= 1;
		
		if active_rendered == 0 then
			BaseDOF.Parent = nil;
		end
	end
end

-----------------------------------------------------------------------------------------

function UIBlur:destroy()
	if self.destroyed then return end;
	
	self.plane:Destroy();
	
	self:set_rendered(false);
	self:set_cornered(false);
	
	self.maid:destroy();
	self.destroyed = true;
end;

function UIBlur:update_ancestry()
	if self.blur.Parent and self.blur.Parent:IsA("GuiObject") then
		self.is_ancestry_valid = true;
		self.frame = self.blur.Parent;
	else
		self.is_ancestry_valid = false;
		self.frame = nil;
	end
end

function UIBlur:set_cornered(value: boolean)
	if self.is_cornered ~= value then
		self.is_cornered = value;
		
		if value then
			for count = 1, 4 do
				self.planes[count] = Assets.Plane:Clone();
				self.corners[count] = Assets.Corner:Clone();
			end;
		else
			for _, plane in self.planes do
				plane:Destroy();
			end;
			
			for _, corner in self.corners do
				corner:Destroy();
			end;
			
			table.clear(self.planes);
			table.clear(self.corners);
		end
	end
end

function UIBlur:set_rendered(value: boolean)
	if self.is_rendered ~= value then
		self.is_rendered = value;
		
		if value then
			push_render();
			
			self.plane.Parent = workspace.Terrain;

			for _, plane in self.planes do
				plane.Parent = workspace.Terrain;
			end;

			for _, corner in self.corners do
				corner.Parent = workspace.Terrain;
			end;
		else
			pop_render();
			
			self.plane.Parent = nil;

			for _, plane in self.planes do
				plane.Parent = nil;
			end;

			for _, corner in self.corners do
				corner.Parent = nil;
			end;
		end;
	end;
end;

function UIBlur:set_active(value: boolean)
	if self.active ~= value then
		self.active = value;
		self:set_rendered(value);
	end
end

function UIBlur:get_visible(): boolean
	local next_frame: Instance? = self.frame;
	
	while next_frame do
		if next_frame:IsA("ScreenGui") then
			return next_frame.Enabled and next_frame:IsDescendantOf(PlayerGui)
		end;
		
		if next_frame:IsA("GuiObject") and not next_frame.Visible then
			return false;
		end;
		
		next_frame = next_frame.Parent;
	end;
	
	return false;
end

function UIBlur:render()
	if not self.active then return end;
	
	local visible = self:get_visible();
	
	if visible then
		if not self.is_rendered then
			self:set_rendered(true);
		end;
		
		local camera = workspace.CurrentCamera;
		local pos, size, rot = self.frame.AbsolutePosition, self.frame.AbsoluteSize, self.frame.AbsoluteRotation;
		local center_pos = pos + size * 0.5;
		
		local ray = camera:ScreenPointToRay(center_pos.X, center_pos.Y, Offset);
		local center = ray.Origin + ray.Direction * Offset;
		
		local scale_factor = (12 + self.stroke_size) * Offset * math.tan(math.rad(camera.FieldOfView * 0.5)) * 2 / camera.ViewportSize.Y;
		
		self.plane.CFrame = CFrame.lookAlong(center, -camera.CFrame.LookVector) * CFrame.Angles(0, 0, math.rad(rot));
		self.plane.Size = Vector3.new(size.X * scale_factor * 0.95, size.Y * scale_factor, 0.001);
		
	elseif self.is_rendered then
		self:set_rendered(false);
	end;
end

-----------------------------------------------------------------------------------------

Observer.observe_tag("UI-Blur", function(blur: BlurEffect)
	local blur = UIBlur.new(blur);
	
	return function()
		blur:destroy();
	end
end)

table.freeze(UIBlur);

return UIBlur;