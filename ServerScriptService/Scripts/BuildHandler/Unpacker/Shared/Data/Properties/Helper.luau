local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asset = require( ReplicatedStorage.Packages.Asset )

return {
	["Decal"] = {
		Texture = Asset.get_decal_id,
	};
	["ParticleEmitter"] = {
		Texture = Asset.get_decal_id,
	};
	["Beam"] = {
		Texture = Asset.get_decal_id,
	};
	["Trail"] = {
		Texture = Asset.get_decal_id,
	};
	["Sound"] = {
		SoundId = Asset.get_rbx_asset,
	};
	["MeshPart"] = {
		MeshId = Asset.get_rbx_asset,
		TextureId = Asset.get_rbx_asset,
	};
	["SpecialMesh"] = {
		MeshId = Asset.get_rbx_asset,
		TextureId = Asset.get_rbx_asset,
	};
	["Sky"] = {
		SunTextureId = Asset.get_decal_id,
		MoonTextureId = Asset.get_decal_id,
		
		SkyboxBk = Asset.get_decal_id,
		SkyboxDn = Asset.get_decal_id,
		SkyboxFt = Asset.get_decal_id,
		SkyboxLf = Asset.get_decal_id,
		SkyboxRt = Asset.get_decal_id,
		SkyboxUp = Asset.get_decal_id,
	};
}