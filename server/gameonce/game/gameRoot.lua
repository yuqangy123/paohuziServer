local skynet = require "skynet"
require "skynet.manager"
local netpack = require "netpack"
local datacenter = require "datacenter"
--local CMD = setmetatable({}, { __gc = function() netpack.clear(queue) end })
local CMD = {}
local max_room_player = 4
local players = {}
local rooms = {}--{agent, pids={}} key=roomid
local roomManager = nil


function CMD.playerOnline(agent, fd, pid)
	players[pid] = agent
	skynet.call(roomManager, "lua", "playerOnline", agent, fd, pid)
end
function CMD.playerOffline(pid)
	players[pid] = nil
	skynet.call(roomManager, "lua", "playerOffline", pid)
end


function init()
	roomManager = skynet.uniqueservice("roomManager")
	local clientErrLog = skynet.uniqueservice("clientErrorCollect")
end

skynet.start(function()
    print("gameRoot service start")
	skynet.dispatch("lua", function (session, address, cmd, ...)
        --print("gameRoot.dispatch.cmd: " .. cmd)
		local f = CMD[cmd]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			skynet.ret(skynet.pack(handler.command(cmd, address, ...)))
		end
	end)
  
  init()
  --skynet.register("gameRoot")
end)
