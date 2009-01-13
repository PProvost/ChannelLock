function parseargs(s)
  local arg = {}
  string.gsub(s, "(%w+)=([\"'])(.-)%2", function (w, _, a)
    arg[w] = a
  end)
  return arg
end
    
function collect(s)
  local stack = {}
  local top = {}
  table.insert(stack, top)
  local ni,c,label,xarg, empty
  local i, j = 1, 1
  while true do
    ni,j,c,label,xarg, empty = string.find(s, "<(%/?)(%w+)(.-)(%/?)>", i)
    if not ni then break end
    local text = string.sub(s, i, ni-1)
    if not string.find(text, "^%s*$") then
      table.insert(top, text)
    end
    if empty == "/" then  -- empty element tag
      table.insert(top, {label=label, xarg=parseargs(xarg), empty=1})
    elseif c == "" then   -- start tag
      top = {label=label, xarg=parseargs(xarg)}
      table.insert(stack, top)   -- new level
    else  -- end tag
      local toclose = table.remove(stack)  -- remove top
      top = stack[#stack]
      if #stack < 1 then
        error("nothing to close with "..label)
      end
      if toclose.label ~= label then
        error("trying to close "..toclose.label.." with "..label)
      end
      table.insert(top, toclose)
    end
    i = j+1
  end
  local text = string.sub(s, i)
  if not string.find(text, "^%s*$") then
    table.insert(stack[#stack], text)
  end
  if #stack > 1 then
    error("unclosed "..stack[stack.n].label)
  end
  return stack[1]
end

local function custom_loader(modulename)
  local errmsg = ""
  -- Find source
  local modulepath = modulename --string.gsub(modulename, "%.", "/")
  for path in string.gmatch(package.path, "([^;]+)") do
    local filename = string.gsub(path, "%?", modulepath)
    local file = io.open(filename, "rb")
    if file then
      -- Compile and return the module
      return assert(loadstring(assert(file:read("*a")), filename))
    end
    errmsg = errmsg.."\n\tno file '"..filename.."' (checked with custom_loader)"
  end
  return errmsg
end

-- Install the loader so that it's called just before the normal Lua loader
table.insert(package.loaders, 2, custom_loader)

function readfile(path)
	local file = io.open(path, "rb")
	if file then return file:read("*a") end
end

function loadLuaFile(path)
	path = string.gsub(path, "^(.*)\.lua$", "%1")
	print("Loading " .. path)
	require(path)
end

function loadWowXml(path)
	print("Parsing "..path)

	local xmlstr = readfile(path)
	if not xmlstr then return end
	local xml = collect(xmlstr)

	-- xml[1] is the root element
	-- xml[1][1] is the first child
	local root = xml[1]

	local basepath = path:gsub("^(.*)\\[^\\]*$","%1\\")
	for i,v in ipairs(root) do
		-- print( string.format("i,v = %d,%s", i, tostring(v)))
		if root[i].label then
			if root[i].label == "Script" then
				loadLuaFile(basepath .. v.xarg.file)
			elseif root[i].label == "Include" then
				loadWowXml(basepath .. v.xarg.file)
			end
		end
	end

end

function LoadToc(toc)
	for line in io.lines(toc) do
		if not string.match(line, "^##") and not string.match(line, "^%s*$") then
			if string.match(line, "^.*%.xml$") then
				-- It is an XML file
				loadWowXml(line)
			elseif string.match(line, "^.*%.lua$") then
				-- LUA file
				loadLuaFile(line)
				-- require(line)
			else
				-- WTF?
				assert("No soup for you!")
			end
		end
	end
end

