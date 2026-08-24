--!strict
--!native

local HttpService = game:GetService("HttpService")

local Null = "\0a";
local Rnd = Random.new();
local Table = {}

Table.null = Null;

Table.cool_emojis = {
	"🍫⭐🐟"; "🗣️"; "💖"; "🫠"; "🐛"; "🥶"; "💎"; "🙏"; "🐦"; 
	"😛"; "😌"; "😘"; "😗"; "🙂"; "😐"; "😶"; "😪"; "🫤"; "🙃"; "🤯"; 
	"🤢"; "🤧"; "🤭"; "🫣"; "😈"; "😸"; "🤖"; "😿";
	"💭"; "🌏"; "🍗"; "( ͡° ͜ʖ ͡°)"; "(￣y▽,￣)╭ "; 
	"（づ￣3￣）づ╭❤️～"
}


do
	local function cyclic_search(tbl, tracked)
		if tracked[tbl] then
			return true;
		end;
		
		tracked[tbl] = true
		
		for index, value in pairs(tbl) do
			if typeof(value) == "table" and cyclic_search(value, tracked) then
				return true, tbl, index, value;
			end;
		end

		return false;
	end

	--[[
		Determines whether the given table is cyclic (contains self referencing tables)
	]]
	function Table.is_cyclic(tbl: any): boolean
		assert(typeof(tbl) == "table", "tbl is not a table");
		
		return cyclic_search(tbl, {});
	end
end


do
	local weak_keys = table.freeze{__mode = "k"};
	
	function Table.weak_keys(t)
		return setmetatable(t, weak_keys);
	end
end;

do
	local weak_key_values = table.freeze{__mode = "kv"};
	
	function Table.weak_key_values(t)
		return setmetatable(t, weak_key_values);
	end
end;

do
	local weak_values = table.freeze{__mode = "v"};
	
	function Table.weak_values(t)
		return setmetatable(t, weak_values);
	end
end;


function Table.nullable(value: any): any
	if (value == nil) then
		return Null;
	else
		return value;
	end
end


-- Reformat pages as tables
function Table.get_all_pages_content(pages: Pages)
	local items = {};

	while not pages.IsFinished do
		table.insert(items, pages:GetCurrentPage())
		
		if not pages.IsFinished then
			pages:AdvanceToNextPageAsync()
		end;
	end;
	
	return items
end;


function Table.iterate_over_pages(pages: Pages): (() -> (any, number))
	local contents = Table.get_all_pages_content(pages)
	local pageNum = 1
	local lastPageNum = #contents
	
	return coroutine.wrap(function()
		while pageNum <= lastPageNum do
			for _, item in ipairs(contents[pageNum]) do
				coroutine.yield(item, pageNum)
			end
			pageNum += 1
		end
	end)
end


--[[
	Deep clones a table
]]
function Table.clone<T>(t: T): T
	assert(typeof(t) == "table", "t is not a table");
	
	local clone = {};

	for i, v: any in t do
		if typeof(v) == "table" then
			clone[i] = Table.clone(v);
		else
			clone[i] = v;
		end;
	end;

	return clone :: any;
end


--[[
	Makes a nested table completely unusable, I would recommend NOT using this unless you want to accidently break the entire game
]]
function Table.annihilate(t: any, seen: any)
	seen = seen or {};
	
	for index, value in t do
		if typeof(value) == "table" and not seen[value] then
			seen[value] = true;
			Table.annihilate(value, seen);
		end
	end
	
	if not table.isfrozen(t) then
		table.clear(t);
		setmetatable(t, nil);
		table.freeze(t);
	end;
end


function Table.dispose(t: any)
	if not table.isfrozen(t) then
		table.clear(t);
		setmetatable(t, nil);
		--table.freeze(t);
	end;
end

