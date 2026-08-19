local MarketplaceService = game:GetService("MarketplaceService")
local AvatarEditorService = game:GetService("AvatarEditorService")
local InsertService = game:GetService("InsertService")
local RunService = game:GetService("RunService")

local product_cache = {};
local item_detail_cache = {};

export type ProductInfo = {
	AssetTypeId: number,
	TargetId: number,
	IsNew: boolean,
	Updated: string,
	AssetId: number,
	ProductId: number,
	MinimumMembershipLevel: number,
	Created: string,
	Creator: {
		Name: string,
		CreatorTargetId: number,
		Id: number,
		HasVerifiedBadge: boolean,
		CreatorType: string,
	},
	IsLimited: boolean,
	ContentRatingTypeId: number,
	Sales: number,
	IsPublicDomain: boolean,
	Name: string,
	IsForSale: boolean,
	Description: string,
	IconImageAssetId: number,
	IsLimitedUnique: boolean,
}

local Asset = {};
Asset.cached_images = {_n = 0};
Asset.cached_animations = {_n = 0};
Asset.num_of_cached_images = 0;

local function cache_item(cache: any, id: string, result: string): string
	assert(id ~= "_n", "Bad Id");
	
	if not cache[id] then
		-- Makes room for newer cache results.
		if cache._n > 500 then
			for index, old_id in cache do
				if index == "_n" then
					continue;
				end;
				
				cache[old_id] = nil;
				cache._n -= 1;
				break;
			end;
		end
		
		cache[id] = result;
		cache._n += 1;
	end;
	
	return result;
end

local function decal_to_image(decal_id: number): string
	local success, asset = pcall(InsertService.LoadAsset, InsertService, decal_id);

	if success then
		local decal = asset:FindFirstChildWhichIsA("Decal");
		
		if decal then
			local id = decal.Texture:match("%d+");
			
			if id then
				return `rbxassetid://{id}`;
			else
				return decal.Texture;
			end;
		end;
	else
		return Asset.get_thumbnail(decal_id);
	end

	return ""; -- No image
end;

local function animation_to_track(animation_id: number): string
	local success, asset = pcall(InsertService.LoadAsset, InsertService, animation_id);
	
	if success then
		local animation = asset:FindFirstChildWhichIsA("Animation");
		
		if animation then
			local id = animation.AnimationId:match("%d+");

			if id then
				return `rbxassetid://{id}`;
			else
				return animation.AnimationId;
			end;
		end;
	end

	return ""; -- No animation
end

local function get_asset_id(asset: string): string?
	asset = asset:lower() -- Makes the match case-insensitive by lowercasing everything

	local id = asset:match("^(%d+)$") or -- DECAL_ID
		asset:match("^rbxassetid://(%d+)$") or -- rbxassetid://DECAL_ID
		asset:match("^http://www%.roblox%.com/asset/%?id=(%d+)$") or -- http://www.roblox.com/asset/?id=DECAL_ID
		asset:match("^https://www%.roblox%.com/library/(%d+)") or -- https://www.roblox.com/library/DECAL_ID
		asset:match("^https://create%.roblox%.com/marketplace/asset/(%d+)") -- https://create.roblox.com/marketplace/asset/DECAL_ID
	
	return id;
end

function Asset.get_thumbnail(asset_id: number, width: number?, height: number?): string
	return `rbxthumb://type=Asset&id={asset_id}&w={width or 420}&h={height or 420}`;
end

function Asset.get_asset_id(asset: string | number): string?
	if typeof(asset) == "number" then
		return get_asset_id( tostring(asset) );
	end
	
	return get_asset_id(asset);
end

function Asset.get_rbx_asset(asset: string | number): string
	if tonumber(asset) then
		return `rbxassetid://{tonumber(asset)}`;
		
	elseif typeof(asset) == "string" then
		return asset;
	end
	
	return "";
end;

function Asset.get_decal_id(asset: string): string
	local asset_id = get_asset_id(asset);

	if asset_id then
		local image_cached = Asset.cached_images[asset_id];
		
		if image_cached then
			return image_cached;
		end;
		
		local success, product_info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, asset_id)
		local asset_type_id = product_info.AssetTypeId
		
		if success then
			if asset_type_id == Enum.AssetType.Decal.Value then
				return cache_item(Asset.cached_images, asset_id, decal_to_image(asset_id));

			elseif asset_type_id == Enum.AssetType.Image.Value then
				return cache_item(Asset.cached_images, asset_id, `rbxassetid://{asset_id}`)
			end;
		else
			warn("Unable to fetch decal product:", product_info);
		end;
	end;

	return "";
end;

function Asset.get_animation_id(asset: string): string
	assert(RunService:IsServer(), "Animation assets can only be loaded from the Server");
	
	local asset_id = get_asset_id(asset);

	if asset_id then
		local animation_cached = Asset.cached_animations[asset_id];

		if animation_cached then
			return animation_cached;
		end;
		
		local success, product_info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, asset_id)
		
		if success then
			if product_info.AssetTypeId == Enum.AssetType.EmoteAnimation.Value then
				return cache_item(Asset.cached_animations, asset_id, animation_to_track(asset_id));
			end;
		else
			warn("Unable to fetch animation product:", product_info);
		end;
	end;
	
	return "";
