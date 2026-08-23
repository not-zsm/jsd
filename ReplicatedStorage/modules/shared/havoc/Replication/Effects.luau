local Material = {};
local Placeholder = script.Placeholder;

function Material.get_weighted(folder: Instance): Instance?
	local items = {};
	local total_weight = 0;

	for _, item in folder:GetChildren() do
		local weight = item:GetAttribute("Weight") or 1;

		items[item] = weight;
		total_weight += weight;
	end;

	local value = math.random() * total_weight;

	for item, weight in items do
		total_weight -= weight;

		if value >= total_weight then
			return item;
		end;
	end;

	return;
end

function Material.get_assets(material: Enum.Material?): typeof(Placeholder)
	if not material then
		material = Enum.Material.Plastic;
	end;

	local assets = script:FindFirstChild(material.Name);

	if assets and assets:IsA("ObjectValue") then
		assets = assets.Value;
	end;

	return assets or Placeholder;
end

function Material.get_audio_from_material(material: Enum.Material): Sound?
	local assets = Material.get_assets(material);
	local sound = Material.get_weighted(assets:FindFirstChild("Audio") or Placeholder.Audio);

	if sound and sound:IsA("Sound") then
		return sound;
	end

	return nil;
end

function Material.get_from_material(material: Enum.Material, folder: string): Folder
	return Material.get_assets(material):FindFirstChild(folder) or Placeholder[folder];
end

function Material.create_audio(material: Enum.Material): Sound
	local sound = Material.get_audio_from_material(material);

	if not sound then
		sound = Instance.new("Sound");
		sound.Name = "Unknown";
	else
		sound = sound:Clone();
	end;

	assert(sound, "No sound could be created");

	sound.PlaybackSpeed = 0.95 + math.random() * 0.125;
	sound.Volume *= 0.95 + math.random() * 0.125;
	sound.Archivable = false;

	return sound;
end

return Material;