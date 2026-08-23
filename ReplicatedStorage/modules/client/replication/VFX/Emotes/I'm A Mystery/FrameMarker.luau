local RunService = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local FrameMarker = {}
FrameMarker.__index = FrameMarker

function FrameMarker.new(settings)
	return setmetatable({
		Framerate = settings.Framerate or 60,

		_FrameMarkerElapsed = 0,
		_sequences = {}
	}, FrameMarker)
end

function FrameMarker:At(frame, call)
	self._sequences[frame] = call
end

function FrameMarker:Chain(root: {[number]: number?}): FrameMarker
	for frame, sequence in root do
		self:At(frame, sequence)
	end

	self:Play()

	return self
end

function FrameMarker:Stop()
	if self._Connection and self._Connection.Connected then
		self._Connection:Disconnect()
	end
end

function FrameMarker:Play()
	self:Stop()
	
	self._Connection = RunService.Heartbeat:Connect(function(deltaTime)
		for frame, callback in self._sequences do
			if self._FrameMarkerElapsed >= frame then
				task.spawn(callback, self)
				self._sequences[frame] = nil
			end
		end

		self._FrameMarkerElapsed += deltaTime * self.Framerate
	end)
end

function FrameMarker:Destroy()
	self:Stop()
	table.clear(self)
	setmetatable(self, nil)
end

return FrameMarker