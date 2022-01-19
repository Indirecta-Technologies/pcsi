local module = {}
module.store = script.Parent:WaitForChild("XFStore")
module.store.Name = game:GetService("HttpService"):GenerateGUID(false)

module.clipboard = script.Parent:WaitForChild("XFHist")
module.clipboard.Name = game:GetService("HttpService"):GenerateGUID(false)

module.currentIndex = module.store

module.fileModes = {
	["r"] = true,
	["w"] = true,
	["a"] = true,
	["w+r"] = true,
	["a+r"] = true,
	["all"] = true
}

local function stringAllowed(str)
	local ProhibitedChars = {
		"!",
		"@",
		"#",
		"%$",
		"%%",
		"¨",
		"&",
		"%*",
		"%(",
		"%)",
		"%[",
		"%]",
		"\"",
		"%^",
		"%?",
		"%+",
		"%-",
		"'",
		'"'
	}
	for i, char in ipairs(ProhibitedChars) do
		if string.match(str, char) then
			return false
		end
	end
	return true
end

local function ShiftReferenceRelated(obj, val)
	if module.type(obj) == "Folder" then
		return val
	else
		return val.Value
	end
end


function module:totalBytesInInstance(objName)
	if not module.exists(objName) then return end
	local obj = module.currentIndex[objName]
	if objName == "." or objName == ".." then return 0 end
	if self.type(objName) == "Link" then
		return 0
	end

	if self.type(objName) == "Reference" then
		local count = 0
		for i,v in pairs(obj.Value:GetDescendants()) do
			count += self:totalBytesInInstance(v.Name)
		end
		return count
	end
	if  self.type(objName) == "File" then
		return (#obj.Value+1)^2
	end
	if  self.type(objName) == "Folder" then
		local count = 0
		for i,v in pairs(obj:GetDescendants()) do
			count += self:totalBytesInInstance(v.Name)
		end
		return count
	end
	
	if obj == module.store or obj == module.clipboard then
		local count = 0
		for i,v in pairs(obj:GetDescendants()) do
			count += self:totalBytesInInstance(v.Name)
		end
		return count
	end
	
	return 0
end

function module.cwd()
	return module.currentIndex.Name == module.store.Name and "C:" or module.currentIndex.Name
end

function module.fullCwd()
		local result = (module.currentIndex == module.store and "C:" or module.currentIndex.Name)
		local object = module.currentIndex
	
		
		while object and object ~= module.store do
			-- Prepend parent name
			result = (object == module.store and object.Name or "C:") .. "/" .. result
			-- Go up the hierarchy
			object = object.Parent
			
		end
		return result
	
end


function module.cd(dir)
	assert(type(dir) == "string", "invalid parameter type, expected string, got "..type(dir))
	assert(module.type(dir) == "Folder" or module.type(dir) == "Reference", "\""..dir.."\" is not a folder")
	module.currentIndex = ShiftReferenceRelated(dir, module.currentIndex[dir])
end



function module.mkdir(name)
	assert(type(name) == "string", "invalid parameter type, expected string, got "..type(name))
	assert(not module.exists(name), "directory \""..name.."\" exists.")
	assert(stringAllowed(name) == true, "dir name has invalid characters")
	local Folder = Instance.new("Folder", module.currentIndex)
	Folder.Name = name

	local Reference = Instance.new("ObjectValue", Folder)
	Reference.Name = "."
	Reference.Value = Folder

	local Parent = Instance.new("ObjectValue", Folder)
	Parent.Name = ".."
	Parent.Value = Folder.Parent
end

function module.mkfile(name)
	assert(type(name) == "string", "invalid parameter type, expected string, got "..type(name))
	assert(stringAllowed(name) == true, "file name has invalid characters")
	assert(not module.exists(name), "file \""..name.."\" exists.")
	local Script = Instance.new("StringValue", module.currentIndex)
	Script.Name = name
	Script:SetAttribute("Mode", "all")
	Script:SetAttribute("Creation", tick())
	Script:SetAttribute("LastEdit", tick())

end

function module.link(file)
	assert(type(file) == "string", "invalid parameter type, expected string, got "..type(file))
	assert(module.exists(file), file.." does not exist.")
	assert(module.type(file) ~= "Reference", "cannot link references")
	assert(module.type(file) ~= "Link", "cannot link links")

	local Script = Instance.new("ObjectValue", module.currentIndex)
	Script.Name = file..".lnk"
	Script:SetAttribute("xlink", true)
	Script:SetAttribute("Creation", tick())
	Script.Value = module.currentIndex[file]
end

function module.del(name)
	assert(type(name) == "string", "invalid parameter type, expected string, got "..type(name))
	assert(module.type(name) ~= "Reference", "cannot delete references")

	module.currentIndex[name]:Destroy()
end

function module.copy(name)
	assert(type(name) == "string", "invalid parameter type, expected string, got "..type(name))
	assert(module.exists(name), name.." does not exists.")
	assert(module.type(name) ~= "Reference", "cannot copy references")
	module.currentIndex[name]:Clone().Parent = module.clipboard
end

function module.paste(name)
	name = name or module.clipboard:GetChildren()[1].Name
	if #module.clipboard:GetChildren() > 1 then
		assert(type(name) == "string", "invalid parameter type, expected string, got "..type(name))
	end
	assert(not module.exists(name), name.." exists.")
	module.clipboard[name]:Clone().Parent = module.currentIndex
end

function module.cut(name)
	assert(type(name) == "string", "invalid parameter type, expected string, got "..type(name))
	assert(module.type(name) ~= "Reference", "cannot cut references")
	module.copy(name)
	module.del(name)
end

function module.clear_history()
	module.clipboard:ClearAllChildren()
end

function module.list(opt, dir)
	if dir ~= nil then
		assert(type(tostring(dir)) == "string", "invalid parameter type, expected string, got "..type(dir))
		assert(module.type(dir) == "Folder" or module.type(dir) == "Reference", "\""..dir.."\" is not a folder/reference") 
	end

	dir = dir or "."

	local start = 1
	local Objects
	local Table

	if opt == "all" then
		Objects = ShiftReferenceRelated(dir, module.currentIndex[dir])
		Table = {}
		for idx, obj in pairs(Objects:GetChildren()) do
			table.insert(Table, obj)
		end
	elseif opt == "clipboard" then
		Objects = module.clipboard
		Table = {}
		for idx, obj in pairs(Objects:GetChildren()) do
			table.insert(Table, obj)
		end
	else
		Objects = ShiftReferenceRelated(dir, module.currentIndex[dir])
		Table = {}
		for idx, obj in pairs(Objects:GetChildren()) do
			if module.type(obj.Name) ~= "Reference" then
				table.insert(Table, obj)
			end
		end
	end

	return function()
		if start > #Table then return nil end

		local i = start
		start += 1

		return {Name = Table[i].Name, Type = module.type(Table[i].Name)}
	end
end

function module.exists(name, onHistory)
	assert(type(name) == "string", "invalid parameter type, expected string, got "..type(name))
	if onHistory then
		return (module.clipboard:FindFirstChild(name) ~= nil)
	else
		return (module.currentIndex:FindFirstChild(name) ~= nil)
	end
end

function module.type(name)
	assert(type(name) == "string", "invalid parameter type, expected string, got "..type(name))
	assert(module.exists(name), name.." does not exist")
	if module.currentIndex[name]:IsA("Folder") then
		return module.currentIndex[name].ClassName
	elseif module.currentIndex[name]:IsA("ObjectValue") then
		if module.currentIndex[name]:GetAttribute("xlink") then
			return "Link"
		end
		return "Reference"
	else
		return "File"
	end
end

function module.diff(file1, file2)
	assert(type(file1) == "string", "invalid parameter type, expected string, got "..type(file1))
	assert(type(file2) == "string", "invalid parameter type, expected string, got "..type(file2))
	assert(module.type(file1) == "File", "\""..file1.."\" is not a file.")
	assert(module.type(file2) == "File", "\""..file2.."\" is not a file.")
	
	local function get_inserted_text(old, new)
		local prv = {}
		for o = 0, #old do
			prv[o] = ""
		end
		for n = 1, #new do
			local nxt = {[0] = new:sub(1, n)}
			local nn = new:sub(n, n)
			for o = 1, #old do
				local result
				if nn == old:sub(o, o) then
					result = prv[o-1]
				else
					result = prv[o]..nn
					if #nxt[o-1] <= #result then
						result = nxt[o-1]
					end
				end
				nxt[o] = result
			end
			prv = nxt
		end
		return prv[#old]
	end

	
	return (file1.Value == file2.Value and "equal" or get_inserted_text(file1.Value,file2.Value))
end

function module.mode(name)
	assert(type(name) == "string", "invalid parameter type, expected string, got "..type(name))
	assert(module.type(name) == "File", name.." must be a file.")
	return module.currentIndex[name]:GetAttribute("Mode")
end

function module.chmod(name, newmode)
	assert(type(name) == "string", "invalid parameter type, expected string, got "..type(name))
	assert(type(newmode) == "string", "invalid parameter type, expected string, got "..type(newmode))
	assert(module.type(name) == "File", name.." must be a file.")
	assert(module.fileModes[newmode] ~= nil, "invalid file mode. (modes are: r, w, a, w+r, a+r and all)")

	module.currentIndex[name]:SetAttribute("Mode", newmode)
	module.currentIndex[name]:SetAttribute("LastEdit", tick())

end

function decodeChar(hex)
	return string.char(tonumber(hex,16))
end
 
function decodeString(str)
	local output, t = string.gsub(str,"%%(%x%x)",decodeChar)
	return output
end

function module.write(name, text)
	assert(type(name) == "string", "invalid parameter type, expected string, got "..type(name))
	assert(type(text) == "string", "invalid parameter type, expected string, got "..type(text))
	assert(module.type(name) == "File", name.." must be a file.")
	assert(module.mode(name) == "w" or module.mode(name) == "w+r" or module.mode(name) == "all", "incorrect mode. (expected w|w+r, got "..module.mode(name)..")")
	module.currentIndex[name].Value = game:GetService("HttpService"):UrlEncode(text)
	module.currentIndex[name]:SetAttribute("LastEdit", tick())

end

function module.rename(name, newname)
	assert(type(name) == "string", "invalid parameter type, expected string, got "..type(name))
	assert(type(newname) == "string", "invalid parameter type, expected string, got "..type(newname))
	assert(module.type(name) == "File", name.." must be a file.")
	assert(module.mode(name) == "w" or module.mode(name) == "w+r" or module.mode(name) == "all", "incorrect mode. (expected w|w+r, got "..module.mode(name)..")")
	module.currentIndex[name].Name = newname
end

function module.compress(name)
	assert(type(name) == "string", "invalid parameter type, expected string, got "..type(name))
	assert(module.type(name) == "File", name.." must be a file.")
	assert(module.mode(name) == "w+r" or module.mode(name) == "all", "incorrect mode. (expected all|w+r, got "..module.mode(name)..")")
	
	local xcompress = require(script.Parent.Parent.lib.xcompress)
	local uncompressed = module.read(name)
	
	module.write(name, xcompress.compress(uncompressed))
	module.currentIndex[name]:SetAttribute("LastEdit", tick())
	module.currentIndex[name]:SetAttribute("xcompress","true")
end


function module.append(name, text)
	assert(type(name) == "string", "invalid parameter type, expected string, got "..type(name))
	assert(type(text) == "string", "invalid parameter type, expected string, got "..type(text))
	assert(module.type(name) == "File", name.." must be a file.")
	assert(module.mode(name) == "a" or module.mode(name) == "a+r" or module.mode(name) == "all", "incorrect mode. (expected a|a+r, got "..module.mode(name)..")")
	local xcompress = require(script.Parent.Parent.lib.xcompress)
	local buffer;
	
	if module.currentIndex[name]:GetAttribute("xcompress") == true then
		buffer = module.read(name)
		buffer ..= text
		buffer = xcompress.compress(buffer)
	else
		buffer = module.read(name)
		buffer ..= text
	end
	
	module.write(name, game:GetService("HttpService"):UrlEncode(buffer))
	module.currentIndex[name]:SetAttribute("LastEdit", tick())

end

module.fileTypes = {
	["luac"] = {
		mime = "application/x-lua-bytecode",
		matches = {
			'[^ -~\n\t]' -- only matches binary bytecode files with "luac0000000000000000" 
		}
	}
}
function module:fileType(name)
	local text = self.read(name)

	for i,k in pairs(self.fileTypes) do
		local matched = false
		for i,v in ipairs(k.matches) do
			if text:match(v) then
				return k.mime
			end
		end
	end

end

function module.read(name)
	assert(type(name) == "string", "invalid parameter type, expected string, got "..type(name))
	assert(module.type(name) == "File" or module.type(name) == "Link" , name.." must be a file.")
	
	assert(module.mode(name) == "r" or module.mode(name) == "w+r" or module.mode(name) == "a+r" or module.mode(name) == "all", "incorrect mode. (expected r|w+r|a+r, got "..module.mode(name)..")")
	local xcompress = require(script.Parent.Parent.lib.xcompress)
	
	
	 

	local toread;
	if module.type(name) == "File" then
		toread = module.currentIndex[name]
	elseif module.type(name) == "Link" then
		toread = module.currentIndex[name].Value
		toread = toread
	end
	
	module.currentIndex[name]:SetAttribute("LastRead", tick())

	
	if toread.Value == "" then return "(empty file)" end
	if toread:GetAttribute("xcompress") == true then return xcompress.decompress(decodeString(toread.Value))
	else return decodeString(toread.Value)
	end
	

end



return module
