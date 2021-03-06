local skynet = require "skynet"
local mutexLock = require "skynet.queue"

local CMD = {}
local cs = mutexLock()
local f
local filename = "logClient"
--require "functions"

function init()
	
end

function CMD.exit()
	cs(function()
		if f then
			f:close()
		end
	end)
end

function CMD.log(errdata)
	cs(function()
		f = io.open(filename, "a+")
		if not f then
			return "clientErrorCollect: can't open " .. filename
		end
		local data = os.date() .. "\n" .. errdata .. "\n\n\n"
		f:write(data)
		f:close()
	end)
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		--print("clientErrorCollect dispatch lua:", command)
		local f = CMD[command]
		f(...)
	end)
	init()
end)
