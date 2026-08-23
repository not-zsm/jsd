-- @author Swordphin123

local replicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local VisualizerCache = require(script.Parent.VisualizerCache)
local Solver = require(script.Parent.Solver)

local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )

local ActiveHitboxes = {}

local Hitbox = {}
Hitbox.__index = Hitbox

function Hitbox:Start(Time : number?, DestroyOnComplete : boolean)
	if self.Active then return end
	
	self.Active = true
	
	if (Time ~= nil) then
		task.delay(Time, self.Stop, self, DestroyOnComplete)
	end
end

function Hitbox:Stop(DestroyOnComplete : boolean)
	if not self.Active then return end
	
	self.Active = false

	if DestroyOnComplete then
		self:Destroy()
	end
end

function Hitbox:Destroy()
	if self.Active then
		self:Stop()
	end
	
	self.PendingRemoval = true
	self.OnHit:Destroy()
end

function Hitbox:_Init()
	for _, Attachment : Attachment in ipairs(self.Object:GetChildren()) do
		if not Attachment:IsA("Attachment") then
			continue
		end
		
		if Attachment:HasTag("RaycastHitbox") then
			local Point = {LastPosition = Attachment.WorldPosition, Attachments = {}}

			table.insert(Point.Attachments, Attachment)
			table.insert(self.Point, Point)
		end
	end
	
	table.insert(ActiveHitboxes, self)
end

RunService.Heartbeat:Connect(function()
	for Index = #ActiveHitboxes, 1, -1 do
		if ActiveHitboxes[Index].PendingRemoval then
			local Hitbox = table.remove(ActiveHitboxes, Index)
			table.clear(Hitbox)
			setmetatable(Hitbox, nil)
			
			continue
		end
		
		for _, Point in ipairs(ActiveHitboxes[Index].Point) do
			if not ActiveHitboxes[Index].Active then
				Point.LastPosition = nil

				continue
			end
		
			local Origin, Direction = Solver.Solve(Point)
			local Raycast = workspace:Raycast(Origin, Direction, Utility.VisualParams)

			if ActiveHitboxes[Index].Visualizer then
				local AdornmentData = VisualizerCache.GetAdornment()

				if AdornmentData then
					local DebugStartPosition : CFrame = Solver.Visualize(Point)

					AdornmentData.Adornment.Length = Direction.Magnitude
					AdornmentData.Adornment.CFrame = DebugStartPosition
				end
			end

			Point.LastPosition = Solver.UpdateToNextPosition(Point)

			if (Raycast ~= nil) then
				if not ActiveHitboxes[Index].Hit[Raycast.Instance] then
					ActiveHitboxes[Index].Hit[Raycast.Instance] = true
					ActiveHitboxes[Index].OnHit:Fire({Position = Raycast.Position, Instance = Raycast.Instance, Normal = Raycast.Normal, Distance = Raycast.Distance})
				end
			end
		end
	end

	local AdornmentsInUse : number = #VisualizerCache._AdornmentInUse

	if AdornmentsInUse > 0 then
		for Index = AdornmentsInUse, 1, -1 do
			if time() - VisualizerCache._AdornmentInUse[Index].LastUse >= 0.2 then
				local Adornment = table.remove(VisualizerCache._AdornmentInUse, Index)
				
				if Adornment then
					VisualizerCache.ReturnAdornment(Adornment)
				end
			end
		end
	end
end)

return Hitbox