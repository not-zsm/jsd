local Utility = {};

-- Clears table 'target' and copies the contents of table 'source' into table 'target'.
function Utility.set_table(target: {[any]: any}, source: {[any]: any}): ()
	table.clear(target);
	for key, value in source do
		target[key] = value;
	end;
end

return Utility;