local cmd = {
	name = script.Name,
	desc = [[WIP]],
	usage = [[]], --TO REDO
	displayOutput = false,
	fn = function(plr, pCsi, essentials, args)
		math.randomseed(os.time())
		local number = math.random(1, 100)
		local player = {}
		player.guess = 0
		while player.guess ~= number do
			pCsi.io.write("Guess a number between 1 and 100")
			player.answer = pCsi.io.read()
            pCsi.io.write("> "..player.answer)
			player.guess = tonumber(player.answer)
            local diff = math.random(number-20, player.guess + 20)
			if player.guess > number then
				pCsi.io.write("Too high, random difference: "..diff.." (20% precision)")
			elseif player.guess < number then
				pCsi.io.write("Too low, random difference: "..diff.." (20% precision)")
			else
				pCsi.io.write("That's right!")
				os.exit()
			end
		end
	end,
}

return cmd
