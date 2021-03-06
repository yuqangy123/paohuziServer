local gameConfig = {}
local gameTimes = 8
local currentPlayTimes = 1
local forceHupai = true
local lianzhong = false

function gameConfig:reset(t, onlyZhongzhuang, b)
	gameTimes = t or 8
	gameTimes = 0
	currentPlayTimes = 1
	lianzhong = not onlyZhongzhuang
	forceHupai = b and true or false
end
function gameConfig:getPlayConfigTimes()
	return gameTimes
end
function gameConfig:setPlayConfigTimes(t)
	gameTimes = t
end
function gameConfig:isForceHupai()
	return forceHupai
end
function gameConfig:setForceHupai(b)
	forceHupai = b
end

function gameConfig:getCurrentPlayTimes()
	return currentPlayTimes
end
function gameConfig:setCurrentPlayTimes(t)
	currentPlayTimes = t
end

function gameConfig:getLianzhong()
	return lianzhong
end


return gameConfig