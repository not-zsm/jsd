local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------------------------------------------------------------------------

local BuildPersistent = ReplicatedStorage:WaitForChild("BuildTools");
local BuildShared = BuildPersistent:WaitForChild("Shared");

local Remotes = BuildPersistent.Remotes;
local AnimationsFolder = ReplicatedStorage.Animations;

------------------------------------------------------------------------------------

local Retrieval = {};
Retrieval.animations = nil;
Retrieval.skills = nil;
Retrieval.skillsets = nil;
Retrieval.effects = nil;

function Retrieval.get_effects()
	if Retrieval.effects then
		return Retrieval.effects;
	end;

	Retrieval.effects = {};
	Retrieval.effects = Remotes.Skills.RequestTableEffects:InvokeServer();

	return Retrieval.effects;
end

function Retrieval.get_animations()
	if Retrieval.animations then
		return Retrieval.animations;
	end;
	
	Retrieval.animations = {};
	Retrieval.animations = Remotes.Skills.RequestTableAnimations:InvokeServer();

	return Retrieval.animations;
end

function Retrieval.get_skills()
	if Retrieval.skills then
		return Retrieval.skills;
	end;
	
	Retrieval.skills = {};
	Retrieval.skillsets = {};
	
	Retrieval.skillsets = Remotes.Skills.RequestTableSkills:InvokeServer();
	
	for character, list in Retrieval.skillsets do
		for _, skill in list do
			table.insert( Retrieval.skills, list );
		end;
	end;
	
	return Retrieval.skills;
end

function Retrieval.get_skill_sets()
	Retrieval.get_skills();
	
	return Retrieval.skillsets;
end

------------------------------------------------------------------------------------

return Retrieval;