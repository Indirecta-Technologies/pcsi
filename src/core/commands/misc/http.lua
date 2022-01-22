local cmd = {
	name = script.Name,
	desc = [[Execute HTTP requests like GET, POST, and also PING, displays the output in requested content type]],
	usage = "$ http post httpbin.org/post application/json {hello: 'world'}\n      $ http ping google.com",
	displayOutput = true,
	fn = function(plr, pCsi, essentials, args)
		local http = game:GetService("HttpService")
		local method = string.upper(args[1])
		local url = "http://"..args[2]
		
		if method == "PING" then
			local startTime = tick()
			local request = http:RequestAsync({
				Url = url,  -- This website helps debug HTTP requests
				Method = "GET",
				Headers = {
					["Content-Type"] = "application/json", 
					["Source"] = "Indirecta.Xinu."..essentials.Identification.SERIAL,
				},
				Body = nil
			})
			local endTime = tick()
			local value = endTime-startTime
			value = math.abs(value)*1000
			value *= 100
			value = math.floor(value)
			value /= 100

			essentials.Console.info("Ping to <b>"..url.."</b> took <b>"..value.."ms</b>")
			return
		end
		local ctype = args[3]
		table.remove(args,1); 			table.remove(args,1); 			table.remove(args,1); 
		local body = table.concat(args, " ")
		if method == "GET" or method == "HEAD" then body = nil end
		local request = http:RequestAsync({
			Url = url,  -- This website helps debug HTTP requests
			Method = method,
			Headers = {
				["Content-Type"] = ctype, 
				["Source"] = "Indirecta.Xinu."..essentials.Identification.SERIAL,
			},
			Body = body
		})
		
		--local bf = require(script.BrainFudge)
		--bf = bf.execute(table.concat(args," "))
		--essentials.Console.info("bf: "..bf)
		return request.Body
	end,
}

return cmd
