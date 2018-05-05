local gameScoreMgr = {}
local scoreMgr = gameScoreMgr
scoreMgr.players={}
scoreMgr.zhuangSite = 0
scoreMgr.msgTrans = nil

local R
local history={}
local cardIds = {}
local gameCtrl = nil


function print_lua_table (lua_table, indent)
    indent = indent or 0
    for k, v in pairs(lua_table) do
        if type(k) == "string" then
            k = string.format("%q", k)
        end
        local szSuffix = ""
        if type(v) == "table" then
            szSuffix = "{"
        end
        local szPrefix = string.rep("    ", indent)
        formatting = szPrefix.."["..k.."]".." = "..szSuffix
        if type(v) == "table" then
            print(formatting)
            print_lua_table(v, indent + 1)
            print(szPrefix.."},")
        else
            local szValue = ""
            if type(v) == "string" then
                szValue = string.format("%q", v)
            else
                szValue = tostring(v)
            end
            print(formatting..szValue..",")
        end
    end
end

function gameScoreMgr:reset(players, cIds, zhuangSite)
	
	for k,v in pairs(players) do 
		scoreMgr.players[k] = v
		history[v:getLocalsite()] = {}
	end
	
	cardIds = cIds
	scoreMgr.zhuangSite = zhuangSite
	
	
end

function gameScoreMgr:setR(rr)
	R = rr
end
function gameScoreMgr:setMsgTransfer(msgt)
	scoreMgr.msgTransfer = msgt
end

function gameScoreMgr:setGameCenter(gamec)
	gameCtrl = gamec
end

local function msgTrans(yieldSite, yieldScore, payBills)
	scoreMgr.msgTransfer:msg(R.sMsg.payBill, {payBills=payBills, yieldScore=yieldScore, yieldPid=scoreMgr.players[yieldSite].pid})
end
local function nextSite(s)
	local z = (s + 1)%(R.MAX_PLAYER_COUNT)
	return z == 0 and 4 or z
end
local function turnSite(s, n)
	local z = (s + n)%(R.MAX_PLAYER_COUNT)
	return z == 0 and 4 or z
end

local function payScoreWithOne(yieldSite, paySite, payScore)
	if payScore > 0 then
		local payBills={{scoreMgr.players[paySite].pid, payScore}}
		msgTrans(yieldSite, payScore, payBills)
		
		local players = gameCtrl:get_players()
		for i=1, R.MAX_PLAYER_COUNT do
			if yieldSite == i then
				players.player[i]:addScore(payScore)
			elseif paySite == i then
				players.player[i]:addScore(-payScore)
			end
		end
	end
