local cmd = {
	name = script.Name,
	desc = [[Output the input]],
	usage = [[$ echo]],
	displayOutput = true,
	fn = function(plr, pCsi, essentials, args)
		-- display os aguments if $ precedes an argument, this should be done directly by the parser
		local bfr = ""
		for i,v in ipairs(args) do 
			bfr ..= tostring(v)..(i < #v and " "or"")
		end

		return table.concat(args, " ")
	end,
}

return cmd
