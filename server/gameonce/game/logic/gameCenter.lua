local skynet = require "skynet"
local netpack = require "netpack"
require "skynet.manager"
local mutexLock = require "skynet.queue"
local sharedata = require "sharedata"

require "functions"
local function hotRequire(file_name)
	package.loaded[file_name] = nil
	local f = require(file_name)
	return f
end

local cs = mutexLock()
local gameCenter = {}
gameCenter.co_run = nil
gameCenter.roomId = 0

local R = nil
local roomMasterPid = 0
MAX_CARD_COUNT = 80

local zhuang = {site=1}
local players = {player={}, count=0}
local gameState = nil
local cardsMgr = {cards={}, cardIds={}, payIndex=0}
local curPaysite = 0--当前出牌local site
local lastPayCardRule = nil
local curPayCardRule = nil
local turnRunCount = 0--当前轮牌次数

--玩家游戏中组牌
local inputPossibles = {}
local playerSelectRuleCards = {}
local g_paycard = 0
local g_lastHupaiPack

local inputCards = {}
local PlayWufubaojing = true
local playerWaitSelectWufubaojing = 0

local msgTransfer = nil--游戏消息传递器

local gameConfig = hotRequire("logic.gameConfig")
local ruleHelp = hotRequire("logic.ruleHelp")
local gameResultMgr = hotRequire("logic.gameResultManager")
local gameScoreMgr = hotRequire("logic.gameScoreManager")
gameScoreMgr:setGameCenter(gameCenter)



local function turnNextSite(s)
	local z = (s + 1)%(R.MAX_PLAYER_COUNT)
	return z == 0 and R.MAX_PLAYER_COUNT or z
end
local function turnSite(s, n)
	local z = (s + n)%(R.MAX_PLAYER_COUNT)
	return z == 0 and R.MAX_PLAYER_COUNT or z
end


function string.split(input, delimiter)
    if not input or input == "" then
        return {}
    end
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter=='') then return false end
    local pos,arr = 0, {}
    -- for each divider found
    for st,sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

local PLAY_MSG = {}
local roomagent = nil
function PLAY_MSG.playerEnter(pack)
	local res = skynet.call(roomagent, "lua", "enterRoom", "joinRoomNotify", pack)
	if res == 0 then
		skynet.call(roomagent, "lua", "playerMsg_multicastNotify", "joinRoomNotify", pack)
	end
end
function PLAY_MSG.playerReEnter(pid, pack)
	local res = skynet.call(roomagent, "lua", "enterRoom", "joinRoomNotify", pack)
	if res == 0 then
		skynet.call(roomagent, "lua", "playerMsg_notify", "joinRoomNotify", pid, pack)
	end
end
function PLAY_MSG.playerInitCards(pack)
	skynet.call(roomagent, "lua", "playerMsg_multicastNotify", "roomCardInitNotify", pack)
end
function PLAY_MSG.playerReInitCards(pid, pack)
	skynet.call(roomagent, "lua", "playerMsg_notify", "roomCardInitNotify", pid, pack)
end
function PLAY_MSG.playerReady(pack)
	skynet.call(roomagent, "lua", "playerMsg_multicastNotify", "readyNotify", pack)
end
function PLAY_MSG.startGame(pack)
	skynet.call(roomagent, "lua", "playerMsg_multicastNotify", "startNotify", pack)
end
function PLAY_MSG.playerChat(pack)
	skynet.call(roomagent, "lua", "playerMsg_multicastNotify", "chatNotify", pack)
end
function PLAY_MSG.payCardSystem(pack)
	skynet.call(roomagent, "lua", "playerMsg_multicastNotify", "paySystemCardNotify", pack)
end
function PLAY_MSG.turnPlayer(pack)
	skynet.call(roomagent, "lua", "playerMsg_multicastNotify", "turnPlayerNotify", pack)
end
function PLAY_MSG.payCardPlayer(pack)
	skynet.call(roomagent, "lua", "playerMsg_multicastNotify", "payCardNotify", pack)
end
function PLAY_MSG.ruleCardsPossible(pack, pid)
	skynet.call(roomagent, "lua", "playerMsg_notify", "ruleCardsPossible", pid, pack)
end
function PLAY_MSG.canWufuBaojing(pack, pid)
	skynet.call(roomagent, "lua", "playerMsg_notify", "canWufuBaojing", pid, pack)
end
function PLAY_MSG.payRuleCardPlayer(pack)
	skynet.call(roomagent, "lua", "playerMsg_multicastNotify", "payRuleCardNotify", pack)
end
function PLAY_MSG.payBill(pack)
	skynet.call(roomagent, "lua", "playerMsg_multicastNotify", "payBillNotify", pack)
end
function PLAY_MSG.hupai(pack)
	skynet.call(roomagent, "lua", "playerMsg_multicastNotify", "hupaiNotify", pack)
	
	g_lastHupaiPack = {}
	for k,v in pairs(pack) do g_lastHupaiPack[k]=v end
end
function PLAY_MSG.hupaiReload(pack)
	skynet.call(roomagent, "lua", "playerMsg_multicastNotify", "hupaiReloadNotify", pack)
