local cmd = {
	name = script.Name,
	desc = [[Chat and display your identity]],
	usage = "$ chat",
	displayOutput = true,
	fn = function(plr, pCsi, essentials, args)
		-- THIS DOES NOT FILTER MESSAGES YET!!!!!!!!!!!!!!!!
        -- Daily Reminder: Make Pointcove Keyboard and Pcsi work with DisplayOverBindable
		local oldparse = pCsi.parseCommand

        local function processMessage(player, message)
        return message
        end

        local function waitForMessage(player)
            function pCsi:parseCommand(...)
                input = { ... }
                local plra = input[1]
                table.remove(input, 1)
                if input == "!quit" or input == "!q" then
                    pCsi.io.write(player.Name.." "..(player == plra and "ended his session" or "'s session was ended by "..plra.Name))
                    pCsi.parseCommand = oldparse
                end
                if not plra == player then pCsi.io.write("This chat session is being used by "..player.Name..", consider ending the session? '!quit' ") end
                input = processMessage(plra, table.concat(input," "))

                local ss, fm = pcall(function()
                    pCsi.io.write(plra.UserId.." "..plra.Name.." :: \n"..input.." :: ")
                end)
               
            end
        end
        
        waitForMessage()
		
	end,
}

return cmd
