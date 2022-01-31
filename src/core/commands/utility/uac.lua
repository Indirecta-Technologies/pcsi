local cmd = {
	name = script.Name,
	desc = [[User Account Control]],
	usage = [[$ uac]],
	displayOutput = true,
	fn = function(pCsi, essentials, argse)
		local oldparse = pCsi.parseCommand
		local loggedIn = true
		local sha256 = pCsi.libs.sha_256

		local password = "myPassword123"
        local salt = "@@##!/()89732423mySLalt##!ç§*è§VERYNICEk"

		local paswLength = #password
		local pasw = sha256().updateStr(salt..password..salt).finish().asHex()
		password = nil

        task.wait(0.9)
		essentials.Console.info("** USER ACCOUNT CONTROL **")
		essentials.Console.info("log(o)ut  -  (q)uit")

		function pCsi:parseCommand(args)
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
					essentials.Console.info("uac :: Wrong password (" .. paswLength .. ")")
				end
			elseif loggedIn then
				essentials.Console.info("uac :: Invalid option; Use q/quit to exit")
			end
		end

	end,
}

return cmd
