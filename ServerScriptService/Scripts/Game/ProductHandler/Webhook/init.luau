local Webhook = {}

function Webhook:Send(Title, Description)
	local HttpService = game:GetService("HttpService")
	local Data = {
		["embeds"] = {
			{
				title = Title,
				description = Description,
			}
		}
	}		

	Data = HttpService:JSONEncode(Data)

	local Request
	pcall(function()
		Request = HttpService:PostAsync(require( script.Url ), Data)
	end)
end

return Webhook
