--!nocheck
local deb = game:GetService("Debris");
local runs = game:GetService("RunService");

local Handler = {};

function Handler:playSound( sfx : Sound, sfxParent, sfxGroup, props, playOnRemove )
	if sfx == nil then return; end;
	sfxParent = sfxParent;
	props = props or {};

	if typeof(sfx) == "table" then
		for i = 1, #sfx do
			if (sfx[i] == nil) then
				table.remove(sfx, i);
			end;
		end;
		sfx = sfx[math.random(1,#sfx)]:Clone();
	else
		sfx = sfx:Clone();
	end;

	for property,value in pairs(props) do
		sfx[property] = value;
	end;

	sfx.Parent = sfxParent;

	if playOnRemove then
		sfx.PlayOnRemove = true;
		sfx:Destroy();
	else
		sfx:Play();

		if ( runs:IsServer() == true ) then
			if sfx.Looped == false then
				deb:AddItem( sfx , sfx.TimeLength+1 );
			end;
		elseif ( runs:IsClient() == true ) then
			if sfx.Looped == false then
				sfx.Ended:Connect(function()
					sfx:Destroy();
				end);
			end;
		end;
	end;

	return sfx;
end;

return Handler;