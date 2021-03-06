local trans = {}


local gameCenter
local msgReceiver
local R
local MSG = {}

local function getAllPids()
	local pids = {}
	local players = gameCenter:get_players()
	for i=1, R.MAX_PLAYER_COUNT do
		pids[i] = players.player[i].pid
	end
	return pids
end
		
--0成功 1人员已满 2游戏进行中
function MSG.playerEnter(enterPid, res, roomId, roomasterPid, gameState)
	local pack = {code=res, pid={}, enterPid = enterPid, nickname={}, ip={}, sex = {}, headimgurl = {}, site={}, ready={}, score = {}, totalScore = {}, winCount={}, zzCount={}, dpCount={}, gameConfig={}, roomid = roomId, isonline={}}
	
	if res == 0 then
		local players = gameCenter:get_players()
		for i=1, R.MAX_PLAYER_COUNT do
			table.insert(pack.pid, players.player[i].pid)
			table.insert(pack.nickname, players.player[i].nickName)
			table.insert(pack.ip, players.player[i].ip)
			table.insert(pack.sex, players.player[i].sex)
			table.insert(pack.headimgurl, players.player[i].headimgurl)
			table.insert(pack.site, players.player[i].site)
			table.insert(pack.ready, (players.player[i]:isReady() and "1" or "0") )
			table.insert(pack.score, players.player[i]:getScore())
			table.insert(pack.totalScore, players.player[i]:getTotalScore())
			table.insert(pack.winCount, players.player[i].winCount)
			table.insert(pack.zzCount, players.player[i].zhongzhuangCount)
			table.insert(pack.dpCount, players.player[i].dianpaoCount)
			table.insert(pack.isonline, (players.player[i]:getOnline() and "1" or "0"))
		end
		
		
		pack.gameConfig = gameCenter:getGameConfig()
		pack.roomid = roomId
		pack.roommaster = roomasterPid
		pack.gamestate = gameState
	end
	
	return pack
end
function MSG.playerReEnter(msgpid, res, roomId, roomasterPid, gameState)
	local pack = {code=res, pid={}, enterPid = msgpid, nickname={}, ip={}, sex = {}, headimgurl = {}, site={}, ready={}, score = {}, totalScore = {}, winCount={}, zzCount={}, dpCount={}, gameConfig={}, roomid = roomId, isonline={}}
	
	if res == 0 then
		local players = gameCenter:get_players()
		for i=1, R.MAX_PLAYER_COUNT do
			table.insert(pack.pid, players.player[i].pid)
			table.insert(pack.nickname, players.player[i].nickName)
			table.insert(pack.ip, players.player[i].ip)
			table.insert(pack.sex, players.player[i].sex)
			table.insert(pack.headimgurl, players.player[i].headimgurl)
			table.insert(pack.site, players.player[i].site)
			table.insert(pack.ready, (players.player[i]:isReady() and "1" or "0") )
			table.insert(pack.score, players.player[i]:getScore())
			table.insert(pack.totalScore, players.player[i]:getTotalScore())
			table.insert(pack.winCount, players.player[i].winCount)
			table.insert(pack.zzCount, players.player[i].zhongzhuangCount)
			table.insert(pack.dpCount, players.player[i].dianpaoCount)
			table.insert(pack.isonline, (players.player[i]:getOnline() and "1" or "0"))
		end
		
		
		pack.gameConfig = gameCenter:getGameConfig()
		pack.roomid = roomId
		pack.roommaster = roomasterPid
		pack.gamestate = gameState
	end
	
	return msgpid, pack
end
function MSG.playerReady(pid)
	return {pid=pid}
end

function MSG.playerChat(pid,faceid)
	return {faceid=faceid,pid=pid}
end

function MSG.startGame()
	return {}
end

