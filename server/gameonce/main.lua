local skynet = require "skynet"
--local sprotoloader = require "sprotoloader"



skynet.start(function()
	--debug console
	if not skynet.getenv "daemon" then
		local console = skynet.newservice("console")
	end
	skynet.newservice("debug_console",8000)
	
	--db service
	local dbserver = skynet.newservice ("db_service")
	
	--login service
	--local loginserver = skynet.newservice("logind")

	--game service
	skynet.uniqueservice("protoloader")
	local gameRoot = skynet.newservice("gameRoot")

	local watchdog = skynet.newservice("watchdog")
	skynet.call(watchdog, "lua", "start", {
		address="120.25.156.167",
		--address="192.168.220.128",
		--address="172.31.23.220",
		port = 8088,
		maxclient = 1024,
		nodelay = true,
		gameRoot = gameRoot,
	})

	--skynet.exit()
end)
