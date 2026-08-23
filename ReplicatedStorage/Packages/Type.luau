--!nocheck
--!native

local replicatedStorage = game:GetService("ReplicatedStorage")

local Math = require( "./Math" )
local Table = require( "./Table" )

local DummyMethod = function() end;

----------------------------------------------------------------------------

export type Truths = { 
	[number]: {
		(value: unknown) -> (boolean, string?)
	};
};

export type Casts = {
	[number]: {
		(set: Set) -> (any, string?)
	}
}

export type ClassSet = {
	__index: ClassSet;
	
	_recursive_table_cast: (self: Set, value: unknown) -> (boolean, string?);
	
	--Alias to <code>Set.assert()</code>
	__call: typeof(function(self: Set, value: unknown): (boolean, string?) end);
	
	--Declares that a value can be <code>nil</code> when <code>Set.assert()</code> is called
	optional: typeof(function(self: Set): Set end);
	
	--Asserts the given set rule object against a <code>value</code>, returning <strong>true</strong> if value meets the conditions
	assert: typeof(function(self: Set, value: unknown): (boolean, string?) end);
	
	--Special assertion 'assert_table_by_key_value' for type table directories, asserting a <code>key</code> (directory) against <code>value</code>.
	--If index is an empty string "", the value will be asserted against the generic type rule if there is one.
	assert_kv: typeof(function(self: Set, directory: string, key: unknown, value: unknown): (boolean, string?) end);
	
	--For set tables, this give the type definition for the given directory (semi-colon seperated).
	--<br><strong>Note</strong>: Throws an exception if directory is invalid.
	find: typeof(function(self: Set, directory: string): Set end);
	
	--Special assertion 'assert_table_by_key_value' for type table directories, asserting a <code>key</code> (directory) against <code>value</code>.
	--If index is an empty string "", the value will be asserted against the generic type rule if there is one.
	assert_v: typeof(function(self: Set, key: string, value: unknown): (boolean, string?) end);
	
	--Casts a value into its appropriate types based on the type set.<br>
	--·Returns the casted value, whether casting was successful, and a type error if unsuccessful.
	--·<strong>Note</strong>: tables may be modified (even if casting was unsuccessful), use a deep copy if this is undesirable.
	--·<strong>Note</strong>: casting is always non-strict with tables (irregardless of :with() or :somewhat())
	cast: typeof(function(self: Set, value: unknown): (any, boolean, string?) end);
	
	--Adds a truth to be asserted
	add_truth: typeof(function(self: Set, truth: any): Set end);
	
	--Adds a cast function to be used in <strong>post</strong>-casting
	add_cast: typeof(function(self: Set, cast: any): Set end);
	
	--Adds a cast function to be used in <strong>pre</strong>-casting
	add_cast_rule: typeof(function(self: Set, for_type: string, cast: any): Set end);
	
	--Asserts that the number must be an <code>integer</code> (a whole number)
	--<strong>Note:</strong> value must be a number
	integer: typeof(function(self: Set): Set end);
	
	--Asserts that the number must be a real number (<code>non-NaN</code>)
	--<strong>Note:</strong> value must be a number
	real: typeof(function(self: Set): Set end);
	
	--Asserts that the string must be in the range <code>[min, max]</code><br>
	--<strong>Note:</strong> if only <code>min</code> is passed, the range will instead be <code>[0, min]</code>
	--<strong>Note:</strong> value must be a <code>string</code>
	length: typeof(function(self: Set, min: number, max: number?): Set end);
	
	--Asserts that the number must be in the range <code>[min, max]</code>
	--<strong>Note:</strong> value must be a <code>number</code>
	range: typeof(function(self: Set, min: number, max: number): Set end);
	
	--Asserts that the <code>Instance</code> has ClassName equal exactly to <code>class_name</code>
	--<strong>Note:</strong> value must be an <code>Instance</code>
	of_class: typeof(function(self: Set, class_name: string): Set end);
	
	--Asserts that the <code>Instance</code> is of Roblox class <code>class_name</code> using <code>Object.IsA()</code>
	--<strong>Note:</strong> value must be an <code>Instance</code>
	isa: typeof(function(self: Set, class_name: string): Set end);
	
	--Asserts that the value must <strong>strictly</strong> follow the rules of the given interface <code>interface</code>
	--<strong>Note:</strong> value must be a <code>table</code>
	with: typeof(function(self: Set, interface: any): Set end);
	
	--Asserts that the value must follow the rules of the given interface <code>interface</code>
	--<strong>Note:</strong> value must be a <code>table</code>
	somewhat: typeof(function(self: Set, interface: any): Set end);
	
	--Checks whether the given value is a <code>Set</code> object
	is_instance: typeof(function(value: unknown): boolean end);
};

