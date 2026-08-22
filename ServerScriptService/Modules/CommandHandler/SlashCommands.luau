local SlashCommands = {}
SlashCommands.__index = SlashCommands

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

function SlashCommands.new(CommandHandler)
	local self = setmetatable({}, SlashCommands)
	
	self.CommandHandler = CommandHandler
	self.Commands = {}
	
	return self
end

function SlashCommands:Create(Name : string, PermissionType : {}, GetArguments : boolean, Callback : (Player, {}) -> ())
	self.Commands[Name] = {
		Callback = Callback
	}
	
	self.Commands[Name].CommandObject = Instance.new("TextChatCommand")
	self.Commands[Name].CommandObject.PrimaryAlias = `/{Name}`
	self.Commands[Name].CommandObject.Name = Name
	self.Commands[Name].CommandObject.Parent = TextChatService:WaitForChild("CustomCommands")

	self.Commands[Name].CommandObject.Triggered:Connect(function(OriginTextSource, Text)
		local Player = Players:GetPlayerByUserId(OriginTextSource.UserId)
		local Level = self.CommandHandler:GetPermission(Player)

		--if Level and Level <= (PermissionType or 1) then
		if Level ~= "None" and table.find(PermissionType or {}, Level) then
			if GetArguments then
				local Arguments = Utility.CaseSplit(Text, " ", '"')

				if Arguments then
					task.spawn(self.Commands[Name].Callback, Player, Arguments, Level)
				end
			else
				task.spawn(self.Commands[Name].Callback, Player, nil, Level)
			end
		end
	end)
end

return SlashCommands
