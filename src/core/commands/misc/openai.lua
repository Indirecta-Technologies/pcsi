local cmd = {
	name = script.Name,
	desc = [[Execute HTTP requests like GET, POST, and also PING, displays the output in requested content type]],
	usage = "$ http post httpbin.org/post application/json {hello: 'world'}\n      $ http ping google.com",
	displayOutput = true,
	fn = function(plr, pCsi, essentials, args)
		local http = game:GetService("HttpService")
		
		local body = table.concat(args, " ")
		local request = http:RequestAsync({
			Url = "https://api.openai.com/v1/engines/text-davinci-001/completions",  -- This website helps debug HTTP requests
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json", 
				["Source"] = "Indirecta.Xinu."..essentials.Identification.SERIAL,
                ["Authorization"] = "Bearer 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"
			},
			Body = http:JSONEncode({
                prompt = body,
                max_tokens = 1000
              })
		})
		print(request.Body)
        local newbody = http:JSONDecode(request.Body).choices[1]

        local TextService = game:GetService("TextService")
        local filteredText = ""
        local success, errorMessage = pcall(function()
            filteredText = TextService:GetNonChatStringForBroadcastAsync(newbody.text)
        end)
        if not success then
           filteredText = "TextService Filter Error: "..errorMessage
            -- Put code here to handle filter failure
        end

		return body..newbody.text:sub(80)..(#newbody.text > 80 and "..." or "").."\n("..newbody.finish_reason..")"
	end,
}

return cmd
