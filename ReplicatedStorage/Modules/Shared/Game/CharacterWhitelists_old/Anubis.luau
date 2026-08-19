local IsTestPlace = workspace:GetAttribute("IsTestPlace")

if IsTestPlace == nil then
	workspace:GetAttributeChangedSignal("IsTestPlace"):Wait()
	IsTestPlace = workspace:GetAttribute("IsTestPlace")
end 

local TestingWhitelist = {
	123188555, -- mxitz
	1242679803, -- mj
	7207821215, -- swrerm
	141123572, -- jimpee
	242509995, -- binx
	119987926, -- rod
	166263406, -- boost
	2912663972, -- hyrum
	699372072, -- dante
	1862053911, -- arc
	143901924, -- vensoul
	150522417, -- erykos05
}

local MainWhitelist = { 
	123188555, -- mxitz
	7207821215, -- swrerm
	141123572, -- jimpee
	150522417, -- erykos05
}

return if IsTestPlace then TestingWhitelist else MainWhitelist