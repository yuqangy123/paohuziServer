local skynet = require "skynet"
require "skynet.manager"
local netpack = require "netpack"
local mutexLock = require "skynet.queue"
local cs = mutexLock()
local CMD = setmetatable({}, { __gc = function() netpack.clear(queue) end })
local roomManager
local gameCenter = nil
local players = {}
local enterPlayers = {}--进入队列
local roomId = 0

local checkoutRoomRequest = {}

function CMD.exit()
	
	skynet.exit()
	
end

--add cs
function CMD.playerOnline(agent, pid)
	players[pid]=agent
	
	skynet.call(gameCenter, "lua", "playerOnlineChange", pid, true)
end
function CMD.playerOffline(pid)
	players[pid]=nil
	
	skynet.call(gameCenter, "lua", "playerOnlineChange", pid, false)
end

function CMD.playerMsg_multicastNotify(name, pack)
	for k,v in pairs(players) do
		skynet.call(v, "lua", "msg_notify", name, pack)
	end
end
function CMD.playerMsg_notify(name, pid, pack)
	if players[pid] then
		skynet.call(players[pid], "lua", "msg_notify", name, pack)
	end
end

function CMD.enterRoom(name, pack)
	if pack.code == 0 then
		skynet.call(roomManager, "lua", "enterRoom", roomId, pack.enterPid, skynet.self())
		return 0
	else
		skynet.call(roomManager, "lua", "playerMsg_notify", pack.enterPid, name, pack)
		return -1
	end
end
function CMD.closeRoom()	
	skynet.send(gameCenter, "lua", "exit")

	local plist = {}
	for k,v in pairs(players) do plist[#plist+1]=k end
	players = {}
	skynet.call(roomManager, "lua", "closeRoom", roomId, plist)
end
function CMD.voice(pid, fileID, time)	
	skynet.call(gameCenter, "lua", "voice", pid, fileID, time)
end

------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
local function tryCheckoutRoom()
	local ok = true
	for k,v in pairs(players) do
		if checkoutRoomRequest[k] ~= 1 then
			ok = false
			break
		end
	end
	
	if ok then
		CMD.playerMsg_multicastNotify("checkoutRoomNotify", {code=0})
		skynet.call(gameCenter, "lua", "gameFinish")
	end
end
function CMD.agreeCheckoutRoom(pid, code)
	cs(function() 
		checkoutRoomRequest[pid] = code == 0 and 1 or -1
		
		if checkoutRoomRequest[pid] == -1 then
			CMD.playerMsg_multicastNotify("checkoutRoomNotify", {code=1})
			checkoutRoomRequest = {}
		else
			tryCheckoutRoom()
		end
	end)
end

function CMD.requestCheckoutRoom(pid)
	cs(function()
		if next(checkoutRoomRequest) == nil then
			for k,v in pairs(players) do checkoutRoomRequest[k] = 0 end
		end
		checkoutRoomRequest[pid] = 1
		
		for k,v in pairs(players) do
			if checkoutRoomRequest[k] == 0 then
				CMD.playerMsg_notify("requestCheckoutRoomNotify", k, {})
			end
		end
		
		tryCheckoutRoom()
	end)
end

function CMD.masterCheckoutRoom(pid)
	cs(function() 
		skynet.call(gameCenter, "lua", "masterCheckoutRoom", pid)
		CMD.closeRoom()
		end)
end

function CMD.rejoinRoom(pid, nickName, ip, sex, headimgurl)
	cs(function() enterPlayers[pid]=true skynet.call(gameCenter, "lua", "playerReEnter", pid, nickName, ip, sex, headimgurl) end)
end

function CMD.joinRoom(pid, nickName, ip, sex, headimgurl)
	cs(function() enterPlayers[pid]=true skynet.call(gameCenter, "lua", "playerEnter", pid, nickName, ip, sex, headimgurl) end)
end

function CMD.playerReady(pid)
	cs(function() skynet.call(gameCenter, "lua", "playerReady", pid) end)
end

function CMD.playerChat(pid, faceid)
	cs(function() skynet.call(gameCenter, "lua", "playerChat", pid, faceid) end)
end

function CMD.playerPayCard(pid, rule, cid)
	cs(function() skynet.call(gameCenter, "lua", "playerPayCards", pid, rule, cid) end)
end

function CMD.selectWufuBaojing(pid, code)
	cs(function() skynet.call(gameCenter, "lua", "selectWufuBaojing", pid, code) end)
end

function CMD.playerStartGame(pid)
	cs(function() skynet.call(gameCenter, "lua", "playerStartGame", pid) end)
end



function CMD.initRoom(rid, jushu, zhongzhuang, qiangzhihupai)
	roomManager = skynet.uniqueservice("roomManager")

	roomId = rid

	if not gameCenter then gameCenter = skynet.newservice ("logic/gameCenter") end
	
	skynet.call(gameCenter, "lua", "initGame", roomId, jushu and 8 or 16, zhongzhuang and true or false, qiangzhihupai and true or false)
	
	skynet.call(gameCenter, "lua", "setMsgTransfer", skynet.self())
	
end

skynet.start(function()
		print("roomAgent service start")
		skynet.dispatch("lua", function (session, address, cmd, ...)
			--print("roomAgent.dispatch.cmd: " .. cmd)
			local f = CMD[cmd]
			if f then
				skynet.ret(skynet.pack(f(...)))
			else
				skynet.ret(skynet.pack(handler.command(cmd, address, ...)))
			end
		end)

end)
