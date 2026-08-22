--!native

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EventService = require( ReplicatedStorage.Shared.Utilities.EventService )

----------------------------------------------------------------------------------

local Main = {}

local Job = {}
Job.__index = Job

----------------------------------------------------------------------------------

type Task = () -> () | RBXScriptConnection | thread | {} | Instance

type class = {
	Tasks : {Task},
	Destroyed : boolean
}

export type object = typeof(setmetatable({} :: class, Job))

----------------------------------------------------------------------------------

function Job.Task<T>(self : object, Connection : T) : T
	if self.Destroyed then
		self:CleanTask(Connection)
	else
		if (Connection ~= nil) then
			self.Tasks[Connection] = true
		end
	end
	
	return Connection
end
	
function Job:BindToRender(Name : string, Priority : number, Fn : () -> ())
	RunService:BindToRenderStep(Name, Priority, Fn)
	
	self:Task(function()
		RunService:UnbindFromRenderStep(Name)
	end)
end

----------------------------------------------------------------------------------

function Job.CleanTask(self : object, Object : Task)
	local Type = typeof(Object)

	if (Type == "function") then
		task.spawn(Object :: () -> ())
	end

	if (Type == "RBXScriptConnection") then
		
		if Object.Connected then
			Object:Disconnect()
		end
		
	elseif (Type == "thread") then
		
		if coroutine.status(Object :: thread) == "suspended" then
			task.cancel(Object :: thread)
		end

	elseif (Type == "table") then
		
		if Object.IsACameraShakeInstance and Object.StartFadeOut and Object.IsShaking and Object:IsShaking() then
			Object:StartFadeOut(0.05)
		end
		
		if Object.Destroy then
			Object:Destroy()
		end
		
	elseif (Type == "Tween") then
		
		Object:Canccel()
		Object:Destroy()

	elseif (Type == "Instance") then
		
		Object:Destroy()
		
	end
end

----------------------------------------------------------------------------------

function Job.Clean(self : object)
	for Task in self.Tasks do
		self.Tasks[Task] = nil;
		self:CleanTask(Task)
	end

	table.clear(self.Tasks)
end

function Job.Destroy(self : object)
	self.Destroyed = true
	self:Clean()
end

function Job.Extend(self : object)
	return Main.Extend(self);
end

----------------------------------------------------------------------------------

function Main.new() : object
	local self = setmetatable({} :: class, Job)
	self.Destroyed = false
	self.Tasks = {}

	return self
end


function Main.Extend(MainJob : object) : object
	local NewJob = Main.new()
	MainJob:Task(NewJob)

	return NewJob
end

----------------------------------------------------------------------------------

table.freeze(Main)
table.freeze(Job)

return Main