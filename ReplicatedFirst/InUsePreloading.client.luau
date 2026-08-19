if not game:IsLoaded() then
	game.Loaded:Wait()
end

local CollectionService = game:GetService("CollectionService")
local ContentProvider = game:GetService("ContentProvider")

local AwaitingPreload = {};
local AwaitingThread: thread?;

local AlreadyPreloaded = {}

local function AddToPreloadStack(Asset)
	if AlreadyPreloaded[Asset] then
		return
	end
	
	if not AwaitingThread then
		AwaitingThread = task.delay(0.1, function()
			local ToPreload = AwaitingPreload;
			
			AwaitingPreload = {};
			AwaitingThread = nil;
			
			local Success, Result = pcall(ContentProvider.PreloadAsync, ContentProvider, ToPreload)

			if not Success then 
				warn(Result) 
			end
		end)
	end
	
	table.insert(AwaitingPreload, Asset)
	AlreadyPreloaded[Asset] = true
end

local function OnInUseTag(Item : Folder | Animation)
	if (Item == nil or Item.Parent == nil) then return end
	
	if Item:GetAttribute("DontPreload") then return end
	
	if Item:IsA("Folder") then
		for _, Asset in ipairs(Item:GetDescendants()) do
			if Asset:IsA("Animation") then
				AddToPreloadStack(Asset)
			end
		end
		
	elseif Item:IsA("Animation") then
		AddToPreloadStack(Item)
	end
end

for _, Item in CollectionService:GetTagged("InUse") do
	OnInUseTag(Item)
end

CollectionService:GetInstanceAddedSignal("InUse"):Connect(OnInUseTag)