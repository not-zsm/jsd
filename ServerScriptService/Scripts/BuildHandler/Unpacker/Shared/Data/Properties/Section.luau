local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Table = require( ReplicatedStorage.Packages.Table )

local Sections = {
	Data = {
		Title = "Data";
		LayoutOrder = 2;
	};
	Appearance = {
		Title = "Appearance";
		LayoutOrder = 1;
	};
	Transform = {
		Title = "Transform";
		LayoutOrder = 3;
	};
	Behaviour = {
		Title = "Behaviour";
		LayoutOrder = 4;
	};
	Collision = {
		Title = "Collision";
		LayoutOrder = 5;
	};
	Part = {
		Title = "Part";
		LayoutOrder = 6;
	};
	Asset = {
		Title = "Asset";
		LayoutOrder = 5;
	};
	Playback = {
		Title = "Playback";
		LayoutOrder = 6;
	};
	Assembly = {
		Title = "Assembly";
		LayoutOrder = 7;
	};
	Teams = {
		Title = "Teams";
		LayoutOrder = 8;
	};
};

return {
	Class = {};
	Any = {
		[Sections.Appearance] = Table.bool_map {
			"BrickColor", "CastShadow", "Color", "Color3", "Material", "Reflectance", "Transparency",
			"Enabled", "LightEmission", "LightInfluence", "Texture", "TextureLength", "TextureMode", "TextureSpeed", "ZOffset", "ZIndex"
		};
		[Sections.Data] = Table.bool_map {
			"Archivable", "ClassName", "Locked", "Name", "Parent",
			"Face"
		};
		[Sections.Transform] = Table.bool_map {
			"Size", "CFrame"
		};
		[Sections.Behaviour] = Table.bool_map {
			"EnableFluidForces", 
			"PlayOnRemove"
		};
		[Sections.Collision] = Table.bool_map {
			"CanCollide", 
		};
		[Sections.Part] = Table.bool_map {
			"Anchored", "Massless", "Shape"
		};
		[Sections.Asset] = Table.bool_map {
			"SoundId"
		};
		[Sections.Playback] = Table.bool_map {
			"Looped", "PlaybackSpeed", "Playing", "TimePosition", "Volume"
		};
		[Sections.Assembly] = Table.bool_map {
			"AssemblyLinearVelocity", "AssemblyAngularVelocity",
		};
		[Sections.Teams] = Table.bool_map {
			"TeamColor", "Neutral", "AllowTeamChangeOnTouch"
		};
	};
};