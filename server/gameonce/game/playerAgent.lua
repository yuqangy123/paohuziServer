local skynet = require "skynet"
local netpack = require "netpack"
local socket = require "socket"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"
local datacenter = require "datacenter"
local mutexLock = require "skynet.queue"
local roomManager
local clientErrorCollect

local cs = mutexLock()
require "functions"
--local sproto_core = require "sproto.core"

local watchdog
local gameRoot
local host
local packMsg

local CMD = {}
local REQUEST = {}

local GAME_VERSION = 140

local user_info = {
	pid = 0,
	openid = 0,
	nikeName = "",
	ip = "",
	sex = "",
	headimgurl = "",
	fd = 0,
}
local game_info = {
	roomid = 0,
	roomagent = nil
}


function REQUEST:totalPush()
	--print_lua_table(self)
	local pid = skynet.call("db_service", "lua", "playerLoginWx", self.openid, self.nickname)
	
	user_info.pid = pid
	user_info.openid = self.openid
	user_info.nikeName = self.nickname
	user_info.sex = self.sex
	user_info.headimgurl = self.headimgurl
	local res = { code=0, pid = user_info.pid, nickname = user_info.nikeName, ip = user_info.ip, roomid = 0}
	
	
	
	skynet.call(gameRoot, "lua", "playerOnline", skynet.self(), user_info.fd, user_info.pid)
	local roomid = skynet.call(roomManager, "lua", "getRoomIdByPid", user_info.pid)
	if roomid then
		res.code = 1
		res.roomid = roomid
		game_info.roomid = roomid
	end
	
	return res
end

function REQUEST:createRoom()
	local roomid = skynet.call(roomManager, "lua", "createRoom", user_info.pid, self.jushu, self.zhongzhuang, self.qiangzhihupai)
	game_info.roomid = roomid or 0
	return {code=0, roomid=roomid or 0}
end

function REQUEST:joinRoom()
	skynet.call(roomManager, "lua", "joinRoom", self.roomid, user_info.pid, user_info.nikeName, user_info.ip, user_info.sex, user_info.headimgurl)
end

function REQUEST:rejoinRoom()
	skynet.call(roomManager, "lua", "rejoinRoom",game_info.roomid, user_info.pid, user_info.nikeName, user_info.ip, user_info.sex, user_info.headimgurl)
end

function REQUEST:roomExist()
	local res = skynet.call(roomManager, "lua", "existRoom", self.roomid)
	return {code=res}
end


function REQUEST:ready()
	if not game_info.roomagent then return nil end
	skynet.call(game_info.roomagent, "lua", "playerReady", user_info.pid)
end

function REQUEST:chat()
	if not game_info.roomagent then return nil end
	skynet.call(game_info.roomagent, "lua", "playerChat", user_info.pid, self.faceid)
end

function REQUEST:payCard()
	if not game_info.roomagent then return nil end
	skynet.call(game_info.roomagent, "lua", "playerPayCard", user_info.pid, self.rule, self.cid)
end

function REQUEST:masterCheckoutRoom()
	if not game_info.roomagent then return nil end
	skynet.call(game_info.roomagent, "lua", "masterCheckoutRoom", user_info.pid)
end

function REQUEST:requestCheckoutRoom()
	if not game_info.roomagent then return nil end
	skynet.call(game_info.roomagent, "lua", "requestCheckoutRoom", user_info.pid)
end

function REQUEST:agreeCheckoutRoom()
	if not game_info.roomagent then return nil end
	skynet.call(game_info.roomagent, "lua", "agreeCheckoutRoom", user_info.pid, self.code)
end

function REQUEST:errLog()
	skynet.send(clientErrorCollect, "lua", "log", self.log)
end

function REQUEST:quit()
	skynet.call(watchdog, "lua", "close", user_info.fd)
end
function REQUEST:selectWufuBaojing()
	if not game_info.roomagent then return nil end
	skynet.call(game_info.roomagent, "lua", "selectWufuBaojing", user_info.pid, self.code)
end
function REQUEST:playerStartGame()
	if not game_info.roomagent then return nil end
	skynet.call(game_info.roomagent, "lua", "playerStartGame", user_info.pid)
end

