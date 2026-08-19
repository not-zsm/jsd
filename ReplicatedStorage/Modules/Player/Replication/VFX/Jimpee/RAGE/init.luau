local EffectsModule = require( script.EffectsModule )

return {
	Start = function(Root : BasePart)
		EffectsModule.StartVFX(Root)
	end,
}