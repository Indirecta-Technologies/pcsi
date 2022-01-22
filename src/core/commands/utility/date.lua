local cmd = {
	name = script.Name,
	desc = [[Date view and format]],
	usage = [[$ date (formatString) (unix)]],
    displayOutput = true,
	fn = function(plr, pCsi, essentials, args)
		return os.date((args[1] or "%c"),(args[2] or os.time() ) )
	end,
}

return cmd
