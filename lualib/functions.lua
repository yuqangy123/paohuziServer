--[[

Copyright (c) 2011-2014 chukong-inc.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]

function printLog(tag, fmt, ...)
    
end

function printError(fmt, ...)
    
end

function printInfo(fmt, ...)
    
end

local function dump_value_(v)
    
end

function dump(value, desciption, nesting)
    
end

function checknumber(value, base)
    return tonumber(value, base) or 0
end

function checkint(value)
    return math.round(checknumber(value))
end

function checkbool(value)
    return (value ~= nil and value ~= false)
end

function checktable(value)
    if type(value) ~= "table" then value = {} end
    return value
end

function isset(hashtable, key)
    local t = type(hashtable)
    return (t == "table" or t == "userdata") and hashtable[key] ~= nil
end

--将父类成员添加到之类__index中
local setmetatableindex_
setmetatableindex_ = function(t, index)
    if type(t) == "userdata" then
        local peer = tolua.getpeer(t)
        if not peer then
            peer = {}
            tolua.setpeer(t, peer)
        end
        setmetatableindex_(peer, index)
    else
        local mt = getmetatable(t)
        if not mt then mt = {} end
        if not mt.__index then
            mt.__index = index
            setmetatable(t, mt)
        elseif mt.__index ~= index then
            setmetatableindex_(mt, index)
        end

        for k,v in pairs(index) do
            local tp = type(v)
            local vStr = tostring(k)
            if "function" == tp then                
                local tv = t[vStr]
                --if tv then
                    t[vStr] = v
                --end
            else
                t[k] = v
            end
        end
    end
end
setmetatableindex = setmetatableindex_

function clone(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local newObject = {}
        lookup_table[object] = newObject
        for key, value in pairs(object) do
            newObject[_copy(key)] = _copy(value)
        end
        return setmetatable(newObject, getmetatable(object))
    end
    return _copy(object)
end

--类申明
function class(classname, ...)
    local cls = {__cname = classname}

    local supers = {...}
    for _, super in ipairs(supers) do
        local superType = type(super)
        assert(superType == "nil" or superType == "table" or superType == "function",
            string.format("class() - create class \"%s\" with invalid super class type \"%s\"",
                classname, superType))

        if superType == "function" then
            assert(cls.__create == nil,
                string.format("class() - create class \"%s\" with more than one creating function",
                    classname));
            -- if super is function, set it to __create
            cls.__create = super
        elseif superType == "table" then
            if super[".isclass"] then
                -- super is native class
                assert(cls.__create == nil,
                    string.format("class() - create class \"%s\" with more than one creating function or native class",
                        classname));
                cls.__create = function(param)
                    if nil == super.ctor then
                        return super:create()
                    else
                        return super:create(param)
                    end
                end
            else
                -- super is pure lua class
                cls.__supers = cls.__supers or {}
                cls.__supers[#cls.__supers + 1] = super
                if not cls.super then
                    -- set first super pure lua class as class.super
                    cls.super = super
                end
            end
        else
            error(string.format("class() - create class \"%s\" with invalid super type",
                        classname), 0)
        end
    end

    cls.__index = cls
    if not cls.__supers or #cls.__supers == 1 then
        if cls.super then
            setmetatable(cls, {__index = cls.super})
        end
    else
        setmetatable(cls, {__index = function(_, key)
            local supers = cls.__supers
            for i = 1, #supers do
                local super = supers[i]
                if super[key] then return super[key] end
            end
        end})
    end

    --构造函数
    if not cls.ctor then
        -- add default constructor
        cls.ctor = function() end
    end
    cls.new = function(param)
        local instance
        if cls.__create then
            instance = cls.__create(param)
        else
            instance = {}
        end
        
        setmetatableindex(instance, cls)
        instance.class = cls
        instance:ctor(param)
        return instance
    end
    cls.create = function(_, param)
        return cls.new(param)
    end

    return cls
end

--类定义(不包含通知)
function new_class(className, param)
    local status, view = xpcall(function()
            return require(className)
        end, function(msg) end)

    local t = type(view)
    if status and (t == "table" or t == "userdata") then
        view = view:create(param)
        --Notifier.addObserver( view )
        return view
    else
        error("create class \"" .. className .. "\" error!!!")
    end
end

local iskindof_
iskindof_ = function(cls, name)
    local __index = rawget(cls, "__index")
    if type(__index) == "table" and rawget(__index, "__cname") == name then return true end

    if rawget(cls, "__cname") == name then return true end
    local __supers = rawget(cls, "__supers")
    if not __supers then return false end
    for _, super in ipairs(__supers) do
        if iskindof_(super, name) then return true end
    end
    return false
end

function iskindof(obj, classname)
    local t = type(obj)
    if t ~= "table" and t ~= "userdata" then return false end

    local mt
    if t == "userdata" then
        if tolua.iskindof(obj, classname) then return true end
        mt = tolua.getpeer(obj)
    else
        mt = getmetatable(obj)
    end
    if mt then
        return iskindof_(mt, classname)
    end
    return false
end

function import(moduleName, currentModuleName)
    local currentModuleNameParts
    local moduleFullName = moduleName
    local offset = 1

    while true do
        if string.byte(moduleName, offset) ~= 46 then -- .
            moduleFullName = string.sub(moduleName, offset)
            if currentModuleNameParts and #currentModuleNameParts > 0 then
                moduleFullName = table.concat(currentModuleNameParts, ".") .. "." .. moduleFullName
            end
            break
        end
        offset = offset + 1

        if not currentModuleNameParts then
            if not currentModuleName then
                local n,v = debug.getlocal(3, 1)
                currentModuleName = v
            end

            currentModuleNameParts = string.split(currentModuleName, ".")
        end
        table.remove(currentModuleNameParts, #currentModuleNameParts)
    end

    return require(moduleFullName)
end

function handler(obj, method)
    return function(...)
        return method(obj, ...)
    end
end

function math.newrandomseed()
    local ok, socket = pcall(function()
        return require("socket")
    end)

    if ok then
        math.randomseed(socket.gettime() * 1000)
    else
        math.randomseed(os.time())
    end
    math.random()
    math.random()
    math.random()
    math.random()
end

function math.round(value)
    value = checknumber(value)
    return math.floor(value + 0.5)
end

local pi_div_180 = math.pi / 180
function math.angle2radian(angle)
    return angle * pi_div_180
end

local pi_mul_180 = math.pi * 180
function math.radian2angle(radian)
    return radian / pi_mul_180
end

function io.exists(path)
    local file = io.open(path, "r")
    if file then
        io.close(file)
        return true
    end
    return false
end

function io.readfile(path)
    local file = io.open(path, "r")
    if file then
        local content = file:read("*a")
        io.close(file)
        return content
    end
    return nil
end


--lua转字符串
function TableToString(obj)  
    local lua = ""  
    local t = type(obj)  
    if t == "number" then  
        lua = lua .. obj  
    elseif t == "boolean" then  
        lua = lua .. tostring(obj)  
    elseif t == "string" then  
        lua = lua .. string.format("%q", obj)  
    elseif t == "table" then  
        lua = lua .. "{"  
    for k, v in pairs(obj) do  
        lua = lua .. "[" .. TableToString(k) .. "]=" .. TableToString(v) .. ","  
    end  
    local metatable = getmetatable(obj)  
        if metatable ~= nil and type(metatable.__index) == "table" then  
        for k, v in pairs(metatable.__index) do  
            lua = lua .. "[" .. TableToString(k) .. "]=" .. TableToString(v) .. ","  
        end  
    end  
        lua = lua .. "}"  
    elseif t == "nil" then  
        return nil  
	elseif t == "function" then  
		lua = lua .. "function. "
    else  
        error("can not TableToString a " .. t .. " type.")  
    end  
    return lua  
end 


function printToFile(log)
	local logText = TableToString(log)
    local t = os.date("%X", os.time())
    local msg = t .. "\n" .. logText .. "\n"
	io.writefile("C:/Users/qiang.yu/Desktop/errorlog.txt", msg .. "\n", "a+")
end


function print_lua_table (lua_table, indent)
    indent = indent or 0
    for k, v in pairs(lua_table) do
        if type(k) == "string" then
            k = string.format("%q", k)
        end
        local szSuffix = ""
        if type(v) == "table" then
            szSuffix = "{"
        end
        local szPrefix = string.rep("    ", indent)
        formatting = szPrefix.."["..k.."]".." = "..szSuffix
        if type(v) == "table" then
            print(formatting)
            print_lua_table(v, indent + 1)
            print(szPrefix.."},")
        else
            local szValue = ""
            if type(v) == "string" then
                szValue = string.format("%q", v)
            else
                szValue = tostring(v)
            end
            print(formatting..szValue..",")
        end
    end
end

function io.writefile(path, content, mode)
    mode = mode or "w+b"
    local file = io.open(path, mode)
    if file then
        if file:write(content) == nil then return false end
        io.close(file)
        return true
    else
        return false
    end
end

function io.pathinfo(path)
    local pos = string.len(path)
    local extpos = pos + 1
    while pos > 0 do
        local b = string.byte(path, pos)
        if b == 46 then -- 46 = char "."
            extpos = pos
        elseif b == 47 then -- 47 = char "/"
            break
        end
        pos = pos - 1
    end

    local dirname = string.sub(path, 1, pos)
    local filename = string.sub(path, pos + 1)
    extpos = extpos - pos
    local basename = string.sub(filename, 1, extpos - 1)
    local extname = string.sub(filename, extpos)
    return {
        dirname = dirname,
        filename = filename,
        basename = basename,
        extname = extname
    }
end

function io.filesize(path)
    local size = false
    local file = io.open(path, "r")
    if file then
        local current = file:seek()
        size = file:seek("end")
        file:seek("set", current)
        io.close(file)
    end
    return size
end

function table.nums(t)
    if not t then
        return 0
    end
    local count = 0
    for k, v in pairs(t) do
        count = count + 1
    end
    return count
end

function table.keys(hashtable)
    local keys = {}
    for k, v in pairs(hashtable) do
        keys[#keys + 1] = k
    end
    return keys
end

function table.values(hashtable)
    local values = {}
    for k, v in pairs(hashtable) do
        values[#values + 1] = v
    end
    return values
end

function table.merge(dest, src)
    for k, v in pairs(src) do
        dest[k] = v
    end
end

function table.insertto(dest, src, begin)
    begin = checkint(begin)
    if begin <= 0 then
        begin = #dest + 1
    end

    local len = #src
    for i = 0, len - 1 do
        dest[i + begin] = src[i + 1]
    end
end

function table.indexof(array, value, begin)
    for i = begin or 1, #array do
        if array[i] == value then return i end
    end
    return false
end

function table.keyof(hashtable, value)
    for k, v in pairs(hashtable) do
        if v == value then return k end
    end
    return nil
end

function table.removebyvalue(array, value, removeall)
    local c, i, max = 0, 1, #array
    while i <= max do
        if array[i] == value then
            table.remove(array, i)
            c = c + 1
            i = i - 1
            max = max - 1
            if not removeall then break end
        end
        i = i + 1
    end
    return c
end

function table.map(t, fn)
    for k, v in pairs(t) do
        t[k] = fn(v, k)
    end
end

function table.walk(t, fn)
    for k,v in pairs(t) do
        fn(v, k)
    end
end

function table.filter(t, fn)
    for k, v in pairs(t) do
        if not fn(v, k) then t[k] = nil end
    end
end

function table.unique(t, bArray)
    local check = {}
    local n = {}
    local idx = 1
    for k, v in pairs(t) do
        if not check[v] then
            if bArray then
                n[idx] = v
                idx = idx + 1
            else
                n[k] = v
            end
            check[v] = true
        end
    end
    return n
end

--转换成数字
function table.convertToNumber(t)
    for k, v in pairs(t) do
        t[k] = tonumber(v)
    end
end

string._htmlspecialchars_set = {}
string._htmlspecialchars_set["&"] = "&amp;"
string._htmlspecialchars_set["\""] = "&quot;"
string._htmlspecialchars_set["'"] = "&#039;"
string._htmlspecialchars_set["<"] = "&lt;"
string._htmlspecialchars_set[">"] = "&gt;"

function string.htmlspecialchars(input)
    for k, v in pairs(string._htmlspecialchars_set) do
        input = string.gsub(input, k, v)
    end
    return input
end

function string.restorehtmlspecialchars(input)
    for k, v in pairs(string._htmlspecialchars_set) do
        input = string.gsub(input, v, k)
    end
    return input
end

function string.nl2br(input)
    return string.gsub(input, "\n", "<br />")
end

function string.text2html(input)
    input = string.gsub(input, "\t", "    ")
    input = string.htmlspecialchars(input)
    input = string.gsub(input, " ", "&nbsp;")
    input = string.nl2br(input)
    return input
end

function string.split(input, delimiter)
    if input == "" then return {} end
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter=='') then return {} end
    local pos,arr = 0, {}
    -- for each divider found
    for st,sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

function string.ltrim(input)
    return string.gsub(input, "^[ \t\n\r]+", "")
end

function string.rtrim(input)
    return string.gsub(input, "[ \t\n\r]+$", "")
end

function string.trim(input)
    input = string.gsub(input, "^[ \t\n\r]+", "")
    return string.gsub(input, "[ \t\n\r]+$", "")
end

function string.ucfirst(input)
    return string.upper(string.sub(input, 1, 1)) .. string.sub(input, 2)
end

local function urlencodechar(char)
    return "%" .. string.format("%02X", string.byte(char))
end
function string.urlencode(input)
    -- convert line endings
    input = string.gsub(tostring(input), "\n", "\r\n")
    -- escape all characters but alphanumeric, '.' and '-'
    input = string.gsub(input, "([^%w%.%- ])", urlencodechar)
    -- convert spaces to "+" symbols
    return string.gsub(input, " ", "+")
end

function string.urldecode(input)
    input = string.gsub (input, "+", " ")
    input = string.gsub (input, "%%(%x%x)", function(h) return string.char(checknumber(h,16)) end)
    input = string.gsub (input, "\r\n", "\n")
    return input
end

function string.utf8len(input)
    local len  = string.len(input)
    local left = len
    local cnt  = 0
    local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    while left ~= 0 do
        local tmp = string.byte(input, -left)
        local i   = #arr
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                break
            end
            i = i - 1
        end
        cnt = cnt + 1
    end
    return cnt
end

function string.formatnumberthousands(num)
    local formatted = tostring(checknumber(num))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

--lua对象深度拷贝
function DeepCopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

--(秒)转成时间格式
function timeToData( s )
    local day = math.floor( s/86400) 
    local h = math.floor((s - day*86400)/3600)
    local m = math.floor((s- day*86400 - h*3600)/60)
    local s = math.floor(s- day*86400 - h*3600 - m * 60)
    return  day..":"..h..":"..m..":"..s      -- {day = day,h = h ,m = m ,s = s}
end
--(秒)转成时间格式，如果天数不满一天，小时不满一小时则不显示
function timeToData1( s )
    local day = math.floor( s/86400) 
    local h = math.floor((s - day*86400)/3600)
    local m = math.floor((s- day*86400 - h*3600)/60)
    local s = math.floor(s- day*86400 - h*3600 - m * 60)
    if day < 1 and h < 1 then
        return  m..":"..s      
    elseif day < 1 and h >= 1 then
        return h..":"..m..":"..s
    else
        return  day..":"..h..":"..m..":"..s
    end
end
--(秒)转成时间格式 返回tybe
function timeToDataT( s )
    local day = math.floor( s/86400) 
    local h = math.floor((s - day*86400)/3600)
    local m = math.floor((s- day*86400 - h*3600)/60)
    local s = math.floor(s- day*86400 - h*3600 - m * 60)
    return  {day = day,h = h ,m = m ,s = s}
end

--(秒)转成时间格式 最大单位为分
function timeToDataM( s )
    local min = math.floor( s/60)
    local sec = s - min*60

    local nstr = string.format("%02d:%02d", min, sec)
    return nstr
end

--数字格式化为制定类型,多少多少万
function numberFormat(num)
	local return_number = nil
	if tonumber(num) > 9999 then
		local _num1 = math.floor( tonumber(num) /10000 )
		local _num2 = math.mod(  math.floor(tonumber(num)/1000) , 10 )
		return_number = _num1..".".._num2.."w"
	else
		return_number = num
	end
	return return_number
end

--根据一段字符串产生对应的唯一Key
local stringKeyCache = {}
function createKeyWithString(str)
    if stringKeyCache[str] then
        return stringKeyCache[str]
    end
    local len = string.len(str)
    if len == 0 then
        return 0
    end
    local key = string.byte(str,1)
    local star = 2
    for i=star,len do
        local sv = string.byte(str,i)
        sv = math.pow(sv,i)
        if (i-star)%4 == 0 then
            key = key + sv
        elseif (i-star)%4 == 1 then
            key = key - sv
        elseif (i-star)%4 == 2 then
            key = key * sv
        elseif (i-star)%4 == 3 then
            key = key / sv
        end
    end
    if key < 0 then key = - key end
    if key > 99999 then key = key%99999 end
    

    stringKeyCache[str] =  math.max(1, math.ceil( key ) )
    print(stringKeyCache[str] )
    return stringKeyCache[str]
end
