local ServerScriptService = game:GetService("ServerScriptService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ServerStorage = game:GetService("ServerStorage")
----------------------------------------------------------------------------------

local Remotes = replicatedStorage.Remotes

local Shared = replicatedStorage.modules.shared
local SharedUtilities = Shared.Utilities

----------------------------------------------------------------------------------

local Job = require( SharedUtilities.Job )
local EventService = require( SharedUtilities.EventService )
local Utility = require( SharedUtilities.Utility )

----------------------------------------------------------------------------------

local LuaPlayerList = require( ServerStorage.modules.LuaPlayerList )

----------------------------------------------------------------------------------

local Items = {}
Items.__index = Items

----------------------------------------------------------------------------------

function Items:Destroy()
	self.Job:Destroy()
end

----------------------------------------------------------------------------------

function Items:_Init()
	self.EquippedItem = nil
	self.List = {}
	self.UnusableItems = {}
	
	self.ItemTemplates = {}
	
	for _, ItemModule in ipairs(script.List:GetChildren()) do
		if ItemModule:IsA("ModuleScript") then
			local ItemTemplate = require( ItemModule )
			self.ItemTemplates[ItemModule.Name] = ItemTemplate
		end
	end
end
----------------------------------------------------------------------------------

function Items:_UpdateItemAnimations(Item : Table, Equipped : Bolean, AnimSpeed : Number?)
	if Equipped then
		if Item.Idle then
			Item.Idle:Play(0.1, 1, AnimSpeed)
		else
			local Animator = self.LuaCharacter.Animator
			if Animator then
				local AnimInstance = replicatedStorage.Animations.Items.Idle[Item.Name]
				if AnimInstance then
					if Item.Idle and Item.Idle.IsPlaying then
						Item.Idle:Stop()
					end

					Item.Idle = Animator:LoadAnimation(AnimInstance)
					Item.Idle.Looped = true
					Item.Idle.Priority = Enum.AnimationPriority.Action2
					Item.Idle:Play(0.1, 1, AnimSpeed)

					if Item.Job then
						Item.Job:Task(function()
							if Item and Item.Idle then
								Item.Idle:Stop()
								Item.Idle = nil
							end
						end)
					end
				end
			end
		end
	else
		for _, _Item in ipairs(self.List) do
			if _Item.Idle and _Item.Idle.IsPlaying then
				_Item.Idle:Stop()
			end
		end
	end
end

function Items:HasEquipped(ItemNameList: string): boolean
	local CurrentTool = self.EquippedItem;
	local ToolNames = string.split(ItemNameList, ";");

	if CurrentTool and CurrentTool.Object and table.find(ToolNames, CurrentTool.Object.Name) then
		return true;
	end;
	
	return false;
end

function Items:IsSinked(): boolean
	local Item = self.EquippedItem;
	
	if Item and Item.Object then
		-- Allows for pass through for M1
		return not Item.Object:GetAttribute("DoNotSink");
	end;
	
	return false;
end;

function Items:GetEquippedTool(): Tool?
	if self.EquippedItem then
		return self.EquippedItem.Object;
	end;
	
	return nil;
end

function Items:Give(ItemName : String, Reference: Tool?)
	if self.EquippedItem then
		self.EquippedItem.Object.Parent = self.LuaPlayer.Player.Backpack
	end
	
	local ItemTemplate = self.ItemTemplates[ItemName]
	
	if ItemTemplate then
		local Item = table.clone(ItemTemplate)
		Item.Job = Job.new()
		
		self.Job:Task(function()
			Item.Job:Destroy()
		end)
		
		Item.Job:Task(function()
			if self.EquippedItem == Item then
				self:SetEquipped(nil)
			end
		end)
		
		local Tool = Reference or ItemTemplate.Template:Clone();
		
		Item.Object = Item.Job:Task(Tool)
		Item.Name = Item.Name or ItemName
		
		local Handle = Item.Object:FindFirstChild("Handle")
		if not Handle then
			local Weld = Item.Weld

			if not Weld then
				Weld = Item.Object:FindFirstChild("Weld")
			end

			if not Weld then
				Item.Object.RequiresHandle = true
				warn(`{ItemName} does not have a valid Weld. Make sure one is assigned, or enable Tool.RequiresHandle`)
			else
				-- Assign Part0
				if not Weld.Part1 then
					Weld.Part1 = Item.Object.PrimaryPart
				end

				-- Assign Part1
				local WeldLimbName = Weld:GetAttribute("LimbName")
				
				if WeldLimbName and WeldLimbName ~= "" then
					Weld.Part0 = self.LuaCharacter.Model:FindFirstChild(WeldLimbName)
				else
					Weld.Part0 = self.LuaCharacter.Model["Right Arm"]
				end
			end
		else
			Item.Object.PrimaryPart = Handle
		end
		
		table.insert(self.List, Item) 
		
		if Item.OnPickedUp then
			pcall(Item.OnPickedUp, self, Item)
		end
		
		Item.Job:Task(Item.Object.Equipped:Connect(function()
			self:SetEquipped(Item);
			pcall(Item.Equipped, self);
			
			if Item.IdleAnimation then
				if Item.IdleAnimation == true then
					self:_UpdateItemAnimations(Item, true)
				elseif Item.IdleAnimation == "Manual" then
					Item.StartIdleAnimation = function(_, AnimSpeed)
						Item.IdleAnimation = true
						self:_UpdateItemAnimations(Item, true, AnimSpeed)
					end
				end
			end
		end))
		
		Item.Job:Task(Item.Object.Unequipped:Connect(function()
			self:SetEquipped(nil);
			pcall(Item.Unequipped, self);
			
			if Item.IdleAnimation and Item.IdleAnimation == true then
				self:_UpdateItemAnimations(Item, false)
			end
		end))
		
		Item.Job:Task(Item.Object.Activated:Connect(function()
			if not self.UnusableItems[ItemName] then
				pcall(Item.Triggered, self)
			end
		end))
		
		-- Player Drops Item
		Item.Job:Task(Item.Object.AncestryChanged:Connect(function(Child, Parent)
			if Parent == workspace then
				self:Drop(Item, ItemName)
			end
		end))
		
		-- If Player Dies
		local DeathConnection
		DeathConnection = self.LuaCharacter.OnHumanoidAvailabilityChanged:Connect(function(Value : boolean)
			if not Value then
				self:Drop(Item)
				DeathConnection:Disconnect()
				DeathConnection = nil
			end
		end)
		Item.Job:Task(DeathConnection)
		
		-- If Player Leaves
		Item.Job:Task(self.LuaPlayer.OnDestroyed:Connect(function()
			self:Drop(Item)
		end));
		
		Item.Object.Parent = self.LuaCharacter.Model;
		
		self:SetEquipped(Item);
		
		return Item
	end
end

function Items:Drop(Item : Tool)
	local Template = Item.Template;
	
	if Template and Template.PrimaryPart and Template.PrimaryPart:FindFirstChild("ProximityPrompt") then
		local DroppedTool = Item.Template:Clone()
		local Prompt : ProximityPrompt = DroppedTool.PrimaryPart.ProximityPrompt
		Prompt.Enabled = true
		
		local Hitbox = DroppedTool:FindFirstChild("Hitbox")
		if not Hitbox then
			Hitbox = DroppedTool.PrimaryPart
		end
		
		DroppedTool.Parent = workspace.Visuals
		DroppedTool.PrimaryPart.CFrame = self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 5, -1.5)
		Hitbox.CanCollide = true
		Hitbox.CollisionGroup = "NoPlayerCollision"
		
		local TriggerConnection
		TriggerConnection = Prompt.Triggered:Connect(function(Player)
			local LuaPlayer = LuaPlayerList.LuaPlayers[Player]
			if #LuaPlayer.Character.Items.List >= 3 then
				return
			end
			
			TriggerConnection:Disconnect()
			TriggerConnection = nil

			DroppedTool:Destroy()
			LuaPlayer.Character.Items:Give(Item.Name)
		end)
	end
	
	self:Remove(Item)
