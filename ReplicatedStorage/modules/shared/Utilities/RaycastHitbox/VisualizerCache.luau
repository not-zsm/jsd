-- @author Swordphin123

local Cache = {}
Cache._AdornmentInUse = {}
Cache._AdornmentInReserve = {}

--export type AdornmentData = {
--	Adornment : LineHandleAdornment,
--	LastUse: number
--}

function Cache._CreateAdornment()
	local Line = Instance.new("LineHandleAdornment")
	Line.Name = "_DebugLine"
	Line.Color3 = Color3.fromRGB(255, 0, 0)
	Line.Thickness = 4

	Line.Length = 0
	Line.CFrame = CFrame.new(0, math.huge, 0)

	Line.Adornee = workspace.Terrain
	Line.Parent = workspace.Terrain

	return {Adornment = Line, LastUse = 0}
end

function Cache.GetAdornment()
	if #Cache._AdornmentInReserve <= 0 then
		table.insert(Cache._AdornmentInReserve, Cache._CreateAdornment())
	end
	
	local Adornment = table.remove(Cache._AdornmentInReserve, 1)

	if Adornment ~= nil then
		Adornment.Adornment.Visible = true
		Adornment.LastUse = time()
		
		table.insert(Cache._AdornmentInUse, Adornment)
	end

	return Adornment
end

function Cache.ReturnAdornment(Adornment)
	Adornment.Adornment.Length = 0
	Adornment.Adornment.Visible = false
	Adornment.Adornment.CFrame = CFrame.new(0, math.huge, 0)
	
	table.insert(Cache._AdornmentInReserve, Adornment)
end

function Cache.Clear()
	for Index = #Cache._AdornmentInReserve, 1, -1 do
		if Cache._AdornmentInReserve[Index].Adornment then
			Cache._AdornmentInReserve[Index].Adornment:Destroy()
		end

		table.remove(Cache._AdornmentInReserve, Index)
	end
end

return Cache