local Success, Result = pcall(function()
	return "https://raw.githubusercontent.com/th4rau/azureLatch/refs/heads/main/jsd.json"
end)

local Web_Repository

if Success then
	Web_Repository = Result
else
	Web_Repository = ""
end

return {
	mode = "Web"; -- "Web" or "Product"

	refresh_time = 60; -- Number of seconds between each request to update the whitelist.
	invalidate_out_of_date_whitelist = 600; -- If this amount of seconds go without an update to the whitelist, the whitelist is cleared for security.

	web_repository = Web_Repository; -- The raws link to the web whitelist.
	product_id = 0000000; -- This should be a developer product.
};