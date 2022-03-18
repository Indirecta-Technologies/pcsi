local cmd = {
	name = script.Name,
	desc = [[Word, lines, bytes, chars count]],
    displayOutput = true,
	usage = [[$ wc]],
	fn = function(plr, pCsi, essentials, args)
        
        args = table.concat(args, " ")
		local isFile = pCsi.xfs.exists(args)
		local file = isFile and pCsi.xfs.read(args) or nil
        
        local bytes = 0
        local chars = 0
        local words = 0
        local lines = 0
        
        local word = false
            local data = isFile and file or args
            bytes = bytes + #data
            chars = chars + utf8.len(data)
            for char in data:gmatch(".") do
                if char == "\n" then
                    lines = lines + 1
                end
                if data:match("%s") and word then
                    word = false
                    words = words + 1
                else
                    word = true
                end
            end
        
       return lines.." "..words.." "..(bytes == chars and bytes or bytes.." "..chars).." "..(isFile and args or "")-- number of lines, word count, byte and characters count
	end,
}

return cmd
