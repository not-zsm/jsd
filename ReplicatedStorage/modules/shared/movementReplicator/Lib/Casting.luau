local TypeCasts = {
	string = {
		any = function(value: any)
			return tostring(value);
		end,
		
		number = function(value: number)
			return tostring(math.round(value*1e7)/1e7);
		end,

		Color3 = function(value: Color3)
			return `{math.round(value.R*255)}, {math.round(value.G*255)}, {math.round(value.B*255)}`;
		end,
	};
	NumberRange = {
		string = function(value: string)
			local split = string.split(value, ",");
			
			return NumberRange.new( tonumber(split[1]), tonumber(split[2]) )
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
	Color3 = {
		string = function(value: string)
			local split = string.split(value, ",");

			return Color3.fromRGB(
				tonumber(split[1]) or 0, 
				tonumber(split[2]) or 0, 
				tonumber(split[3]) or 0
			)
		end,
	};
	Vector3 = {
		string = function(value: string)
			return Vector3.new(unpack(string.split(value, ",")));
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

return function(value: any, to_type: string): (boolean, any)
	local value_type = typeof(value);
	
	if TypeCasts[to_type] then
		local cast_function = TypeCasts[to_type][value_type] or TypeCasts[to_type].any;
		
		if cast_function then
			local success, cast_value = pcall(cast_function, value);
			
			if success then
				return true, cast_value;
			end;
		end;
	end;
	
	return false, nil;
end