end
local function payScoreWithEvery(yieldSite, payScore)
	if payScore > 0 then
		local payBills={}
		for i=1,R.MAX_PLAYER_COUNT-1 do 
			payBills[#payBills+1] = {scoreMgr.players[turnSite(yieldSite, i)].pid, payScore} 
		end
		msgTrans(yieldSite, (R.MAX_PLAYER_COUNT-1)*payScore, payBills)
		
		local players = gameCtrl:get_players()
		for i=1, R.MAX_PLAYER_COUNT do
			if yieldSite == i then
				players.player[i]:addScore((R.MAX_PLAYER_COUNT-1)*payScore)
			else
				players.player[i]:addScore(-payScore)
			end
		end
	end
end

local function Peng(rule, yieldSite, cards, paySite)
	local recordCnt = 0
	if history[yieldSite][R.rule.Peng] then recordCnt = recordCnt + #history[yieldSite][R.rule.Peng] end
	if history[yieldSite][R.rule.Wei] then recordCnt = recordCnt + #history[yieldSite][R.rule.Wei] end
	if history[yieldSite][R.rule.Kan] then recordCnt = recordCnt + #history[yieldSite][R.rule.Kan] end
	if history[yieldSite][R.rule.Wei_chou] then recordCnt = recordCnt + #history[yieldSite][R.rule.Wei_chou] end
	if history[yieldSite][R.rule.Ti] then recordCnt = recordCnt + #history[yieldSite][R.rule.Ti] end
	if history[yieldSite][R.rule.Ti_zimo] then recordCnt = recordCnt + #history[yieldSite][R.rule.Ti_zimo] end
	
	
	if recordCnt < 3 then
		if paySite ~= 0 then
			return yieldSite, paySite, 3
		else
			return yieldSite, 1
		end
		
	elseif recordCnt == 3 then
		if paySite ~= 0 then
			return yieldSite, paySite, 15
		else
			return yieldSite, 5
		end
		
	elseif recordCnt == 4 then
		if paySite ~= 0 then
			return yieldSite, paySite, 15
		else
			return yieldSite, 5
		end
		
	elseif recordCnt == 5 then
		if paySite ~= 0 then
			return yieldSite, paySite, 120
		else
			return yieldSite, 40
		end
	end
end
local function Wei(rule, yieldSite, cards, paySite)
	local recordCnt = 0
	if history[yieldSite][R.rule.Peng] then recordCnt = recordCnt + #history[yieldSite][R.rule.Peng] end
	if history[yieldSite][R.rule.Wei] then recordCnt = recordCnt + #history[yieldSite][R.rule.Wei] end
	if history[yieldSite][R.rule.Kan] then recordCnt = recordCnt + #history[yieldSite][R.rule.Kan] end
	if history[yieldSite][R.rule.Wei_chou] then recordCnt = recordCnt + #history[yieldSite][R.rule.Wei_chou] end
	if history[yieldSite][R.rule.Ti] then recordCnt = recordCnt + #history[yieldSite][R.rule.Ti] end
	if history[yieldSite][R.rule.Ti_zimo] then recordCnt = recordCnt + #history[yieldSite][R.rule.Ti_zimo] end
	
	if recordCnt < 3 then
		return yieldSite, 2
		
	elseif recordCnt == 3 then
		return yieldSite, 6
		
	elseif recordCnt == 4 then
		return yieldSite, 6
		
	elseif recordCnt == 5 then
		return yieldSite, 40
	end
end

local function Pao(rule, yieldSite, cards, paySite)
	if rule == R.rule.Pao then
		return yieldSite, 4
		
	elseif rule == R.rule.Pao_wei or rule == R.rule.Pao_kan then
		if paySite ~= 0 then
			return yieldSite, paySite, 12
		else
			return yieldSite, 4
		end
		
	elseif rule == R.rule.Pao_peng then
		if history[yieldSite][R.rule.Peng] then
			--record = {cards={}, paySite=cardSite}
			if not cards or #cards == 0 then return yieldSite, 4 end
			for k,v in pairs(history[yieldSite][R.rule.Peng]) do			
				if cardIds[v.cards[1]]:equal(cardIds[cards[1]]) then
					if v.paySite ~= 0 then
						return yieldSite, v.paySite, 12
					else
						return yieldSite, 4
					end
				end
			end
		end
	end
end

local function Ti(rule, yieldSite, cards, paySite)
	local recordCnt = #history[yieldSite][rule]
	
	if rule == R.rule.Ti or rule == R.rule.Ti_zimo then
		if recordCnt == 2 then
			return yieldSite, 30
		else
			return yieldSite, 10
		end
		
	elseif rule == R.rule.Ti_kan then
		return yieldSite, 8
		
	elseif rule == R.rule.Ti_wei then
		return yieldSite, 8
	end
end


function gameScoreMgr:payscoreHupai(winType, winRule, winSite, paySite, dpSite, isZhuangWin, zhongzhuang, lianzhongCnt)
	print("payscoreHupai", winType, winRule, winSite, paySite, dpSite, isZhuangWin, zhongzhuang, lianzhongCnt)
	local function calcWinRuleScore()
		local baseWinScore = isZhuangWin and 4 or 4
		if R.wintype.dihu == winType then baseWinScore = isZhuangWin and 8 or 8 end
		
		local losePlayer = {}
		for i=1, R.MAX_PLAYER_COUNT-1 do losePlayer[turnSite(winSite, i)] = 0 end
		
		local spa,spb,spc = self:payRulecard(winSite, winRule, {}, paySite)
		if spa then
			if dpSite > 0 and not spc then
				spc = spb*(R.MAX_PLAYER_COUNT-1)
				spb = dpSite
			end
			if spb and spc then
				losePlayer[spb] = losePlayer[spb] + spc + baseWinScore*(R.MAX_PLAYER_COUNT-1)
				if zhongzhuang then losePlayer[spb] = losePlayer[spb] * 2 end
				if lianzhongCnt then
					losePlayer[spb] = losePlayer[spb] + lianzhongCnt*4*(R.MAX_PLAYER_COUNT-1)
				end
			elseif spb then
				for k,v in pairs(losePlayer) do losePlayer[k] = losePlayer[k] + spb + baseWinScore end
				if zhongzhuang then 
					for k,v in pairs(losePlayer) do losePlayer[k] = losePlayer[k] * 2 end
				end
				if lianzhongCnt then
					for k,v in pairs(losePlayer) do losePlayer[k] = losePlayer[k] + lianzhongCnt*4 end
				end
			end
		end
		
		for k,v in pairs(losePlayer) do
			payScoreWithOne(winSite, k, v)
		end
	end
	
	if R.wintype.qidui == winType then
		local score = isZhuangWin and 80 or 40
		--if zhongzhuang then score = score*2 end
		--if lianzhongCnt then score = score + lianzhongCnt*4 end
		payScoreWithEvery(winSite, score)
		
	elseif R.wintype.shuanglong == winType then
		local score = isZhuangWin and 80 or 40
		if zhongzhuang then score = score*2 end
		if lianzhongCnt then score = score + lianzhongCnt*4 end
		payScoreWithEvery(winSite, score)
		
	elseif R.wintype.pinghu == winType then
		local losePlayer = {}
		for i=1, R.MAX_PLAYER_COUNT-1 do
			local site = turnSite(winSite, i)
			local s = dpSite > 0 and (dpSite == site and 12 or 0) or 4
			losePlayer[site] = s
		end
		if zhongzhuang then 
			for k,v in pairs(losePlayer) do losePlayer[k] = losePlayer[k] * 2 end
		end
		if lianzhongCnt then
			if dpSite > 0 then 
				losePlayer[dpSite] = losePlayer[dpSite] + lianzhongCnt*4*(R.MAX_PLAYER_COUNT-1)
			else
				for k,v in pairs(losePlayer) do losePlayer[k] = losePlayer[k] + lianzhongCnt*4 end
			end
		end
		
		for k,v in pairs(losePlayer) do payScoreWithOne(winSite, k, v) end
	
	elseif R.wintype.tianhu == winType then
		local baseWinScore = isZhuangWin and 8 or 8
		local losePlayer = {}
		for i=1, R.MAX_PLAYER_COUNT-1 do
			local site = turnSite(winSite, i)
			local s = dpSite > 0 and (dpSite == site and baseWinScore*((R.MAX_PLAYER_COUNT-1)) or 0) or baseWinScore
			losePlayer[site] = s
		end
		if zhongzhuang then 
			for k,v in pairs(losePlayer) do losePlayer[k] = losePlayer[k] * 2 end
		end
		if lianzhongCnt then
			if dpSite > 0 then 
				losePlayer[dpSite] = losePlayer[dpSite] + lianzhongCnt*4*(R.MAX_PLAYER_COUNT-1)
			else
				for k,v in pairs(losePlayer) do losePlayer[k] = losePlayer[k] + lianzhongCnt*4 end
			end
		end
			
		for k,v in pairs(losePlayer) do payScoreWithOne(winSite, k, v) end
	
	elseif R.wintype.paoshuang == winType or R.wintype.wufu == winType then
		local losePlayer = {}
		for i=1, R.MAX_PLAYER_COUNT-1 do
			local site = turnSite(winSite, i)
			local s = dpSite > 0 and (dpSite == site and 120 or 0) or 40
			losePlayer[site] = s
		end	
		for k,v in pairs(losePlayer) do payScoreWithOne(winSite, k, v) end
		
	else
		calcWinRuleScore()
	end
end

--cardSite == 0别人摸的牌，其他为别人打的牌
function gameScoreMgr:payRulecard(yieldSite, rule, cards, cardSite)
	local record = {cards={}, paySite=cardSite}
	for k,v in pairs(cards) do record.cards[k]=v end
	
	if not history[yieldSite][rule] then history[yieldSite][rule] = {} end
	table.insert(history[yieldSite][rule], record)
	
	local a,b,c
	if rule == R.rule.Peng then
		a,b,c = Peng(rule, yieldSite, cards, cardSite)
	elseif rule == R.rule.Wei or rule == R.rule.Kan or rule == R.rule.Wei_chou then
		a,b,c = Wei(rule, yieldSite, cards, cardSite)
	elseif rule == R.rule.Pao or rule == R.rule.Pao_kan or rule == R.rule.Pao_wei or rule == R.rule.Pao_peng then
		a,b,c = Pao(rule, yieldSite, cards, cardSite)
	elseif rule == R.rule.Ti or rule == R.rule.Ti_zimo or rule == R.rule.Ti_kan or rule == R.rule.Ti_wei then
		a,b,c = Ti(rule, yieldSite, cards, cardSite)
	elseif rule == R.rule.Chi or rule == R.rule.None then
		a=yieldSite
		b=0
	end
	return a,b,c
end


function gameScoreMgr:payscore(yieldSite, rule, cards, cardSite, ...)
	local a,b,c = self:payRulecard(yieldSite, rule, cards, cardSite)
	
	if a then
		if b and c then
			payScoreWithOne(a, b, c)
		elseif b then
			payScoreWithEvery(a, b)
		end
	end
end



return gameScoreMgr
