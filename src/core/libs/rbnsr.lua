local rbnsr = {
	_IDENTITY    = "rbnsr",
	_AUTHOR      = "Whim#2349",
	_VERSION     = "v0.1",
	_DESCRIPTION = "A Full Roblox DataType Serializer.",
	_LICENSE = [[  MIT LICENSE
    Copyright (c) 2022 Theron Akubuiro
    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:
    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
	]],
	-- ProtoTypes.
	Serialize = function(tableToSerialize : table)end,
	Deserialize = function(binaryString : string)end,
} 


local throw = function(_,...) 
	warn("["..rbnsr._IDENTITY.." "..rbnsr._VERSION.."]".._..":",...)
end
-- Below, are simply depedancies of the main module, dont be scared. its really just more of the DataSaving/Compression/Encosion. Then the actual saving.
-- Import .Header^
function splitbyte(input)
	local byte,p,flags = string.byte(input),128,{false,false,false,false,false,false,false,false}
	for i=1,8 do
		if byte>=p then flags[i],byte = true,byte-p end
		p=p/2
	end
	return flags
end
function formbyte(...)
	local byte = 0
	for p=1,8 do
		local bit=select(p,...)
		if bit then byte=byte+2^(8-p) end
	end
	return string.char(byte)
end
local valueType = "f"
function deflate(forceType,...) 
	return string.pack(string.rep(forceType or valueType,#{...}),...)
end 
function flate(forceType,raw,n)
	return string.unpack(string.rep(forceType or valueType,n),raw)
end 

function getNativeSize(forceType) 
	return #string.pack(forceType or valueType ,1) 
end
--- Nice Binary Functions^^^^^^^^^^ Lazy formatting/macros


--  Kept this cacheing for backwards compatability.
local EnumStorage = {} 
local cache = function(storage,enum) 
	local Table  = {}
	for _,v in ipairs(enum:GetEnumItems()) do
		Table[v.Value] = v 
	end
	storage[enum] = Table
end 

for i,enum in ipairs(Enum:GetEnums()) do 
	cache(EnumStorage,enum)
end



local Convertors =  {
	-- Normal Conversion 
	["ColorSequence"] = function(isClass,ColorSequenceValue) 
		if isClass then 
			local encodeStr = ""
			local blockSize =  string.packsize("f I1 I1 I1")
			for i,v in ipairs(ColorSequenceValue.Keypoints) do 
				local ColorKeypoint = v 
				local C3 = ColorKeypoint.Value
				local r, g, b = math.floor(C3.R*255), math.floor(C3.G*255), math.floor(C3.B*255)
				local block =  string.pack("f I1 I1 I1",ColorKeypoint.Time,r,g,b) --  further optimizations are possible to store
				encodeStr=encodeStr..block 
			end
			return encodeStr 
		else 
			local array  = {} 
			local blockSize =  string.packsize("f I1 I1 I1")
			for i=1,#ColorSequenceValue,blockSize do 
				local block = ColorSequenceValue:sub(i,i+blockSize) 
				local Time , r,g,b  = string.unpack("f I1 I1 I1",block) 
				table.insert(array,ColorSequenceKeypoint.new(Time,Color3.new(r/255,g/255,b/255)))
			end
			return ColorSequence.new(array)
		end
	end,
	["ColorSequenceKeypoint"] = function(isClass,ColorKeypoint) 
		if isClass then 
			local C3 = ColorKeypoint.Value
			local r, g, b = math.floor(C3.R*255), math.floor(C3.G*255), math.floor(C3.B*255)
			return string.pack("f I1 I1 I1",ColorKeypoint.Time,r,g,b) --  further optimizations are possible to store
		else
			local Time , r,g,b  = string.unpack("f I1 I1 I1",ColorKeypoint)
			return ColorSequenceKeypoint.new(Time,Color3.new(r/255,g/255,b/255))
		end
	end,
	["NumberSequence"] = function(isClass,NumberSequenceValue) 
		if isClass then 
			-- Basic binary array 
			local encodeStr = ""
			local nativeFloatSize = getNativeSize(nil) 
			local blockSize = nativeFloatSize*3 
			for i,v in ipairs(NumberSequenceValue.Keypoints) do 
				local block = deflate(nil,v.Time,v.Value,v.Envelope)
				encodeStr = encodeStr..block 
			end 

			return encodeStr
		else
			local array = {} 
			local nativeFloatSize = getNativeSize(nil) 
			local blockSize = nativeFloatSize*3 
			for i=1,#NumberSequenceValue,blockSize do 
				local block = NumberSequenceValue:sub(i,i+blockSize) 
				local a,b,c = flate(nil,block,3) 
				table.insert(array,NumberSequenceKeypoint.new(a,b,c))
			end
			return NumberSequence.new(array)
		end
	end,
	["NumberSequenceKeypoint"] = function(isClass,NumberKeypoint)
		if isClass then 
			return deflate(nil,NumberKeypoint.Time,NumberKeypoint.Value,NumberKeypoint.Envelope)
		else 
			local a,b,c = flate(nil,NumberKeypoint,3) 
			return NumberSequenceKeypoint.new(a,b,c)
		end
	end,
	["Rect"] = function(isClass,RectValue)
		if isClass then 
			return deflate(nil,RectValue.Min.X,RectValue.Min.Y,RectValue.Max.X,RectValue.Max.Y)
		else 
			local a,b,c,d = flate(nil,RectValue,4)
			return Rect.new(a,b,c,d)
		end
	end,
	["Ray"] = function(isClass,RayValue) 
		if isClass then 
			return deflate(nil,RayValue.Orgin.X,RayValue.Orgin.Y,RayValue.Orgin.Z,RayValue.Direction.X,RayValue.Direction.Y,RayValue.Direction.Z)
		else 
			local x,y,z,x1,y1,z1 = flate(nil,RayValue,6)
			return Ray.new(Vector3.new(x,y,z,x1,y1,z1))
		end
	end,
	["PhysicalProperties"] = function(isClass,PhysicalPropertiesValue) 
		if isClass then 
			return deflate(nil,PhysicalPropertiesValue.Density,PhysicalPropertiesValue.Friction,PhysicalPropertiesValue.Elasticity,
				PhysicalPropertiesValue.FrictionWeight,PhysicalPropertiesValue.ElasticityWeight)
		else 
			local a,b,c,d,e = flate(nil,PhysicalPropertiesValue,5)
			return PhysicalProperties.new(a,b,c,d,e)
		end
	end,
	["NumberRange"] = function(isClass,NumberRangeValue) 
		if isClass then 
			return deflate(nil,NumberRangeValue.Min,NumberRangeValue.Max)
		else 
			local a,b = flate(nil,NumberRangeValue,2)
			return NumberRange.new(a,b)
		end
	end,
	["UDim"] = function(isClass,value)
		if isClass then 
			return deflate(nil,value.Scale,value.Offset) 
		else 
			local a,b = flate(nil,value,2)
			return UDim2.new(a,b)
		end
	end,
	["Color3"] = function(isClass,C3) 
		if isClass then 
			local r, g, b = math.round(C3.R*255), math.round(C3.G*255), math.round(C3.B*255)
			return deflate("I1",r,g,b)	
		else 
			local r1,g2,b2 = flate("I1",C3,3) 
			local r,g,b = r1/255,g2/255,b2/255
			return Color3.new(r,g,b)
		end
	end,
	["UDim2"] = function(isClass,value)
		if isClass then
			return  deflate(nil,value.X.Scale,value.X.Offset,value.Y.Scale,value.Y.Offset)
		else 
			local a,b,c,d = flate(nil,value,4)
			return UDim2.new(a,b,c,d)
		end
	end,
	["Vector3"] = function(isClass,vector) 
		if isClass then 
			if vector then 
				return deflate(nil,vector.X,vector.Y,vector.Z)
			end
		else 
			local X,Y,Z = flate(nil,vector,3)
			return Vector3.new(X,Y,Z)
		end
	end,
	["Vector3int16"] = function(isClass,vector) 
		if isClass then 
			if vector then 
				return deflate("i2",vector.X,vector.Y,vector.Z)
			end
		else 
			local X,Y,Z = flate("i2",vector,3)
			return Vector3.new(X,Y,Z)
		end
	end,
	["Vector2"] = function(isClass,vector) 
		if isClass then 
			if vector then 
				return deflate(nil,vector.X,vector.Y)
			end
		else 
			local X,Y = flate(nil,vector,2)
			return Vector2.new(X,Y)
		end
	end,
	["Vector2int16"] = function(isClass,vector) 
		if isClass then 
			if vector then 
				return deflate("i2",vector.X,vector.Y)
			end
		else 
			local X,Y = flate("i2",vector,2)
			return Vector2.new(X,Y)
		end
	end,
	["Content"]= function(isClass,str) 
		return str
	end,
	["ProtectedString"] = function(isClass,str) 
		return str
	end,
	["string"] = function(isClass,str) 
		return str 
	end,
	["bool"] = function(isClass,bool) 
		if isClass then 
			return ({[true]="#",[false]="$"})[bool]
		else 
			return ({["#"]=true,["$"]=false})[bool]
		end
	end,
	["float"] = function(isCLass,float) 
		if isCLass then 
			return deflate("f",float)
		else 
			local a = flate("f",float,1)
			return a 
		end
	end,
	["double"] = function(isCLass,float) 
		if isCLass then 
			return deflate("d",float)
		else 
			local a = flate("d",float,1)
			return a 
		end
	end,
	["number"] = function(isCLass,float) 
		if isCLass then 
			return deflate("n",float)
		else 
			local a = flate("n",float,1)
			return a 
		end
	end,
	["table"] = function() 
		return ""
	end,
	["int"] = function(isCLass,float) 
		if isCLass then 
			return deflate("i",math.floor(float))
		else 
			local a = flate("i",float,1)
			return a 
		end
	end,
	["int64"] = function(isCLass,float) 
		if isCLass then 
			return deflate("i8",math.floor(float))
		else 
			local a = flate("i8",float,1)
			return a 
		end
	end,
	["SurfaceType"] = function(isClass,surfaceType) 
		if isClass then 
			return deflate(nil,surfaceType.Value)
		else 
			local id = flate(nil,surfaceType,1)
			return EnumStorage[Enum.SurfaceType][id]
		end
	end,
	["BrickColor"] = function(isClass,brickColor)  
		if isClass then 
			return deflate(nil,math.floor(brickColor.Number))
		else 
			local id = flate(nil,brickColor,1)
			return BrickColor.new(id)
		end
	end,
	["Material"] = function(isClass,material)
		if isClass then
			return deflate(nil,material.Value)
		else  
			local id = flate(nil,material,1)
			return EnumStorage[Enum.Material][id]
		end
	end,
	["Faces"] = function(isClass,faces) 
		if isClass then 
			local byte = splitbyte(string.char(0))
			for i,v in ipairs(table.pack(faces.Top,faces.Bottom,faces.Left,faces.Right,faces.Back,faces.Front)) do 
				byte[i] = v 
			end
			-- table.unpack removes the tuple for some reason ?  
			return formbyte(faces)
		else 
			local face = {}
			local newValues = splitbyte(faces)
			for i,v in ipairs(newValues) do 
				if i <= 5 then 
					face[i] = v
				end
			end
			return Faces.new(table.unpack(face))
		end
	end,
	["CFrame"] = function(isClass,Cframe) 
		if isClass then 
			return deflate(nil,Cframe:components())
		else 
			-- yeah just thank string.unpack!
			local a,b,c,d,e,f,g,h,i,j,k,l = flate(nil,Cframe,12)
			return CFrame.new(a,b,c,d,e,f,g,h,i,j,k,l)
		end
	end,
	["CoordinateFrame"] = function(isClass,Cframe) 
		if isClass then 
			return deflate(nil,Cframe:components())
		else 
			local a,b,c,d,e,f,g,h,i,j,k,l = flate(nil,Cframe,12)
			return CFrame.new(a,b,c,d,e,f,g,h,i,j,k,l)
		end
	end
}
-- .Conversion -> Import!^
local DataIndex = {
	ValueHeader = {
		-- Pattern of Values
		["__Pattern"] = "I1", -- Value1! 
	    ["Invalid"]=0,
		["StaticIndexStaticValue"]=1,
		["StaticIndexObjectValue"]=2,
		["ObjectIndexStaticValue"]=3,
		["ObjectIndexObjectValue"]=4
	
	},
	DataType = {
		["__Pattern"] = "I1",
		["Invalid"] = 0,
		-- Roblox DataTypes
		["Axes"]=1,
		["BrickColor"]=2,
		["CatalogSearchParams"]=3,
		["CFrame"]=4,
		["Color3"]=5,
		["ColorSequence"]=6,
		["ColorSequenceKeypoint"]=7,
		["DateTime"]=8,
		["DockWidgetPluginGuiInfo"]=9,
		["Enum"]=10,
		["EnumItem"]=11,
		["Enums"]=12,
		["Faces"]=13,
		["FloatCurveKey"]=14,
		["Instance"]=15,
		["NumberRange"]=16,
		["NumberSequence"]=17,
		["NumberSequenceKeypoint"]=18,
		["OverlapParams"]=19,
		["PathWaypoint"]=20,
		["PhysicalProperties"]=21,
		["Random"]=22,
		["Ray"]=23,
		["RaycastParams"]=24,
		["RaycastResult"]=25,
		["RBXScriptConnection"]=26,
		["RBXScriptSignal"]=27,
		["Rect"]=28,
		["Region3"]=29,
		["Region3int16"]=30,
		["TweenInfo"]=31,
		["UDim"]=32,
		["UDim2"]=33,
		["Vector2"]=34,
		["Vector2int16"]=35,
		["Vector3"]=36,
		["Vector3int16"]=37,
		-- NormalValues 
		["string"]=38,
		["bool"]=39,
		["int"]=40,
		["float"]=41,
		["double"]=42,
		["number"]=43,
		
		-- Redudantvalues
		["table"]=255
		-- FINISHED CAN  ADD MORE LATER! 
	},
}

local TranslateIndex = {} 
for name,Indexes in pairs(DataIndex) do 
	TranslateIndex[name] = {}
	for i,v in pairs(Indexes) do 
		TranslateIndex[name][v] = i
	end 
end 
local sizeof = function(Index) 
	local Data = DataIndex[Index]
	if Data then 
		return string.packsize(Data["__Pattern"])
	else
		throw("[Binary]","Cannot get sizeof ",Index)
	end
end
local readByte = function(data,pos) 
	return string.byte(data:sub(pos,pos))
end 
local ReadStreamByte = function(data,pos)
	local decimal = string.byte(data:sub(pos,pos))
	return pos+1, decimal 
end
local ReadValue1 = function(data,pos)
	local packsize = string.packsize("I1")
	local size = string.unpack("I1",data:sub(pos,pos+packsize))
	local rawdata = data:sub(pos+packsize,(pos+packsize+size)-1)
	return (pos+packsize+size) , rawdata
end
local ReadValue2 = function(data,pos)
	local packsize = string.packsize("I2")
	local size = string.unpack("I2",data:sub(pos,pos+packsize))
	local rawdata = data:sub(pos+packsize,(pos+packsize+size)-1)
	return (pos+packsize+size) , rawdata
end
local translate = function(Index,value) 
	local  Data = TranslateIndex[Index] 
	return Data[value] or "Invalid"
end 
local describe = function(Index,Type) 
	local Data = DataIndex[Index]
	if Data and Data[Type] then 
		return string.pack(Data["__Pattern"],Data[Type])
	else
		if Index == "Value1" then 
			local Type = tostring(Type)
			local dataSize = #Type 
			if dataSize > 255 then 
				throw("[Binary]","Value1 Cannot Encode DataValues more than 255 Bytes.")
				return 
			end 
			return (string.pack("I1",dataSize)..Type) or 0
		end 
		if Index == "Value2" then 
			local Type = tostring(Type)
			local dataSize = #Type 
			if dataSize > 65535 then 
				throw("[Binary]","Value2 Cannot Encode DataValues more than 65,535 Bytes.")
				return 
			end 
			return (string.pack("I2",dataSize)..Type) or 0
		end 
		throw("[Binary]","Could not describe",Index,Type)
		return 0 
	end 
end 
-- .Binary -> Import^
local MAKE_JSON_SAFE = false -- If this is true, " will be replaced by ' in the encoding

local CHAR_SET = [[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!#$%&()*+,./:;<=>?@[]^_`{|}~"]]

local encode_CharSet = {}
local decode_CharSet = {}
for i = 1, 91 do
	encode_CharSet[i-1] = string.sub(CHAR_SET, i, i)
	decode_CharSet[string.sub(CHAR_SET, i, i)] = i-1
end

if MAKE_JSON_SAFE then
	encode_CharSet[90] = "'"
	decode_CharSet['"'] = nil
	decode_CharSet["'"] = 90
end

local function encodeBase91(input)
	local output = {}
	local c = 1

	local counter = 0
	local numBits = 0

	for i = 1, #input do
		counter = bit32.bor(counter, bit32.lshift(string.byte(input, i), numBits))
		numBits = numBits+8
		if numBits > 13 then
			local entry = bit32.band(counter, 8191) -- 2^13-1 = 8191
			if entry > 88 then -- Voodoo magic (https://www.reddit.com/r/learnprogramming/comments/8sbb3v/understanding_base91_encoding/e0y85ot/)
				counter = bit32.rshift(counter, 13)
				numBits = numBits-13
			else
				entry = bit32.band(counter, 16383) -- 2^14-1 = 16383
				counter = bit32.rshift(counter, 14)
				numBits = numBits-14
			end
			output[c] = encode_CharSet[entry%91]..encode_CharSet[math.floor(entry/91)]
			c = c+1
		end
	end

	if numBits > 0 then
		output[c] = encode_CharSet[counter%91]
		if numBits > 7 or counter > 90 then
			output[c+1] = encode_CharSet[math.floor(counter/91)]
		end
	end

	return table.concat(output)
end

local function decodeBase91(input)
	local output = {}
	local c = 1

	local counter = 0
	local numBits = 0
	local entry = -1

	for i = 1, #input do
		if decode_CharSet[string.sub(input, i, i)] then
			if entry == -1 then
				entry = decode_CharSet[string.sub(input, i, i)]
			else
				entry = entry+decode_CharSet[string.sub(input, i, i)]*91
				counter = bit32.bor(counter, bit32.lshift(entry, numBits))
				if bit32.band(entry, 8191) > 88 then
					numBits = numBits+13
				else
					numBits = numBits+14
				end

				while numBits > 7 do
					output[c] = string.char(counter%256)
					c = c+1
					counter = bit32.rshift(counter, 8)
					numBits = numBits-8
				end
				entry = -1
			end
		end
	end

	if entry ~= -1 then
		output[c] = string.char(bit32.bor(counter, bit32.lshift(entry, numBits))%256)
	end

	return table.concat(output)
end

if MAKE_JSON_SAFE then
	encode_CharSet[90] = '"'
	decode_CharSet["'"] = nil
	decode_CharSet['"'] = 90
end

local Base92 = {
	encode = encodeBase91,
	decode = decodeBase91,
}
-- .Base92 -> Import^
--MIT license ^^ [///removed!///]
local char = string.char
local type = type
local select = select
local sub = string.sub
local tconcat = table.concat

local basedictcompress = {}
local basedictdecompress = {}
for i = 0, 255 do
	local ic, iic = char(i), char(i, 0)
	basedictcompress[ic] = iic
	basedictdecompress[iic] = ic
end

local function dictAddA(str, dict, a, b)
	if a >= 256 then
		a, b = 0, b+1
		if b >= 256 then
			dict = {}
			b = 1
		end
	end
	dict[str] = char(a,b)
	a = a+1
	return dict, a, b
end

local function compress(input)
	if type(input) ~= "string" then
		return nil, "string expected, got "..type(input)
	end
	local len = #input
	if len <= 1 then
		return "u"..input
	end

	local dict = {}
	local a, b = 0, 1

	local result = {"c"}
	local resultlen = 1
	local n = 2
	local word = ""
	for i = 1, len do
		local c = sub(input, i, i)
		local wc = word..c
		if not (basedictcompress[wc] or dict[wc]) then
			local write = basedictcompress[word] or dict[word]
			if not write then
				return nil, "algorithm error, could not fetch word"
			end
			result[n] = write
			resultlen = resultlen + #write
			n = n+1
			if  len <= resultlen then
				return "u"..input
			end
			dict, a, b = dictAddA(wc, dict, a, b)
			word = c
		else
			word = wc
		end
	end
	result[n] = basedictcompress[word] or dict[word]
	resultlen = resultlen+#result[n]
	n = n+1
	if  len <= resultlen then
		return "u"..input
	end
	return tconcat(result)
end

local function dictAddB(str, dict, a, b)
	if a >= 256 then
		a, b = 0, b+1
		if b >= 256 then
			dict = {}
			b = 1
		end
	end
	dict[char(a,b)] = str
	a = a+1
	return dict, a, b
end

local function decompress(input)
	if type(input) ~= "string" then
		return nil, "string expected, got "..type(input)
	end

	if #input < 1 then
		return nil, "invalid input - not a compressed string"
	end

	local control = sub(input, 1, 1)
	if control == "u" then
		return sub(input, 2)
	elseif control ~= "c" then
		return nil, "invalid input - not a compressed string"
	end
	input = sub(input, 2)
	local len = #input

	if len < 2 then
		return nil, "invalid input - not a compressed string"
	end

	local dict = {}
	local a, b = 0, 1

	local result = {}
	local n = 1
	local last = sub(input, 1, 2)
	result[n] = basedictdecompress[last] or dict[last]
	n = n+1
	for i = 3, len, 2 do
		local code = sub(input, i, i+1)
		local lastStr = basedictdecompress[last] or dict[last]
		if not lastStr then
			return nil, "could not find last from dict. Invalid input?"
		end
		local toAdd = basedictdecompress[code] or dict[code]
		if toAdd then
			result[n] = toAdd
			n = n+1
			dict, a, b = dictAddB(lastStr..sub(toAdd, 1, 1), dict, a, b)
		else
			local tmp = lastStr..sub(lastStr, 1, 1)
			result[n] = tmp
			n = n+1
			dict, a, b = dictAddB(tmp, dict, a, b)
		end
		last = code
	end
	return tconcat(result)
end

local LZW =  {
	compress = compress,
	decompress = decompress,
}
-- .Compress -> Import^ 
-- . -> Import | combinr0.1

-- if anybody wants combinr (Combines modulescripts into one!) LMK

-- Above are the depandancy modules that make it work, but really all of the magic is done below
-- It isnt complicated, serilzation with a basic understanding of datatstructures and recursion makes this so much easier <3

local function Convert(Value) 
	local Convertor = Convertors[typeof(Value)] 
	if Convertor then      --     IsClass,Value
		local Conversion = Convertor(true,Value) 
		if Conversion ~= nil then 
			return Conversion
		end
	end
end

local function DataConvert(Type,Value) 
	local Convertor = Convertors[Type] 
	if Convertor then      --      IsClass,Value
		local Conversion = Convertor(false,Value) 
		if Conversion ~= nil then 
			return Conversion
		end
	end
end

local function encode(tbl) 
	local BinaryString = ""
	-- 
	for Index,Value in pairs(tbl) do 
		-- TypeIndex,TypeValue
		local TIndex,TValue = typeof(Index),typeof(Value)
		--ConvertedIndex,ConvertedValue
		local CIndex, CValue = Convert(Index) , Convert(Value)
		if TValue == "table" then 
			if TIndex == "table" then 
				-- ObjectIndexObjectValue
				local Table1 = encode(Index) 
				local Table2 = encode(Value) 
				BinaryString = BinaryString..describe("ValueHeader","ObjectIndexObjectValue")..
					describe("Value2",Table1)..
					describe("Value2",Table2)
			else 
				-- StaticIndexObjectValue
				local Table = encode(Value) 
				BinaryString = BinaryString..describe("ValueHeader","StaticIndexObjectValue")..
					describe("DataType",TIndex)..
					describe("Value2",CIndex).. 
					describe("Value2",Table)
			end
			continue
		end

		if CIndex~=nil and CValue~=nil then 
			if TIndex == "table" then 
				-- ObjectIdnexStaticValue 
				local Table = encode(Index) 
				BinaryString = BinaryString..describe("ValueHeader","ObjectIndexStaticValue")..
					describe("Value2",Table)..
					describe("DataType",TValue)..
					describe("Value2",CValue)
				continue
			else
				-- StaticIndexStaticValue
				BinaryString = BinaryString..describe("ValueHeader","StaticIndexStaticValue")..
					describe("DataType",TIndex)..
					describe("Value2",CIndex)..
					describe("DataType",TValue)..
					describe("Value2",CValue)
				-- ValueType,Value
			end 
		else 
			throw("[Encode]","Failure to encode values, doesnt match a siganture.")
		end
	end

	return BinaryString
end

local function decode(Data) 
	local Table = {}



	local bytePos,fnd=0,false
	while bytePos < #Data do bytePos = bytePos + 1 
		-- ReadByte -> Value1 
		local ValueHeader = translate("ValueHeader",readByte(Data,bytePos)) or "Invalid"
		-- JumpHeaderSize 
		bytePos = bytePos + sizeof("ValueHeader")
		
		if ValueHeader == "ObjectIndexObjectValue" then 
			-- Automated Byte reading! : ) So much better than RBXLSerialize :) 
			local ReadEnd , TableIndexData = ReadValue2(Data,bytePos);bytePos = ReadEnd 
			local ReadEnd , TableValueData = ReadValue2(Data,bytePos);bytePos = ReadEnd-1
			-- Do conversions!
			-- Generate Table
			local Index = decode(TableIndexData) 
			-- Generate Table
			local Value = decode(TableValueData)
			-- store 
			Table[Index] = Value
			-- Signal that This ValueHeader was valid.
			fnd = true 
		end
		if ValueHeader == "ObjectIndexStaticValue" then
			-- Automated Byte reading! : ) So much better than RBXLSerialize :) 
			local ReadEnd , TableIndexData = ReadValue2(Data,bytePos);bytePos = ReadEnd 
			local ReadEnd , ValueDataTypeData = ReadStreamByte(Data,bytePos);bytePos = ReadEnd 
			local ReadEnd , ValueData = ReadValue2(Data,bytePos);bytePos = ReadEnd-1
			-- Do conversions!
			-- Generate Table
			local Index = decode(TableIndexData) 
			local ValueDataType = translate("DataType",ValueDataTypeData)
			local Value = DataConvert(ValueDataType,ValueData)
			-- store 
			Table[Index] = Value
			-- Signal that This ValueHeader was valid.
			fnd = true 
		end
		if ValueHeader == "StaticIndexObjectValue" then 
			-- Automated Byte reading! : ) So much better than RBXLSerialize :) 
			local ReadEnd , IndexDataTypeData = ReadStreamByte(Data,bytePos);bytePos = ReadEnd 
			local ReadEnd , IndexData = ReadValue2(Data,bytePos);bytePos = ReadEnd 
			local ReadEnd , TableData = ReadValue2(Data,bytePos);bytePos = ReadEnd-1
			-- Do conversions!
			local IndexDataType = translate("DataType",IndexDataTypeData)
			local Index = DataConvert(IndexDataType,IndexData) 
			-- Generate Table 
			local Value = decode(TableData)
			-- store 
			Table[Index] = Value
			-- Signal that This ValueHeader was valid.
			fnd = true 
		end
		if ValueHeader == "StaticIndexStaticValue" then 
			-- Automated Byte reading! : ) So much better than RBXLSerialize :) 
			local ReadEnd , IndexDataTypeData = ReadStreamByte(Data,bytePos);bytePos = ReadEnd 
			local ReadEnd , IndexData = ReadValue2(Data,bytePos);bytePos = ReadEnd 
			local ReadEnd , ValueDataTypeData = ReadStreamByte(Data,bytePos);bytePos = ReadEnd 
			local ReadEnd , ValueData = ReadValue2(Data,bytePos);bytePos = ReadEnd-1
			-- Do conversions!
			local IndexDataType = translate("DataType",IndexDataTypeData)
			local Index = DataConvert(IndexDataType,IndexData) 
			local ValueDataType = translate("DataType",ValueDataTypeData)
			local Value = DataConvert(ValueDataType,ValueData)	
			-- store 
			Table[Index] = Value
			-- Signal that This ValueHeader was valid.
			fnd = true 
		end
		-- BinaryComprimization implintation
		if not fnd or ValueHeader == "Invalid" then 
			throw("[Binary]","Failed while decoding : could not determine a valid ValueHeader [",ValueHeader,"]")

			return Table 
		end
	end

	return Table
end



rbnsr.Serialize = function(tbl) 
	local Success,Result= pcall(function()
		return encode(tbl) 
	end) 
	if not Success then 
		throw("[LuaError]",Result)
		return ""
	end
	return Base92.encode(LZW.compress(Result))
end

rbnsr.Deserialize = function(str) 
	local Data = LZW.decompress(Base92.decode(str))
	local Success,Result= pcall(function()
		return decode(Data) 
	end) 
	if not Success then 
		throw("[LuaError]",Result)
		return {}
	end
	return Result
end


return rbnsr