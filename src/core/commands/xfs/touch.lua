local cmd = {
	name = script.Name,
	desc = [[Usage: touch [OPTION]... FILE...
	Update the modification times of each FILE to the current time.
	A FILE argument that does not exist is created empty, unless -c is supplied.
	  -c, --no-create    do not create any files
		  --help         display this help and exit]],
	usage = [[$ ]],
	fn = function(plr, pCsi, essentials, args)
		--[[Lua implementation of the UN*X touch command--]]

		local options = {
			c = false,
			help = false
		}

		local file = nil

		if args[1] == "-c" or args[1] == "--no-create" then file = args[2]; options.c = true end
		if args[1] == "--help" then file = args[2]; options.help = true end

		local function usage()
			print([[Usage: touch [OPTION]... FILE...
Update the modification times of each FILE to the current time.
A FILE argument that does not exist is created empty, unless -c is supplied.
  -c, --no-create    do not create any files
      --help         display this help and exit]])
		end

		if options.help then
			usage()
			return 0
		elseif #args == 0 then
			pCsi.io.write("touch: missing operand\n")
			return 1
		end

		options.c = options.c or options["no-create"]
		local errors = 0
		
		for _, arg in ipairs(args) do
			
					if pCsi.xfs.exists(file) or not options.c then
						file = pCsi.xfs.read(file)
					end
					if not file then
						file = options.c
					end
				if not file then
					pCsi.io.write(string.format("touch: cannot touch `%s'", arg))
					errors = 1
				end
			
		end

		return errors
	end,
}

return cmd
