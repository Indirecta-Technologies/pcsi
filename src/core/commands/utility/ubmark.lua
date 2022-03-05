local cmd = {
	name = script.Name,
	desc = [[Benchmarks Lua functions]],
	usage = [[$ ubmark > 05032022.bm\n$ ubmark | more]],
	displayOutput = true,
	fn = function(plr, pCsi, essentials, args)
	--
-- ubmark.lua -- A collection of Lua microbenchmarks 
-- Targeted at LuaJIT 2.1.0-beta3.
--
-- References:
-- https://cr.yp.to/talks/2015.04.16/slides-djb-20150416-a4.pdf
-- https://github.com/google/caliper/wiki/JavaMicrobenchmarks
-- http://www.ellipticgroup.com/html/benchmarkingArticle.html
-- http://hugoduncan.org/criterium/
-- http://www.serpentine.com/criterion/
-- https://en.wikipedia.org/wiki/Kolmogorov%E2%80%93Smirnov_test
-- https://en.wikipedia.org/wiki/Mann%E2%80%93Whitney_U_test
local output = ""


local bmark = (function() -- Local wrapper.

    local gc, pairs = collectgarbage, pairs
    local abs, exp, floor, sqrt = math.abs, math.exp, math.floor, math.sqrt
    local concat, sort = table.concat, table.sort
    local format, match, sub = string.format, string.match, string.sub
    local write = function(...)
        output ..= table.concat({...}).." "
    end
    local clock = os.clock -- Can be overridden.
    
    -- Measure the clock time of repeteadly executing a thunk.
    local function timeR(reps, thunk, init)
        local ud = init and init(reps)
        local t0 = clock()
        for i=1, reps, 16 do -- Unrolled.
            thunk(ud, i   ) thunk(ud, i+ 1) thunk(ud, i+ 2) thunk(ud, i+ 3)
            thunk(ud, i+ 4) thunk(ud, i+ 5) thunk(ud, i+ 6) thunk(ud, i+ 7)
            thunk(ud, i+ 8) thunk(ud, i+ 9) thunk(ud, i+10) thunk(ud, i+11)
            thunk(ud, i+12) thunk(ud, i+13) thunk(ud, i+14) thunk(ud, i+15)
        end
        return clock() - t0
    end
    
    -- Choose a suitable number of repetitions to profile a thunk.
    local function pickR(thunk, init, tolerance)
        local reps = 1024
        local n = 0
        for _=0, 10 do
            reps = reps*(1 + exp(-n))
            if timeR(reps, thunk, init) > 1000e-6 then -- Tolerance in useconds.
                if n == 5 then break end
                n = n + 1
            elseif n > 0 then n = n - 1
            end
        end
        return reps - reps % 16
    end
    
    -- Display a histogram for the given results. [ UNUSED ]
    --[[
    local function histogram(r, bn, a, b)
        local b = {} for i=1, bn do b[i] = 0 end
        for i=1, #r do
            local j = math.min(1+floor(r[i]*a + b), bn)
            b[j] = b[j] + 1
        end
        print("Histogram: "..r.case)
        for i=1, bn do print(format("%2d| %s", i, string.rep("@", b[i]))) end
        print ""
    end
    --]]
    
    -- Measure the time and summarize executing a thunk a repeated number of times.
    local function timeS(series, reps, thunk, init)
        assert(series % 20 == 0 and reps % 16 == 0)
        local r = {nil,nil,nil,nil}
        for i=1, series do
            local t = timeR(reps, thunk, init) / reps
            r[i] = t -- Insert-sort.
            while i > 1 and r[i] < r[i-1] do r[i-1], r[i], i = t, r[i-1], i-1 end
        end
        local a, b = 0.05*series, 0.95*series -- Trim both 5th quantiles.
        local n = 0.90*series
        local x = 0 -- Mean. Calculated after sorting to squeeze precision.
        for i=a, b do x = x + r[i] end
        x = x / n
        local s2 = 0 -- Variance.
        for i=a, b do local y = x - r[i] s2 = s2 + y*y end
        r.mean = x
        r.ops = x > 1e-10 and floor(1/x) or 0
        r.var = s2 / (n-1)
        r.stdev = sqrt(r.var)
        r.min = r[1] -- Percentile-based stats.
        r.median = r[0.50*series]
        r.q1 = r[0.25*series]
        r.q3 = r[0.75*series]
        r.iqr = r.q3 - r.q1
        return r
    end
    
    local function fmtSI(u, m)
        if m >= 1 then
            for i=0, 5 do
                if m < 1000 then
                    return format("%.3f %s%s", m, sub("kMGTP", i, i), u)
                end
                m = m/1000
            end
            return "inf"
        elseif m > 0 then
            for i=1, 5 do
                m = m*1000
                if m >= 1 then
                    return format("%.3f %s%s", m, sub("munpf", i, i), u)
                end
            end
        end
        return "0.000 "..u
    end
    
    -- Compute the p-value for a normal difference.
    local function erf(x)
        x = abs(x)*2^-0.5
        local t = 1/(1+0.3275911*x) -- A&S Handbook of Mathematical Functions, Formula 7.1.26.
        return (((((1.061405429*t-1.453152027)*t)+1.421413741)*t-0.284496736)*t+0.254829592)*t*exp(-x*x)
    end
    
    local function cmp_mean(a, b) return a.mean < b.mean end
    
    local stats = {
    "case"   , format, "%s",
    "mean"   , fmtSI, "s",
    "stdev"  , fmtSI, "s",
    "ops"    , fmtSI, "Hz",
    "reldiff", format, "%+.1f%%",
    "pvalue" , format, "%.6f%%",
    "tscore" , format, "%g",
    "df"     , format, "%d",
    "min"    , fmtSI, "s",
    "median" , fmtSI, "s",
    "iqr"    , fmtSI, "s",
    "reps"   , fmtSI, "",
    }
    local skip_first = { reldiff=1, pvalue=1, tscore=1, df=1 }
    
    -- Run a benchmark.
    local function bmark(def)
        local t0 = clock()
        local data = {}
        local series, init = def.series or 100, def.init
        for case, thunk in pairs(def.cases) do
            local reps = def.reps or pickR(thunk, init)
            local r = timeS(series, reps, thunk, init)
            r.case = case
            r.reps = reps
            data[#data+1] = r
        end
        sort(data, cmp_mean)
        local b = data[1] -- Best.
        for j=1, #data do
            local r = data[j]
            local v1, v2 = r.var, b.var
            local v1_v2 = v1 + v2
            r.tscore = (r.mean - b.mean) * sqrt(series / v1_v2)
            r.df = abs(floor(v1_v2*v1_v2 / (v1*v1 + v2*v2) * (series-1) + 0.5))
            r.reldiff = 100 * (r.mean/b.mean - 1)
            r.pvalue = 100 * erf(r.tscore)
        end
        local duration = clock() - t0
        -- for i=1, #data do local r = data[i] histogram(r, 8, 8/(data[1][#r]-r[1])) end
        write("\n", def.name or "no name!", "\n")
        for i=1, #stats, 3 do
            local key = stats[i]
            local fmt = stats[i+1]
            local ctx = stats[i+2]
            write(format("%7s:", key))
            for j=1, #data do
                if j == 1 and skip_first[key] then write("                ")
                else write(format("%16s", fmt(ctx, data[j][key])))
                end
            end
            write("\n")
        end
    end
    
    local queue = {}
    local queue_only = false
    
    local L = {
        __call = bmark,
        q = function(def) -- Queue a benchmark.
            if def.off then return end
            if def.only then queue_only = true end
            queue[#queue+1] = def
        end,
        run = function() -- Run the queue.
            for i=1, #queue do
                local def = queue[i]
                if queue_only ~= not def.only then
                    bmark(def)
                end
            end
        end
    }
    
    return setmetatable(L, L)
    
    end)() -- /Local wrapper.
    
    
    
    -------------------------------------------------------------------------------
    
    local function ctrl_nop(_, i) return end
    bmark.q{ name = "control",
        reps = 2^18,
        cases = {
            ["1a"] = ctrl_nop,
            ["1b"] = ctrl_nop,
            ["2a"] = function() end,
            ["2b"] = function() end,
        },
    }
    
    local sqrt = math.sqrt
    bmark.q{ name = "bytecode:sqrt",
        cases = {
            ["math.sqrt"] = function(_, i) return math.sqrt(i) end,
            ["uv-sqrt"] = function(_, i) return sqrt(i) end,
            ["pow-op"] = function(_, i) return i^0.5 end,
        },
    }
    
    bmark.q{ name = "bytecode:division",
        cases = {
            ["mul"] = function(_, i)
                local _ = i * (1/3) local _ = i * (1/3)
                local _ = i * (1/3) local _ = i * (1/3)
                local _ = i * (1/3) local _ = i * (1/3)
                local _ = i * (1/3) local _ = i * (1/3)
            end,
            ["div"] = function(_, i)
                local _ = i / 3 local _ = i / 3
                local _ = i / 3 local _ = i / 3
                local _ = i / 3 local _ = i / 3
                local _ = i / 3 local _ = i / 3
            end,
        },
    }
    
    local max, huge, unpack = math.max, math.huge, unpack
    bmark.q{ name = "bytecode:maximum",
        init = function()
            local t = { n = 100, aux = {} }
            for i=1, t.n do t[i] = {math.random()} end
            return t
        end,
        cases = {
            ["math.max"] = function(ud)
                local m = -huge
                for i=1, ud.n do m = max(m, ud[i][1]) end
            end,
            ["lt-op"] = function(ud)
                local m = -huge
                for i=1, ud.n do
                    local x = ud[i][1]
                    if x > m then m = x end
                end
            end,
            ["unpack-max"] = function(ud)
                local aux = ud.aux
                for i=1, ud.n do aux[i] = ud[i][1] end
                local _ = max(unpack(aux, 1, ud.n))
            end,
        },
    }
    
    bmark.q{ name = "bytecode:specialization",
        cases = {
            ["no"] = function(_, i) -- MULVV
                local five = 5
                local _ = i * five local _ = i * five
                local _ = i * five local _ = i * five
                local _ = i * five local _ = i * five
                local _ = i * five local _ = i * five
                local _ = i * five local _ = i * five
                local _ = i * five local _ = i * five
                local _ = i * five local _ = i * five
                local _ = i * five local _ = i * five
            end,
            ["yes"] = function(_, i) -- MULVN
                local _ = i * 5 local _ = i * 5
                local _ = i * 5 local _ = i * 5
                local _ = i * 5 local _ = i * 5
                local _ = i * 5 local _ = i * 5
                local _ = i * 5 local _ = i * 5
                local _ = i * 5 local _ = i * 5
                local _ = i * 5 local _ = i * 5
                local _ = i * 5 local _ = i * 5
            end,
        },
    }
    
    bmark.q{ name = "storage:upvalue/table",
        init = function()
            local a
            return {
                a = a,
                uset = function(x) a = x end,
                tset = function(self, x) self.a = x end,
            }
        end,
        cases = {
            ["upvalue"] = function(ud, i) ud.uset(i) end,
            ["table"] = function(ud, i) ud:tset(i) end,
        },
    }
    
    bmark.q{ name = "table:vivification",
        init = function()
            return {
                t1 = {},
                t2 = setmetatable({}, {
                    __index = function(self, k)
                        self[k] = 0
                        return 0
                    end,
                })
            }
        end,
        cases = {
            ["branch"] = function(ud)
                local t = ud.t1
                for i=1, 128 do
                    local n = (i*37)%32
                    t[n] = (t[n] or 0) + 1
                end
            end,
            ["metatable"] = function(ud)
                local t = ud.t2
                for i=1, 128 do
                    local n = (i*37)%32
                    t[n] = t[n] + 1
                end
            end,
        },
    }
    
    bmark.q{ name = "table:inflated",
        cases = {
            ["no"] = function()
                local a = {}
                for i=1, 10 do a[i] = i end
            end,
            ["yes"] = function()
                local a = {nil,nil,nil,nil}
                for i=1, 10 do a[i] = i end
            end,
        },
    }
    
    bmark.q{ name = "bytecode:intermediate-slots",
        init = function()
            return { a = { b = { c = { d = { e = { f = 0 } } } } } }
        end,
        cases = {
            ["no"] = function(ud, i)
                ud.a.b.c.d.e.f = i
            end,
            ["yes"] = function(ud, i)
                local a = ud.a
                local b = a.b
                local c = b.c
                local d = c.d
                local e = d.e
                e.f = i
            end,
        },
    }
    
    local next, ipairs, pairs = next, ipairs, pairs
    bmark.q{ name = "table:iteration",
        init = function()
            local t = {}
            for i=1, 1000 do t[i] = i end
            return t
        end,
        cases = {
            ["for-n"] = function(ud)
                local a = 0
                for i=1, #ud do a = a + ud[i] end
            end,
            ["next"] = function(ud)
                local a = 0
                for i in next, ud do a = a + ud[i] end
            end,
            ["ipairs"] = function(ud)
                local a = 0
                for _, v in ipairs(ud) do a = a + v end
            end,
            ["pairs"] = function(ud)
                local a = 0
                for _, v in pairs(ud) do a = a + v end
            end,
        },
    }
    
    bmark.q{ name = "table:method/__call",
        init = function()
            local t = { __call = function() end }
            return setmetatable(t, t)
        end,
        cases = {
            ["method"] = function(ud)
                ud.__call() ud.__call() ud.__call() ud.__call()
                ud.__call() ud.__call() ud.__call() ud.__call()
            end,
            ["__call"] = function(ud)
                ud() ud() ud() ud()
                ud() ud() ud() ud()
            end,
        },
    }
    
    local has_table_clear, clear_builtin = pcall(require, "table.clear")
    if has_table_clear then
    local function clear_lua(t) for k in pairs(t) do t[k] = nil end end
    bmark.q{ name = "table:clear",
        series = 20,
        off = true,
        init = function(reps)
            local t = {}
            for i=1, reps do
                t[i] = {}
                for j=1, 100 do
                    t[i][math.random()] = j
                    t[i][j] = j
                end
            end
            return t
        end,
        cases = {
            ["builtin"] = function(ud, i)
                clear_builtin(ud[i])
            end,
            ["lua"] = function(ud, i)
                assert(ud[i], i)
                clear_lua(ud[i])
            end,
        }
    }
    end
    
    bmark.q{ name = "storage:vararg", only = true,
        init = function()
            local index_lookup = {
                one   = 1,
                two   = 2,
                three = 3,
                four  = 4,
                five  = 5,
                six   = 6,
                seven = 7,
                eight = 8,
            }
    
            local _arg_buffer = {}
            local function read_from_vararg(...)
                for i=1, select("#", ...) do
                    _arg_buffer[i] = select(i, ...)
                end
    
                local one   = _arg_buffer[1]
                local two   = _arg_buffer[2]
                local three = _arg_buffer[3]
                local four  = _arg_buffer[4]
            end
    
            local function read_from_indexed_array(t)
                local one   = t[ index_lookup.one   ]
                local two   = t[ index_lookup.two   ]
                local three = t[ index_lookup.three ]
                local four  = t[ index_lookup.four  ]
            end
    
            local function read_from_dictionary(t)
                local one   = t[ "one"   ]
                local two   = t[ "two"   ]
                local three = t[ "three" ]
                local four  = t[ "four"  ]
            end
            return {
                index_lookup = index_lookup,
                read_from_vararg = read_from_vararg,
                read_from_indexed_array = read_from_indexed_array,
                read_from_dictionary = read_from_dictionary,
                array = {}, -- Reused.
                dict = {}, -- Reused.
            }
        end,
        cases = {
            ["array"] = function(ud)
                ud.read_from_vararg("a", "b", 1, 2, 3, nil, false, "z")
            end,
            ["lookup"] = function(ud, i)
                local array, index_lookup = ud.array, ud.index_lookup
                array[index_lookup.one  ] = "a"
                array[index_lookup.two  ] = "b"
                array[index_lookup.three] = 1
                array[index_lookup.four ] = 2
                array[index_lookup.five ] = 3
                array[index_lookup.six  ] = nil
                array[index_lookup.seven] = false
                array[index_lookup.eight] = "z"
                ud.read_from_indexed_array(array)
            end,
            ["dict"] = function(ud, i)
                local dict = ud.dict
                dict.one   = "a"
                dict.two   = "b"
                dict.three = 1
                dict.four  = 2
                dict.five  = 3
                dict.six   = nil
                dict.seven = false
                dict.eight = "z"
                ud.read_from_dictionary(dict)
            end,
        },
    }
    
    bmark.run()
    return output
	end,
}

return cmd