export type Set = typeof(setmetatable({} :: {
	_type: string?;
	_optional: boolean;
	_truths: Truths;
	_casts: any?;
	_cast_rules: any?;
	_interface: any?;
	
}, {} :: ClassSet));

export type ClassTupleSet = {
	__index: ClassTupleSet;
	
	--Alias to <code>TupleSet.assert()</code>
	__call: typeof(function(self: TupleSet, ...: unknown): (boolean, string?) end);
	
	--Asserts the given set rule object against a tuple <code>...</code>, returning <strong>true</strong> if the tuple meets the conditions of its corresponding tuple argument
	assert: typeof(function(self: TupleSet, ...: unknown): (boolean, string?) end);
	
	--Casts the tuple into its appropriate types based on the tuple set.<br>
	--·Returns a tuple of casted values, a tuple index will be nil if casting was unsuccessful.
	--·<strong>Note</strong>: tables may be modified (even if casting was unsuccessful), use a deep copy if this is undesirable.
	--·<strong>Note</strong>: casting is always non-strict with tables (irregardless of :with() or :somewhat())
	cast: typeof(function(self: TupleSet, ...: any): (...any) end);
};

export type TupleSet = typeof(setmetatable({} :: {
	_tuple: {Set};

}, {} :: ClassTupleSet));

----------------------------------------------------------------------------

@native local function format_number(value: number, precision: number): string
	if not precision then
		precision = 3;
	end;
	
	return string.gsub(string.format(`%.{precision}f`, value), "%.?0+$", "");
end;

local TypeCasts = {
	string = {
		any = function(value: any)
			return tostring(value);
		end,
		
		number = function(value: number)
			return tostring(math.round(value*1e7)/1e7)
		end,

		Color3 = function(value: Color3)
			return `{math.round(value.R*255)}, {math.round(value.G*255)}, {math.round(value.B*255)}`;
		end,
		
		NumberRange = function(value: NumberRange)
			if value.Min == value.Max then
				return `{value.Min}`;
			else
				return `{value.Min}, {value.Max}`;
			end
		end,
		
		UDim2 = function(value: UDim2)
			return `{format_number(value.X.Scale)}, {format_number(value.X.Offset)}, {format_number(value.Y.Scale)}, {format_number(value.Y.Offset)}`;
		end,
	};
	UDim2 = {
		string = function(value: string)
			local split = string.split(value, ",");
			return UDim2.new(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]), tonumber(split[4]))
		end,
	};
	boolean = {
		string = function(value: string)
			return string.lower(value) ~= "false";
		end,
		
		number = function(value: number)
			return if value == 0 then false else true;
		end,
	};
	number = {
		string = function(value: string)
			return tonumber(value);
		end,
		
		boolean = function(value: boolean)
			return if value then 1 else 0;
		end,
	};
	NumberRange = {
		string = function(value: string)
			return NumberRange.new(unpack(string.split(value, ",")));
		end,
	};
	BrickColor = {
		string = function(value: string)
			return BrickColor.new(value);
		end,
		
		Color3 = function(value: Color3)
			return BrickColor.new(value);
		end,
	};
	Color3 = {
		string = function(value: string)
			local split = string.split(value, ",");

			return Color3.fromRGB(
				tonumber(split[1]) or 255, 
				tonumber(split[2]) or 255, 
				tonumber(split[3]) or 255
			)
		end,
	};
	Vector3 = {
		string = function(value: string)
			return Vector3.new(unpack(string.split(value, ",")));
		end,
	};
	Vector2 = {
		string = function(value: string)
			return Vector2.new(unpack(string.split(value, ",")));
		end,
	};
	CFrame = {
		string = function(value: string)
			local v = string.split(value, ",");
			
			if #v == 6 then
				return CFrame.new(v[1], v[2], v[3]) * CFrame.Angles(v[4], v[5], v[6])
			else
				return CFrame.new(unpack(v));
			end
		end,
	};
	EnumItem = {
		string = function(value: string)
			local split = string.split(value, ".");
			
			return Enum[split[2]][split[3]];
		end,
	};
};

