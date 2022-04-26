
local cmd = {
	name = script.Name,
	desc = [[Study current working directory of files and produce a mixed output]],
	displayOutput = true,
	usage = [[$ markovchain true 2500]],
	fn = function(plr, pCsi, essentials, args)
		local chain = pCsi.libs.markovchain
        local studyPunctuation = args[#args - 1]
        local size = args[#args]
        local markov = chain.new()
		local weight = 0;


        for obj in pCsi.xfs.list() do
            local bytes = pCsi.xfs:totalBytesInInstance(obj.Name)
				  bytes = pCsi.xfs:formatBytesToUnits(bytes)
            local name = obj.Name
            obj = pCsi.xfs.read(name)

			pCsi.io.write("[Markov-Chain] :: Studying ".. name .." source ".."; "..bytes.." size")
			markov:Study(obj,studyPunctuation)
        end


		pCsi.io.write("[Markov-Chain] :: Generating output of "..size.." words..")
		local output = markov:Generate(args)
        return output

	end,
}

return cmd