function REQUEST:gameRecord()
	local res = skynet.call("db_service", "lua", "gameRecord", user_info.pid)
	local pack = {rid="",time="",p1name="",p1score="",p2name="",p2score="",p3name="",p3score="",p4name="",p4score=""}
	for k,v in pairs(res) do
		pack.rid = pack.rid .. v.rid .. ","
		pack.time = pack.time .. v.time .. ","
		pack.p1name = pack.p1name .. v.p1name .. ","
		pack.p1score = pack.p1score .. v.p1score .. ","
		pack.p2name = pack.p2name .. v.p2name .. ","
		pack.p2score = pack.p2score .. v.p2score .. ","
		pack.p3name = pack.p3name .. v.p3name .. ","
		pack.p3score = pack.p3score .. v.p3score .. ","
		pack.p4name = pack.p4name .. v.p4name .. ","
		pack.p4score = pack.p4score .. v.p4score .. ","
	end
	pack.rid = string.sub(pack.rid, 1, string.len(pack.rid)-1)
	pack.p1name = string.sub(pack.p1name, 1, string.len(pack.p1name)-1)
	pack.p1score = string.sub(pack.p1score, 1, string.len(pack.p1score)-1)
	pack.p2name = string.sub(pack.p2name, 1, string.len(pack.p2name)-1)
	pack.p2score = string.sub(pack.p2score, 1, string.len(pack.p2score)-1)
	pack.p3name = string.sub(pack.p3name, 1, string.len(pack.p3name)-1)
	pack.p3score = string.sub(pack.p3score, 1, string.len(pack.p3score)-1)
	pack.p4name = string.sub(pack.p4name, 1, string.len(pack.p4name)-1)
	pack.p4score = string.sub(pack.p4score, 1, string.len(pack.p4score)-1)
	
	return pack
end
function REQUEST:voice()
	if not game_info.roomagent then return nil end
	skynet.call(game_info.roomagent, "lua", "voice", user_info.pid, self.fileID, self.time)
end

function REQUEST:versionCheck()
	return {code = self.version == GAME_VERSION and 0 or 1}
end

function REQUEST:heartbeat()
end

local function request(name, args, response)
	--print("playeragent.request.name", name, user_info.pid or 0)
	local f = assert(REQUEST[name])
	local r = f(args)

	if response then
		--print("playeragent.response.name", name, user_info.pid or 0)
		return response(r)
	end
end

local function send_package(pack)
	local package = string.pack(">s2", pack)
	socket.write(user_info.fd, package)
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		--local bin = sproto_core.unpack(msg, sz)
		return host:dispatch(msg, sz)
	end,
	dispatch = function (_, _, type, ...)
		if type == "REQUEST" then
			local ok, result  = pcall(request, ...)
			if ok then
				if result then
					send_package(result)
				end
			else
				skynet.error(result)
			end
		else
			assert(type == "RESPONSE")
			error "This example doesn't support request client"
		end
	end
}


function CMD.msg_notify(msgName, pack)
	cs(function() 
		--skynet.sleep(40)
		--print("MSG>>>>>>>>>>playerAgent.msg_notify.msgName", user_info.pid, msgName)
		--print_lua_table(pack)
		send_package(packMsg(msgName,pack))
	end)
	
end

function CMD.roomAgentRelate(agent)
	game_info.roomagent = agent
end

function CMD.roomAgentUnRelate()
	game_info.roomagent = nil
end

function CMD.start(conf)
	local gate = conf.gate
	gameRoot = conf.gameRoot
	watchdog = conf.watchdog
	user_info.ip = conf.addr
	user_info.fd = conf.client
	
	roomManager = skynet.uniqueservice("roomManager")
	clientErrorCollect = skynet.uniqueservice("clientErrorCollect")
	
	
	-- slot 1,2 set at main.lua
	host = sprotoloader.load(1):host "package"
	packMsg = host:attach(sprotoloader.load(2))
	
	
	skynet.fork(function()
		while true do
			send_package(packMsg("heartbeat"))
			skynet.sleep(1000)
		end
	end)
	
	
	skynet.call(gate, "lua", "forward", user_info.fd)
end

function CMD.disconnect()
	-- todo: do something before exit
	skynet.call(gameRoot, "lua", "playerOffline", user_info.pid)
	skynet.exit()
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		--print("playeragent dispatch lua:", command, user_info.pid or 0)
		local f = CMD[command]
		--f(...)
		skynet.ret(skynet.pack(f(...)))
	end)
end)
