--[[
	Only run in the command line! if you rely on this during runtime, the serialiser will confuse different parts!
	If you add more parts, existing AssetLink'd parts will retain their id, so you can use this multiple times without worry.
	All this is too make UnionOperations and MeshParts serialise without worry in all scenairos even if users modify the part itself.
	Uncomment the lines below and run in the command line to compile the AssetLink
-- ]]

local Reidentify = {};

function Reidentify.get_inventory_asset_links(inventory: Instance)
	local identified = {};

	for _, instance in inventory:GetDescendants() do
		if instance:IsA("MeshPart") or instance:IsA("UnionOperation") then
			table.insert(identified, instance);
		end;
	end;

	return identified;
end

function Reidentify.identify_inventory(inventory: Instance)
	local identified = {};
	local to_id = {};
	local current_id = 0;

	for _, instance in Reidentify.get_inventory_asset_links(inventory) do
		if instance:GetAttribute("AssetLink") then
			current_id += 1;
		else
			table.insert(to_id, instance);
		end;
	end

	return to_id, current_id;
end


function Reidentify.link_inventory(inventory: Instance)
	local to_identify, current_id = Reidentify.identify_inventory(inventory);

	for _, instance in to_identify do
		current_id += 1;
		instance:SetAttribute("AssetLink", current_id);
	end;
end

-- Run this in the command line:
-- require(game.ServerScriptService:FindFirstChild("Reidentify", true)).link_inventory(game.ServerScriptService.BuildHandler.Unpacker.Shared.Assets.Build.Inventory);

-------------------------------------------------------

return Reidentify;