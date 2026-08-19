local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

--------------------------------------------------------------------------

local Observer = require( ReplicatedStorage.Packages.Observer );
local Maid = require( ReplicatedStorage.Packages.Maid );
local Fruits = require( script.List );

--------------------------------------------------------------------------

local Player = Players.LocalPlayer;
local Rnd = Random.new();

--------------------------------------------------------------------------

local PlayerGui: typeof(StarterGui) = Player:WaitForChild("PlayerGui")
local Assets = script:WaitForChild("Assets");

--------------------------------------------------------------------------

local Gui = Assets:WaitForChild("FruitUI"):Clone();
Gui.Parent = PlayerGui;

--------------------------------------------------------------------------

local function ball_rnd(value: number): number
	return Rnd:NextNumber(-value / 2, value / 2);
end

local function add_fruity(ball: BasePart)
	local fruit = Fruits[math.random(#Fruits)];

	for _, child in ball:GetChildren() do
		if child:IsA("Decal") then
			child.Texture = fruit.AssetId;
		end
	end
	
	return fruit;
end

local function spawn_ball(spawner: BasePart)
	local extents = spawner.CFrame:VectorToWorldSpace(spawner.Size):Abs();

	local ball = Assets.Ball:Clone();
	ball.CFrame = spawner.CFrame * CFrame.new(ball_rnd(extents.X), ball_rnd(extents.Y), ball_rnd(extents.Z))
	ball.LinearVelocity.VectorVelocity = -ball.CFrame.LookVector * 300 + Vector3.yAxis * 15;
	ball.Archivable = false;
	
	Debris:AddItem(ball.LinearVelocity, 0.1)
	Debris:AddItem(ball, 1);

	ball.Parent = workspace:FindFirstChild("Visuals") or workspace.Terrain;
end

--------------------------------------------------------------------------

Observer.observe_tag("JumpscareBall", function(ball: BasePart)
	local fruit = add_fruity(ball);

	local touched = ball.Touched:Connect(function(part)
		if Player.Character:HasTag("FruityImmune") then return end;

		if part:IsDescendantOf(Player.Character) and not Gui.Jumpscare.Visible then
			Gui.Jumpscare.Visible = true;
			Gui.Jumpscare.Image = fruit.AssetId;
			
			local sound = Assets.Sounds:FindFirstChild(fruit.Name);
			
			if sound then
				SoundService:PlayLocalSound(sound);
			end;
			
			task.delay(fruit.Duration, function()
				Gui.Jumpscare.Visible = false;
			end)
		end
	end)

	return function()
		touched:Disconnect();
	end
end)

Observer.observe_tag("BallSpawner", function(spawner: Instance)
	local maid = Maid.new();
	local spawner_part = if spawner:IsA("BasePart") then spawner else spawner:FindFirstAncestorWhichIsA("BasePart");
	
	if spawner_part then
		local in_distance = false;
		
		maid:add(task.spawn(function()
			while spawner_part do
				in_distance = Player:DistanceFromCharacter(spawner_part.Position) < 500;
				task.wait(0.50);
			end
		end))
		
		local thread = maid:add(task.spawn(function()
			while task.wait(0.05) do
				if in_distance then
					spawn_ball(spawner_part);
				end;
			end
		end))
	end;

	return function()
		maid:destroy();
	end;
end);

--------------------------------------------------------------------------

local Main = {};

table.freeze(Main);

return Main;