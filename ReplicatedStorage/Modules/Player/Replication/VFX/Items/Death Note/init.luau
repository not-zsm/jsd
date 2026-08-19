local SplitterModule = {}

for _, Child in ipairs(script:GetChildren()) do
	if Child:IsA("ModuleScript") then
		local Module = require(Child)

		for Key, Value in pairs(Module) do
			if type(Value) == "function" then
				SplitterModule[`{Child.Name}/{Key}`] = Value
			end
		end
	end
end

return SplitterModule