end;


-- Converts a table (data) to a Lua type definition (Use for automatically defining a type for GetProductInfo and that)
function Asset.get_lua_type_definition(type_name: string, data: any): string
	local build: {string} = {};
	table.insert(build, `export type {type_name} = \{\n`);
	
	local function recursive_type_define(main_table, nest_table): ()
		local directory: {string} = {};
		
		for key, value in nest_table do
			if typeof(value) == "table" then
				table.insert(directory, `\t{key}: \{`);
				recursive_type_define(directory, value);
				table.insert(directory, `\},`);
			else
				table.insert(directory, `\t{key}: {typeof(value)},`);
			end
		end;
		
		table.insert(main_table, table.concat(directory, `\n`));
	end;
	
	recursive_type_define(build, data);
	table.insert(build, `\n\}`);
	
	return table.concat(build);
end;


-- Returns and caches the result of <code>MarketplaceService:GetProductInfo(asset_id)</code>
-- Cache is invalidated after <code>'cache_invalidation_period'</code> seconds (default 480), and will be refetched on the next call to the same <code>'asset_id'</code>.
function Asset.get_product_details(asset_id: number, cache_invalidation_period: number?): ProductInfo?
	local cache = product_cache[asset_id];
	local tick_now = tick();

	if cache and tick_now - cache.tick < cache.warmth then
		return cache.value;
	end;

	local success, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, asset_id);

	if success then
		product_cache[asset_id] = {
			warmth = cache_invalidation_period or 480,
			tick = tick_now;
			value = info;
		};
		
		return info;
	else
		warn(`Unable to retrieve marketplace info for {asset_id}: {info}`);
	end;

	return nil;
end;

function Asset.get_item_details_from_cache(asset_id: number, item_type: Enum.AvatarItemType): any
	if not item_detail_cache[item_type] then
		return nil;
	end;

	return item_detail_cache[item_type][asset_id];
end;

function Asset.get_item_details(asset_id: number, item_type: Enum.AvatarItemType): any
	local detail_list = Asset.get_batch_item_details({asset_id}, item_type);

	if detail_list then
		return detail_list[asset_id];
	end;

	return nil;
end

function Asset.get_batch_item_details(asset_ids: {number}, item_type: Enum.AvatarItemType): {[number]: any}?
	local to_fetch_asset_ids = {};
	local to_reflect_asset_ids = {};
	local tick_now = tick();

	if not item_detail_cache[item_type] then
		item_detail_cache[item_type] = {};
	end;

	for _, asset_id in asset_ids do
		local cache = item_detail_cache[item_type][asset_id];

		if (cache and tick_now - cache.tick < cache.warmth) then
			table.insert(to_reflect_asset_ids, asset_id);
		else
			table.insert(to_fetch_asset_ids, asset_id);
		end;
	end;

	local success: boolean = true;
	local info: any = nil;

	if #to_fetch_asset_ids > 0 then
		success, info = pcall(AvatarEditorService.GetBatchItemDetails, AvatarEditorService, to_fetch_asset_ids, item_type);
	end;

	if success then
		local details = {};

		for _, asset_id in to_reflect_asset_ids do
			details[asset_id] = item_detail_cache[item_type][asset_id].value;
		end;

		for index, asset_id in to_fetch_asset_ids do
			details[asset_id] = info[index];

			item_detail_cache[item_type][asset_id] = {
				warmth = math.huge,
				tick = tick_now,
				value = info[index];
			};
		end;

		return details;
	else
		warn(`Unable to retrieve item details info for given assets: {info}`);
	end;

	return nil;
end

-- Returns a nice number that displays as a float upto the given precision, truncating ending with zeros.
@native function Asset.display_number(value: number, precision: number): string
	return string.gsub(string.format(`%.{precision}f`, value), "%.?0+$", "");
end;

@native function Asset.display_number_spaced(value: string | number): string
	local num_value: number = tonumber(value);
	local str_value: string = tostring(value);
	local integral_part: number = math.floor(num_value);
	
	local result = string.gsub(string.gsub((string.reverse(string.gsub(string.reverse(tostring(integral_part)), "(%d%d%d)","%1,")) .. (string.match(str_value, "%.%d+") or "")), "^,", ""), "^(%-),", "%1")
	
	return result;
end

@native function Asset.pretty_string(str: string): string
	return string.gsub(string.gsub(str, "(%u)", " %1"), "^%s", "")
end

@native function Asset.pretty_number(value: number, precision: number?): string

	if precision then
		local parts = string.split( Asset.display_number(value, precision) , ".");
		
		parts[1] = Asset.display_number_spaced( parts[1] );
		
		return table.concat(parts, ".");
	end;
	
	return Asset.display_number_spaced( math.floor(value) );
end

-- Only for durations under 60 minutes
@native function Asset.pretty_time(value: number): string
	return string.format("%d:%02d", value / 60, value % 60);
end;

return Asset;