--[[
	Same as <code>table.find()</code>, but uses a dictionary.
]]
function Table.find<K, V>(t: {[K]: V}, v: V): K?
	for i, s in t do
		if v == s then
			return i;
		end;
	end;
	
	return nil;
end

--[[
	Sequentially searches the table until function returns true for a given value; and returning that value
]]
function Table.search<T>(t: {T}, f: (T) -> (boolean)): T?
	for i, v in t do
		if f(v) then
			return v;
		end;
	end;
	
	return nil;
end

--[[
	Sequentially finds the best value using the given sorting function
]]
function Table.peak<T>(t: {T}, f: (T, T) -> (boolean)): T
	local best: T;
	for i, v in t do
		if not best or f(v, best) then
			best = v;
		end
	end
	return best;
end

--[[
	Returns a copy of the table where false values returned by the filter function are omitted
]]
function Table.filter<T>(t: {T}, f: (T, number) -> (boolean)): {T}
	local c = table.create(#t);
	
	for i, v in t do
		if f(v, i) then
			table.insert(c, v); 
		end;
	end;

	return c;
end;

--[[
	Gets the length of any table (Dictionary, Array, Hashmap)
]]
function Table.length(t: any): number
	assert(typeof(t) == "table", "t must be of type table");
	local length = 0;
	for _ in pairs(t) do
		length += 1;
	end;
	return length;
end;

--[[
	Swaps key, value pairs to be of value, key pairs
]]
function Table.hashmap<K, V>(t: {[K]: V}): {[V]: K}
	local hashmap = {};
	for i, v in t do
		hashmap[v] = i;
	end;
	return hashmap;
end

--[[
	Returns an array where all values are the given table's key pairs
]]
function Table.keys<T>(t: {[T]: any}): {T}
	local c = {};
	for i, v in t do
		table.insert(c, i);
	end;
	return c;
end

--[[
	Returns an array where all values are the given table's value pairs
]]
function Table.values<T>(t: {[any]: T}): {T}
	local c = {};
	for i, v in t do
		table.insert(c, v);
	end;
	return c;
end

--[[
	Returns an array where all values are mapped through <code>tostring()</code>
]]
function Table.values_to_string<T>(t: {[any]: T}): {string}
	local c = {};
	for i, v in t do
		table.insert(c, tostring(v));
	end;
	return c;
end

--[[
	
]]
function Table.map<T, V>(t: {T}, v: V): {[T]: V}
	local c = {};
	for k, z in t do
		c[z] = v;
	end;
	return c;
end


function Table.bool_map<T>(t: {T}): {[T]: boolean}
	return Table.map(t, true);
end

--[[
	Reverses a given array
]]
function Table.reverse<T>(t: {T}): {T}
	for i = 1, #t // 2 do
		local j = #t - i + 1;
		t[i], t[j] = t[j], t[i];
	end;
	
	return t;
end;

--[[
	Selects a random value from an array
]]
function Table.random<T>(t: {T}): T
	if #t ~= 0 then
		return t[math.random(#t)];
	end;
	
	return nil :: any;
end;

function Table.random_dict<T>(t: any): (any, any)
	assert(typeof(t) == "table", "t is not a table");
	
	local count = Table.length(t);
	
	if (count >= 1) then
		local choice = math.random(1, count);
		local index = 0;
		
		for key, value in pairs(t) do
			index += 1;
			
			if (index >= choice) then
				return key, value;
			end
		end
	end;
	
	return nil, nil;
end

--[[
	Selects a random value from an array, selecting only values that pass through the filter function
]]
function Table.pick_random<V>(tbl: {[any]: V}, filter: (any) -> (boolean)): V
	assert(typeof(tbl) == "table", "t is not a table");

	local keyset = {};

	for key, value in tbl do
		if filter(value) then
			table.insert(keyset, key);
		end;
	end;

	if #keyset ~= 0 then
		return tbl[keyset[math.random(#keyset)]];
	end;

	return nil :: any;
end


--[[
	Selects a random value from a table, selecting only values that pass through the filter function
]]
function Table.random_filtered<V>(tbl: {[any]: V}, filter: (any, any) -> (boolean)): V
	assert(typeof(tbl) == "table", "t is not a table");
	
	local keyset = {};
	
	for key, value in tbl do
		if filter(key, value) then
			table.insert(keyset, key);
		end;
	end;
	
	if #keyset ~= 0 then
		local index = keyset[math.random(#keyset)];
		
		return index, tbl[index];
	end;
	
	return nil :: any;
end

--[[
	Appends a value to the end of the table
]]
function Table.add<T>(t: {T}, v: T): T
	table.insert(t, v);
	return v;
end

--[[
	Returns a new table which is a union of both tables t1 and t2
	<strong>Note</strong>: t1 will have a higher priority over the same indexes
]]
function Table.union<T1, T2>(t1: T1, t2: T2): T1 & T2
	assert(typeof(t1) == "table", "t1 is not a table");
	assert(typeof(t2) == "table", "t2 is not a table");
	
	local t3 = table.clone(t2);
	
	for i, v in t1 do
		if typeof(i) == "number" then
			table.insert(t3, v);
		else
			t3[i] = v;
		end
	end
	
	return t3 :: any;
end

--[[
	Inserts a value into an array mapped by a key.
	Automatically will add a key value table if it does not exist.
]]
function Table.nest_add(map: {[any]: {any}}, key: any, value: any): boolean
	if key ~= nil then
		if not map[key] then
			map[key] = {};
		end;

		local index = table.find(map[key], value)

		if not index then
			table.insert(map[key], value);
			return true;
		end;
	end;
	
	return false;
end

--[[
	Remotes a value from an array mapped by a key.
	Automatically will remove the key value table if it becomes empty.
]]
function Table.nest_remove(map: {[any]: {any}}, key: any, value: any): boolean
	if key ~= nil and map[key] then
		local index = table.find(map[key], value)

		if index then
			table.remove(map[key], index);

			if #map[key] == 0 then
				map[key] = nil;
			end;
			
			return true;
		end;
	end;
	
	return false;
end

--[[
	Removes a value from the table if found, will return <code>nil</code> if the value is not found in the array
]]
function Table.remove<T>(t: {T}, v: T): T?
	local i = table.find(t, v);
	
	if i then
		return table.remove(t, i);
	end;
	
	return nil;
end

--[[
	Removes a value from the table without shuffling
]]
function Table.index_remove<T>(t: {T}, v: T): ()
	for i, v2 in t do
		if v2 == v then
			t[i] = nil;
		end
	end
end

--[[
	Recursively calls <code>table.freeze()</code> on the nested table
]]
function Table.lock<T>(t: {T}): ()
	for i, v in t do
		if typeof(t) == "table" and not table.isfrozen(t) then
			table.freeze(t);
			Table.lock(t);
		end
	end;
end;

--[[
	Returns a deep-copy of the given table that is frozen (immutable)
]]
function Table.immutable<T>(t: {T}): {T}
	local c = Table.clone(t);
	Table.lock(c);
	
	return c;
end

--[[
	Fastly checks whether a table is empty
]]
function Table.is_empty<T>(t: {T}): boolean
	return next(t) == nil;
end;

--[[
	Shuffles a table
]]
function Table.shuffle<T>(t: {T}): {T}
	Rnd:Shuffle(t);
	
	return t;
end

--[[
	Truncates the end of the table until the table is of length <code>length</code>
]]
function Table.truncate<T>(t: {T}, length: number): {T}
	for i, v in t do
		length -= 1;
		
		if length <= 0 then
			t[i] = nil;
		end
	end
	
	return t;
end

--[[
	Returns a new table with a selection random elements from table <code>t</code> and is of size <code>samples</code>
]]
function Table.sample<T>(t: {T}, samples: number): {T}
	local c = table.clone(t);
	
	return Table.truncate(Table.shuffle(c), samples);
end

--[[
	Appends table <code>extension</code> onto the end of table <code>target</code>
]]
function Table.extend<T>(target: {T}, extension: {T}): {T}
	for i, v in extension do
		table.insert(target, v);
	end;
	
	return target;
end;

--[[
	Returns an array with elements in <code>t1</code> also found in <code>t2</code>
]]
function Table.cross<T>(t1: {T}, t2: {T}): {T}
	local crossed = {};
	
	if t1 and t2 then
		for i, v in t1 do
			if table.find(t2, v) then
				table.insert(crossed, v)
			end
		end
	end
	
	return crossed;
end

--[[
	Returns an array with elements that only appear in one table
]]
function Table.unique<T>(t1: {T}, t2: {T}): {T}
	local unique = table.create(#t1 + #t2);
	
	for i, v in t1 do
		if not table.find(t2, v) then
			table.insert(unique, v);
		end
	end
	
	for i, v in t2 do
		if not table.find(t1, v) then
			table.insert(unique, v);
		end
	end
	
	return unique;
end

--[[
	Converts a table into a Json string.
]]
function Table.to_json(t: any): string
	if typeof(t) == "table" then
		local success, result = pcall(HttpService.JSONEncode, HttpService, t);
		
		if success then
			return result;
		end;
	end
	
	return "{}";
end

--[[
	Converts a Json string into a lua table.
]]
function Table.from_json(s: string): {[string]: any}
	if typeof(s) == "string" then
		local success, result = pcall(HttpService.JSONDecode, HttpService, s);

		if success then
			return result;
		end;
	end

	return {};
end

--[[
	Returns an array with <strong>unordered</strong> values within <code>dict</code>
]]
function Table.dictionary_to_array<T>(dict: {[any]: T}): {T}
	local t = {};
	for i, v in dict do
		table.insert(t, v);
	end
	return t;
end

local function check_content(table1: any, table2: any): boolean
	for index, value_1 in table1 do
		local value_2 = table2[index];
		
		if typeof(value_1) == "table" and typeof(value_2) == "table" then
			local result = check_content(value_1, value_2);

			if not result then
				return false;
			end;
			
		elseif value_1 ~= value_2 then
			return false;
		end;
	end;
	
	return true;
end;

--[[
	Returns whether the two tables contain the same contents.
]]
function Table.same_content(t1, t2): boolean
	if not t1 or not t2 then return false; end

	if not ( check_content(t1, t2) and check_content(t2, t1) ) then
		return false;
	end
	
	return true;
end;

--[[
	Finds a value within a nested table <code>t</code> using <code>k</code>
]]
function Table.access(t: any, k: string, separator: string?): any?
	assert(typeof(t) == "table", "t is not a table");
	local value = t;
	
	for i, str in string.split(k, separator or "/") do
		value = value[str];
			
		if value == nil then return nil end;
	end;
	
	return value;
end


--[[
	Clones a table but ignoring indexes if they fail to meet the rule
]]
function Table.selective_clone(tbl: any, rule: (any, any) -> boolean?): any
	assert(typeof(tbl) == "table", "t is not a table");
	
	local clone = {};
	
	for key, value in pairs(tbl) do
		if not rule(key, value) then continue end;
		
		if typeof(value) == "table" then
			clone[key] = Table.selective_clone(value, rule);
		else
			clone[key] = value;
		end
	end
	
	return clone;
end

function Table.flatten(tbl: any, seperator: string, include_tables: boolean?): any
	local flat_table = {};

	local function flatten(ntbl, nkey)
		for key, value in ntbl do
			local ckey = `{nkey}{key}`;
			
			if typeof(value) == "table" then
				flatten(value, `{ckey}{seperator}`);
				
				if include_tables then
					flat_table[ckey] = value;
				end
			else
				flat_table[ckey] = value;
			end
		end
	end
	
	flatten(tbl, "");
	return flat_table;
end

--[[
	Sets missing indexes in table 'tbl' that are present in table 'default'.
	<strong>Note</strong>: only reconciles string type indexes.
]]
function Table.reconcile<T>(tbl: T, default: any): T
	assert(typeof(tbl) == "table", "tbl is not a table");
	assert(typeof(default) == "table", "default is not a table");
	
	for key, value in pairs(default) do
		local t_value = tbl[key];
		
		if (t_value == nil) then
			if typeof(value) == "table" then
				tbl[key] = Table.reconcile({}, value)
				
			else--if typeof(key) == "string" then 
				tbl[key] = value;
			end;
			
		elseif typeof(value) == "table" then
			Table.reconcile(t_value, value)
		end;
	end
	
	return tbl;
end

--[[
	Sets a value <code>v</code> within a nested table <code>t</code> using <code>k</code>.
	<strong>Note</strong>: returns whether the table was successfully modified
]]
function Table.modify(t: any, k: string, v: any, separator: string?, no_create: boolean?): boolean
	assert(typeof(t) == "table", "t is not a table");
	
	if (v == Null) then
		v = nil;
	end;
	
	if typeof(k) ~= "string" then
		local current = t[k];
		t[k] = v;
		
		return (current ~= v);
	else
		local split = string.split(k, separator or "/");
		local value = t;
		
		for i, str in ipairs(split) do
			if #split == i then 
				local current = value[str];
				value[str] = v;

				return (current ~= v);
			end;

			if value[str] == nil then
				if no_create then
					return false;
				end;
				value[str] = {};
			end

			value = value[str];
		end;
		
		return false;
	end;
end


--[[
	Selects a random value using weight. The array must have elements that are strictly tables in the form of: <code>{[any]: number}</code>
]]
function Table.pick_weight(dict: {[any]: number}): any
	local total, run, fin = 0, 0, 0;
	
	for key, weight in dict do
		total += weight;
	end;
	
	fin = Rnd:NextInteger(1, total);
	
	for key, weight in dict do
		run += weight;
		
		if (run >= fin) then
			return key;
		end;
	end;

	return nil;
end

--[[
	Selects a random value using weight. The array must have elements that are strictly tables in the form of: <code>{[number]: {Weight: number}}</code>
]]
function Table.weighted_random<T>(t: {T}): T
	local total, run, fin = 0, 0, 0;

	for _, tbl2: any in ipairs(t) do
		total += tbl2.Weight;
	end;

	fin = Rnd:NextInteger(1, total);

	for _, tbl2: any in ipairs(t) do
		run += tbl2.Weight;

		if (run >= fin) then
			return tbl2;
		end;
	end;

	return next(t) :: any;
end

--[[
	If t's metatable indexes itself, t will have its metatable removed.
]]
function Table.break_metaindex_loops<T>(t: T): T
	assert(typeof(t) == "table", "t is not a table");
	
	local m = getmetatable(t);
	
	if m and m.__index == t then
		setmetatable(t :: any, nil);
	end;
	
	return t;
end

--[[ 
	Basically turns a table with 'default metatable indexing' into a raw table 
	with the defaults embedded 
]]
local function indexed_metatable_setter(source: any, target: any): any
	local meta: any = getmetatable(source) or {};

	for key, value in meta.__index or {} do
		if typeof(value) == "table" then
			target[key] = {}
			indexed_metatable_setter(value, target[key]);
		else
			target[key] = value
		end
	end

	for key, value in source :: any do
		if typeof(value) == "table" then
			target[key] = {}
			indexed_metatable_setter(value, target[key]);
		else
			target[key] = value
		end
	end

	return target
end

--[[
	Assembles a new table that exactly represents by value indexing a table that has been transformed by <code>Table.mirror()</code>
]]
function Table.get_meta_indexed_table<T>(t: T): T
	assert(typeof(t) == "table", "t is not a table");
	
	return indexed_metatable_setter(t, {});
end

local function metatable_mirror(source: any, target: any)	
	for key, value in source do
		local tvalue = target[key];
		
		if typeof(value) == "table" then
			if typeof(tvalue) ~= "table" then
				target[key] = {};
				tvalue = target[key];
			end;
			
			metatable_mirror(value, tvalue);
			setmetatable(tvalue, {__index = value})
		end
	end
end

--[[
	Recursively transforms table <code>target</code> such that indexing will reference table <code>source</code> if the index is <code>nil</code>.
	Esentially if an index is <code>nil</code> in <code>target</code>, it will return <code>source</code>'s index value instead.
	<br><strong>Note</strong>: Incompatible with <code>Table.deep_proxy()</code> and tables with metatables, will also deep freeze the source table if not already
]]
function Table.mirror<S, T>(source: S, target: T): (S & T)
	assert(typeof(source) == "table", "source is not a table");
	assert(typeof(target) == "table", "target is not a table");
	
	Table.lock(source);
	
	metatable_mirror(source, target);
	setmetatable(target::any, {__index = source});
	
	return target;
end

type CommitMode = "change" | "no-change";

--type CommitMode = "deep-no-change" | "deep" | "shallow";

--local function tbl_commit<T>(tbl: T, commit: T, mode: CommitMode, has_changed: {[string]: any}, b_link: {[any]: any}, rkey: string?): {[string]: any}
--	assert(typeof(tbl) == "table", "tbl is not a table");
--	assert(typeof(commit) == "table", "commit is not a table");

--	for key, value in commit do
--		local nkey = if rkey then `{rkey}/{key}` else key;

--		if typeof(value) == "table" and typeof(tbl[key]) == "table" then
--			b_link[tbl[key]] = {tbl, key};
--			tbl_commit(tbl[key], value, mode, has_changed, b_link, nkey)

--		elseif tbl[key] ~= value then
--			if typeof(value) == "table" and (mode == "deep" or mode == "deep-no-change") then
--				local ntbl = has_changed[nkey] or {};

--				if mode ~= "deep-no-change" then
--					tbl[key] = ntbl;
--				end;
--				has_changed[nkey] = ntbl;
--				b_link[ntbl] = {tbl, key};

--				tbl_commit(ntbl, value, mode, has_changed, b_link, nkey)
--			else
--				if mode ~= "deep-no-change" then
--					tbl[key] = value;
--				end;

--				has_changed[nkey] = value;
--			end
--		end
--	end

--	return has_changed;
--end

local function tbl_light_commit(tbl: {[any]: any}, commit: {[any]: any}, mode: CommitMode, has_changed: {[string]: any}, rkey: string?): {[string]: any}
	for key, value in commit do
		local nkey = if rkey then `{rkey}/{key}` else key;
		if (value == Null) then value = nil end;
		
		if typeof(value) == "table" and typeof(tbl[key]) == "table" then
			has_changed[nkey] = value;
			tbl_light_commit(tbl[key], value, mode, has_changed, nkey)

		elseif tbl[key] ~= value then
			if mode == "change" then
				tbl[key] = value;
			end;
			
			has_changed[nkey] = value;
		end
	end
	
	return has_changed;
end

--[[
	Modifies the table <code>tbl</code> recursively by mapping table <code>commit</code>.<br>
	·If mode is 'deep', the returned table will have nested values also as indexes.
	·Returns a flattened table of recursive index keys with their changed values.
]]
function Table.commit<T>(tbl: T, commit: T, mode: CommitMode): {[string]: any}
	assert(typeof(tbl) == "table", "tbl is not a table");
	assert(typeof(commit) == "table", "commit is not a table");
	assert(mode, "No commit mode was specified");
	
	return tbl_light_commit(tbl, commit, mode, {});
end

table.freeze(Table);

return Table;