end;

function Items:SetEquipped(Item)
	local CurrentItem = self.EquippedItem;
	
	if CurrentItem ~= Item then
		self.EquippedItem = Item;
		self.OnEquipChanged:Fire(Item, CurrentItem);
	end;
end;

function Items:Remove(Item)
	if not Item then return end
	
	local Index = table.find(self.List, Item);
	
	if Index then
		table.remove(self.List, Index);
	end;
	
	Item.Job:Destroy();
end;

function Items:LockItems(Lock : boolean, UnequippCurrent : boolean?)
	if Lock ~= false then
		self.LuaCharacter.Model:SetAttribute("FreezeHotbar", true)
	else
		self.LuaCharacter.Model:SetAttribute("FreezeHotbar", false)
	end
	
	if UnequippCurrent then
		local Tool = self:GetEquippedTool();
		
		if Tool then
			Tool.Parent = self.LuaPlayer.Player.Backpack
		end
	end
end

----------------------------------------------------------------------------------

function Items.new(LuaCharacter)
	local self = setmetatable({}, Items)
	
	self.Job = Job.new()

	self.LuaCharacter = LuaCharacter
	self.LuaPlayer = LuaCharacter.LuaPlayer
	self.Combat = self.LuaCharacter.Combat
	self.UseMove = require( script.UseMove )
	self.OnEquipChanged = self.Job:Task(EventService.new());
	----------------------------------------
	
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Items)

return Items