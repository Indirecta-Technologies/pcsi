local cmd = {
	name = script.Name,
	desc = [[Word, lines, bytes, chars count]],
    displayOutput = true,
	usage = [[$ wc]],
	fn = function(plr, pCsi, essentials, args)
        
        args = table.concat(args, " ")

        -- return lines, words, bytes, characters of args
       

		local isFile = pCsi.xfs.exists(args)
		local file = isFile and pCsi.xfs.read(args) or nil
        
    
            local data = isFile and file or args
            local lines, words, bytes, chars = 0, 0, 0, 0
        for line in data:gmatch("[^\r\n]+") do
            lines = lines + 1
            for word in line:gmatch("[^%s]+") do
                words = words + 1
                bytes = bytes + #word
                for char in word:gmatch(".") do
                    chars = chars + 1
                end
            end
        end
        

       return lines.." "..words.." "..(bytes == chars and bytes or bytes.." "..chars).." "..(isFile and args or "")-- number of lines, word count, byte and characters count
	end,
}

return cmd
