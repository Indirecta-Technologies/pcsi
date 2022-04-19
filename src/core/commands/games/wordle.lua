local cmd = {
	name = script.Name,
	desc = [[WIP]],
	usage = [[]], --TO REDO
	displayOutput = false,
	fn = function(plr, pCsi, essentials, args)
        
-- wordle in lua

  
  local wordle = pCsi.libs.wordle
  
  game = wordle.new()
  --game = wordle.new('chafe',sgbwords,{hardmode=true})
  local resultstr = ''
  task.wait(0.1)
  essentials.Output:OutputToAll("ClearScreen")
while true do
    local newguess = pCsi.io.read()
    local output = game:guess(newguess)
    essentials.Output:OutputToAll("ClearScreen")
    pCsi.io.write([[
   .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------. 
  | .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
  | | <font color='rgb(185, 185, 185)'>_____  _____</font> | || |     <font color='rgb(238, 234, 24)'>____</font>     | || |  <font color='rgb(238, 234, 24)'>_______</font>     | || |  <font color='rgb(185, 185, 185)'>________</font>    | || |   <font color='rgb(24, 238, 95)'>_____</font>      | || |  <font color='rgb(24, 238, 95)'>_________</font>   | |
  | |<font color='rgb(185, 185, 185)'>|_   _||_   _|</font>| || |   <font color='rgb(238, 234, 24)'>.'    `</font>.   | || | <font color='rgb(238, 234, 24)'>|_   __ \</font>    | || | <font color='rgb(185, 185, 185)'>|_   ___ `.</font>  | || |  <font color='rgb(24, 238, 95)'>|_   _|</font>     | || | <font color='rgb(24, 238, 95)'>|_   ___  |</font>  | |
  | |  <font color='rgb(185, 185, 185)'>| | /\ | |</font>  | || |  <font color='rgb(238, 234, 24)'>/  .--.  \</font>  | || |   <font color='rgb(238, 234, 24)'>| |__) |</font>   | || |   <font color='rgb(185, 185, 185)'>| |   `. \</font> | || |    <font color='rgb(24, 238, 95)'>| |</font>       | || |   <font color='rgb(24, 238, 95)'>| |_  \_|</font>  | |
  | |  <font color='rgb(185, 185, 185)'>| |/  \| |</font>  | || |  <font color='rgb(238, 234, 24)'>| |    | |</font>  | || |   <font color='rgb(238, 234, 24)'>|  __ /</font>    | || |   <font color='rgb(185, 185, 185)'>| |    | |</font> | || |    <font color='rgb(24, 238, 95)'>| |</font>   _   | || |   <font color='rgb(24, 238, 95)'>|  _|  _</font>   | |
  | |  <font color='rgb(185, 185, 185)'>|   /\   |</font>  | || |  <font color='rgb(238, 234, 24)'>\  `--'  /</font>  | || |  <font color='rgb(238, 234, 24)'>_| |  \ \_</font>  | || |  <font color='rgb(185, 185, 185)'>_| |___.' /</font> | || |   <font color='rgb(24, 238, 95)'>_| |__/ |</font>  | || |  _<font color='rgb(24, 238, 95)'>| |___/ |</font>  | |
  | |  <font color='rgb(185, 185, 185)'>|__/  \__|</font>  | || |   <font color='rgb(238, 234, 24)'>`.____.'</font>   | || | <font color='rgb(238, 234, 24)'>|____| |___|</font> | || | <font color='rgb(185, 185, 185)'>|________.'</font>  | || |  <font color='rgb(24, 238, 95)'>|________|</font>  | || | <font color='rgb(24, 238, 95)'>|_________|</font>  | |
  | |              | || |              | || |              | || |              | || |              | || |              | |
  | '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
   '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------' 
   
   <font color='rgb(24, 238, 95)'><b>Green</b></font>: The letter is in the word and in the correct spot
   <font color='rgb(238, 234, 24)'><i>Yellow</i></font>: The letter is in the word but in the wrong spot
   <font color='rgb(185, 185, 185)'><s>Gray</s></font>: The letter is not in the word in any spot
   ]])
   
   local addword = true

    if output.t == 'incomplete' then
      pCsi.io.write('\n You have '..game.config.guesses - #game.guesses..' guesses left.\n')
    elseif output.t == 'nomoreguesses' then
        addword = false
      pCsi.io.write('You have '..game.config.guesses - #game.guesses..' guesses left.\n')
    elseif output.t == 'toomany' then
        addword = false
      pCsi.io.write('That is too many letters! Your guess should have '..game.config.wordlength..' letters.')
    elseif output.t == 'toofew' then
        addword = false
      pCsi.io.write('That is too few letters! Your guess should have '..game.config.wordlength..' letters.')
    elseif output.t == 'hardmodefail' then
      if output.t2 == 'knowngrey' then
        pCsi.io.write('You used the letter '.. output.t3 ..', even though you already knew it was not present!')
      elseif output.t2 == 'notenoughyellow' then
        pCsi.io.write('You only used the letter '.. output.t3 ..' ' .. output.t4.. ' times, even though you already knew there are at least'.. output.t5 .. '!')
      end
    elseif output.t == 'notaword' then
        addword = false
      pCsi.io.write(newguess..' is not a valid word!')
    elseif output.t == 'complete' then
      pCsi.io.write('Congratulations! ' .. game.word .. ' was the correct word. You got it in '.. #game.guesses..' guesses.')
    elseif output.t == 'gameover' then
      pCsi.io.write('Game over. The correct answer was '.. game.word..'.')
    end
    if addword then
        for i,v in ipairs(output.guess) do
            if v.letter then v.letter = string.upper(v.letter) end
            if v.color == 2 then
              resultstr ..= "<font color='rgb(24, 238, 95)'><b>"..v.letter..'</b> </font>' --GREEN
            elseif v.color == 1 then
              resultstr ..= "<font color='rgb(238, 234, 24)'><i>"..v.letter..'</i> </font>' --YELLOW
            else
              resultstr ..= "<font color='rgb(185, 185, 185)'><s>"..v.letter..'</s> </font>' --GRAY
            end
          end
          resultstr ..= "\n"
    end
    pCsi.io.write(resultstr)

  end
  
	end,
}

return cmd

