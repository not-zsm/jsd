local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local replicatedValue = require(script.Parent.replicatedValue)

local runContext: "server" | "client" = if RunService:IsServer() then "server" else "client"
local valueFolder: Folder
local valueDictionary: {
	[string]: replicatedValue.replicatedValueType,
} = {}

local values = {}

function values.start()
	if runContext == "server" then
		local storage = Instance.new("Folder")
		storage.Name = "BytenetStorage"
		storage.Parent = ReplicatedStorage

		valueFolder = storage
	elseif runContext == "client" then
		valueFolder = ReplicatedStorage:WaitForChild("BytenetStorage")
	end
end

function values.access(name: string): replicatedValue.replicatedValueType
	-- caching
	if valueDictionary[name] then
		return valueDictionary[name]
	end

	if runContext == "client" then
		-- the server creates the value empty then writes it, so wait for both or
		-- replicatedValue JSONDecodes an empty string and throws
		local valueInstance = valueFolder:WaitForChild(name) :: StringValue
		if valueInstance.Value == "" then
			valueInstance.Changed:Wait()
		end

		local value = replicatedValue(valueInstance)

		valueDictionary[name] = value

		return value
	elseif runContext == "server" then
		-- create the value and return it
		local newValueInstance = Instance.new("StringValue")
		newValueInstance.Name = name
		newValueInstance.Parent = valueFolder

		local value = replicatedValue(newValueInstance)

		valueDictionary[name] = value

		return value
	end

	return valueDictionary[name]
end

return values