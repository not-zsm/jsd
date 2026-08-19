local DialogueSystem = require( script.DialogueSystem )
local DialogueInstance

return {
	Init = function(UI)
		DialogueInstance = DialogueSystem.new(UI)
		return DialogueInstance
	end,
	Get = function()
		return DialogueInstance
	end
}