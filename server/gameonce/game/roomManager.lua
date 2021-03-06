local skynet = require "skynet"
require "skynet.manager"
local datacenter = require "datacenter"
local mutexLock = require "skynet.queue"
local sharedata = require "sharedata"
local cs = mutexLock()
local CMD = {}
require "functions"
local rooms = {}--{agent} key=roomid
local players = {}--{roomagent, roomid, agent} key=pid


function CMD.playerOnline(agent, fd, pid)
	if not players[pid] then
		players[pid] = {}
	end
	players[pid].agent = agent
	if players[pid].roomagent then
		skynet.call(players[pid].roomagent, "lua", "playerOnline", agent, pid)
	end

end

function CMD.playerOffline(pid)
	if players[pid] then
		if players[pid].roomagent then
			skynet.call(players[pid].roomagent, "lua", "playerOffline", pid)
			players[pid].agent = nil
		else
			players[pid] = nil
		end
	end
end

function CMD.playerMsg_notify(pid, name, pack)
	if players[pid] and players[pid].agent then
		skynet.call(players[pid].agent, "lua", "msg_notify", name, pack)
	end
end

function CMD.enterRoom(rid, pid, roomagent)
	if players[pid] and rooms[rid] then
		players[pid].roomagent = roomagent
		players[pid].roomid = rid
		if players[pid].agent then
			skynet.call(players[pid].agent, "lua", "roomAgentRelate", roomagent)
		end
		skynet.call(players[pid].roomagent, "lua", "playerOnline", players[pid].agent, pid)
	end
	
end
function CMD.closeRoom(rid, playerlist)
	if rooms[rid] then 
		skynet.send(rooms[rid], "lua", "exit")
		rooms[rid] = nil
	end
	
	for k,v in pairs(playerlist) do
		if players[v] and players[v].agent then
			skynet.call(players[v].agent, "lua", "roomAgentUnRelate")
			players[v].roomagent = nil
			players[v].roomid = nil
		end
	end
end

function CMD.existRoom(rid)
	return rooms[rid] and 0 or -1
end

function CMD.getRoomIdByPid(pid)
	if players[pid] then
		return players[pid].roomid
	end
end

-----------------------------------------------------------------
-----------------------------------------------------------------

function createRobotPlayer(roomid)
	for i=1, 3 do
		local player = skynet.newservice("playerRobotAgent")
		skynet.call(player, "lua", "start", { addr = "192.168.1."..i, roomManager=skynet.self() })
		
		local token = ""
		for i=1, math.random(1, 10)do token = token .. math.random(0, 9) end
		skynet.call(player, "lua", "totalPush", token)
		
		skynet.call(player, "lua", "joinRoom", roomid)

		skynet.call(player, "lua", "ready")
		
	end
end

function CMD.createRoom(pid, jushu, zhongzhuang, qiangzhihupai)
	return cs(function()
		local roomid = skynet.call("db_service", "lua", "getNewRoomId")
		local room = skynet.newservice ("roomAgent")
		skynet.call(room, "lua", "initRoom", roomid, jushu, zhongzhuang, qiangzhihupai)
		rooms[roomid] = room
		
		--createRobotPlayer(roomid)
		
		return roomid
	end)
end

function CMD.joinRoom(rid, pid, nickName, ip, sex, headimgurl)
	if not rooms[rid] or not players[pid] then return nil end
	skynet.call(rooms[rid], "lua", "joinRoom", pid, nickName, ip, sex, headimgurl)
end

function CMD.rejoinRoom(rid, pid, nickName, ip, sex, headimgurl)
	if not rooms[rid] or not players[pid] then return nil end
	skynet.call(rooms[rid], "lua", "rejoinRoom", pid, nickName, ip, sex, headimgurl)
end

function init()
	sharedata.new("R", "@server/gameonce/game/logic/R.lua")
end

skynet.start(function()
    print("roomManager service start")
	skynet.dispatch("lua", function (session, address, cmd, ...)
        --print("roomManager.dispatch.cmd: " .. cmd)
		local f = CMD[cmd]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			skynet.ret(skynet.pack(handler.command(cmd, address, ...)))
		end
	end)
	
	init()
	skynet.register(".roomManager")
end)