function MSG.playerInitCards(zpid, remainSystemCards)
	local pack = {}
		
	local mostCards = gameCenter:get_mostCards()
	local idsDesc = ""
	local handcard = ""
	local rulecard = ""
	local singlecard = ""
	for k,v in pairs(mostCards) do
		idsDesc = idsDesc .. v:msgString() .. ","
	end
	idsDesc = string.sub(idsDesc, 1, string.len(idsDesc)-1)
	
	
	local players = gameCenter:get_players()
	for i=1, R.MAX_PLAYER_COUNT do
		local cards = players.player[i]:getHandCards()
		local handDesc = ""
		for k,v in pairs(cards) do
			handDesc = handDesc .. v.id .. "_"
		end
		if string.len(handDesc) > 0  then handDesc = string.sub(handDesc, 1, string.len(handDesc)-1) end
		handcard = handcard .. handDesc .. ","
	end
	if string.len(handcard) > 0 then handcard = string.sub(handcard, 1, string.len(handcard)-1) end
	
	for i=1, R.MAX_PLAYER_COUNT do
		local cards = players.player[i]:getShowRuleCards()
		
		local ruleDesc = ""
		for rname,rlist in pairs(cards) do
			ruleDesc = ruleDesc .. rname .. ":"
			for k,rcards in pairs(rlist) do
				for kk,c in pairs(rcards) do
					ruleDesc = ruleDesc .. c.id .. "_"
				end
				ruleDesc = string.sub(ruleDesc, 1, string.len(ruleDesc)-1)
				ruleDesc = ruleDesc .. "-"
			end
			ruleDesc = string.sub(ruleDesc, 1, string.len(ruleDesc)-1)
			ruleDesc = ruleDesc .. "+"
		end
		ruleDesc = string.sub(ruleDesc, 1, string.len(ruleDesc)-1)
		rulecard = rulecard .. ruleDesc .. ","
	end
	rulecard = string.sub(rulecard, 1, string.len(rulecard)-1)
	
	for i=1, R.MAX_PLAYER_COUNT do
		local cards = players.player[i]:getShowSingleCards()
		local singleDesc = ""
		for k,v in pairs(cards) do
			singleDesc = singleDesc .. v.id .. "_"
		end
		if string.len(singleDesc) > 0  then singleDesc = string.sub(singleDesc, 1, string.len(singleDesc)-1) end
		singlecard = singlecard .. singleDesc .. ","
	end
	singlecard = string.sub(singlecard, 1, string.len(singlecard)-1)
	
	pack.pids = idsDesc
	pack.hand = handcard
	pack.rule = rulecard
	pack.single = singlecard
	pack.zhuangpid = zpid
	pack.remainsystemcards = remainSystemCards
	return pack
end
function MSG.playerReInitCards(msgpid, zpid, remainSystemCards)
	local pack = {}
		
	local mostCards = gameCenter:get_mostCards()
	local idsDesc = ""
	local handcard = ""
	local rulecard = ""
	local singlecard = ""
	for k,v in pairs(mostCards) do
		idsDesc = idsDesc .. v:msgString() .. ","
	end
	idsDesc = string.sub(idsDesc, 1, string.len(idsDesc)-1)
	
	
	local players = gameCenter:get_players()
	for i=1, R.MAX_PLAYER_COUNT do
		local cards = players.player[i]:getHandCards()
		local handDesc = ""
		for k,v in pairs(cards) do
			handDesc = handDesc .. v.id .. "_"
		end
		if string.len(handDesc) > 0  then handDesc = string.sub(handDesc, 1, string.len(handDesc)-1) end
		handcard = handcard .. handDesc .. ","
	end
	if string.len(handcard) > 0 then handcard = string.sub(handcard, 1, string.len(handcard)-1) end
	
	for i=1, R.MAX_PLAYER_COUNT do
		local cards = players.player[i]:getShowRuleCards()
		
		local ruleDesc = ""
		for rname,rlist in pairs(cards) do
			ruleDesc = ruleDesc .. rname .. ":"
			for k,rcards in pairs(rlist) do
				for kk,c in pairs(rcards) do
					ruleDesc = ruleDesc .. c.id .. "_"
				end
				ruleDesc = string.sub(ruleDesc, 1, string.len(ruleDesc)-1)
				ruleDesc = ruleDesc .. "-"
			end
			ruleDesc = string.sub(ruleDesc, 1, string.len(ruleDesc)-1)
			ruleDesc = ruleDesc .. "+"
		end
		ruleDesc = string.sub(ruleDesc, 1, string.len(ruleDesc)-1)
		rulecard = rulecard .. ruleDesc .. ","
	end
	rulecard = string.sub(rulecard, 1, string.len(rulecard)-1)
	
	for i=1, R.MAX_PLAYER_COUNT do
		local cards = players.player[i]:getShowSingleCards()
		local singleDesc = ""
		for k,v in pairs(cards) do
			singleDesc = singleDesc .. v.id .. "_"
		end
		if string.len(singleDesc) > 0  then singleDesc = string.sub(singleDesc, 1, string.len(singleDesc)-1) end
		singlecard = singlecard .. singleDesc .. ","
	end
	singlecard = string.sub(singlecard, 1, string.len(singlecard)-1)
	
	pack.pids = idsDesc
	pack.hand = handcard
	pack.rule = rulecard
	pack.single = singlecard
	pack.zhuangpid = zpid
	pack.remainsystemcards = remainSystemCards
	pack.reloadId = msgpid
	
	return msgpid, pack
end


function MSG.payCardSystem(data)
	--{pid=players.player[curPaysite].pid, card=paycard}
	local pack={cid=data.card, pid=data.pid, show=data.show and true or false}
	return pack
end

function MSG.turnPlayer(pid)
	local pack = {pid=pid}
	return pack
