--// rateLimiter: per-player per-key flood guard, `rate` calls per 1s window

local Players = game:GetService("Players")

local rateLimiter = {}

-- [player] = { [key] = { count: number, windowStart: number } }
local buckets: { [Player]: { [string]: { count: number, windowStart: number } } } = {}

Players.PlayerRemoving:Connect(function(player)
	buckets[player] = nil
end)

function rateLimiter.check(player: Player, key: string, rate: number): boolean
	if not player then return false end

	local playerBuckets = buckets[player]
	if not playerBuckets then
		playerBuckets = {}
		buckets[player] = playerBuckets
	end

	local bucket = playerBuckets[key]
	local now = os.clock()

	if not bucket or (now - bucket.windowStart) >= 1 then
		playerBuckets[key] = { count = 1, windowStart = now }
		return true
	end

	if bucket.count >= rate then
		return false
	end

	bucket.count += 1
	return true
end

function rateLimiter.reset(player: Player, key: string?)
	local playerBuckets = buckets[player]
	if not playerBuckets then return end
	if key then
		playerBuckets[key] = nil
	else
		buckets[player] = nil
	end
end

return rateLimiter