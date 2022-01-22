local cmd = {
	name = script.Name,
	desc = [[Execute HTTP requests like GET, POST, and also PING, displays the output in requested content type]],
	usage = "$ http post httpbin.org/post application/json {hello: 'world'}\n      $ http ping google.com",
	displayOutput = true,
	fn = function(plr, pCsi, essentials, args)
		local method = args[1]
		local player_opt = game:GetService("Players"):GetPlayers()[args[2]]

		if player_opt then
        player_opt = player_opt.UserId
		table.remove(args, 1)
		end
		table.remove(args, 1)

		local text = table.concat(args," ")

        local TextService = game:GetService("TextService")
		local allowedEndpoints = {["GetChatForUserAsync"] = true, ["GetNonChatStringForBroadcastAsync"] = true, ["GetNonChatStringForUserAsync"] = true}

		if not allowedEndpoints[method] then return "Unallowed method: "..method end

		local function getTextObject(message, fromPlayerId)
			local textObject
			local success, errorMessage = pcall(function()
				textObject = TextService:FilterStringAsync(message, fromPlayerId)
			end)
			if success then
				return textObject
			end
			return false
		end

        print(plr.Name)
        text = getTextObject(text, plr.UserId)

        local filteredText = ""
        local success, errorMessage = pcall(function()
            print(player_opt)
            filteredText = text[method](text, player_opt)
        end)
        if not success then
           filteredText = "TextService Filter Error: "..errorMessage
            -- Put code here to handle filter failure
        end

		return filteredText
	end,
}

return cmd
