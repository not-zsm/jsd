--- The client's one entry point. Everything else is a system on mainClient.
if not game:IsLoaded() then
	game.Loaded:Wait()
end

require(script.Parent.mainClient).Default():Start()
