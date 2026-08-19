local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local LuaPlayerList = require( ServerScriptService.Scripts.Game.Modules.LuaPlayerList )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local Sorting = require(script.Sorting)

---------------------------------

local Hitbox = {}
Hitbox.__index = Hitbox

---------------------------------

function Hitbox:GetLuaPlayerFrom(Model : Model)
	local LuaPlayer = LuaPlayerList.Get(Model)

	if LuaPlayer and not LuaPlayer.Character.Combat:CanDamageAI() then
		return nil
	end

	return LuaPlayer
end


function Hitbox:OnIgnoreList(Model : Model)
	for _, Object in self.Settings.Ignore do
		if (Model == Object) or Object:IsDescendantOf(Model) then
			return true
		end
	end

	return false
end


function Hitbox:Sort(List)
	local SortFn = Sorting[self.Settings.ListSorting]

	if (SortFn ~= nil) then
		SortFn(List, self.Adornee.Position)
	end
end


function Hitbox:Valid()
	return (self.Adornee and self.Adornee.Parent ~= nil)
end


function Hitbox:Destroy()
	table.clear(self)
	setmetatable(self, nil)
end

---------------------------------

function Hitbox.new(Adornee : BasePart, Settings : {})
	assert(Adornee, "No adornee was provided.")
	assert(Settings, "No settings were given.")

	local self = {}
	setmetatable(self, Hitbox)

	self.Adornee = Adornee
	self.Settings = Settings

	return self
end


function Hitbox:Detect()
	local List = {}
	local Count = 0

	if self:Valid() then

		local Bounds = workspace:GetPartBoundsInRadius(self.Adornee.Position, self.Settings.Range, Utility.HitboxParams)

		for _, Hit in Bounds do
			
			if Hit.Name ~= "HumanoidRootPart" then 
				continue 
			end
			
			local Model = Hit:FindFirstAncestorOfClass("Model")

			if not Model:IsA("Model") then
				continue
			end

			if Model:HasTag("NPC") then
				continue
			end

			local LuaPlayer : {}? = self:GetLuaPlayerFrom(Model)
			
			if not (LuaPlayer) or self:OnIgnoreList(Model) then
				continue
			end

			Count += 1
			table.insert(List, LuaPlayer)
		end

		self:Sort(List)
	end

	return List, Count
end

---------------------------------


return Hitbox