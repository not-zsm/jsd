local RunService = game:GetService("RunService")

local function Tip(Text : string)
	return function(GUI : TextButton)
		GUI.Button.Skill.Tip.Text = Text
		GUI.Button.Skill.Tip.Visible = true
	end
end

local module = {
	["Lapse Pull"] = {
		OnAdded = Tip("[CURSOR AIMED]")
	},

	["Check"] = {
		OnAdded = Tip("[CURSOR AIMED]")
	},

	-----------------------------------

	["Fight"] = {
		OnAdded = Tip("[TIMED]")
	},

	["Seven Souls"] = {
		OnAdded = Tip("[TIMED]")
	},

	-----------------------------------

	["Chaos Barrage"] = {
		OnAdded = Tip("[HOLD SPACE]")
	},

	["Ruthless Beatdown"] = {
		OnAdded = Tip("[HOLD SPACE]")
	},

	["Helping Hand"] = {
		OnAdded = Tip("[HOLD SPACE]")
	},

	-----------------------------------

	["Whirlwind Slam"] = {
		OnAdded = Tip("[USE TWICE]")
	},

	["Staff Whiplash"] = {
		OnAdded = Tip("[UNFINISHED]")
	},

	-----------------------------------

	["Reset"] = {
		OnAdded = Tip("[COUNTER]")
	},

	["Evil Spirit"] = {
		OnAdded = Tip("[COUNTER]")
	},

	-----------------------------------

	["YOU THOUGHT!"] = {
		OnAdded = Tip("[FEINT]")
	},

	-----------------------------------

	["Spirit Link"] = {
		OnAdded = Tip("[DAMAGE BUFF]")
	},

	-----------------------------------

	["W.I.P"] = {
		OnAdded = Tip("[W.I.P]")
	}
}

if workspace:GetAttribute("DisableAtonement") then
	module["Atonement"] = {
		OnAdded = Tip("[DISABLED]")
	}
end

return module