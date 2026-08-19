--!native
--!strict

local ServerScriptService = game:GetService("ServerScriptService")

---------------------------------------------------------------------------------------------------

local Data = require( script.Parent ) :: {[string]: {string}}

---------------------------------------------------------------------------------------------------

local Properties = {};
Properties.inheritance_cache = {};
Properties.properties_cache = {};

---------------------------------------------------------------------------------------------------

@native local function get_property(instance: Instance, property: string): any
	return instance[property];
end

@native local function get_inheritance_tree_cache(instance: Instance): {string}
	local class_name = instance.ClassName;
	local inheritance_tree = Properties.inheritance_cache[class_name];
	
	if not inheritance_tree then
		inheritance_tree = {};

		if Data[class_name] then
			table.insert(inheritance_tree, class_name);
		end;
		
		for other_class, properties in Data do
			if instance:IsA(other_class) then
				table.insert(inheritance_tree, other_class);
			end
		end
		
		table.freeze(inheritance_tree);
		Properties.inheritance_cache[class_name] = inheritance_tree;
	end;
	
	return inheritance_tree;
end

@native local function get_properties_cache(instance: Instance): {[string]: boolean}
	local class_name = instance.ClassName;
	local properties = Properties.properties_cache[class_name];

	if not properties then
		properties = {};

		for _, class in get_inheritance_tree_cache(instance) do
			for _, property in Data[class] do
				properties[property] = true;
			end;
		end;
		
		table.freeze(properties);
		Properties.properties_cache[class_name] = properties;
	end;

	return properties;
end

---------------------------------------------------------------------------------------------------

-- Returns a copy of the inheritance tree array of a class.
function Properties.get_inheritance_tree(instance: Instance?): {string}
	if typeof(instance) ~= "Instance" then
		return {};
	end;
	
	local tree = get_inheritance_tree_cache(instance);
	
	return table.clone(tree);
end

-- Returns whether a property is valid for the given instance.
function Properties.is_property(instance: Instance, property: string): boolean
	if typeof(instance) ~= "Instance" then
		return false;
	end;
	
	if get_properties_cache(instance)[property] then
		return true;
	end;
	
	return false;
end

-- Returns a copy of the table of properties where the index is the property.
function Properties.get_properties(instance: Instance?): {[string]: boolean}
	if typeof(instance) ~= "Instance" then
		return {};
	end;
	
	local properties = get_properties_cache(instance);
	
	return table.clone(properties);
end;

-- Returns the dictionary of properties of the given instance. Where the key is the property, and the value is the value of the property.
function Properties.get_properties_of(instance: Instance): {[string]: any}
	assert(instance, "No Instance was passed");
	
	local properties: {[string]: any} = {};
	
	for property in get_properties_cache(instance) do
		local success, value = pcall(get_property, instance, property);
		
		if success then
			properties[property] = value;
		end;
	end;
	
	return properties;
end

---------------------------------------------------------------------------------------------------

table.freeze(Properties);

return Properties;