-- If keys is a table it means either key will do the same thing.

local Data = 
	{
		{ id = "UNDO"; text = "Undo"; keys = Enum.KeyCode.Z; control = true; };
		{ id = "REDO"; text = "Redo"; keys = Enum.KeyCode.Y; control = true; };
		{ id = "CLONE"; text = "Clone"; keys = Enum.KeyCode.F; control = true; };
		{ id = "COPY"; text = "Copy"; keys = Enum.KeyCode.C; control = true; };
		{ id = "PASTE"; text = "Paste"; keys = Enum.KeyCode.V; control = true; };
		{ id = "GROUP"; text = "Group"; keys = Enum.KeyCode.G; control = true; };
		{ id = "RESET_ORIENTATION"; text = "Resets selected part's orientation"; keys = Enum.KeyCode.U; control = true; };
		{ id = "ROTATE"; text = "Rotates parts by 45 degrees"; keys = Enum.KeyCode.R; control = true; };
		{ id = "TILT"; text = "Tilts parts by 45 degrees"; keys = Enum.KeyCode.T; control = true; };
		{ id = "LOCAL_SPACE"; text = "Toggle Local Space"; keys = Enum.KeyCode.L; control = true; };
		{ id = "SAVE_TO_HOTBAR"; text = "Save Selected To Hotbar"; keys = Enum.KeyCode.H; control = true; };
		{ id = "CLOSE_UI"; text = "Opens/Closes the user interface"; keys = Enum.KeyCode.RightBracket;};
		{ id = "INVENTORY_OPEN"; text = "Open the Inventory"; keys = Enum.KeyCode.M; };
		{ id = "DESELECT_ALL"; text = "Deselects everything selected"; keys = {Enum.KeyCode.Backquote, Enum.KeyCode.Escape}; };
		{ id = "DELETE_SELECTED"; text = "Deletes selected"; keys = {Enum.KeyCode.Delete, Enum.KeyCode.Backspace, Enum.KeyCode.KeypadMinus}; };
		{ id = "GPAD_TOOL_NEXT"; text = "Next ribbon tool"; keys = Enum.KeyCode.DPadRight; };
		{ id = "GPAD_TOOL_PREV"; text = "Previous ribbon tool"; keys = Enum.KeyCode.DPadLeft; };
		{ id = "GPAD_HOTBAR_NEXT"; text = "Next hotbar slot"; keys = Enum.KeyCode.ButtonR1; };
		{ id = "GPAD_HOTBAR_PREV"; text = "Previous hotbar slot"; keys = Enum.KeyCode.ButtonL1; };
		{ id = "GPAD_DESELECT"; text = "Deselects everything selected"; keys = Enum.KeyCode.ButtonL2; };
		{ id = "GPAD_INVENTORY_OPEN"; text = "Opens the inventory"; keys = Enum.KeyCode.DPadUp; };
		{ id = "GPAD_ALTER_SELECT"; text = "Cycles the alt/control mode for non-keyboard users"; keys = Enum.KeyCode.DPadDown; };
		{ id = "RIBBON_SELECT"; text = "Use the Select tool"; keys = Enum.KeyCode.One; };
		{ id = "RIBBON_MOVE"; text = "Use the Move tool"; keys = Enum.KeyCode.Two; };
		{ id = "RIBBON_SCALE"; text = "Use the Scale tool"; keys = Enum.KeyCode.Three; };
		{ id = "RIBBON_ROTATE"; text = "Use the Rotate tool"; keys = Enum.KeyCode.Four; };
		{ id = "RIBBON_GAPFILL"; text = "Use the Gapfill tool"; keys = Enum.KeyCode.Five; };
		{ id = "RIBBON_VOXEL"; text = "Use the Voxel tool"; keys = Enum.KeyCode.Six; };
		{ id = "INSTANCE_RENAME"; text = "Renames a selected instance"; keys = Enum.KeyCode.F2; };
	};

local Schema = {};
Schema.keybinds = {};
Schema.data = Data;

function Schema.regenerate()
	table.clear(Schema.keybinds);
	
	for index, info in Data do
		Schema.keybinds[info.id] = info.keys;
	end;
end

Schema.regenerate();
table.freeze(Schema);

return Schema;