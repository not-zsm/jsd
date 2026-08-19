local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local BaseAttack = require( "./BaseAttack" );
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local Preloading = require( ReplicatedStorage.Modules.Preloading )

-- I usually avoid using multi-inheritance but whatever
local BaseStand = setmetatable({}, BaseAttack);
BaseStand.__index = BaseStand;

function BaseStand:MoveStand(CF : CFrame, Time : number)
	Time = (Time or 0.5)

	Utility.CloseThreadSafe(self.ServerC0Reset)

	self:FireReliableVFX(self.NameVFX, "Move", self.LuaCharacter.Model, CF, Time)
	
	if (Time == 0) then
		self.ServerC0Reset = nil
		self.Weld.C0 = CF
	else
		self.ServerC0Reset = task.delay(Time, function()
			self.ServerC0Reset = nil
			self.Weld.C0 = CF
		end)
	end;
end;

function BaseStand:MoveStandByAction(Action : string, ...)
	if Action == "Idle" then
		self:MoveStand(self.IdleCF, ...)

	elseif Action == "Attack" then
		self:MoveStand(CFrame.new(0, 0, 3), ...)
		
	elseif Action == "Rest" then
		self:MoveStand(CFrame.new(0, 1, 0.25), ...)
	end
end

function BaseStand:CreateAura(Model : Model)
	if not self.Assets:FindFirstChild("Aura") then
		return warn("No Aura folder in assets");
	end;
	
	for _, Limb in ipairs(Model:GetChildren()) do
		if not Limb:IsA("BasePart") or Limb.Name == "HumanoidRootPart" then
			continue
		end

		for _, Aura in ipairs(self.Assets.Aura:GetChildren()) do
			if Aura:IsA("ParticleEmitter") then
				local NewAura = Aura:Clone()
				NewAura.Enabled = false;
				NewAura.Parent = Limb;
				
				self.Auras[NewAura] = true
			end
		end
	end
end

function BaseStand:UpdateAnimations()
	table.clear(self.Animations)

	for _, AttackFolder in ipairs(ReplicatedStorage.Animations.Attacks:GetDescendants()) do
		if AttackFolder:IsA("Folder") and AttackFolder.Name == self.Directory.Name then
			self.AttackFolder = AttackFolder

			Preloading.Add(self.LuaPlayer.Player, AttackFolder)
			self.Combat:IterateThroughAnimationFolder(self.Animations, AttackFolder, self.Animator)

			break
		end;
	end;
end;

function BaseStand:SetAuraVisible(Value: boolean)
	for Aura in self.Auras do
		Aura.Enabled = Value;
	end;
end;

function BaseStand:UpdateMoveset()
	local Info = self.Combat.CurrentCharacter.Info;
	
	--if Info.Ultimate and Info.Ultimate.Attacks then
	--	for AttackName : string in Info.Ultimate.Attacks do
	--		local Attack = self.Combat:GetFirstAttack(AttackName);

	--		if Attack then
	--			Attack:SetEnabled(self.Summoned);
	--		end;
	--	end;
	--end;
	
	if Info.StandOnAttacks then
		for AttackName : string in Info.StandOnAttacks do
			local Attack = self.Combat:GetFirstAttack(AttackName);
			
			if Attack then
				Attack:SetEnabled(self.Summoned);
			end;
		end;
	end;
	
	if Info.StandOffAttacks then
		for AttackName : string in Info.StandOffAttacks do
			local Attack = self.Combat:GetFirstAttack(AttackName);

			if Attack then
				Attack:SetEnabled(not self.Summoned);
			end;
		end;
	end;
end;

function BaseStand:SetModelVisible(Value: boolean): ()
	local Transparency = if Value then 0 else 1;
	
	for _, Item: Instance in self.Model:GetDescendants() do
		if Item:GetAttribute("Invisible") then
			continue;
		end;
		
		if Item:IsA("BasePart") and (Item.Name ~= "HumanoidRootPart") then
			Item.Transparency = Transparency;

		elseif Item:IsA("Decal") then
			Item.Transparency = Transparency;
		end;
	end;
