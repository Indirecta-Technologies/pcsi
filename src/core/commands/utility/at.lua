local schedules = {}

local cmd = {
	name = script.Name,
	desc = [[Schedule commands at a later time, arg1 must be a %X date (HH:MM:SS)]],
	usage = [[$ info]],
	displayOutput = true,
	fn = function(plr, pCsi, essentials, args)
		local arg1 = args[1]
		table.remove(1, args)
		local arg2 = table.concat(args, " ")
		if arg1 == "all" then
			return game:GetService("HttpService"):JSONEncode(schedules)
		else
			table.insert(schedules, task.spawn(function()
				while not arg1 == os.date("%X",os.time()) do task.wait(1) end
				pCsi.parseCommand(plr, arg2)
			end))
		end
	end,
}

return cmd
