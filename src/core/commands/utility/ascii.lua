local schedules = {}

local cmd = {
	name = script.Name,
	desc = [[Schedule commands at a later time, arg1 must be a %X date (HH:MM:SS)]],
	usage = [[$ info]],
	displayOutput = true,
	fn = function(plr, pCsi, essentials, args)
        local bfr = ""
        function ASCIITable()
            local Ctrl = false -- set to true if ASCII<32 appear as valid chars
            local hl = "    +----------------+\n"
            bfr ..= ("ASCII Table:\n"..hl.."Hex |0123456789ABCDEF|\n"..hl)
            local start = Ctrl and 0 or 32
            for x = start, 240, 16 do
                bfr ..= (string.format(" %02X |", x))
              for y = x, x+15 do bfr ..= (string.char(y)) end
              bfr ..= ("|\n")
            end
            bfr ..= (hl)
            if not Ctrl then
                bfr ..= (
                "\nControl Characters:\n"..
                " 00: NUL SOH STX ETX\n 04: EOT ENQ ACK BEL\n"..
                " 08: BS  HT  LF  VT\n 0C: FF  CR  SO  SI\n"..
                " 10: DLE DC1 DC2 DC3\n 14: DC4 NAK SYN ETB\n"..
                " 18: CAN EM  SUB ESC\n 1C: FS  GS  RS  US\n"
              )
            end
          end
          ASCIITable()
          return bfr:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"):gsub("'", "&apos;")
	end,
}

return cmd


