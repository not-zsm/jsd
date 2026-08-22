local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local MatchmakingScreen = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MatchmakingScreen")
MatchmakingScreen.Enabled = true

local Status = MatchmakingScreen:WaitForChild("Status")

local Functions = require(ReplicatedStorage.Shared.QueueFunctions)
local HitboxBox = require(ReplicatedStorage.Shared.Game.Hitbox.Type.Box)

local MatchmakingElo = 0
local ZoneSessionId = 0
local LocalQueueSessionId = 0
local ServerClock = 0

local IsQueueing = false
local RequestInFlight = false
local Waiting = false

local CurrentMatch
local UserCache = {}
local WaitingSentinel = {}
local ExitConn
local CharacterConn
local ZoneHitbox

local ZonePart = workspace.Map.Model:WaitForChild("Hitbox1V1")
local ZoneSizePadding = Vector3.new(0, 2, 0)

local LastZoneEnterTime = 0
local ZoneEnterDebounceTime = 0.5

local function DisconnectExitWatch()
	if ExitConn or CharacterConn then
		print("Disconnecting exit watch connections.")
	end
	if ExitConn then
		ExitConn:Disconnect()
		ExitConn = nil
	end

	if CharacterConn then
		CharacterConn:Disconnect()
		CharacterConn = nil
	end
end

local function CancelQueue()
	if not IsQueueing then
		return
	end

	print("Cancellation initiated. Forcing UI to hide.")
	
	IsQueueing = false
	RequestInFlight = false
	CurrentMatch = nil

	ReplicatedStorage.Remotes.Queue.CancelMatchmake:FireServer()
	
	UpdateMatchmakingStatus(nil, MatchmakingElo)
	DisconnectExitWatch()
	
	ZoneHitbox:Reset()
	
	LocalQueueSessionId = 0
end

local function NextZoneSession()
	ZoneSessionId += 1
	return ZoneSessionId
end

local function GetUserData(UserId)
	if UserId < 1 then
		UserId = 1
	end
	if not UserCache[UserId] then
		UserCache[UserId] = {
			Headshot = Players:GetUserThumbnailAsync(UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100),
			Name = Players:GetNameFromUserIdAsync(UserId),
		}
	end
	return UserCache[UserId]
end

local ErrorToken = 0

local function ShowErrorMsg(Message)
	ErrorToken += 1
	local Token = ErrorToken
	print("Showing error message:", Message)
	MatchmakingScreen.Error.Visible = true
	MatchmakingScreen.Error.Label.Text = Message
	task.delay(5, function()
		if Token == ErrorToken then
			MatchmakingScreen.Error.Visible = false
		end
	end)
end

MatchmakingScreen.TextBox.FocusLost:Connect(function()
	MatchmakingScreen.TextBox.TextEditable = false
	pcall(function()
		local UserId = Players:GetUserIdFromNameAsync(MatchmakingScreen.TextBox.Text)
		local Success, ErrorMsg = ReplicatedStorage.Remotes.Queue.PartyRequest:InvokeServer(UserId)
		if not Success then
			MatchmakingScreen.TextBox.Text = ErrorMsg
		else
			MatchmakingScreen.TextBox.Text = "Sent request!"
		end
		task.wait(2)
	end)
	MatchmakingScreen.TextBox.TextEditable = true
end)

function UpdateMatchmakingStatus(Match, Elo)
	MatchmakingElo = Elo
	
	if Match then
		TweenService:Create(Status, TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), { Position = UDim2.fromScale(0.5, 1 - Status.Size.Y.Scale) }):Play()
	else
		TweenService:Create(Status, TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), { Position = UDim2.fromScale(0.5, 1) }):Play()
	end
	
	CurrentMatch = Match
end

ReplicatedStorage.Remotes.Queue.UpdateMatchmakingStatus.OnClientEvent:Connect(function(Match, Elo, ServerNow)
	print("Received UpdateMatchmakingStatus from server. Match exists:", Match ~= nil)
	
	if not IsQueueing and Match ~= nil then
		print("Ignoring stale server update because client is not queueing.")
		return
	end
	
	if typeof(ServerNow) == "number" then
		ServerClock = ServerNow - DateTime.now().UnixTimestamp
	end
	
	UpdateMatchmakingStatus(Match, Elo)
end)

ReplicatedStorage.Remotes.Queue.UpdatePartyStatus.OnClientEvent:Connect(function(Party, Owner)
	for _, Frame in MatchmakingScreen.Party.Body:GetChildren() do
		if Frame:IsA("ImageLabel") then
			Frame:Destroy()
		end
	end
	
	for _, UserInfo in Party do
		task.spawn(function()
			local UserData = GetUserData(UserInfo.UserId)
			local Headshot = script.Headshot:Clone()
			Headshot.Image = UserData.Headshot
			Headshot.DisplayName.Text = UserData.Name
			Headshot.TextButton.Visible = Owner
			Headshot.TextButton.MouseButton1Up:Connect(function()
				ReplicatedStorage.Remotes.Queue.KickPlayer:FireServer(UserInfo.UserId)
			end)
			Headshot.Parent = MatchmakingScreen.Party.Body
		end)
	end
	
	MatchmakingScreen.Party.Visible = #Party > 1
end)

ReplicatedStorage.Remotes.Queue.Error.OnClientEvent:Connect(ShowErrorMsg)

