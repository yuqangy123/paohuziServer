local skynet = require "skynet"
require "skynet.manager"    -- import skynet.register
local mysql = require "mysql"
local db = nil
local mutexLock = require "skynet.queue"
local cs = mutexLock()


local userIDSerial = 0

local table_players = "players"
local table_playerdata = "playerData"

local table_user = "user"
local table_iddb = "iddb"
local table_roomRecord = "roomRecord"

local CMD = setmetatable({}, { __gc = function() netpack.clear(queue) end })

local cache = {
	players = {},
	roomids = {},
}
function string.split(input, delimiter)
    if not input or input == "" then
        return {}
    end
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter=='') then return false end
    local pos,arr = 0, {}
    -- for each divider found
    for st,sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
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

function CMD.open( source, conf )
end

function CMD.close()
end


function CMD.gameRecord(pid)
	print("gameRecord")
	local sql = "select * from " .. table_players .. " where pid = \'" .. pid .. "\'"
	local res = db:query(sql)
	local record = {}
	local rids = string.split(res[1].roomids, "|")
	for k,v in pairs(rids) do
		sql = "select * from " .. table_roomRecord .. " where roomid = \'" .. v .. "\'"
		res = db:query(sql)
		print_lua_table(res)
		if #res > 0 then
			local rnt = #record + 1
			record[rnt] = {}
			record[rnt].time = res[1].times
			record[rnt].rid = tonumber(v)
			record[rnt].p1name = res[1].p1name
			record[rnt].p1score = res[1].p1score
			record[rnt].p2name = res[1].p2name
			record[rnt].p2score = res[1].p2score
			record[rnt].p3name = res[1].p3name
			record[rnt].p3score = res[1].p3score
			record[rnt].p4name = res[1].p4name
			record[rnt].p4score = res[1].p4score
		end			
	end
	return record
end

function CMD.gameFinish(playInfo, roomInfo)
	cs(function() 	
		local sql
		local res
		
		sql = string.format("insert into %s values('%d','%s','%s','%s','%s',%d,'%s',%d,'%s',%d,'%s',%d);", table_roomRecord, 
			roomInfo.rid, roomInfo.js, roomInfo.zz, os.time(),
			playInfo[1].name, playInfo[1].score, playInfo[2].name, playInfo[2].score,
			playInfo[3].name, playInfo[3].score, playInfo[4].name, playInfo[4].score)
		res = db:query(sql)
		
		
		for k,v in pairs(playInfo) do
			sql = "select * from " .. table_players .. " where pid = \'" .. v.pid .. "\'"
			res = db:query(sql)
			if string.len(res[1].roomids) > 0 then res[1].roomids = res[1].roomids .. "|" end
			res[1].roomids = res[1].roomids .. roomInfo.rid
			while(true) do
				if string.len(res[1].roomids) > 1024 then
					res[1].roomids = string.sub(string.find(res[1].roomids, ",")+1)
				else
					break
				end
			end
			
			sql = "update " .. table_players .. " set roomids='" .. res[1].roomids .."' where pid=" .. v.pid
			res = db:query(sql)
		end
	end)
end

function CMD.playerLoginWx(openid, nickname)
	return cs(function() 	
		if not openid then return  false end
		
		if cache.players[openid] then
			if cache.players[openid].nickname == nickname then
				return cache.players[openid].pid
			end
		end
		
		local sql = "select * from " .. table_players .. " where openid = \'" .. openid .. "\'"
		res = db:query(sql)
		
		if #res == 0 then
			sql = "select * from " .. table_iddb
			res = db:query(sql)
			res[1].pid = res[1].pid + 1
			sql = "update " .. table_iddb .. " set pid=" .. res[1].pid .." where roomid=" .. res[1].roomid
			db:query(sql)
			local newpid = res[1].pid
			
			sql = string.format("insert into %s values('%d','%s','%s','')", table_players, newpid, openid, nickname)
			db:query(sql)
			
			cache.players[openid] = {nickname=nickname, pid=newpid}
		else
			cache.players[openid] = {nickname=res[1].nickname, pid=res[1].pid}
			if cache.players[openid].nickname ~= nickname then
				sql = "update " .. table_players .. " set name=" .. nickname .." where pid=" .. cache.players[openid].pid
				db:query(sql)
				cache.players[openid].nickname = nickname
			end
		end
		return cache.players[openid].pid
	end)
end

function CMD.getNewRoomId()
	return cs(function() 	
		if not cache.roomids then
			cache.roomids = {}
			local sql = "select * from " .. table_roomRecord
			local res = db:query(sql)
			for k,v in pairs(res) do
				cache.roomids[v.roomid] = "0"
			end
		end
		
		while true do
			local newid = math.random(0, 999999)
			if not cache.roomids[newid] then
				cache.roomids[newid] = "0"
				return newid
			end
		end
	end)
end

skynet.start(function()
    print("db_service start")

	local function on_connect(db)
		db:query("set charset utf8");
	end
	db=mysql.connect({
		host="127.0.0.1",
		port=3306,
		database="rrphDB",
		user="root",
		password="Internet@2014",
		max_packet_size = 1024 * 1024,
		on_connect = on_connect
	})
	if not db then
		skynet.error("failed to connect db")
		assert(false, "failed to connect db")
	end
	print("success to connect to mysql server")
	
	skynet.dispatch("lua", function (session, address, cmd, ...)
                            print("dbService.dispatch.cmd: " .. cmd)
		local f = CMD[cmd]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			skynet.ret(skynet.pack(handler.command(cmd, address, ...)))
		end
	end)

    skynet.register("db_service")
end)
