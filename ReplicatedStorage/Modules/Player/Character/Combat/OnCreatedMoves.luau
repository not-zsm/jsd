local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )
local NumberStack = require( ReplicatedStorage.Modules.Shared.Utilities.NumberStack )

local function AirVariant_HoldingSpace_FreeFalling(Name : string, ChangingName: string, Color : Color3, self : Combat, NewJob : Job.object)
	local Stack = NumberStack.new()

	Stack.OnChanged:Connect(function()
		if Stack:IsFalse() then
			self.UI:ChangeHotbarDisplay(Name, Name, nil, Color)
		else
			self.UI:ChangeHotbarDisplay(Name, ChangingName, nil, Color)
		end
	end)
	
	NewJob:Task(self.OnSpaceChanged:Connect(function(Value : boolean)
		if Value then
			Stack:Add()
		else
			Stack:Subtract()
		end
	end))
	
	NewJob:Task(self.OnFreeFalling:Connect(function()
		Stack:Add()
	end))

	NewJob:Task(self.OnLanded:Connect(function()
		Stack:Reset()
	end))
	
	NewJob:Task(function()
		Stack:Destroy()
	end)
end

local function AirVariant_HoldingSpace(Name : string, ChangingName: string, Color : Color3, self : Combat, NewJob : Job.object)
	NewJob:Task(self.OnSpaceChanged:Connect(function(Value : boolean)
		if Value then
			self.UI:ChangeHotbarDisplay(Name, ChangingName, nil, Color)
		else
			self.UI:ChangeHotbarDisplay(Name, Name, nil, Color)
		end
	end))
end

local function AirLocked_Uptilted(Name : string, ChangingName: string, Color : Color3, self : Combat, NewJob : Job.object)
	local Stack = NumberStack.new()

	Stack.OnChanged:Connect(function()
		if Stack:IsFalse() then
			self.UI:ChangeHotbarDisplay(Name, Name, nil, Color)
		else
			self.UI:ChangeHotbarDisplay(Name, ChangingName, nil, Color)
		end
	end)
	
	for _, AttributeName in {"AirLocked", "UpTilted"} do
		local Previous = self.LuaPlayer.Replication.Attributes:GetAttribute(AttributeName) or 0
		
		if Previous > 0 then
			for _ = 1, Previous do
				Stack:Add()
			end
		end
		
		NewJob:Task(self.LuaPlayer.Replication.Attributes:GetAttributeChangedSignal(AttributeName):Connect(function()
			local Value = self.LuaPlayer.Replication.Attributes:GetAttribute(AttributeName)
			local Change = Value - Previous
			
			if Change > 0 then
				for _ = 1, Change do
					Stack:Add()
				end
			elseif Change < 0 then
				for _ = 1, -Change do
					Stack:Subtract()
				end
			end
			
			Previous = Value
		end))
	end
	
	NewJob:Task(function()
		Stack:Destroy()
	end)
end

local function AirVariant_FreeFalling(Name : string, ChangingName: string, Color : Color3, self : Combat, NewJob : Job.object)
	NewJob:Task(self.OnFreeFalling:Connect(function()
		self.UI:ChangeHotbarDisplay(Name, ChangingName, nil, Color)
	end))

	NewJob:Task(self.OnLanded:Connect(function()
		self.UI:ChangeHotbarDisplay(Name, Name, nil, Color)
	end))
end

return { 
	["Sweep"] = {
		Created = function(self : Combat, NewJob : Job.object)
			AirVariant_HoldingSpace_FreeFalling("Sweep", "Red", Color3.fromRGB(191, 0, 0), self, NewJob)
		end,
	},
	
	["SALT PUAAANNCH"] = {
		Created = function(self : Combat, NewJob : Job.object)
			AirVariant_HoldingSpace_FreeFalling("SALT PUAAANNCH", "Anti-Esper Dropkick", Color3.fromRGB(144, 72, 216), self, NewJob)
		end,
	},
	
	["Chaos Barrage"] = {
		Created = function(self : Combat, NewJob : Job.object)
			AirVariant_HoldingSpace("Chaos Barrage", "Chaos Blades", Color3.fromRGB(255, 85, 0), self, NewJob)
		end,
	},
	
	["Ruthless Beatdown"] = {
		Created = function(self : Combat, NewJob : Job.object)
			AirVariant_HoldingSpace("Ruthless Beatdown", "Ruthless Kicks", Color3.fromRGB(0, 170, 255), self, NewJob)
		end,
	},

	["Onslaught"] = {
		Created = function(self : Combat, NewJob : Job.object)
			AirVariant_HoldingSpace("Onslaught", "Feral Takedown", Color3.fromRGB(191, 0, 0), self, NewJob)
		end,
	},
	
	["Helping Hand"] = {
		Created = function(self : Combat, NewJob : Job.object)
			AirVariant_HoldingSpace("Helping Hand", "Heed My Call", Color3.fromRGB(191, 0, 0), self, NewJob)
		end,
	},
}