ReplicatedStorage.Remotes.Queue.NotifyPartyRequest.OnClientEvent:Connect(function(Requests)
	MatchmakingScreen.Requests.Visible = #Requests > 0
	
	for _, Frame in MatchmakingScreen.Requests:GetChildren() do
		if Frame:IsA("Frame") then
			Frame:Destroy()
		end
	end
	
	for _, UserId in Requests do
		task.spawn(function()
			local UserData = GetUserData(UserId)
			
			local PartyRequest = script.PartyRequest:Clone()
			PartyRequest.Headshot.Image = UserData.Headshot
			PartyRequest.InviteText.Text = PartyRequest.InviteText.Text:format(UserData.Name)
			PartyRequest.TextButton.MouseButton1Click:Connect(function()
				if Waiting then
					return 
				end
				
				Waiting = true
				PartyRequest.TextButton.Text = "..."
				
				local CouldJoin, ErrorMsg = ReplicatedStorage.Remotes.Queue.JoinParty:InvokeServer(UserId)
				
				if ErrorMsg then
					PartyRequest.TextButton.Text = ErrorMsg
				end
				
				if CouldJoin then
					for _, Frame in MatchmakingScreen.Requests:GetChildren() do
						if Frame:IsA("Frame") then Frame:Destroy() end
					end
					
					MatchmakingScreen.Requests.Visible = false
				end
				
				Waiting = false
			end)
			
			PartyRequest.Parent = MatchmakingScreen.Requests
		end)
	end
end)

local ZoneParams = HitboxBox.NewParams()
ZoneParams.Size = ZonePart.Size
ZoneParams.Offset = CFrame.identity
ZoneParams.DestroyOnEndCast = false
ZoneParams.MaxTargets = -1
ZoneParams.Recursive = false
ZoneParams.TrySorting = false
ZoneParams.Ignore = {}

local QueryAll = OverlapParams.new()
QueryAll.FilterType = Enum.RaycastFilterType.Include
QueryAll.FilterDescendantsInstances = { workspace.Models }
QueryAll.RespectCanCollide = false
QueryAll.MaxParts = 0
ZoneParams.OverlapParams = QueryAll

ZoneHitbox = HitboxBox.new(ZonePart, ZoneParams)

local function BeginExitWatch(Session, Character)
	print("Beginning exit watch for session:", Session)
	
	DisconnectExitWatch()
	
	CharacterConn = LocalPlayer.CharacterAdded:Connect(function()
		if ZoneSessionId == Session then
			print("Character respawned, cancelling queue.")
			CancelQueue()
		end
	end)
	
	local Params = OverlapParams.new()
	Params.FilterType = Enum.RaycastFilterType.Include
	Params.FilterDescendantsInstances = { Character }
	Params.RespectCanCollide = false
	Params.MaxParts = 0
	
	ExitConn = RunService.Heartbeat:Connect(function()
		if ZoneSessionId ~= Session then
			DisconnectExitWatch()
			return
		end
		
		local Parts = workspace:GetPartBoundsInBox(ZonePart.CFrame, ZonePart.Size + ZoneSizePadding, Params)
		
		if #Parts == 0 then
			print("Player left zone, cancelling queue.")
			CancelQueue()
		end
	end)
end

ZoneHitbox.Events.HumanoidHit:Connect(function(Humanoid)
	if IsQueueing or RequestInFlight then
		return 
	end
	if CurrentMatch ~= nil then 
		return 
	end
	
	local Character = LocalPlayer.Character
	
	if not Character or Humanoid.Parent ~= Character then 
		return 
	end

	local Now = os.clock()
	
	if Now - LastZoneEnterTime < ZoneEnterDebounceTime then
		print("Zone entry debounced.")
		return
	end
	
	LastZoneEnterTime = Now
	print("Player entered matchmaking zone.")
	
	local Session = NextZoneSession()
	
	UpdateMatchmakingStatus(WaitingSentinel, MatchmakingElo)

	RequestInFlight = true
	
	local Success, Reason = ReplicatedStorage.Remotes.Queue.StartMatchmake:InvokeServer("1v1_casual")
	
	RequestInFlight = false

	if not Success then
		ShowErrorMsg(Reason)
		UpdateMatchmakingStatus(nil, MatchmakingElo)
		return
	end

	IsQueueing = true
	LocalQueueSessionId = Session
	BeginExitWatch(Session, Character)
	ZoneHitbox:Reset()
end)

ZoneHitbox:BeginCast()

local FrameIndex = 0
while task.wait(0.25) do
	FrameIndex = (FrameIndex + 1) % 4
	if CurrentMatch == nil or CurrentMatch == WaitingSentinel then
		Status.Label.Text = "Finding a match" .. string.rep(".", FrameIndex) .. string.rep(" ", 3 - FrameIndex)
	else
		local ServerNowAdjustment = DateTime.now().UnixTimestamp + ServerClock
		local Elapsed = 0
		if CurrentMatch and CurrentMatch.CreationTime then
			Elapsed = math.max(0, ServerNowAdjustment - CurrentMatch.CreationTime)
		end
		Status.Label.Text = "Waiting for match" .. string.rep(".", FrameIndex) .. string.rep(" ", 3 - FrameIndex) ..
			string.format(" [%d/%d] (%s) at ELO: %s", #CurrentMatch.Players, CurrentMatch.MaxPlayers, Functions.FormatTime(Elapsed), tostring(MatchmakingElo))
	end
end
