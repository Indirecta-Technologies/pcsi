-- this code was adapted from http://wiki.roblox.com/index.php?title=User:Kingkiller1000/SHA256
-- by Kingkiller1000
-- edited by kingdom5

local con = 2 ^ 32 

local k = {
	0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
	0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
	0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
	0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
	0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
	0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
	0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
	0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
}

local And, xor, Not, rrotate, rshift, Or, lshift = bit32.band, bit32.bxor, bit32.bnot, bit32.rrotate, bit32.rshift, bit32.bor, bit32.lshift

local function wordToByte(n, tbl)
	local b0, b1,b2,b3
	b3 = And(n, 0xFF) n = rshift(n, 8)
	b2 = And(n, 0xFF) n = rshift(n, 8)
	b1 = And(n, 0xFF) n = rshift(n, 8)
	b0 = And(n, 0xFF)
	
	tbl[#tbl+1] = And(n, 0xFF)
	tbl[#tbl+1] = b1
	tbl[#tbl+1] = b2
	tbl[#tbl+1] = b3
end

local function digest(h, w)

	local h0, h1, h2, h3, h4, h5, h6, h7 = h[1], h[2], h[3], h[4], h[5],h[6], h[7], h[8]
	local t0, t1
	local s0, s1
	
	for i = 17, 64 do
		s0 = xor(xor(rrotate(w[i-15],7),rrotate(w[i-15],18)),rshift(w[i-15],3))
		s1 = xor(xor(rrotate(w[i-2],17),rrotate(w[i-2],19)),rshift(w[i-2],10))
		w[i] = (w[i-16] + s0 + w[i-7] + s1) % con
	end
	
	for i = 1, 64 do
		t0 = h7 + xor(xor(rrotate(h4,6),rrotate(h4,11)),rrotate(h4,25)) + xor(And(h4,h5),And(Not(h4),h6))+k[i]+w[i]
		t1 = xor(xor(rrotate(h0,2),rrotate(h0,13)),rrotate(h0,22)) + xor(xor(And(h0,h1),And(h0,h2)),And(h1,h2))
		h7 = h6
		h6 = h5
		h5 = h4
		h4 = (h3+t0)%con
		h3 = h2
		h2 = h1
		h1 = h0
		h0 = (t0+t1)%con
	end
	
	h[1] = (h[1]+h0) % con
	h[2] = (h[2]+h1) % con
	h[3] = (h[3]+h2) % con
	h[4] = (h[4]+h3) % con
	h[5] = (h[5]+h4) % con
	h[6] = (h[6]+h5) % con
	h[7] = (h[7]+h6) % con
	h[8] = (h[8]+h7) % con
end

return function ()
	
	local h = {
		0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
		0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
	}
	
	local w = {
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0
	}	
	local q, qc = {}, 0
	
	local f = {}
	
	-- get then clear item in queue
	local function get(i)
		local tmpVal = q[i]
		q[i] = nil
		return tmpVal
	end
	
	local function run()
		
		local wi = 1
		for i = 1, 61, 4 do
			w[wi] = (((((get(i) * 256) + get(i+1)) * 256) + get(i+2)) * 256) + get(i+3)				
			wi = wi + 1
		end
		
		digest(h, w)
		qc = qc + 64

	end
	
	function f.updateStr(str)
		for i=1, #str do
			q[#q+1] = str:byte(i)
			if #q >= 64 then run() end
		end
		
		return f
	end
	
	function f.updateBytes(data)
		for i=1, #data do
			q[#q+1] = data[i]
			if #q >= 64 then run() end
		end
		
		return f
	end

	function f.finish()
		
		local finalQcounter = (qc + #q) * 8
		
		q[#q+1] = 128

		if #q > 56 then
			for i=#q+1, 64 do
				q[i] = 0
			end
			run()
		end
		
		for i=#q+1, 56 do
			q[i] = 0
		end
		
		
		wordToByte(math.floor(finalQcounter/0x100000000), q)
		wordToByte(finalQcounter, q)

		run()
		q, qc, w =  nil, nil, nil
		
		return f
	end
	 
	function f.asBytes()
		local tbl = {}
		wordToByte(h[1], tbl)
		wordToByte(h[2], tbl)
		wordToByte(h[3], tbl)
		wordToByte(h[4], tbl)
		wordToByte(h[5], tbl)
		wordToByte(h[6], tbl)
		wordToByte(h[7], tbl)
		wordToByte(h[8], tbl)
		return tbl		
	end
	
	function f.asHex()
		return ("%08x%08x%08x%08x%08x%08x%08x%08x"):format(unpack(h))
	end
	
	return f
end