local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NewspaperViewer = {}
NewspaperViewer.__index = NewspaperViewer

local NewsData = require( script.NewsData )
local LocalPlayer = game:GetService("Players").LocalPlayer

function NewspaperViewer.new()
	local self = setmetatable({}, NewspaperViewer)
	
	self.ScreenGui = script.ScreenGui:Clone()
	self.GUI = self.ScreenGui.NewspaperFrame
	self.GUI.Visible = false
	self.ScreenGui.Parent = LocalPlayer.PlayerGui
	
	self.PageImage = self.GUI:WaitForChild("PageImage")
	self.LeftButton = self.GUI:WaitForChild("LeftButton")
	self.RightButton = self.GUI:WaitForChild("RightButton")
	self.ExitButton = self.GUI:WaitForChild("ExitButton")
	self.SecretButton = self.GUI:WaitForChild("SecretButton")
	self.NewsData = NewsData
	self.CurrentArticle = nil
	self.CurrentPage = 1
	
	self.NPC = workspace:WaitForChild("NPC's", 100):WaitForChild("News Boy", 100)
	
	self:_setupConnections()

	return self
end

function NewspaperViewer:_setupConnections()
	self.LeftButton.MouseButton1Click:Connect(function()
		self:PreviousPage()
	end)

	self.RightButton.MouseButton1Click:Connect(function()
		self:NextPage()
	end)

	self.ExitButton.MouseButton1Click:Connect(function()
		self:Close()
	end)
	
	self.SecretButton.MouseButton1Click:Connect(function()
		self:SecretPage()
	end)
end

function NewspaperViewer:OpenArticle(Article)
	if self.NPC then
		self.NPC:SetAttribute("Reading", true)
	end
	
	ReplicatedStorage.Remotes.NPCs.ReadPaper:FireServer(true)
	
	self.CurrentArticle = Article
	self.CurrentPage = 1
	self.GUI.Visible = true
	self:UpdatePage()
end

function NewspaperViewer:UpdatePage()
	local pages = self.CurrentArticle.Pages
	if pages and pages[self.CurrentPage] then
		self.PageImage.Image = pages[self.CurrentPage]
	end
	
	if self.CurrentArticle.SecretPage and self.CurrentArticle.SecretPage.StartPage == pages[self.CurrentPage] then
		self.SecretButton.Visible = true
	else
		self.GUI.SecretButton.Visible = false
	end
end

function NewspaperViewer:NextPage()
	local pages = self.CurrentArticle.Pages
	if self.CurrentPage < #pages then
		self.CurrentPage += 1
		self:UpdatePage()
	end 
end

function NewspaperViewer:PreviousPage()
	if self.CurrentPage > 1 then
		self.CurrentPage -= 1
		self:UpdatePage()
	end
end

function NewspaperViewer:Close()
	self.GUI.Visible = false
	self.CurrentArticle = nil
	self.CurrentPage = 1
	
	if self.NPC then
		self.NPC:SetAttribute("Reading", false)
	end
	
	ReplicatedStorage.Remotes.NPCs.ReadPaper:FireServer(false)
end

function NewspaperViewer:GetChoices()
	local Choices = {}
	for _, Article in ipairs(NewsData) do
		table.insert(Choices, {
			Text = Article.Name,
			Function = function()
				self:OpenArticle(Article)

				script.PaperSound:Play()
			end,
			EndConversation = true
		})
	end

	table.insert(Choices, {Text = "Nope", EndConversation = true})
	
	return Choices
end

function NewspaperViewer:SecretPage()
	self.PageImage.Image = self.CurrentArticle.SecretPage.Secret
end


return NewspaperViewer
