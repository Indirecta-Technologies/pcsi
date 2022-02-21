local cmd = {
	name = script.Name,
	desc = [[Date view and format]],
	usage = [[$ date (formatString) (unix)]],
    displayOutput = true,
	fn = function(plr, pCsi, essentials, args)
		return essentials.Output:OutputToAll("ClearScreen")
	end,
}

return cmd
