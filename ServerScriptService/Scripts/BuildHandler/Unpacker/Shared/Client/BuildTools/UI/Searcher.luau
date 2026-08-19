local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildShared = ReplicatedStorage:WaitForChild("BuildTools");
local Maid = require( ReplicatedStorage.Packages.Maid )

local function default_setter(frame: Frame, value: boolean): ()
	frame.Visible = value;
end;

local Searcher = {};
Searcher.__index = Searcher;

function Searcher.new(search_box: TextBox, search_frame: GuiObject)
	local maid = Maid.new();
	
	local self = setmetatable(
		{
			maid = maid;
			box = search_box,
			frame = search_frame;
			update_thread = nil;
		}, 
		Searcher);
	
	self:initialise();
	
	return self;
end;

local function is_hidden(frame)
	return frame:GetAttribute("Hide")
end

local function query_children(frame, search): boolean
	local any_set = false;
	
	for _, frame: Instance in frame:GetChildren() do
		if not frame:IsA("GuiObject") then continue end;

		if string.match(string.lower(frame.Name), search) and not is_hidden(frame) then
			frame.Visible = true;
			any_set = true;
		else
			frame.Visible = false;
		end;
	end;
	
	return any_set;
end

function Searcher:update_results_now_nested(nest_body: boolean?)
	if self.update_thread then
		self.update_thread = nil;
	end

	local search = string.lower(self.box.Text);
	
	for _, frame: Instance in self.frame:GetChildren() do
		local query_frame = frame;
		
		if nest_body then 
			query_frame = frame:FindFirstChild("Body"); 
		end;
		
		if not query_frame or not query_frame:IsA("GuiObject") or not frame:IsA("GuiObject") then 
			continue; 
		end;
		
		local section_visible = query_children(query_frame, search);
		
		if not is_hidden(query_frame) then
			frame.Visible = section_visible;
		else
			frame.Visible = false;
		end;
	end;
end;

function Searcher:update_results_now()
	if self.update_thread then
		self.update_thread = nil;
	end

	local search = string.lower(self.box.Text);
	
	query_children(self.frame, search);
end

function Searcher:update_results()
	if not self.update_thread then
		self.update_thread = task.defer(self.update_results_now, self);
	end
end

function Searcher:initialise()
	self.maid:add(self.box:GetPropertyChangedSignal("Text"):Connect(function()
		self:update_results();
	end));
	
	self.maid:add(self.frame.ChildAdded:Connect(function()
		self:update_results();
	end))
	
	self.maid:add(self.frame.ChildRemoved:Connect(function()
		self:update_results();
	end))
end

function Searcher:destroy()
	self.maid:destroy();
end

table.freeze(Searcher);

return Searcher;