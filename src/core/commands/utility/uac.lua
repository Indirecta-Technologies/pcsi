local cmd = {
	name = script.Name,
	desc = [[User Account Control]],
	usage = [[$ uac]],
	displayOutput = true,
	fn = function(plr, pCsi, essentials, argse)
		local oldparse = pCsi.parseCommand
		local loggedIn = true

		math.randomseed(os.time()*plr.UserId+tick())

		local sha256 = pCsi.libs.sha_256
        local salt = "@@##!/()89732423mySLalt##!ç§*è§VERYNICEk"..math.random(1111,999999)

		local pasw = sha256().updateStr(salt.."myPassword123"..salt).finish().asHex()
		salt = nil

        task.wait(0.9)
		essentials.Console.info("** USER ACCOUNT CONTROL **")
		essentials.Console.info("log(o)ut  -  (q)uit")

		function pCsi:parseCommand(plr, args)
			args = string.split(args, " ")
			if args[1] == "q" or args[1] == "quit" and loggedIn then
				self.parseCommand = oldparse
				return
			elseif args[1] == "o" or args[1] == "logout" and loggedIn then
				essentials.Console.info("uac :: Terminal Locked; Input pasw to unlock")
				loggedIn = false
			elseif not loggedIn then
				local newpass = sha256().updateStr(salt..table.concat(args, " ")..salt).finish().asHex()
				if newpass == pasw then
					essentials.Console.info("uac :: Terminal unlocked")
					self.parseCommand = oldparse
					loggedIn = true
				else
					essentials.Console.info("uac :: Wrong password")
				end
			elseif loggedIn then
				essentials.Console.info("uac :: Invalid option; Use q/quit to exit")
			end
		end

	end,
}

return cmd
