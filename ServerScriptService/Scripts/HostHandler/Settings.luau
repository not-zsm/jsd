
return {
	
	SERVER_EXPIRY = 86_400, -- 1 Day.
	RESERVE_MAP_EXPRIY = 86_400, -- 1 Day. Recommended to be the same as SERVER_EXPIRY
	REFRESH_TIME = 40, -- This is the passive server list refresh whenever someone has their browser open.
	SPONTANEOUS_REFRESH_TIME = 12.5, -- Refresh quicker if a player actively refreshes.
	ACCESS_CODE_GENERATE_ATTEMPTS = 3, -- Amount of retries before access code generation fails.
	MAX_SERVERS_DISPLAYED = 200, -- The more servers that can be displayed at the possible cost of using more quota.	
	SERVER_CACHE_INVALIDATION_TIME = 10; -- The time after caching which a server will need to be refetched.
	
	BATCH_PLAYER_COUNT_TIME = 7.50, -- The delay in which player counts are updated in the server browser.
	MAX_ACCESS_CODE_ATTEMPTS = 4, -- The number of attempts in a custom server instance to get the access code before giving up.
	
	MY_SERVER_VALIDATION_DEBOUNCE = 5;	
};