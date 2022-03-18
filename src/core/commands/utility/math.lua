

local cmd = {
	name = script.Name,
	desc = [[Evaluate a mathematic expression]],
	usage = [[$ eval 2+2]],
	displayOutput = true,
	fn = function(plr, pCsi, essentials, args)
		local eval = pCsi.libs.MathEvaluator
		return eval(table.concat(args, " "), eval.SYParser)
	end,
}

return cmd