local TruthCasts = {
	integer = function(value: number)
		return math.floor(value);
	end,
	
	length = function(value: string, min: number, max: number?)
		if not max then
			min, max = 0, min;
		end;
		
		return string.sub(value, min, max);
	end,
	
	range = function(value: number, min: number, max: number)
		return math.clamp(value, min, max);
	end,
}

local Truths = {
	integer = function(value: number)
		if value % 1 == 0 then
			return true;
		end;
		
		return false, "number is not an integer"
	end,
	
	real = function(value: number)
		if value == value then
			return true;
		end;
		
		return false, "number is NaN"
	end,
	
	length = function(value: string, min: number, max: number?)
		if not max then
			min, max = 0, min;
		end;
		
		if #value >= min and #value <= max then
			return true;
		end;
		
		return false, `string does not fall in length range [{min}, {max}]`
	end,
	
	range = function(value: number, min: number, max: number)
		if value >= min and value <= max then
			return true;
		end;
		
		return false, `number does not fall in range [{min}, {max}]`
	end,
	
	of_class = function(value: Instance, class_name: string)
		if value.ClassName == class_name then
			return true;
		end;
		
		return false, `instance is not of ClassName {class_name} (got {value.ClassName})`
	end,
	
	isa = function(value: Instance, class_name: string)
		if value:IsA(class_name) then
			return true;
		end;
		
		return false, `instance is does not inherit from {class_name} (got {value.ClassName})`
	end,
	
	union = function(value: unknown, pack: {Set})
		for _, set in pairs(pack) do
			if set:assert(value) then
				return true;
			end;
		end;
		
		return false, `Type union couldn't match any set with the given value`;
	end,
	
	intersect = function(value: unknown, pack: {Set})
		for i, set in ipairs(pack) do
			local success, err = set:assert(value);

			if not success then
				return success, `Argument #{i}: {err}`;
			end;
		end;
		
		return true;
	end,
	
	enum = function(value: EnumItem, enum: Enum)
		if value.EnumType == enum then
			return true;
		end;
		
		return false, `value is not of EnumType {enum} (got {value.EnumType})`;
	end,
};

local TruthsHashmap = Table.hashmap(Truths);

----------------------------------------------------------------------------

local TupleSet = {} :: ClassTupleSet
TupleSet.__index = TupleSet;

function TupleSet:assert(...)
	local pack = {...};
	
	for i, set in ipairs(self._tuple) do
		local success, err = set:assert(pack[i]);

		if not success then
			return success, `bad tuple argument #{i}: {err}`;
		end;
	end;
	
	return true;
end

