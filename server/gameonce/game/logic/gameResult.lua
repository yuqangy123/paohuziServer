
local gameResult = {}
gameResult.type = 0

local winPid = 0
local winSite = 0
local zhuangSite = 0
local hongzhuangIndex = false
local wintype = 0
local winCard = 0
local dpSite = 0
local remainPayIndex = 0
	
local winner = {
	none = 0,
	hongzhuang = 1,
	tianhu = 2,
	dihu = 3,
	zimo = 4,
	popaohu = 5,
	chouhu = 6,	
	honghu = 7,
	dianhu = 8,
	hongwu = 9,--红乌
	wuhu = 10,
	zimo = 11,
	duiduihu = 12,
	haidi = 13
}

function gameResult:set(zSite, wpid, wsite, winType,winCard, dpSite, remainPayIndex, hz)
	winPid = wpid
	winSite = wsite
	zhuangSite = zSite
	hongzhuangIndex = hz
	wintype = winType
	winCard = winCard
	dpSite = dpSite
	remainPayIndex = remainPayIndex
end

--是否篊庄
function gameResult:isHongzhuang()
	return hongzhuangIndex
end
function gameResult:getWinType()
	return wintype
end

function gameResult:getWinnerPid()
	return winPid
end

function gameResult:getWinnerSite()
	return winSite
end

function gameResult:getZhuangSite()
	return zhuangSite
end
function gameResult:getWinCard()
	return winCard
end
function gameResult:getDpSite()
	return dpSite
end
function gameResult:getRemainPayIndex()
	return remainPayIndex
end



function gameResult:isWin()
	return winSite == zhuangSite and not self:isHongzhuang()
end

return gameResult
