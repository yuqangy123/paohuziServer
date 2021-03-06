local gameResultMgr = {}
local history = {}--{gameResult}
local R

local function hotRequire(file_name)
	package.loaded[file_name] = nil
	local f = require(file_name)
	return f
end

function gameResultMgr:setR(rr)
	R = rr
end

function gameResultMgr:reset()
	history = {}
end

function gameResultMgr:getLastResult()
	if #history > 0 then return history[#history] end
end

function gameResultMgr:getResultCount()
	return #history
end

function gameResultMgr:getLianzhuangCount()
	local maxCon = 0
	local winres = history[#history]:isWin()		
	for i=#history, 1, -1 do
		if history[i]:isWin() then
			maxCon=maxCon+1
		else
			break
		end
	end
	return maxCon
end

function gameResultMgr:addResult(zhuangSite, winnerPid, winnerSite, winType, winCard, dpSite, remainPayIndex, isHongzhuang)
	local gameres = hotRequire("logic.gameResult")
	gameres:set(zhuangSite, winnerPid, winnerSite, winType, winCard, dpSite, remainPayIndex, isHongzhuang)
	history[#history+1] = gameres
end

function gameResultMgr:createZhuangSite()
	local lastHis = self:getLastResult()
	if not lastHis then
		return 0
	end
	print("createZhuangSite", #history, lastHis:isWin(), lastHis:getZhuangSite(), lastHis:getWinnerSite(), lastHis:isHongzhuang())
	local function turnNextSite(s)
		local z = (s + 1)%(R.MAX_PLAYER_COUNT)
		return z == 0 and R.MAX_PLAYER_COUNT or z
	end
		
	if lastHis:isWin() then
		return lastHis:getWinnerSite()
	end
	
	if lastHis:isHongzhuang() then
		local zhuangSite = lastHis:getZhuangSite()
		return turnNextSite(zhuangSite)
	end
	
	return lastHis:getWinnerSite()
end

function gameResultMgr:parseWinnerType(winType, winPayRule, winSite, winPayCardSite, turnRunCount)
	--print("parseWinnerType", winType, winPayRule, winSite, winPayCardSite, turnRunCount)
	if winType == R.wintype.pinghu then
		if winPayRule == R.rule.Peng then return R.wintype.penghu end
		
		if turnRunCount == 0 then return R.wintype.tianhu end
		if turnRunCount == 1 then return R.wintype.dihu end
		
		if winPayRule == R.rule.Pao or 
			winPayRule == R.rule.Pao_kan or
			winPayRule == R.rule.Pao_wei or
			winPayRule == R.rule.Pao_peng then
		return R.wintype.paohu end
		
		if winPayRule == R.rule.Ti or 
			winPayRule == R.rule.Ti_kan or
			winPayRule == R.rule.Ti_wei then
		return R.wintype.tihu end
		
		if winPayRule == R.rule.Wei or 
			winPayRule == R.rule.Wei_chou then
		return R.wintype.zimo end
		
		if winPayRule == R.rule.Chi then
			return winSite == winPayCardSite and R.wintype.zimo or R.wintype.pinghu
		end
		
		return winType
	end
	
	if winType == R.wintype.sandalianhu then
		if winPayRule == R.rule.Peng then
			return R.wintype.sandalianhu
		end
		if winPayRule == R.rule.Pao or winPayRule == R.rule.Pao_kan or winPayRule == R.rule.Pao_peng or 		winPayRule == R.rule.Pao_wei then
			return R.wintype.paohu
		end
		if winPayRule == R.rule.Wei or winPayRule == R.rule.Wei_chou then
			return R.wintype.saosandalianhu
		end
		if winPayRule == R.rule.Chi then
			return winSite == winPayCardSite and R.wintype.zimo or R.wintype.pinghu
		end
	end
	if winType == R.wintype.siqinglianhu then
		if winPayRule == R.rule.Peng then
			return R.wintype.siqinglianhu
		end
		if winPayRule == R.rule.Wei or winPayRule == R.rule.Wei_chou then
			return R.wintype.saosiqinglianhu
		end
		if winPayRule == R.rule.Chi then
			return winSite == winPayCardSite and R.wintype.zimo or R.wintype.pinghu
		end
		if winPayRule == R.rule.Pao or winPayRule == R.rule.Pao_kan or winPayRule == R.rule.Pao_peng or winPayRule == R.rule.Pao_wei then
			return R.wintype.paohu
		end
	end
	
	return winType
end

function gameResultMgr:getWinBuff()
	local zhuangWin zhongzhuang, lianzhongCnt = false,false,0
	while(true) do
		if #history == 0 then 
			break 
		end
		if #history == 1 then
			zhuangWin = history[1]:isWin()
			break
		end
		
		local maxCon = 0
		local winres = history[#history]:isWin()		
		for i=#history, 1, -1 do
			if history[i]:isWin() then
				maxCon=maxCon+1
			else
				break
			end
		end
		zhongzhuang = (maxCon > 1 and true or false)
		zhuangWin = winres
		lianzhongCnt = math.max(0, maxCon - 2)
		break
	end
	
	return zhuangWin, zhongzhuang, lianzhongCnt
end

return gameResultMgr