function TupleSet:cast(...)
	local pack = {...};
	local repack = table.create(#self._tuple);
	
	for i, set in ipairs(self._tuple) do
		local value, success = set:cast(pack[i]);

		if success then
			repack[i] = value;
		end;
	end;
	
	return unpack(repack);
end

TupleSet.__call = TupleSet.assert;

----------------------------------------------------------------------------

local Set = {} :: ClassSet;
Set.__index = Set;

--Internal <code>table</code> type assertion function used by <code>Set.with()</code> and <code>Set.somewhat()</code>
local function enforce_table(input: any, interface: any, strict: boolean)
	local range_key, range_rule;

	for key, rule: Set in pairs(interface) do
		local rough_value = input[key];

		if Set.is_instance(key) and Set.is_instance(rule) then
			if range_key then
				continue;
			end

			range_key, range_rule = key, rule;

			for index, value in pairs(input) do
				local key_yes, key_err = key:assert(index);
				
				if not key_yes then
					return false, `[{index}] index error: {key_err}`;
				end
				
				local rule_yes, rule_err = rule:assert(value);
				
				if not rule:assert(value) then
					return false, `[{index}] value error: {rule_err}`;
				end
			end

		else
			--local success, err = rule:assert(rough_value);
			
			--if not success then print("nah imma do my own thing", rough_value, key, rule)
			--	return false, `[{key}] error: {err}`;
			--end;
		end
	end;
	
	if strict then
		for index, value in pairs(input) do
			local rough_rule = interface[index];

			if (rough_rule == nil) then
				if range_key then
					local range_key_yes, range_key_err = range_key:assert(index)

					if not range_key_yes then
						return false, `{index} does not meet index rule: {range_key_yes}`
					end

					local range_value_yes, range_value_err = range_rule:assert(value)

					if not range_value_yes then
						return false, `{index} does not meet value rule: {range_value_err}`
					end
				else
					return false, `{index} is an unexpected index`;
				end;
			end
		end
	end;
	
	return true;
end


--Asserts the key and value against any generics found in the given set table
local function enforce_generic_kv(set: Set, key: unknown, value: unknown): boolean
	for k, v in set._interface do
		if not (Set.is_instance(k) and Set.is_instance(v)) then 
			continue;
		end;

		local sk, errk = k:assert(key);
		if not sk then return sk, errk; end
		
		local sv, errv = v:assert(value);
		if not sv then return sv, errv; end
	end;
	
	return true;
end


function Set.is_instance(value: unknown)
	return typeof(value) == "table" and getmetatable(value) == Set;
end


function Set:assert(value)
	if self._optional and value == nil then return true end;
	if self._type and typeof(value) ~= self._type then 
		return false, `value is not of type {self._type} (got {typeof(value)})`; 
	end;
	
	for _, truth in ipairs(self._truths) do
		local success, err = truth(value);
		
		if not success then
			return false, err;
		end
	end;

	return true;
end

function Set:assert_v(key, value)
	local set = self:find(key);

	if set then
		return set:assert(value);
	end;

	return false, `index does not exist in table`;
end

function Set:assert_kv(directory, key, value)
	local split = string.split(directory, "/");
	local set = self:find(directory);
	
	if set then
		if split[#split] == "" then
			return enforce_generic_kv(set, key, value);
		end;
		
		return set:assert(value);
	end;
	
	return false, `index does not exist in table`;
end

function Set:find(directory)
	local split = string.split(directory, "/");
	local set: Set = self;

	for index, str in ipairs(split) do
		if str == "" then continue end
		if not set or not set._interface then break end;
		
		set = set._interface[str];
	end
	
	return set;
end

function Set:_recursive_table_cast(value)
	local success, type_err = true, nil;
	
	for k, v in self._interface do
		if Set.is_instance(k) and Set.is_instance(v) then 
			-- Is a key, value type pair, must reiterate through value table to cast
			for k2, v2 in value do
				local rk, s1, te1 = k:cast(k2);
				local rv, s2, te2 = v:cast(v2);

				if not s1 or not s2 then
					success, type_err = false, te1 or te2;
				else
					value[k2] = nil;
					value[rk] = rv;
				end
			end

		elseif Set.is_instance(v) then
			local rv, s, te = v:cast(value[k]);

			if not s then
				success, type_err = s, te;
			else
				value[k] = rv;
			end
		end;
	end;
	
	return success, type_err;
end

local function cast_to_type(self: Set, value)
	local type_self = self._type;
	local type_value = typeof(value);
	local type_cast = TypeCasts[type_self];

	if type_cast then
		local cast = type_cast[type_value] or type_cast.any;

		if cast then
			local success, result = pcall(cast, value);

			if not success then
				return nil, false, `unable to cast`;

			elseif result == nil then
				return nil, false, "unable to cast (cast function gave nil)";

			else
				return result, true, nil;
			end
		end
	end;
	
	return nil, false, "unable to cast (no cast function)";
end

local function cast_to_bespoke_type(self: Set, value)
	local type_self = self._type;
	local type_value = typeof(value);
	
	for _, cast in self._cast_rules[type_self][type_value] do
		local success, result = pcall(cast, value);

		if success and result ~= nil then
			return result, true, nil;
		end;
	end

	return nil, false, `unable to cast`;
end

function Set:cast(value)
	local new_value = value;
	
	if typeof(value) == self._type then
		
		if self._type == "table" then
			local success, type_err = self:_recursive_table_cast(new_value);
			
			if not success then
				return nil, false, type_err;
			end
		end;
		
	else
		local result, success, err;
		
		if self._cast_rules and self._cast_rules[self._type] and self._cast_rules[self._type][typeof(value)] then
			result, success, err = cast_to_bespoke_type(self, new_value);
		end
		
		if not success then
			result, success, err = cast_to_type(self, new_value);
		end
		
		if not success or result == nil then
			return nil, false, err
		end;
		
		new_value = result;
	end
	
	-- now assumed to be of the correct datatype
	if self._casts then
		for _, caster in self._casts do
			local success, result, err = pcall(caster, new_value, value);

			if not success then
				return nil, false, `unable to cast`;

			elseif (result == nil) then
				return nil, false, err;
				
			else
				new_value = result;
			end
		end
	end;
	
	return new_value, true, nil;
end

function Set:add_cast(cast: any)
	if not self._casts then 
		self._casts = {};
	end;
	
	table.insert(self._casts, cast);
	
	return self;
end

function Set:add_truth(truth)
	if not self._truths then
		self._truths = {};
	end;
	
	table.insert(self._truths, truth);
	
	return self;
end

function Set:add_cast_rule(for_type: string, cast: any)
	if not self._cast_rules then
		self._cast_rules = {};
	end;
	
	if not self._cast_rules[self._type] then
		self._cast_rules[self._type] = {};
	end;
	
	if not self._cast_rules[self._type][for_type] then
		self._cast_rules[self._type][for_type] = {};
	end;
	
	table.insert(self._cast_rules[self._type][for_type], cast);
	
	return self;
end

function Set:optional()
	self._optional = true;
	
	return self;
end

function Set:integer()
	self:add_truth(Truths.integer);
	
	self:add_cast(function(value)
		return TruthCasts.integer(value);
	end)
	
	return self;
end

function Set:real()
	self:add_truth(Truths.real)
	
	return self;
end

function Set:length(min: number, max: number)
	self:add_truth(function(value)
		return Truths.length(value, min, max)
	end)
	
	self:add_cast(function(value)
		return TruthCasts.length(value, min, max)
	end)
	
	return self;
end

function Set:range(min: number, max: number)
	self:add_truth(function(value)
		return Truths.range(value, min, max)
	end)
	
	self:add_cast(function(value)
		return TruthCasts.range(value, min, max)
	end)
	
	return self;
end

function Set:of_class(class_name: string)
	self:add_truth(function(value)
		return Truths.of_class(value, class_name)
	end)
	
	return self;
end

function Set:isa(class_name: string)
	self:add_truth(function(value)
		return Truths.isa(value, class_name)
	end)
	
	return self;
end

function Set:with(interface: any)
	assert(not self._interface, "Cannot use multiple interfaces");
	
	self:add_truth(function(value)
		return enforce_table(value, interface, true)
	end)

	self._interface = interface;
	
	return self;
end

function Set:somewhat(interface: any)
	assert(not self._interface, "Cannot use multiple interfaces");
	
	self:add_truth(function(value)
		return enforce_table(value, interface, false)
	end)
	
	self._interface = interface;
	
	return self;
end

Set.__call = Set.assert;

----------------------------------------------------------------------------

local Type = {}
Type.__index = Set;

--Asserts the given set rule object against a <code>value</code>, returning <strong>true</strong> if value meets the conditions
Type.assert = Set.assert :: typeof(function(self: Type, value: unknown): (boolean, string?) end);

--Casts a value into its appropriate types based on the type set.<br>
--·Returns the casted value, whether casting was successful, and a type error if unsuccessful.
--·<strong>Note</strong>: tables may be modified (even if casting was unsuccessful), use a deep copy if this is undesirable.
--·<strong>Note</strong>: casting is always non-strict with tables (irregardless of :with() or :somewhat())
Type.cast = Set.cast :: typeof(function(self: Type, value: unknown): (any, boolean, string?) end);

--Defines a new set
function Type.__call(self: Type): Set
	local set = setmetatable({
		
		_type = self._type;
		_truths = table.clone(self._truths);
		_optional = false;
		
	}, Set);
	
	self.instantiates(set);
	
	return set;
end

--Defines a new set that asserts <strong>true</strong> if <strong>atleast one</strong> of the sets asserts to <strong>true</strong> 
function Type.union(...: Set): Set
	local pack = {...};
	
	return setmetatable({
		
		_truths = {function(value)
			return Truths.union(value, pack)
		end};
		
		_optional = false;
		
	}, Set);
end

--Defines a new set that asserts <strong>true</strong> if <strong>all</strong> of the sets asserts to <strong>true</strong> 
function Type.intersect(...: Set): Set
	local pack = {...};
	
	return setmetatable({
		
		_truths = {function(value)
			return Truths.intersect(value, pack)
		end};
		_optional = false;
		
	}, Set);
end

--Defines a new tuple set
function Type.tuple(...: Set): TupleSet
	return setmetatable({

		_tuple = {...};

	}, TupleSet);
end

--Defines a new type used to create <code>Set</code> objects.
--· The <code>truths</code> argument will enforce a table of truths in any created <code>Set</code>
function Type.typeof(str: string, instantiates: ((Set) -> ())? ): Type
	local self = setmetatable({
		
		_truths = {};
		_type =  if str == "any" then nil else str;
		
		instantiates = if instantiates then instantiates else DummyMethod;
		
	}, Type)
	
	if instantiates then
		instantiates(self);
	end;
	
	table.freeze(self)
	table.freeze(self._truths);
	
	return self;
end;

--Defines a new set that will enforce that any <code>EnumItem</code> is of the passed parent <code>enum</code> type.
function Type.enum(enum: Enum): Set
	local set = Type.EnumItem();
	
	set:add_truth(function(value)
		return Truths.enum(value, enum);
	end)
	
	set:add_cast(function(value, in_value)
		if value.EnumType ~= enum then
			return nil, `unable to cast (value is not EnumType {enum})`;
		end
		
		return value;
	end)
	
	set:add_cast_rule("string", function(value)
		return enum[value];
	end)
	
	return set;
end

--Casts a table into a json compatible table, any non-primitive types are casted into a <code>string</code>.
function Type.json_compatible(tbl: any): any
	if typeof(tbl) ~= "table" then return end;
	
	local tbl2 = Table.clone(tbl);
	
	for i, v in pairs(tbl) do
		if typeof(v) == "table" then
			tbl2[i] = Type.json_compatible(v);
			
		elseif typeof(v) ~= "string" and typeof(v) ~= "boolean" and typeof(v) ~= "number" then
			tbl2[i] = Type.string:cast(v);
			
		else
			tbl2[i] = v;
		end;
	end;
	
	return tbl2;
end

-- Generates an instantiated <code>Set</code> that matches the type of the value.
function Type.define(value: any, strict: boolean?): Set
	local value_type = typeof(value);
	local dtype = Type[value_type]();
	
	if typeof(value) == "table" then
		local definitions = {};
		
		for key, next_value in pairs(value) do
			local next_type = typeof(next_value);
			
			if next_type == "table" then
				definitions[key] = Type.define(next_value);
			else
				definitions[key] = Type[next_type]();
			end
		end
		
		if strict then
			dtype:with(definitions);
		else
			dtype:somewhat(definitions);
		end
	end;
	
	return dtype;
end;

-- Returns a string that is in user-friendly editable format (to 3dp).
function Type.format_string(value: any, data_type: string?): string
	if not data_type then
		data_type = typeof(value);
	end;
	
	local cast_type = Type[data_type];
	
	if cast_type then
		return Type.stringenum:cast( cast_type:cast(value) );
	else
		return tostring(value); -- womp womp :(
	end;
end;

export type Type = typeof(Type.typeof(...));

----------------------------------------------------------------------------

Type.any = Type.typeof("any");
Type.boolean = Type.typeof("boolean");
Type.number = Type.typeof("number")
Type.string = Type.typeof("string");
Type.Vector2 = Type.typeof("Vector2");
Type.Vector3 = Type.typeof("Vector3");
Type.Color3 = Type.typeof("Color3");
Type.CFrame = Type.typeof("CFrame");
Type.Rect = Type.typeof("Rect");
Type.NumberRange = Type.typeof("NumberRange");
Type.ColorSequence = Type.typeof("ColorSequence");
Type.NumberSequence = Type.typeof("NumberSequence");
Type.Instance = Type.typeof("Instance");
Type.Enum = Type.typeof("Enum");
Type.EnumItem = Type.typeof("EnumItem");
Type.table = Type.typeof("table");
Type.BrickColor = Type.typeof("BrickColor");
Type.UDim2 = Type.typeof("UDim2");

Type.string32 = Type.typeof("string", function(set) set:length(0, 32); end)
Type.string64 = Type.typeof("string", function(set) set:length(0, 64); end)
Type.string256 = Type.typeof("string", function(set) set:length(0, 256); end)

Type.integer = Type.typeof("number", function(set) set:integer() end)
Type.Model = Type.typeof("Instance", function(set) set:isa("Model") end)
Type.Player = Type.typeof("Instance",  function(set) set:isa("Player") end)
Type.Humanoid = Type.typeof("Instance",  function(set) set:isa("Humanoid") end)
Type.BasePart = Type.typeof("Instance",  function(set) set:isa("BasePart") end)
Type.RemoteEvent = Type.typeof("Instance",  function(set) set:isa("RemoteEvent") end)

Type.stringenum = Type.typeof("string", function(set)
	set:add_cast_rule("CFrame", function(value: CFrame)
		local rx, ry, rz = value:ToEulerAnglesXYZ();
		
		return `{format_number(value.X)}, {format_number(value.Y)}, {format_number(value.Z)}, {format_number(rx)}, {format_number(ry)}, {format_number(rz)}`;
	end);
	
	set:add_cast_rule("Vector3", function(value)
		return `{format_number(value.X)}, {format_number(value.Y)}, {format_number(value.Z)}`;
	end);
	
	set:add_cast_rule("NumberRange", function(value)
		return `{format_number(value.Min)}, {format_number(value.Max)}`;
	end);
	
	set:add_cast_rule("number", function(value)
		return `{format_number(value)}`;
	end);
	
	set:add_cast_rule("EnumItem", function(value)
		return value.Name;
	end)
end)

Type.integer32 = Type.typeof("number", function(set)
	set:integer();
	set:range(-2147483648, 2147483648);
end)

Type.integer16 = Type.typeof("number", function(set)
	set:integer();
	set:range(-32768, 32768);
end)

----------------------------------------------------------------------------

table.freeze(Type);

return Type;