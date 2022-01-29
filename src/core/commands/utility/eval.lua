local eval = require(script.Parent.Parent.Parent.lib.MathEvaluator)


local cmd = {
	name = script.Name,
	desc = [[Evaluate a mathematic expression]],
	usage = [[$ eval 2+2]],
	displayOutput = true,
	fn = function(plr, pCsi, essentials, args)
		return eval(table.concat(args, " "), eval.SYParser)
	end,
}

return cmd
