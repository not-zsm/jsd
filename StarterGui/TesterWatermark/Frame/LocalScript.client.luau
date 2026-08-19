local UI = script.Parent

--local RunService = game:GetService("RunService")

if (game.PlaceId ~= 95576587700882) then
	UI.Visible = false
	return
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserId = LocalPlayer.UserId

if (UserId == 289049081) then
	UI.Visible = false
	return
end

local Grid = UI.UIGridLayout;
local ViewSize = workspace.CurrentCamera.ViewportSize;
local PixelSizeX = ViewSize.X * Grid.CellSize.X.Scale 
local PixelSizeY = ViewSize.Y * Grid.CellSize.Y.Scale 

local MaxCells = (ViewSize.X / PixelSizeX + 1) * (ViewSize.Y / PixelSizeY + 1)

local Template = UI.Template.Frame
local Watermarks = {};

local function Update()
	for _, Watermark in Watermarks do
		Watermark:Destroy()
	end;
	
	table.clear(Watermarks);
	
	for Index = 1, MaxCells do
		local Frame = Template:Clone()
		Frame.ID.Text = tostring(UserId)
		Frame.Parent = UI
		Frame.Visible = true

		table.insert(Watermarks, Frame);
	end
end

task.spawn(Update);
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(Update)