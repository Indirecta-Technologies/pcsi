local cmd = {
	name = script.Name,
	desc = [[Unset OS Variable]],
	usage = "$ unset <varname>[ <varname2> [...]]",
	displayOutput = true,
	fn = function(plr, pCsi, essentials, args)
    if #args < 1 then
      pCsi.io.write("Usage: unset <varname>[ <varname2> [...]]")
    else
      for _, k in ipairs(args) do
        pCsi.setVar(k, nil)
      end
    end
	end,
}

return cmd
