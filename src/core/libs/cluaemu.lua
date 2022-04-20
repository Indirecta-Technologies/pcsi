--"Lua C" emulator in Lua by 3dsboy08
--Credits to Josh for his amazing Lua API wrapper (https://github.com/NewVoids/LuaAPI/)

-- MAY USE GLOBALS FROM HERE, UNFIT FOR USE YET

local unpack = unpack or table.unpack
local cache = {}
local memory, address = {states = {}, threads = {}}, 0x0000001
local types = {
   LUA_TNONE = -1,
   LUA_TNIL = 0,
   LUA_TBOOLEAN = 1,
   LUA_TLIGHTUSERDATA = 2,
   LUA_TNUMBER = 3,
   LUA_TSTRING = 4,
   LUA_TTABLE = 5,
   LUA_TFUNCTION = 6,
   LUA_TUSERDATA = 7,
   LUA_TTHREAD = 8
}
local gcactions = {
   'LUA_GCSTOP',
   'LUA_GCRESTART',
   'LUA_GCCOLLECT',
   'LUA_GCCOUNT',
   'LUA_GCCOUNTB',
   'LUA_GCSTEP',
   'LUA_GCSETPAUSE',
   'LUA_GCSETSTEPMUL'
}
local sign = function(n)
   return n < 0 and -1 or n > 0 and 1 or 0
end
local gettype = function(...)
   if select('#', ...) == 0 then
      return types.LUA_TNONE
   elseif type(...) == 'nil' then
      return types.LUA_TNIL
   elseif type(...) == 'boolean' then
      return types.LUA_TBOOLEAN
   elseif type(...) == 'number' then
      return types.LUA_TNUMBER
   elseif type(...) == 'string' then
      return types.LUA_TSTRING
   elseif type(...) == 'table' then
      return types.LUA_TTABLE
   elseif type(...) == 'function' then
      return types.LUA_TFUNCTION
   elseif type(...) == 'userdata' and #... ~= 'fthread' then
      return types.LUA_TUSERDATA
   elseif type(...) == 'thread' or #... == 'fthread' then
      return types.LUA_TTHREAD
   end
   return types.LUA_TLIGHTUSERDATA
end
local push = function(L, v)
   L.stacksize = L.stacksize + 1
   L.stack[L.stacksize] = v
end
local getaddress = function()
   address = address + 0x01
   return string.format('0x%07x', address)
end
local stackKey = function(L, i)
   return (sign(i) == -1 and (L.stacksize + 1) + i) or i
end
local get = function(L, i)
   return L.stack[(sign(i) == -1 and (L.stacksize + 1) + i) or i]
end
local set = function(L, i, v)
   L.stack[(sign(i) == -1 and (L.stacksize + 1) + i) or i] = v
end
local shift = function(L, s, n)
   if sign(s) == -1 then
      for i = ((sign(n) == -1 and (L.stacksize + 1) + n) or n) + 1, L.stacksize do
         L.stack[i - 1] = L.stack[i]
      end
      set(L,  L.stacksize, nil)
      L.stacksize = L.stacksize - 1
   else
      local new = {}
      for i = (sign(n) == -1 and L.stacksize - n or n), L.stacksize do
         new[i + 1] = L.stack[i]
      end
      for k, v in next, new do
         L.stack[k] = v
      end
      set(L, n, nil)
      L.stacksize = L.stacksize + 1
   end
end
local pop = function(L, i)
   local val = get(L, i)
   set(L, i, nil)
   shift(L, -1, i)
   return val
end
local lua_functions = {
   LUA_MULTRET = -math.huge,
   luaL_newstate = function()
      local state = newproxy(true)
      getmetatable(state).__tostring = function() return 'state: ' .. memory[state] end
      getmetatable(state).__index = function(...) error('Lua state libraries not open (luaL_openlibs(L))', 0) end
      memory[state] = state
      return state
   end,
   luaL_openlibs = function(L)
      getmetatable(L).__index = {stack = {}, stacksize = 0, memory = {}}
      getmetatable(L).__newindex = getmetatable(L).__index
      return L
   end,
   luaL_loadstring = function(L, s)
      return loadstring(s) -- UNPROTECTED LOADSTRING!!!!
   end,
   lua_close = function(L)
      memory[L] = nil
   end,
   lua_getglobal = function(L, g)
      push(L, getfenv(0)[g] or cache[g])
   end,
   lua_setglobal = function(L, n)
      cache[n] = get(L, -1)
   end,
   lua_getfenv = function(L, n)
      push(L, setmetatable(cache, {__index = getfenv(n)}))
   end,
   lua_setfenv = function(L, n)
      cache = {}
      local instr = pop(L, -1)
      setfenv(n, instr)
      push(L, (type(instr) ~= 'function' and type(instr) ~= 'thread' and type(instr) ~= 'userdata' and 0) or 1)
   end,
   lua_getfield = function(L, n, k)
      push(L, get(L, n)[k])
   end,
   lua_gettable = function(L, i)
      push(L, get(L, i)[pop(L, -1)])
   end,
   lua_getmetatable = function(L, n)
      if getmetatable(get(L, n)) and get(L, n) then
         push(L, getmetatable(get(L, n)))
      else
         return 0
      end
   end,
   lua_setmetatable = function(L, n)
      set(L, n, setmetatable(get(L, n), pop(L, -1)))
   end,
   lua_createtable = function(L, n)
      push(L, {})
   end,
   lua_settable = function(L, n)
      get(L, n)[pop(L, -2)] = pop(L, -1)
   end,
   lua_settop = function(L, n)
      if stackKey(L, n) < L.stacksize then
         for i = stackKey(L, n) + 1, L.stacksize do
            shift(L, -1, -1)
         end
      else
         for i = L.stacksize, stackKey(L, n) do
            push(L, nil)
         end
      end
   end,
   lua_pop = function(L, n)
      for i = 1, n do
         shift(L, -1, -1)
      end
   end,
   lua_setfield = function(L, n, k)
      get(L, n)[k] = pop(L, -1)
   end,
   lua_toboolean = function(L, n)
      return get(L, n) and 1 or 0
   end,
   lua_tointeger = function(L, n)
      return tonumber(get(L, n))
   end,
   lua_tonumber = function(L, n)
      return tonumber(get(L, n))
   end,
   lua_tostring = function(L, n)
      return tostring(get(L, n))
   end,
   lua_tolstring = function(L, n, len)
      return len and string.sub(get(L, n), 1, len) or tostring(get(L, n))
   end,
   lua_iscfunction = function(L, n)
      return pcall(string.dump, get(L, n)) and 1 or 0
   end,
   lua_isfunction = function(L, n)
      return L, type(get(L, n)) == 'function' and 1 or 0
   end,
   lua_isnil = function(L, n)
      return get(L, n) == nil and 1 or 0
   end,
   lua_isnoneornil = function(L, n)
      return get(L, n) == nil and 1 or 0
   end,
   lua_isthread = function(L, n)
      return type(get(L, n)) == 'thread' and 1 or 0
   end,
   lua_istable = function(L, n)
      return type(get(L, n)) == 'table' and 1 or 0
   end,
   lua_isuserdata = function(L, n)
      return type(get(L, n)) == 'userdata' and 1 or 0
   end,
   lua_isstring = function(L, n)
      return type(get(L, n)) == 'string' and 1 or 0
   end,
   lua_isnumber = function(L, n)
      return type(get(L, n)) == 'number' and 1 or 0
   end,
   lua_isboolean = function(L, n)
      return type(get(L, n)) == 'boolean' and 1 or 0
   end,
   lua_lessthan = function(L, n1, n2)
      return get(L, n1) < get(L, n2) and 1 or 0
   end,
   lua_equal = function(L, n1, n2)
      return get(L, n1) == get(L, n2) and 1 or 0
   end,
   lua_rawequal = function(L, n1, n2)
      return rawequal(n1, n2) and 1 or 0
   end,
   lua_rawgeti = function(L, i, n)
      return rawget(get(L, i), n)
   end,
   lua_rawseti = function(L, i, n)
      return rawset(get(L, i)), n, pop(L, -1)
   end,
   lua_gettop = function(L, i)
      return L.stacksize
   end,
   lua_next = function(L, i)
      local res = next(get(L, -1))
      push(L, res == nil and types.LUA_TNIL or res, i)
   end,
   lua_type = function(L, ...)
      return gettype(...)
   end,
   lua_typename = function(L, n)
      local tvalue = gettype(get(L, n))
      for typename, value in next, types do
         if tvalue == value then
            return typename
         end
      end
      return 'LUA_TNONE'
   end,
   lua_newthread = function(L, nresults)
      local thread = newproxy(true)
      local cache = {}
      local f = {}
      memory[L][thread] = getaddress()
      getmetatable(thread).__tostring = function() return 'fthread: ' .. memory[L][thread] end
      getmetatable(thread).__index = cache
      getmetatable(thread).__len = function(self) return 'fthread' end
      getmetatable(thread).__call = function(self, c)
         if not cache[c] then
            local rthread = coroutine.create(c)
            cache[rthread] = getaddress()
            cache[c] = rthread
            return rthread
         else
            return cache[c]
         end
      end
      push(L, thread)
   end,
   lua_yield = function(L, nresults)
      return select(coroutine.yield(), 1, nresults)
   end,
   lua_resume = function(L, narg)
      local f = L.stack[L.stacksize - narg]
      local t = L.stack[L.stacksize - narg - 1]
      local args, n = {}, 0
      for i = (L.stacksize + 1) - narg, L.stacksize do
         n = n + 1
         args[n] = L.stack[i]
      end
      for i = (L.stacksize + 1) - narg, L.stacksize do
         shift(L, -1, i)
      end
      local val = {pcall(coroutine.resume, t(f), unpack(args, 1, n))}
      local s, m = val[1], {select(2, unpack(val))}
      shift(L, -1, -1)
      shift(L, -1, -1)
      push(L, select(2, unpack(val)))
   end,
   lua_pushboolean = function(L, b)
      assert(type(b) == 'boolean', 'Argument type "' .. type(b) .. '" is incompatible with parameter of type boolean')
      push(L, b)
   end,
   lua_pushnil = function(L)
      push(L, nil)
   end,
   lua_pushnumber = function(L, n)
      assert(type(n) == 'number', 'Argument type "' .. type(n) .. '" is incompatible with parameter of type number')
      push(L, n)
   end,
   lua_pushstring = function(L, s)
      assert(type(s) == 'string', 'Argument type "' .. type(s) .. '" is incompatible with parameter of type string')
      push(L, s)
   end,
   lua_pushtable = function(L, t)
      assert(type(t) == 'table', 'Argument type "' .. type(t) .. '" is incompatible with parameter of type table')
      push(L, t)
   end,
   lua_pushvalue = function(L, n)
      push(L, get(L, n))
   end,
   lua_pushclosure = function(L, c)
      assert(type(c) == 'function', 'Argument type "' .. type(c) .. '" is incompatible with parameter of type function')
      push(L, c)
   end,
   lua_remove = function(L, n)
      pop(L, n)
      shift(L, -1, n)
   end,
   lua_insert = function(L, n)
      local element = get(L, -1)
      shift(L, 1, n)
      set(L, n, element)
   end,
   lua_pcall = function(L, nargs, nresults, errfunc)
      local f = L.stack[L.stacksize - nargs]
      local args, n = {}, 0
      for i = (L.stacksize + 1) - nargs, L.stacksize do
         n = n + 1
         args[n] = L.stack[i]
      end
      for i = (L.stacksize + 1) - nargs, L.stacksize do
         shift(L, -1, i)
      end
      local val = {pcall(f, unpack(args, 1, n))}
      local s, m = val[1], {select(2, unpack(val))}
      local r = {unpack(m, 1, nresults == -math.huge and #m or nresults)}
      shift(L, -1, -1)
      if not s and errfunc ~= 0 then
         push(L, get(L, errfunc)(m))
      else
         push(L, select(2, unpack(val)))
      end
   end,
   lua_call = function(L, nargs, nresults)
      local f = L.stack[L.stacksize - nargs]
      assert(type(f) == 'function', 'Unprotected error in call to Lua API (attempt to call a ' .. type(f) .. ' value)')
      local args, n = {}, 0
      for i = (L.stacksize + 1) - nargs, L.stacksize do
         n = n + 1
         args[n] = L.stack[i]
      end
      for i = (L.stacksize + 1) - nargs, L.stacksize do
         shift(L, -1, i)
      end
      local val = {f(unpack(args, 1, n))}
      local r = {unpack(val, 1, nresults == -math.huge and #val or nresults)}
      shift(L, -1, -1)
      push(L, unpack(r))
   end,
   emptystack = function(L)
      L.stack = {}
      L.stacksize = 0
   end
}

local function emu(scr)
   local L = lua_functions.luaL_newstate()
   lua_functions.luaL_openlibs(L)

   local function reconstruct_string(t, idx)
    local ret = ""
    for i=idx,#t do
        ret = ret .. t[i] .. " "
    end
    return ret:sub(1, -2)
   end

   local function convert_number(str, pc)
    local res = tonumber(str)
    assert(type(res) == "number", "invalid number (pc = " .. tostring(pc) .. ")")
    return res
   end

   local pc = 1
   for line in scr:gmatch("([^\n]*)\n?") do
    local args = {}
    for arg in string.gmatch(line, "%S+") do table.insert(args, arg) end
    if #args >= 1 then
        if args[1] == "getglobal" then
            assert(#args >= 2, "invalid amount of arguments (getglobal, pc = " .. tostring(pc) .. ")")
            lua_functions.lua_getglobal(L, reconstruct_string(args, 2))
        elseif args[1] == "getfield" then
            assert(#args >= 3, "invalid amount of arguments (getfield, pc = " .. tostring(pc) .. ")")
            lua_functions.lua_getfield(L, convert_number(args[2], pc), reconstruct_string(args, 3))
        elseif args[1] == "setfield" then
            assert(#args >= 3, "invalid amount of arguments (setfield, pc = " .. tostring(pc) .. ")")
            lua_functions.lua_setfield(L, convert_number(args[2], pc), reconstruct_string(args, 3))
        elseif args[1] == "pushvalue" then
            assert(#args == 2, "invalid amount of arguments (pushvalue, pc = " .. tostring(pc) .. ")")
            lua_functions.lua_pushvalue(L, convert_number(args[2], pc))
        elseif args[1] == "pcall" then
            assert(#args == 4, "invalid amount of arguments (pcall, pc = " .. tostring(pc) .. ")")
            lua_functions.lua_pcall(L, convert_number(args[2], pc), convert_number(args[3], pc), convert_number(args[4], pc))
        elseif args[1] == "call" then
            assert(#args == 3, "invalid amount of arguments (call, pc = " .. tostring(pc) .. ")")
            lua_functions.lua_pcall(L, convert_number(args[2], pc), convert_number(args[3], pc))
        elseif args[1] == "pushnumber" then
            assert(#args == 2, "invalid amount of arguments (pushnumber, pc = " .. tostring(pc) .. ")")
            lua_functions.lua_pushnumber(L, convert_number(args[2], pc))
        elseif args[1] == "pushboolean" or args[1] == "pushbool" then
            assert(#args == 2, "invalid amount of arguments (pushboolean, pc = " .. tostring(pc) .. ")")
            if args[2] == "true" then
                lua_functions.lua_pushboolean(L, true)
            elseif args[2] == "false" then
                lua_functions.lua_pushboolean(L, false)
            else
                error("invalid boolean, pc = " .. tostring(pc))
            end
        elseif args[1] == "pushnil" then
            lua_functions.lua_pushnil(L)
        elseif args[1] == "pushstring" then
            assert(#args >= 2, "invalid amount of arguments (pushstring, pc = " .. tostring(pc) .. ")")
            lua_functions.lua_pushstring(L, reconstruct_string(args, 2))
        elseif args[1] == "settop" then
            assert(#args == 2, "invalid amount of arguments (settop, pc = " .. tostring(pc) .. ")")
            lua_functions.lua_settop(L, convert_number(args[2], pc))
        elseif args[1] == "remove" then
            assert(#args == 2, "invalid amount of arguments (remove, pc = " .. tostring(pc) .. ")")
            lua_functions.lua_remove(L, convert_number(args[2], pc))
        elseif args[1] == "pop" then
            assert(#args == 2, "invalid amount of arguments (pop, pc = " .. tostring(pc) .. ")")
            lua_functions.lua_pop(L, convert_number(args[2], pc))
        elseif args[1] == "emptystack" then
            lua_functions.emptystack(L)
        end
        pc = pc + 1
    end
   end

   lua_functions.lua_close(L)
end

return emu