end

function MSG.payCardPlayer(data)
	local pack={pid=data.pid, cid=data.card, show=data.show and true or false}
	return pack
end

function MSG.ruleCardsPossible(pid, data)
	local pack = {}
	
	local rule = ""
	local cid = ""
	local ocid = ""
	for k,v in pairs(data) do
		rule = rule .. v.rule .. ","
		
		local citem = ""
		local cs = ""
		for kk,vv in pairs(v.cards) do
			for kkk,vvv in pairs(vv) do
				cs = cs .. vvv .. "_"
			end
			if string.len(cs) > 0 then cs = string.sub(cs, 1, string.len(cs)-1) end
			cs = cs .. "-"
		end
		if string.len(cs) > 0 then cs = string.sub(cs, 1, string.len(cs)-1) end
		cid = cid .. cs .. ","
		
		ocid = ocid .. v.othercard .. ","
	end
	if string.len(rule) > 0 then rule = string.sub(rule, 1, string.len(rule)-1) end
	if string.len(cid) > 0 then cid = string.sub(cid, 1, string.len(cid)-1) end
	if string.len(ocid) > 0 then ocid = string.sub(ocid, 1, string.len(ocid)-1) end
	
	pack.pid = pid
	pack.rule = rule
	pack.cid = cid
	pack.ocid = ocid
	
	return pack, pid
end

--data:{pid=pid, rule=R.rule.Kan, cards=v}
function MSG.payRuleCardPlayer(data)
	local pack={pid=data.pid, cid="", rule=data.rule, othercard=data.othercard}
	
	for k,v in pairs(data.cards) do
		pack.cid = pack.cid .. v .. ","
	end
	if string.len(pack.cid) > 0  then pack.cid = string.sub(pack.cid, 1, string.len(pack.cid)-1) end
	
	return pack
end

function MSG.payBill(data)
	local pack={}
	
	pack.yieldPid = data.yieldPid
	pack.yieldScore = data.yieldScore
	local payBills = ""
	for k,v in pairs(data.payBills) do
		payBills = payBills .. v[1] .. "_" .. v[2] .. ","
	end
	if string.len(payBills) > 0 then payBills = string.sub(payBills, 1, string.len(payBills)-1) end
	pack.payBills = payBills
	
	return pack
end

function MSG.hupai(pid, rule, winCard, dpPid, lzCnt, gameCnt, allCards, payIndex)
	local pack={pid=pid, rule=rule, hupaiCard=winCard, dpPid=dpPid, lianzhuangCount=lzCnt, gameCount=gameCnt}
	
	local remainCards = ""
	for i=payIndex, #allCards do
		remainCards = remainCards .. allCards[i].id .. ","
	end
	if string.len(remainCards) > 0 then remainCards = string.sub(remainCards, 1, string.len(remainCards)-1) end
	pack.remaincards = remainCards
	
	return pack
end

function MSG.gameFinish()
	local pack={}
	return pack
end

function MSG.masterCheckoutRoom()
	local pack={}
	return pack
end

function MSG.wufuBaojing(pid)
	return {pid=pid}
end

function MSG.canWufuBaojing(pid)
	local pack = {}
	return pack, pid
end

function MSG.playerOnlineChange(pid, isonline)
	return {pid=pid, code = isonline and 0 or 1}
end


function MSG.reloadInfo(pid, curPlayCardPid, lianzhuangCnt, gameCount, curSystemPayCard)
	local pack = {curPayPid=curPlayCardPid, lianzhuangCnt=lianzhuangCnt, gameCount=gameCount, curSystemPayCard=curSystemPayCard, pengSingleCard=""}
	local players = gameCenter:get_players()
	
	local desc = ""
	for i=1, R.MAX_PLAYER_COUNT do
		local p = players.player[i]
		local cards = p:getPengRuleSingleCard()
		if #cards > 0 then
			desc = desc .. p.pid .. ":"
			for k,v in pairs(cards) do
				desc = desc .. v .. "-"
			end
			desc = string.sub(desc, 1, string.len(desc)-1)
			desc = desc .. ","
		end
	end
	if string.len(desc) > 0 then desc = string.sub(desc, 1, string.len(desc)-1) end
	pack.pengSingleCard = desc
	return pack, pid
end

function MSG.voice(pid, fileID, time)
	local pack={pid=pid, fileID=fileID, time=time}
	return pack
end

function trans:setR(rr)
	R = rr
end

function trans:setGameCenter(gamec)
	gameCenter = gamec
end

function trans:setMsgReceiver(receiver)
	msgReceiver = receiver
end




function trans:msg(msgid, ...)
	local f = assert(MSG[msgid])
	local pack, pid = f(...)
	
	msgReceiver(msgid, pack, pid)
end

return trans
