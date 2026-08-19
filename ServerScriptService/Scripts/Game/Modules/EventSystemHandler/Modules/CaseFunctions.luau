local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

return {
	DropCase = function(self, Type, Ended)
		if not self.CaseHolder then 
			return 
		end

		self.PickupMaid = self.Maid:limb()
		self.CaseHolder:SetAttribute("HoldingCrate", false)

		local LuaPlayer = self.System.LuaPlayers[self.CaseHolder]

		if not Ended and LuaPlayer then
			if Type == "DeadDrop" then
				LuaPlayer.Replication:FireReliableVFXToSelf("WorldEvents/DeadDrop", "EquipCrate", false)
			elseif Type == "HotProperty" then
				LuaPlayer.Replication:FireReliableVFXToSelf("WorldEvents/HotProperty", "EquipCrate", false)
			end
		end

		if self.CaseHolderMaid then
			self.CaseHolderMaid:destroy()
			self.CaseHolderMaid = nil
		end

		local Weld = self.Case:FindFirstChildOfClass("WeldConstraint")
		if Weld then
			Weld:Destroy()
		end

		self.Case.Anchored = true
		self.Case.CFrame *= CFrame.new(0, 0, -1.75)

		--local HumanoidRootPart = self.CaseHolder.Character and self.CaseHolder.Character:FindFirstChild("HumanoidRootPart")
		--local ExcludeParts = { self.Case }

		--if HumanoidRootPart then
		--	for _, Limb in pairs(self.CaseHolder.Character:GetChildren()) do
		--		if Limb:IsA("Part") then
		--			table.insert(ExcludeParts, Limb)
		--		end
		--	end
		--end

		--local Params = RaycastParams.new()
		--Params.FilterType = Enum.RaycastFilterType.Exclude
		--Params.FilterDescendantsInstances = ExcludeParts

		local RaycastResult = workspace:Raycast(self.Case.Position, Vector3.new(0, -1, 0) * 500, Utility.VisualParams)

		if RaycastResult then
			self.Case.CFrame = CFrame.new(RaycastResult.Position) * CFrame.new(0, 1.25, 0)
		else
			self.Case.CFrame = self.Case.CFrame * CFrame.new(0, -1.75, 0)
		end

		self.Case.CollisionGroup = "NoPlayerCollision"
		self.Case.CanCollide = true

		self.PickupMaid:add(task.delay(0.5, function()
			self.Case.CollisionGroup = "Default"
		end))

		local Prompt = self.Case:FindFirstChild("ProximityPrompt")
		if Prompt then Prompt.Enabled = true end

		self.CaseHolder = nil

		if Type == "HotProperty" then
			self.CaseHolderStartTime = nil
		end
	end,

	HandleCasePickup = function(self, Type, Player)
		if self.CaseHolder then
			return -- Case is already being held
		end

		local Character = Player.Character
		local Torso = Character:FindFirstChild("Torso") or Character:FindFirstChild("HumanoidRootPart")

		if self.PickupMaid then
			self.PickupMaid:destroy()
			self.PickupMaid = nil
		end

		Player:SetAttribute("HoldingCrate", true)

		local CasePrompt = self.Case:FindFirstChild("ProximityPrompt")
		CasePrompt.Enabled = false

		-- Weld the case to the player's back
		self.Case.CanCollide = false
		self.Case.Anchored = false
		self.Case.CFrame = Torso.CFrame * CFrame.new(0, 0, 1.75)

		local Weld = Instance.new("WeldConstraint")
		Weld.Part0 = Torso
		Weld.Part1 = self.Case
		Weld.Parent = self.Case
		self.Maid:add(Weld)

		if self.Case.PickupSound then
			self.Case.PickupSound:Play()
		end

		self.CaseHolderMaid = self.Maid:limb()

		local LuaPlayer = self.System.LuaPlayers[Player]

		if Type == "DeadDrop" then
			LuaPlayer.Replication:FireReliableVFXToSelf("WorldEvents/DeadDrop", "EquipCrate", true, self.DealerNPC.Head.HairAttachment)

		elseif Type == "HotProperty" then
			LuaPlayer.Replication:FireReliableVFXToSelf("WorldEvents/HotProperty", "EquipCrate", true, (self.EndTime))
		end

		-- Drop Case
		self.CaseHolderMaid:add(LuaPlayer.Character.Combat.OnStateChanged:Connect(function(State, Value)
			if (State == "Stunned" or State == "Ragdolled") and Value then
				self:DropCase()
			end
		end))

		-- If Player Switches Characters
		self.CaseHolderMaid:add(LuaPlayer.Character.Combat.OnCharacterSwitching:Connect(function()
			self:DropCase()
		end))

		-- If Player Dies
		self.CaseHolderMaid:add(LuaPlayer.Character.OnHumanoidAvailabilityChanged:Connect(function(Value : boolean)
			if not Value then
				self:DropCase()
			end
		end))

		-- If Player Leaves
		self.CaseHolderMaid:add(LuaPlayer.OnDestroyed:Connect(function()
			print("Player Left?")
			self:DropCase()
		end))

		self.CaseHolder = Player
	end,
}