end
function PLAY_MSG.gameFinish(pack)
	skynet.call(roomagent, "lua", "playerMsg_multicastNotify", "gameFinishNotify", pack)
end
function PLAY_MSG.masterCheckoutRoom(pack)
	skynet.call(roomagent, "lua", "playerMsg_multicastNotify", "masterCheckoutRoomNotify", pack)
	PLAY_MSG.gameFinish()
end
function PLAY_MSG.wufuBaojing(pack)
	skynet.call(roomagent, "lua", "playerMsg_multicastNotify", "wufuBaojingNotify", pack)
end
function PLAY_MSG.canWufuBaojing(pack, pid)
	skynet.call(roomagent, "lua", "playerMsg_notify", "canWufuBaojing", pid, pack)
end
function PLAY_MSG.playerOnlineChange(pack)
	skynet.call(roomagent, "lua", "playerMsg_multicastNotify", "playerOnlineChangeNotify", pack)
end
function PLAY_MSG.reloadInfo(pack, pid)
	skynet.call(roomagent, "lua", "playerMsg_notify", "reloadInfo", pid, pack)
end
function PLAY_MSG.voice(pack)
	skynet.call(roomagent, "lua", "playerMsg_multicastNotify", "voiceNotify", pack)
end

local CMD = setmetatable({}, { __gc = function() netpack.clear(queue) end })
function CMD.exit()
	skynet.exit()
end
function CMD.initGame(roomid, playTimes, zhongzhuang, forceHupai)
	R = sharedata.query("R")
	gameScoreMgr:setR(R)
	ruleHelp:setR(R)
	gameResultMgr:setR(R)

	gameState = R.GAME_STATE.waiting

	gameCenter:init(roomid, playTimes, zhongzhuang, forceHupai)
end

function CMD.setMsgTransfer(room)
	roomagent = room
	local gameMessageTransfer = require "logic.gameMessageTransfer"
	gameMessageTransfer:setMsgReceiver(function(msgName, pack, pid)
		local f = PLAY_MSG[msgName]
		f(pack, pid)
	end)
	msgTransfer = gameMessageTransfer
	msgTransfer:setGameCenter(gameCenter)
	msgTransfer:setR(R)
	

	gameScoreMgr:setMsgTransfer(gameMessageTransfer)
end

function CMD.playerEnter(pid, nickName, ip, sex, headimgurl)
	gameCenter:playerEnter(pid, nickName, ip, sex, headimgurl)
end

function CMD.playerReEnter(pid, nickName, ip, sex, headimgurl)
	gameCenter:playerReEnter(pid, nickName, ip, sex, headimgurl)
end

function CMD.playerReady(pid)
	gameCenter:playerReady(pid)
	
end

function CMD.playerPayCards(pid, rule, cardsdata)
	if gameCenter.co_run then 
		local cards = string.split(cardsdata, ",")
		for k,v in pairs(cards) do cards[k] = tonumber(v) end
		inputCards = {site=gameCenter:getSiteByPid(pid), rule=rule, cards=cards}
		skynet.wakeup(gameCenter.co_run) 
		gameCenter.co_run = nil
	end	
end

function CMD.playerChat(pid, faceid)
	msgTransfer:msg(R.sMsg.playerChat, pid, faceid)
end

function CMD.masterCheckoutRoom(pid)
	if roomMasterPid == pid then
		msgTransfer:msg(R.sMsg.masterCheckoutRoom)
	end
end


function CMD.selectWufuBaojing(pid, code)
	PlayWufubaojing = code
	skynet.wakeup(gameCenter.co_run) 
	gameCenter.co_run = nil
end

function CMD.playerStartGame(pid)
	local start = true
	for i=1, R.MAX_PLAYER_COUNT do
		if not players.player[i]:isPlayerStartGame() then
			start = false
			break
		end
	end
	
	if not start then
		for i=1, R.MAX_PLAYER_COUNT do
			if players.player[i].pid == pid then
				players.player[i]:playerStartGame()
				break
			end
		end
		
		start = true
		for i=1, R.MAX_PLAYER_COUNT do
			if not players.player[i]:isPlayerStartGame() then
				start = false
				break
			end
		end
		if start then
			skynet.wakeup(gameCenter.co_run) 
			gameCenter.co_run = nil
		end
	end
end

function CMD.playerOnlineChange(pid, isonline)
	for i=1, R.MAX_PLAYER_COUNT do
		if players.player[i].pid == pid then
			players.player[i]:setOnline(isonline)
			break
		end
	end
	msgTransfer:msg(R.sMsg.playerOnlineChange, pid, isonline)
end

function CMD.voice(pid, fileID, time)
	msgTransfer:msg(R.sMsg.voice, pid, fileID, time)
end

function CMD.gameFinish()
	gameCenter:gameFinish()
end

skynet.start(function()
	print("gameCenter service start")
	skynet.dispatch("lua", function (session, address, cmd, ...)
		--print("gameCenter.dispatch.cmd: " .. cmd)
		local f = CMD[cmd]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			skynet.error("gameCenter dispatch unknown msg: ".. cmd)
			skynet.ret(skynet.pack(handler.command(cmd, address, ...)))
		end
	end)
end)

------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------


