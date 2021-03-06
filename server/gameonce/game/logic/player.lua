--单个玩家的逻辑
local player = {}
player.pid = 0
player.nickName = ""
player.ip = ""
player.sex = ""
player.headimgurl = ""
player.roomId = 0
player.site = 0
player.score = 0
player.totalScore = 0
player.winCount = 0
player.zhongzhuangCount = 0
player.dianpaoCount = 0
player.waitStartGame = 0 --0为等待client发送开始通知，1为开始通知
player.online = true

--local  card = {all={}, handed={}, showed={}, rules={}}--all,handed手上的牌(key:id,item:card)，showed显示出来的rule牌(key:ruletype,item:{index,id})，rules手上的分类了的rule牌(key:ruletype,item:{index,id})，rule.none(key:index,item:id)

local function hotRequire(file_name)
	package.loaded[file_name] = nil
	local f = require(file_name)
	return f
end

local cardMgr = hotRequire("logic.playerCardManager")
local zhuangIndex = false
local isready = false



local ruleHelp
local R

function player:setRuleHelp(rr)
	ruleHelp = rr
	cardMgr:setRuleHelp(rr)
end

function player:setR(rr)
	R = rr
	cardMgr:setR(rr)
end

function player:ready(r)
	isready = r
end

function player:zhuang(r)
	zhuangIndex = r
end

function player:isReady()
	return isready
end

function player:isZhuang()
	return zhuangIndex
end

function player:setLocalsite(s)
	player.site = s
end

function player:getLocalsite()
	return player.site
end

function player:addScore(s)
	self.score = self.score + s
	self.totalScore = self.totalScore + s
end

function player:getScore()
	return player.score
end
function player:getTotalScore()
	return player.totalScore
end


function player:initCards(mycards, allcards)
	cardMgr:init(mycards, allcards)
end

function player:getHandCards()
	return cardMgr:getHandCards()
end

function player:getShowSingleCards()
	return cardMgr:getShowSingleCards()
end

function player:getShowRuleCards()
	return cardMgr:getShowRuleCards()
end

function player:gameover(winnerPid, winType, isDianpao)
	self:ready(false)
	
	self.winCount = self.winCount + (winnerPid == self.pid and 1 or 0)
	self.zhongzhuangCount = self.zhongzhuangCount + (winType == R.wintype.hongzhuang and 1 or 0)
	if isDianpao then self.dianpaoCount = self.dianpaoCount + 1 end
	isready = false
	
	self.waitStartGame = 0
end

--出牌
function player:payCards(rt, cards, othercard)
	
	local res = cardMgr:payCards(rt, cards, othercard)
	return res
end
function player:backspacePaycards()
	cardMgr:popHistory()
end



function player:dispatchCardTest(isSelfCard, cardSite, card, isSystemCard)
	--print("player:dispatchCardTest", self.pid)
	if isSelfCard then
		return cardMgr:dispatchMyCard(card, isSystemCard)
	else
		return cardMgr:dispatchOtherCard(player.site, cardSite, card, isSystemCard)
	end
end

--[[
function player:testHupai(card)
	return cardMgr:testHupai(card)
end
--]]
function player:getHupaiType( addCards )
	--print("getHupaiType", self.pid)
	local rt = cardMgr:getHupaiType(zhuangIndex, addCards)
	return rt
end

function player:getBestHupaiType()
	return cardMgr:getBestHupaiType()
end

function player:removeSingleShowCard(cid)
	return cardMgr:removeSingleShowCard(cid)
end


function player:checkWufuBaojing()
	return cardMgr:checkWufuBaojing()
end
function player:isWufuBaojing()
	return cardMgr:isWufuBaojing()
end

function player:neverWufuBaojing(baojing)
	return cardMgr:neverWufuBaojing(baojing)
end

function player:canPayCardAfterRule(rule)
	return cardMgr:canPayCardAfterRule(rule)
end

function player:choupai(rule, paycard)
	return cardMgr:choupai(rule, paycard)
end

function player:canChiWithPay(cards, curPaysite)
	return cardMgr:canChiWithPay(cards, player.site, curPaysite)
end

function player:playerStartGame()
	self.waitStartGame = 1
	self.score = 0
end
function player:isPlayerStartGame()
	return self.waitStartGame == 1
end

function player:setOnline(b)
	self.online = b
end
function player:getOnline()
	return self.online
end

function player:addPengRuleSingleCard(cid)
	return cardMgr:addPengRuleSingleCard(cid)
end
function player:getPengRuleSingleCard()
	return cardMgr:getPengRuleSingleCard()
end


return player
