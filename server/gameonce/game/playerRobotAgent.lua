local skynet = require "skynet"
local netpack = require "netpack"
local socket = require "socket"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"
local datacenter = require "datacenter"

require "functions"
--local sproto_core = require "sproto.core"

local watchdog
local roomManager
local host
local packMsg

local CMD = {}
local REQUEST = {}
local m_inRoom = false


local user_info = {
	pid = 0,
	nikeName = "",
	ip = "",
	fd = 0,
}
local game_info = {
	roomid = 0
}
local playing = false


function CMD.totalPush(token)
	--local r = skynet.call("db_service", "lua", "getPlayerData", self.token)
	
	local pid = 0
	--local pid = datacenter.get("serial_pid", "pid")
	--pid = pid + 1
	--datacenter.set("serial_pid", "pid", pid)

	user_info.pid = pid
	user_info.nikeName = token .. ":" .. pid
	skynet.call(roomManager, "lua", "playerOnline", skynet.self(), user_info.fd, pid)
	
	local res = { code=0, pid = user_info.pid, nickname = user_info.nikeName, ip = user_info.ip, roomid = 0}

	--return res
end


function CMD.joinRoom(roomid)
		
	skynet.sleep(10)
	game_info.roomid = roomid
	skynet.call(roomManager, "lua", "joinRoom", roomid, user_info.pid, user_info.nikeName, user_info.ip)

end


function CMD.ready()
	if not game_info.roomagent then return nil end
	skynet.call(game_info.roomagent, "lua", "playerReady",user_info.pid)
end

function CMD.chat(faceid)
	if not game_info.roomagent then return nil end
	skynet.call(game_info.roomagent, "lua", "playerChat", user_info.pid, faceid)
end


function CMD.quit()

end

function CMD.roomAgentRelate(agent)
	game_info.roomagent = agent
end

function CMD.roomAgentUnRelate()
	game_info.roomagent = nil
end

function msg_notify(msgName, pack)
	--print("playerRobotAgent.msg_notify.msgName", msgName)
	if msgName == "joinRoomNotify" then
		local pidList = string.split(pack.pid, ",")
		local siteList = string.split(pack.site, ",")
		for i=1, #pidList do
			if tonumber(pidList[i]) == user_info.pid then
				game_info.site = tonumber(siteList[i])
				break
			end
		end
		
	elseif msgName == "roomCardInitNotify" then
		game_info.cardIds = {}
		local idsList = string.split(pack.pids, ",")
		for k,v in pairs(idsList) do
			local cinfo = string.split(v, "_")
			game_info.cardIds[tonumber(cinfo[3])] = {value = tonumber(cinfo[1]), capital = tonumber(cinfo[2]) == 1, id = tonumber(cinfo[3])}
		end
		
		game_info.phandlist = {}
		local handList = string.split(pack.hand, ",")
		local idlist = string.split(handList[game_info.site], "_")			
		for j=1, #idlist do
			local id = tonumber(idlist[j])
			table.insert(game_info.phandlist,  game_info.cardIds[id])
		end
		
	elseif msgName == "turnPlayerNotify" then
		if pack.pid == user_info.pid then
			skynet.fork(function()
				skynet.sleep(300)
				local pn = math.random(1,#game_info.phandlist)
				local payid = tostring(game_info.phandlist[pn].id)
				--print("robotagent payid", payid , user_info.pid)
				skynet.call(game_info.roomagent, "lua", "playerPayCard", user_info.pid, "0", payid)
				table.remove(game_info.phandlist, pn)
			end)
		end
		
	elseif msgName == "ruleCardsPossible" then		
		if pack.pid == user_info.pid then
			local rules = string.split(pack.rule, ",")
			local cids = string.split(pack.cid, ",")
			local ocids = string.split(pack.ocid, ",")
			
			local rulecids = ""
			for i=1, #cids do
				local cards = string.split(cids[i], "-")
				for j=1, #cards do
					
					local cc = string.split(cards[j], "_")
					for k=1, #cc do
						rulecids = rulecids .. cc[k] .. ","
						for n=1, #game_info.phandlist do 
							if game_info.phandlist[n].id == tonumber(cc[k]) then 
								table.remove(game_info.phandlist, n) 
								break 
							end 
						end
					end
					break
				end
				break
			end
			skynet.fork(function()
				skynet.sleep(300)
				skynet.call(game_info.roomagent, "lua", "playerPayCard",  user_info.pid, rules[1], rulecids)
			end)
			
		end
		
	elseif msgName == "hupaiNotify" then
		skynet.fork(function()
			skynet.sleep(math.random(1,3)*100)
			CMD.ready()
		end)

		
	elseif msgName == "gameFinishNotify" then
		--print(user_info.pid .. " recv gameFinishNotify")
	end
end

function CMD.msg_notify(msgName, pack)
	--skynet.fork(function()
	--	skynet.sleep(300)
		msg_notify(msgName, pack)
	--end)
end

function CMD.start(conf)
	local gate = conf.gate
	roomManager = conf.roomManager
	watchdog = conf.watchdog
	user_info.ip = conf.addr
	user_info.fd = conf.client
	

	
end

function CMD.disconnect()
	-- todo: do something before exit
	skynet.call(roomManager, "lua", "playerOffline", skynet.self(), user_info.pid)
	skynet.exit()
end

skynet.start(function()	
    --print("playerRobotAgent service start")
	skynet.dispatch("lua", function(_,_, command, ...)
		--print("playerRobotAgent dispatch lua:", command)
		local f = CMD[command]
		--f(...)
		
		skynet.ret(skynet.pack(f(...)))
	end)
end)
