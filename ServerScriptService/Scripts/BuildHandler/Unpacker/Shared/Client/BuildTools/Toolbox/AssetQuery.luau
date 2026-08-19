local InsertService = game:GetService("InsertService")
local AssetService = game:GetService("AssetService")

---------------------------------------------------------------------

local VALID_QUERY_TYPES = {
	[Enum.AssetType.Audio] = true,
	[Enum.AssetType.Model] = true,
	[Enum.AssetType.Decal] = true,
};

---------------------------------------------------------------------

local PagesWrapper = {};
PagesWrapper.__index = PagesWrapper;

function PagesWrapper:AdvanceToNextPageAsync()
	if self.Pages then
		return self.Pages:AdvanceToNextPageAsync();
	end;
	
	self.Index += 1;
end

function PagesWrapper:GetCurrentPage()
	if self.Pages then
		return self.Pages:GetCurrentPage();
	end;
	
	if not self.Cached[self.Index] then
		local success, result = pcall(self.Getter, self.Index);
		
		if success then
			self.Cached[self.Index] = result;
		end;
	end;
	
	return self.Cached[self.Index];
end

function PagesWrapper.new(Pages, Query)
	local self = setmetatable(
		{
			Pages = Pages;
			Index = 0;
			Query = Query or {};
			
			Cached = nil,
			Getter = nil,
		}, 
		PagesWrapper)
	
	return self;
end

function PagesWrapper.psuedo(Query, Getter)
	local self = setmetatable(
		{
			Pages = nil;
			Index = 0;
			Query = Query or {};

			Cached = {},
			Getter = Getter,
		}, 
		PagesWrapper)

	return self;
end

---------------------------------------------------------------------

local AssetQuery = {};

function AssetQuery.search_audio(query)
	query.AssetType = Enum.AssetType.Audio;
	
	local audio_params: AudioSearchParams;
	
	if query.AudioSearchParams then
		audio_params = Instance.fromExisting(query.AudioSearchParams);
	else
		audio_params = Instance.new("AudioSearchParams");
		audio_params.AudioSubType = Enum.AudioSubType.Music;
	end
	
	audio_params.SearchKeyword = query.Text;
	
	local success, result = pcall(AssetService.SearchAudio, AssetService, audio_params)
	
	if success then
		return PagesWrapper.new(result, query);
	end;
end

function AssetQuery.search_model(query)
	query.AssetType = Enum.AssetType.Model;
	
	return PagesWrapper.psuedo(query, function(page)
		return InsertService:GetFreeModels(query.Text, page);
	end)
end

function AssetQuery.search_decal(query)
	query.AssetType = Enum.AssetType.Decal;
	
	return PagesWrapper.psuedo(query, function(page)
		return InsertService:GetFreeDecals(query.Text, page);
	end)
end

function AssetQuery.search(query: any)
	
	if (query.AssetType == Enum.AssetType.Audio) then
		return AssetQuery.search_audio(query);
		
	elseif (query.AssetType == Enum.AssetType.Model) then
		return AssetQuery.search_model(query);
		
	elseif (query.AssetType == Enum.AssetType.Decal) then
		return AssetQuery.search_decal(query);
		
	else
		error(`AssetType {query.AssetType.Name} is unsupported`)
	end
end

---------------------------------------------------------------------

return AssetQuery;