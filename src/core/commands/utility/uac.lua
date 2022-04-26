local cmd = {
	name = script.Name,
	desc = [[User Account Control]],
	usage = [[$ uac]],
	displayOutput = true,
	fn = function(plr, pCsi, essentials, args)
		local oldparse = pCsi.parseCommand
		local loggedIn = true

		math.randomseed(os.time()*plr.UserId+tick())

		local sha256 = pCsi.libs.sha_256
        local salt = "@@##!/()89732423mySLalt##!ç§*è§VERYNICEk"..math.random(1111,999999)

		local pasw = sha256().updateStr(salt.."myPassword123"..salt).finish().asHex()

        task.wait(0.9)
		pCsi.io.write("** USER ACCOUNT CONTROL **")
		pCsi.io.write("log(o)ut  -  (q)uit  - (c)hange")

		function pCsi:parseCommand(plr, args)
			args = string.split(args, " ")
			if args[1] == "q" or args[1] == "quit" and loggedIn then
				self.parseCommand = oldparse
				return
			elseif args[1] == "o" or args[1] == "logout" and loggedIn then
				loggedIn = false
				essentials.Output:OutputToAll("ClearScreen")
				pCsi.io.write("uac :: Terminal Locked; Input pasw to unlock")
			elseif args[1] == "c" or args[1] == "change" and loggedIn then
				pCsi.io.write("uac :: Old password: ")
				local newpass = sha256().updateStr(salt.. pCsi.io.read()..salt).finish().asHex()
				if newpass == pasw then
				pCsi.io.write("uac :: New password: ")
				local newwpass = sha256().updateStr(salt.. pCsi.io.read()..salt).finish().asHex()
				pCsi.io.write("uac :: Repeat: ")
				local newwwpass = sha256().updateStr(salt.. pCsi.io.read()..salt).finish().asHex()
				if newwwpass == newwpass then
					pasw = newwwpass; 
					pCsi.io.write("uac :: Changed password")
					--loggedIn = false; essentials.Output:OutputToAll("ClearScreen"); pCsi.io.write("uac :: Changed password and logged out")
				else return pCsi.io.write("uac :: <b>"..plr.Name.."</b>, wrong password")
				end

				else return pCsi.io.write("uac :: <b>"..plr.Name.."</b>, wrong password")
				end
			elseif not loggedIn then
				print(salt, args)
				local newpass = sha256().updateStr(salt..table.concat(args, " ")..salt).finish().asHex()
				if newpass == pasw then
					pCsi.io.write("uac :: Terminal unlocked")
					self.parseCommand = oldparse
					loggedIn = true
				else
					pCsi.io.write("uac :: <b>"..plr.Name.."</b>, wrong password")
				end
			elseif loggedIn then
				pCsi.io.write("uac :: Invalid option; Use q/quit to exit")
			end
		end

	end,
}

return cmd