function gameCenter:init(roomid, playTimes, zhongzhuang, forceHupai)
	
	gameCenter.roomId = roomid
	gameConfig:reset(playTimes, zhongzhuang, forceHupai)
	gameResultMgr:reset()
	
	zhuang.site = 1	
	players.player = {}
	players.count = 0
	
	for i=1, R.MAX_PLAYER_COUNT do
		local p = hotRequire("logic.player")
		p:setRuleHelp(ruleHelp)
		p:setR(R)
		table.insert(players.player, p)
	end
		
	gameState = R.GAME_STATE.waiting
	
	cardsMgr = {cards={}, cardIds={}, payIndex=0}
	
	curPaysite = 0
	
	inputCards = {}
	
	inputPossibles = {}
		
    math.randomseed(tostring(os.time()):reverse():sub(1, 6))
end

function gameCenter:gameOver(dpSite)
	gameState = R.GAME_STATE.gameover
	
	curPaysite = 0
	turnRunCount = 0
	inputCards = {}
	inputPossibles = {}
	
	for i=1, R.MAX_PLAYER_COUNT do
		local his = gameResultMgr:getLastResult()
		players.player[i]:gameover(his:getWinnerPid(), his:getWinType(), dpSite == i)
	end
end

function gameCenter:destoryRoom()
	skynet.call(roomagent, "lua", "closeRoom")
end

function gameCenter:gameFinish()
	gameState = R.GAME_STATE.finish
	msgTransfer:msg(R.sMsg.gameFinish)
	
	--playInfo, roomInfo
	local playInfo = {}
	local roomInfo = {}
	for i=1, R.MAX_PLAYER_COUNT do
		local his = gameResultMgr:getLastResult()
		players.player[i]:gameover(his:getWinnerPid(), his:getWinType(), dpSite == i)
		print("gameFinish players.player[i].nickName", players.player[i].nickName, i)
		playInfo[i] = {pid = players.player[i].pid, name = players.player[i].nickName, score = players.player[i].totalScore}
	end 
	
	roomInfo.rid = gameCenter.roomId
	roomInfo.js = tostring(gameConfig:getPlayConfigTimes())
	roomInfo.zz = gameConfig:getLianzhong() and "1" or "0"
	print_lua_table(roomInfo)
	skynet.call("db_service", "lua", "gameFinish", playInfo, roomInfo)
end

function gameCenter:get_players()
	return players
end
function gameCenter:get_mostCards() 
	return cardsMgr.cardIds
end
function gameCenter:getGameConfig()
	local c = ""
	c = c .. gameConfig:getPlayConfigTimes() .. ","
	c = c .. (gameConfig:isForceHupai() and "1" or "0") .. ","
	c = c .. (gameConfig:getLianzhong() and "1" or "0")
	return c
end

function gameCenter:getSiteByPid(pid)
	for i=1, #players.player do
		if players.player[i].pid == pid then return i end
	end
	return 0
end
function gameCenter:getPidBySite(site)
	if  players.player[site] then
		return players.player[site].pid
	end
	return 0
end

function gameCenter:playerEnter(pid, nickName, ip, sex, headimgurl)
	print("2self.nickname", self.nickName)
	if players.count >= R.MAX_PLAYER_COUNT then
		msgTransfer:msg(R.sMsg.playerEnter, pid, -1, gameCenter.roomId, 0, gameState)
		return
	end
	
	if gameState ~= R.GAME_STATE.waiting then
		msgTransfer:msg(R.sMsg.playerEnter, pid, -2, gameCenter.roomId, 0, gameState)
		return
	end
		
	for i=1, R.MAX_PLAYER_COUNT do
		if players.player[i].pid == 0 then
			players.player[i].pid = pid
			players.player[i].nickName = nickName
			players.player[i].ip = ip
			players.player[i].sex = sex
			players.player[i].headimgurl = headimgurl
			players.player[i]:setLocalsite(i)
			if i == 1 then roomMasterPid = pid end
			break
		end
	end
		
	players.count =players.count + 1
	msgTransfer:msg(R.sMsg.playerEnter, pid, 0, gameCenter.roomId, roomMasterPid, gameState)
end