end

function BaseStand:Summon()
	if self.Summoned then return end;
	
	self.Summoned = true;
	self.Combat:StackState("StandSummoned", true);
	
	--if self.LuaCharacter.HumanoidAlive then
	self:FireReliableVFX(self.NameVFX, "Summon", self.LuaCharacter.Model);
	
	self:SetAuraVisible(true);
	self:MoveStandByAction("Idle");
	self:UpdateMoveset();
	
	--else
	--	self.Job:Task(self.LuaCharacter.OnHumanoidAvailabilityChanged:Connect(function(Value : boolean)
	--		if Value then
	--			self:FireReliableVFX(self.NameVFX, "Summon", self.LuaCharacter.Model)
	--		end;
	--	end))
	--end;
end;

function BaseStand:Unsummon()
	if not self.Summoned then return end;
	
	self.Summoned = false;
	self.Combat:StackState("StandSummoned", false);
	
	self:FireReliableVFX(self.NameVFX, "Unsummon", self.LuaCharacter.Model);
	
	self:SetAuraVisible(false);
	self:MoveStandByAction("Rest");
	self:UpdateMoveset();
end;

function BaseStand:CreateModel(Model)
	self.Model = Model:Clone();
	self.Model.Name = "Stand";
	
	self.RootPart = self.Model:WaitForChild("HumanoidRootPart")
	self.Humanoid = self.Model:WaitForChild("Humanoid")
	self.Animator = self.Humanoid:WaitForChild("Animator")
	
	self.Weld = Instance.new("Motor6D", self.RootPart)
	self.Weld.Name = "Mover"
	self.Weld.Part0 = self.RootPart
	self.Weld.Part1 = self.LuaCharacter.RootPart
	self.Weld.C0 = self.IdleCF

	self.Weld:AddTag("StandJoint")
	self.Weld:SetAttribute("Aggression", 0.04)
	self.Weld:SetAttribute("Speed", 10)
	self.Weld:SetAttribute("Offset", CFrame.identity)
	
	self:CreateAura(self.LuaCharacter.Model);
	self:CreateAura(self.Model);
	
	self.Job:Task(self.Model)
	
	self.Job:Task(function()
		for Aura : ParticleEmitter in self.Auras do
			Aura:Destroy()
		end

		table.clear(self.Auras)
	end)
	
	self.Job:Task(Players.PlayerAdded:Connect(function(Player)
		self:FireReliableVFXTo(Player, self.NameVFX, "StandShown", self.LuaCharacter.Model, self.Summoned);
	end))
	
	self:MoveStandByAction("Rest");
	self:SetModelVisible(false);
	
	self.Model.Parent = self.LuaCharacter.Model;
end;

function BaseStand:Initialise()
	if not self.NameVFX then
		self.NameVFX = `{self.Name}/Stand`;
	end;
	
	self:CreateModel( self.Assets.Model );
	
	if self.Combat.CurrentCharacter.Info.StandOnAttacks then
		
		if self.Combat.CurrentCharacter.Info.StandOffAttacks then
			for Name, Key in self.Combat.CurrentCharacter.Info.StandOffAttacks do
				local Attack = self.Combat:CreateAttack(Name, Key);
				Attack.RemoveOnSpawn = true;
				Attack:SetEnabled(not self.Summoned);
			end;
		end;
		
		for Name, Key in self.Combat.CurrentCharacter.Info.StandOnAttacks do
			local Attack = self.Combat:CreateAttack(Name, Key);
			Attack.RemoveOnSpawn = true;
			Attack:SetEnabled(self.Summoned);
		end;
	end;
end;

function BaseStand.new(...)
	local self = setmetatable(BaseAttack.new(...), BaseStand);
	
	self.Summoned = false;
	self.IdleCF = CFrame.new(-1.5, -1, -1.5)
	self.Assets = script;
	self.Auras = {};
	
	return self;
end;

table.freeze(BaseStand);

return BaseStand;