function gameCenter:playerReEnter(pid, nickName, ip, sex, headimgurl)
	local ok = false
	for i=1, R.MAX_PLAYER_COUNT do
		if players.player[i].pid == pid then
			players.player[i].nickName = nickName
			players.player[i].ip = ip
			players.player[i].sex = sex
			players.player[i].headimgurl = headimgurl
			ok = true
			break
		end
	end
	
	if ok then
		msgTransfer:msg(R.sMsg.playerReEnter, pid, 0, gameCenter.roomId, roomMasterPid, gameState)
	
		msgTransfer:msg(R.sMsg.playerReInitCards, pid, players.player[zhuang.site].pid, MAX_CARD_COUNT-cardsMgr.payIndex)
			
		if gameState == R.GAME_STATE.playing then
			--看是不是掉线玩家正在选组牌
			for k,v in pairs(playerSelectRuleCards) do
				if k == pid then
					msgTransfer:msg(R.sMsg.ruleCardsPossible, k, v)
					break
				end
			end
		end
		
		--发送重载信息
		local lianzhuangCnt = 0
		local lastresult = gameResultMgr:getLastResult()
		if lastresult and pid == lastresult:getWinnerPid() then 
			lianzhuangCnt = gameResultMgr:getLianzhuangCount()
			lianzhuangCnt = gameConfig:getLianzhong() and lianzhuangCnt or math.min(lianzhuangCnt,1)
		end			
		local gameCount = gameResultMgr:getResultCount() + 1
		local curPayId = curPaysite > 0 and players.player[math.max(1,curPaysite)].pid or 0
		msgTransfer:msg(R.sMsg.reloadInfo, pid, curPayId, lianzhuangCnt, gameCount, #inputPossibles == 0 and 0 or g_paycard)
		
		--是否正在选择五福报警
		print("playerWaitSelectWufubaojing3", playerWaitSelectWufubaojing)
		if playerWaitSelectWufubaojing > 0 then
			msgTransfer:msg(R.sMsg.canWufuBaojing, playerWaitSelectWufubaojing)
		end
				
		--游戏是结束
		if gameState == R.GAME_STATE.gameover or gameState == R.GAME_STATE.finish then
			PLAY_MSG.hupaiReload(g_lastHupaiPack)
			if gameState == R.GAME_STATE.finish then msgTransfer:msg(R.sMsg.gameFinish) end
		end
		
	else
		msgTransfer:msg(R.sMsg.playerReEnter,pid, -3, gameCenter.roomId, roomMasterPid, gameState)
	end
end

function gameCenter:playerReady(pid)
	if gameState == R.GAME_STATE.playing then return end
	if gameState == R.GAME_STATE.finish then return end
	
	for k,v in pairs(players.player) do
		if v.pid == pid then
			if v:isReady() then return end
			v:ready(true)
			msgTransfer:msg(R.sMsg.playerReady, pid)
			break
		end
	end
	
	local readyCnt = 0
	for i=1, #players.player do
		if players.player[i]:isReady() then readyCnt = readyCnt + 1 end
	end
	
	if readyCnt == R.MAX_PLAYER_COUNT then
		self:startPlay()
	end
end



function gameCenter:startPlay()
	if gameState == R.GAME_STATE.playing then return -1 end
	gameState = R.GAME_STATE.playing
	
	msgTransfer:msg(R.sMsg.startGame)
	
	
	
	--生成庄家	
	zhuang.site = gameResultMgr:createZhuangSite()
	print("zhuang.site", zhuang.site)
	if zhuang.site == 0 then zhuang.site = self:getSiteByPid(roomMasterPid) end
	for i=1, #players.player do
		players.player[i]:zhuang(zhuang.site == players.player[i]:getLocalsite())
	end
	
	--发牌
	local function dispatchPokes()
		cardsMgr = {cards={}, cardIds={}, payIndex=0}
		
		local tmpcards = {}
		local cindex = 1
		
		--一种牌各4张
		for i=1, 4 do
			for k,v in pairs(R.value) do
				local c = hotRequire("logic.card")
				c:set(v, false, cindex)
				cindex = cindex + 1
				table.insert(tmpcards, c)
			end
		end
		for i=1, 4 do
			for k,v in pairs(R.value) do
				local c = hotRequire("logic.card")
				c:set(v, true, cindex)
				cindex = cindex + 1
				table.insert(tmpcards, c)
			end
		end
		
		
		local indexs = {}
		local playerCardCnt = 14
		local ccnt = #tmpcards
		MAX_CARD_COUNT = ccnt
		local T = ccnt * 10
		local a, b, ia, ib		
		for i=1, ccnt do indexs[i] = i end
		for i=1, T do
			a = math.random(1, ccnt)
			b = math.random(1, ccnt)
			tmp=indexs[a]
			ia=indexs[a]
			ib=indexs[b]
			indexs[a]=ib
			indexs[b]=ia
		end
		for i=1, ccnt do
			table.insert(cardsMgr.cards, tmpcards[indexs[i]])--cardsMgr = {cards={}, cardIds={}, payIndex=0}
		end
		
		
		--test player card
		local testcard = require("logic.testPlayerCard")
		if testcard and gameResultMgr:getResultCount() >= 0 then
			print("using testcard")
			if testcard[6] and testcard[6]>0 then zhuang.site = testcard[6] print("test zhuang:", players.player[zhuang.site].pid, zhuang.site) end
			local pi = {}
			local syscards = {}
			for i=1, R.MAX_PLAYER_COUNT do pi[i]={} end
			for i=1, R.MAX_PLAYER_COUNT do
				for k,v in pairs(testcard[i]) do
					
					for j=1, #cardsMgr.cards do
						if cardsMgr.cards[j].value == v[1] and cardsMgr.cards[j].capital == (v[2]==1) then
							table.insert(pi[i], cardsMgr.cards[j])
							table.remove(cardsMgr.cards, j)
							break
						end
					end
				end
			end
			
			for k,v in pairs(testcard[5]) do
				for j=1, #cardsMgr.cards do
					if cardsMgr.cards[j].value == v[1] and cardsMgr.cards[j].capital == (v[2]==1) then
						table.insert(syscards, cardsMgr.cards[j])
						table.remove(cardsMgr.cards, j)
						break
					end
				end
			end
			
			for i=1, R.MAX_PLAYER_COUNT do
				local picnt = #pi[i] + 1
				for j=picnt, playerCardCnt do
					table.insert(pi[i], cardsMgr.cards[#cardsMgr.cards])
					table.remove(cardsMgr.cards)
				end
			end
			
			local cardstmp={}
			for i=1, R.MAX_PLAYER_COUNT do
				for k,v in pairs(pi[i]) do table.insert(cardstmp, v) end
			end
			table.insert(cardstmp, cardsMgr.cards[#cardsMgr.cards])
			table.remove(cardsMgr.cards)
			for k,v in pairs(syscards) do table.insert(cardstmp, v) end
			for k,v in pairs(cardsMgr.cards) do table.insert(cardstmp, v) end
			cardsMgr.cards = {}
			for k,v in pairs(cardstmp) do table.insert(cardsMgr.cards, v) end
		end
		for i=1, #cardsMgr.cards do
			cardsMgr.cardIds[cardsMgr.cards[i].id] = cardsMgr.cards[i]
		end
		
		--every player have 14 card
		cardsMgr.payIndex = 1
		
		local playercards = {}
		for i=1, R.MAX_PLAYER_COUNT do playercards[i]={} end
		for j=0, R.MAX_PLAYER_COUNT-1 do
			local site = turnSite(zhuang.site, j)
			for i=1, playerCardCnt do
				table.insert(playercards[site], cardsMgr.cards[cardsMgr.payIndex])
				cardsMgr.payIndex = cardsMgr.payIndex + 1
			end
		end
		table.insert(playercards[zhuang.site], cardsMgr.cards[cardsMgr.payIndex])
		cardsMgr.payIndex = cardsMgr.payIndex + 1
		
		for i=1, R.MAX_PLAYER_COUNT do 
			players.player[i]:initCards(playercards[i], cardsMgr.cards) 
		end
	end
	dispatchPokes()
	msgTransfer:msg(R.sMsg.playerInitCards, players.player[zhuang.site].pid, MAX_CARD_COUNT-cardsMgr.payIndex+1)
	gameScoreMgr:reset(players.player, cardsMgr.cardIds, zhuang.site)
	
	curPaysite = zhuang.site
	lastPayCardRule = R.rule.Ti
	curPayCardRule = R.rule.Ti
	
	
	skynet.fork(function()
		local winnerPid, winnerType, winCard, dpSite = self:run()
		local winnerSite = self:getSiteByPid(winnerPid)
		winnerType = gameResultMgr:parseWinnerType(winnerType, curPayCardRule, winnerSite, curPaysite, turnRunCount)
		
		gameResultMgr:addResult(zhuang.site, winnerPid, winnerSite, winnerType, winCard, dpSite, cardsMgr.payIndex, winnerType==R.wintype.hongzhuang)
		
		local zhuangWin, zhongzhuang, lianzhongCnt = gameResultMgr:getWinBuff()
		lianzhongCnt = gameConfig:getLianzhong() and lianzhongCnt or false--中庄，连中
		gameScoreMgr:payscoreHupai(winnerType, curPayCardRule, winnerSite, lastPayCardRule == R.rule.None and 0 or curPaysite, dpSite, zhuangWin, zhongzhuang, lianzhongCnt)
		
		local lianzhuangCnt, playCount = gameResultMgr:getLianzhuangCount(), gameResultMgr:getResultCount()
		lianzhuangCnt = gameConfig:getLianzhong() and lianzhuangCnt or math.min(lianzhuangCnt,1)
		msgTransfer:msg(R.sMsg.hupai, winnerPid, winnerType, winCard, dpSite<=0 and 0 or players.player[dpSite].pid, lianzhuangCnt, playCount+1, cardsMgr.cards, cardsMgr.payIndex)
		
		local curTimes = gameConfig:getCurrentPlayTimes()
		gameConfig:setCurrentPlayTimes(curTimes+1)
		if (curTimes+1) >= gameConfig:getPlayConfigTimes() then
			self:gameFinish()
			self:destoryRoom()
		else
			self:gameOver(dpSite)
		end
	end)
end

function gameCenter:checkHupai(site, addCards)
	if not site then
		for i=0, R.MAX_PLAYER_COUNT-1 do
			site = turnSite(curPaysite, i)
			local winType = players.player[site]:getHupaiType(addCards)
			if R.wintype.none ~= winType then
				return players.player[site].pid, winType
			end
		end
	else
		local winType = players.player[site]:getHupaiType(addCards)
		if R.wintype.none ~= winType then
			return players.player[site].pid, winType
		end
	end
end

local stime = 150
function gameCenter:run()
	
	local function tryHupai(site, addCards)
		local pid, wintype = self:checkHupai(site, addCards)
		if pid then
			return pid, wintype
		end
	end
	local function waitPlayerPayPoke()
		while true do 
			gameCenter.co_run = coroutine.running()
			skynet.wait()
			if inputCards.site == curPaysite and inputCards.rule == R.rule.None then
				return inputCards.cards[1]
			end
		end
	end
	
	local function checkWufuBaojing(checkSite)
		local function waitResponse(pid)
			gameCenter.co_run = coroutine.running()
			skynet.sleep(100*120)
			if PlayWufubaojing then
				msgTransfer:msg(R.sMsg.wufuBaojing, pid)
			end			
		end
		if checkSite then
			if players.player[checkSite]:checkWufuBaojing() then
				msgTransfer:msg(R.sMsg.canWufuBaojing, players.player[checkSite].pid)
				playerWaitSelectWufubaojing = players.player[checkSite].pid
				print("playerWaitSelectWufubaojing1", playerWaitSelectWufubaojing)
				waitResponse(players.player[checkSite].pid)
				playerWaitSelectWufubaojing = 0
				print("playerWaitSelectWufubaojing2", playerWaitSelectWufubaojing)
				players.player[checkSite]:neverWufuBaojing(PlayWufubaojing)
			end
			
		else
			for i=0, R.MAX_PLAYER_COUNT-1 do
				local site = turnSite(curPaysite, i)
				if players.player[site]:checkWufuBaojing() then
					msgTransfer:msg(R.sMsg.canWufuBaojing, players.player[site].pid)
					waitResponse(players.player[site].pid)
					players.player[site]:neverWufuBaojing(PlayWufubaojing)
					break
				end
			end
		end
		PlayWufubaojing = false
	end
	local function waitPlayerPayRulePoke()
		if next(inputPossibles) == nil then return 0, R.rule.None, {} end
		
		table.sort(inputPossibles, function(a,b) return tonumber(a.rule) > tonumber(b.rule) end)
		
		local function getInfoWithInputCards(input)
			if input.rule == R.rule.None then return input.site, input.rule, input.cards end
			for k,v in pairs(inputPossibles) do
				if v.rule == input.rule and v.site == input.site then
					for kk,vv in pairs(v.cards) do
						local idcnt = 0
						local hasid = 0
						for k1,v1 in pairs(vv) do idcnt=idcnt+v1 end
						for k1,v1 in pairs(input.cards) do hasid=hasid+v1 end
						if idcnt == hasid then
							return v.site, v.rule, vv
						end
					end
				end
			end
		end
		while true do 
			gameCenter.co_run = coroutine.running()
			skynet.wait()	
			local site, rule, cards = getInfoWithInputCards(inputCards)
			
			--如果是最大的值，则取消其它所有的玩家选择权。直接让最大的出牌
			local idx = 1
			while(true) do
				if idx > #inputPossibles then break end
				if not inputPossibles[idx].play then
					inputPossibles[idx].play = inputPossibles[idx].site == inputCards.site
				end
				
					if inputPossibles[idx].site == inputCards.site and inputPossibles[idx].play and (inputPossibles[idx].rule ~= rule or R.rule.None == rule) then
						table.remove(inputPossibles, idx)
						idx = 1
					else
						if inputPossibles[idx].site == inputCards.site and inputPossibles[idx].play and inputPossibles[idx].rule == rule then
							inputPossibles[idx].cards = cards
						end
						idx = idx + 1
					end
			end
			if 0 == #inputPossibles then
				return 0, R.rule.None
			end
			
			if inputPossibles[1].play then
				local res = inputPossibles[1]
				return res.site, res.rule, res.cards
			end
		end
	end
	
	local function dispatchCardTest(card, cardSite, system)
		local res = {}
		local begin = system and 0 or 1
		for i=begin, R.MAX_PLAYER_COUNT-1 do
			local site = turnSite(cardSite, i)
			
			local rulecards = players.player[site]:dispatchCardTest(curPaysite==site, cardSite, card, system)
			for k,v in pairs(rulecards) do
				table.insert(res, {site=site, rule=k, cards=v})
			end
		end
		return res
	end	
	
	local function systemDispatchCard()
		if cardsMgr.payIndex <= MAX_CARD_COUNT then
			local card = cardsMgr.cards[cardsMgr.payIndex]
			cardsMgr.payIndex = cardsMgr.payIndex + 1
			return card.id
		end
	end
	
	local function playerPayCards(site, rule, paycards, othercard)
		local res = players.player[site]:payCards(rule, paycards, othercard)
		if res then curPayCardRule = rule end
		return res
	end
	
	local function waitPlayerStartGame()
		gameCenter.co_run = coroutine.running()
		skynet.wait()
	end
	
	waitPlayerStartGame()
	
	--qidui,tianhu,shuanglong,tiwei,hupai,paopeng,chi
	for i=0, R.MAX_PLAYER_COUNT-1 do
		local site = turnSite(curPaysite, i)
		local hupaiType = players.player[site]:getBestHupaiType()
		if R.wintype.none ~= hupaiType then
			return players.player[site].pid, hupaiType, 0, 0
		end
	end
	
	--ti,kan
	for i=0, R.MAX_PLAYER_COUNT-1 do
		local site = turnSite(curPaysite, i)
		local ruleCards = players.player[site]:dispatchCardTest(true)
		
		if ruleCards[R.rule.Ti_zimo] then
			for k,v in pairs(ruleCards[R.rule.Ti_zimo]) do
				if players.player[site]:payCards(R.rule.Ti_zimo, v) then
					msgTransfer:msg(R.sMsg.payRuleCardPlayer, {pid=players.player[site].pid, rule=R.rule.Ti_zimo, cards=v,othercard=0})
					gameScoreMgr:payscore(site, R.rule.Ti_zimo, v, 0)
				end
			end
		end
		
		if ruleCards[R.rule.Kan] then
			for k,v in pairs(ruleCards[R.rule.Kan]) do
				if players.player[site]:payCards(R.rule.Kan, v) then
					msgTransfer:msg(R.sMsg.payRuleCardPlayer, {pid=players.player[site].pid, rule=R.rule.Kan, cards=v, othercard=0})
					gameScoreMgr:payscore(site, R.rule.Kan, v, 0)
				end
			end
		end
	end
	checkWufuBaojing()
	
	local winnerPid, winnerType = tryHupai()
	if winnerPid then return winnerPid, winnerType, 0, 0 end
	
	
	
	while true do
		if gameState ~= R.GAME_STATE.playing then break end
		turnRunCount = turnRunCount + 1
		
		--出牌
		g_paycard = nil
		local payMessage = lastPayCardRule == R.rule.None and R.sMsg.payCardSystem or R.sMsg.payCardPlayer
		
		local paySite = players.player[curPaysite].pid
		
		if lastPayCardRule == R.rule.None then
			g_paycard = systemDispatchCard()
			if not g_paycard then
				msgTransfer:msg(payMessage, {pid=paySite, card=g_paycard, show=true})
				return players.player[zhuang.site].pid, R.wintype.hongzhuang, 0, 0
			end
		else
			msgTransfer:msg(R.sMsg.turnPlayer, players.player[curPaysite].pid)
			g_paycard = waitPlayerPayPoke()
			playerPayCards(curPaysite, R.rule.None, {g_paycard})
			players.player[curPaysite]:choupai(R.rule.Chi, g_paycard)-- 自己之前打过的牌是不能再吃的，例如之前打过小一。然后后面再出现小二是不能提示吃的
		end
		
		local rulecards = dispatchCardTest(g_paycard, curPaysite, lastPayCardRule == R.rule.None)
		local continue = true
		
		--print("rulecards")
		--print_lua_table(rulecards)
		--强制牌1
		for k,v in pairs(rulecards) do
			if ruleHelp:isForceRule1(v.rule) then
				for kk,vv in pairs(v.cards) do
					local paycards = {}
					for kkk,vvv in pairs(vv) do if vvv ~= g_paycard then table.insert(paycards, vvv) end end
					if playerPayCards(v.site, v.rule, paycards, g_paycard) then
						
						local hidecard = ruleHelp:hideSystemCard(v.rule)
						msgTransfer:msg(payMessage, {pid=paySite, card=g_paycard, show=not hidecard})
						skynet.sleep(hidecard and 0 or stime)
						
						msgTransfer:msg(R.sMsg.payRuleCardPlayer, {pid=players.player[v.site].pid, rule=v.rule, cards=vv, othercard=0})
						
						
						local winnerPid, winnerType = tryHupai(v.site)--强制牌后再检查一次胡牌
						if winnerPid then
							return winnerPid, winnerType, g_paycard, lastPayCardRule ~= R.rule.None and curPaysite or 0
						else
							gameScoreMgr:payscore(v.site, v.rule, vv, lastPayCardRule == R.rule.None and 0 or curPaysite)
						end
						
						checkWufuBaojing(v.site)
						skynet.sleep(stime)
						
						--组牌后，可否出牌
						if players.player[v.site]:canPayCardAfterRule(v.rule) then
							curPaysite = v.site
							lastPayCardRule = v.rule
							msgTransfer:msg(R.sMsg.turnPlayer, players.player[v.site].pid)
						else
							curPaysite = turnNextSite(v.site)
							lastPayCardRule = R.rule.None
							skynet.sleep(stime)
						end
						continue = false
						break
					end
				end	
			end
		end
		
		
		--胡牌
		if continue then			
			for k,v in pairs(rulecards) do				
				for kk,vv in pairs(v.cards) do
					local paycards = {}
					for kkk,vvv in pairs(vv) do if vvv ~= g_paycard then table.insert(paycards, vvv) end end
					if playerPayCards(v.site, v.rule, paycards, g_paycard) then
						local winnerPid, winnerType = tryHupai(v.site)
						if winnerPid then
							continue = false
							msgTransfer:msg(payMessage, {pid=paySite, card=g_paycard, show=true})
							skynet.sleep(stime)
							
							msgTransfer:msg(R.sMsg.payRuleCardPlayer, {pid=players.player[v.site].pid, rule=v.rule, cards=vv, othercard=lastPayCardRule == R.rule.None and 0 or g_paycard})
							return winnerPid, winnerType, g_paycard, lastPayCardRule ~= R.rule.None and curPaysite or 0
						else
							players.player[v.site]:backspacePaycards()
						end
					end
				end
			end
		end
		if continue then
			for i=1, R.MAX_PLAYER_COUNT do
				if (lastPayCardRule == R.rule.None or i ~= curPaysite) --[[and not players.player[i]:isWufuBaojing()--]] then
					local winnerPid, winnerType = tryHupai(i, {g_paycard})
					if winnerPid then
						continue = false
						curPayCardRule = R.rule.None
						
						msgTransfer:msg(payMessage, {pid=paySite, card=g_paycard, show=true})
						skynet.sleep(stime)
						
						return winnerPid, winnerType, g_paycard, lastPayCardRule ~= R.rule.None and curPaysite or 0
					end
				end
			end
		end
		
		
		--强制牌2,Pao_peng有BUG
		for k,v in pairs(rulecards) do
			if ruleHelp:isForceRule2(v.rule) then
				for kk,vv in pairs(v.cards) do
					local paycards = {}
					for kkk,vvv in pairs(vv) do if vvv ~= g_paycard then table.insert(paycards, vvv) end end
					if playerPayCards(v.site, v.rule, paycards, g_paycard) then
						local hidecard = ruleHelp:hideSystemCard(v.rule)
						msgTransfer:msg(payMessage, {pid=paySite, card=g_paycard, show=not hidecard})
						skynet.sleep(hidecard and 0 or stime)
						msgTransfer:msg(R.sMsg.payRuleCardPlayer, {pid=players.player[v.site].pid, rule=v.rule, cards=vv, othercard=lastPayCardRule == R.rule.None and 0 or g_paycard})
												
						local winnerPid, winnerType = tryHupai(v.site)--强制牌后再检查一次胡牌
						if winnerPid then
							return winnerPid, winnerType, g_paycard, lastPayCardRule ~= R.rule.None and curPaysite or 0
						else
							gameScoreMgr:payscore(v.site, v.rule, vv, lastPayCardRule == R.rule.None and 0 or curPaysite)
						end
						
						--组牌后，可否出牌
						if players.player[v.site]:canPayCardAfterRule(v.rule) then
							curPaysite = v.site
							lastPayCardRule = v.rule
							msgTransfer:msg(R.sMsg.turnPlayer, players.player[v.site].pid)
						else
							curPaysite = turnNextSite(v.site)
							lastPayCardRule = R.rule.None
							skynet.sleep(stime)
						end
						
						continue = false
						break
					end
				end	
			end
		end
		
		--组牌
		if continue then
			msgTransfer:msg(payMessage, {pid=paySite, card=g_paycard, show=true})
			
			local sitecards = {}
			playerSelectRuleCards = {}
			
			--filter非法吃牌
			local i = #rulecards
			while(i > 0) do
				if rulecards[i].rule == R.rule.Chi then		
					if players.player[rulecards[i].site]:canChiWithPay(rulecards[i].cards, curPaysite) then
						i=i-1
					else
						table.remove(rulecards, i)
						i=#rulecards
					end
				else
					i=i-1
				end
			end
			
			--分发通知牌型
			for k,v in pairs(rulecards) do
				local pid = self:getPidBySite(v.site)
				if not playerSelectRuleCards[pid] then playerSelectRuleCards[pid] = {} end
				table.insert(playerSelectRuleCards[pid], {rule=v.rule, site=v.site, cards=v.cards, othercard=g_paycard})
				table.insert(sitecards, {rule=v.rule, site=v.site, cards=v.cards, othercard=g_paycard})
			end
			
			for k,v in pairs(playerSelectRuleCards) do
				msgTransfer:msg(R.sMsg.ruleCardsPossible, k, v)
			end
			
			inputPossibles = sitecards
			local site, rule, cards = waitPlayerPayRulePoke()
			
			--整理臭牌
			for playerid,rulelist in pairs(playerSelectRuleCards) do
				for k,v in pairs(rulelist) do
					local has = false
					for kk,vv in pairs(inputPossibles) do
						if vv.site == v.site and vv.rule == v.rule then
							has = true
							break
						end
					end
					if not has then
						players.player[v.site]:choupai(v.rule, g_paycard)
					end
				end
			end
			
			--去除被拿走的牌
			if rule == R.rule.Pao_peng or rule == R.rule.Pao or rule == R.rule.Pao_kan
				or rule == R.rule.Pao_wei or rule == R.rule.Chi or rule == R.rule.Chiyibisan then
				local ok
				for kk,vv in pairs(cards) do 
					for i=1, R.MAX_PLAYER_COUNT do
						if players.player[i]:removeSingleShowCard(vv) then
							ok = true
							break 
						end
					end
					if ok then	break end
				end
			end
			if rule == R.rule.Peng and lastPayCardRule ~= R.rule.None then--只有两个碰的牌，另外一张牌
				players.player[site]:addPengRuleSingleCard(g_paycard)
			end
			
			playerSelectRuleCards = {}
			inputPossibles = {}
			
			if rule == R.rule.None then
				curPaysite = turnNextSite(curPaysite)
				lastPayCardRule = rule
				skynet.sleep(stime)
				continue = false
				
			else
				local paycards = {}
				for kk,vv in pairs(cards) do if vv ~= g_paycard then table.insert(paycards, vv) end end
				playerPayCards(site, rule, paycards, g_paycard)
				
				msgTransfer:msg(R.sMsg.payRuleCardPlayer, {pid=players.player[site].pid, rule=rule, cards=cards, othercard=lastPayCardRule == R.rule.None and 0 or g_paycard})
				gameScoreMgr:payscore(site, rule, cards, lastPayCardRule == R.rule.None and 0 or curPaysite)
				
				checkWufuBaojing(site)
				skynet.sleep(stime)
				
				curPaysite = site
				lastPayCardRule = rule
				continue = false
			end
		end
	end
end

return interface
