local cardMgr = {}
local R = nil
local ruleHelp = nil



cardMgr.all={}--所有的牌(key:id,item:card)
cardMgr.handed={}--手上的牌(key:ruletype,item:{index,id})rule.none(key:index,item:id)
cardMgr.showed={}--打出来的牌(key:ruletype,item:{index,id})rule.none(key:index,item:id)
cardMgr.PengRuleSingleCard = {}
cardMgr.choupaid={}--臭牌
cardMgr.owncards={}
cardMgr.wufuBaojingIndex = false
cardMgr.wantWufuBaojingIndex = 0
cardMgr.history={}

function SimpleCopy(object)
    local new_object = {}
    for k,v in pairs(object) do
        new_object[k] = v
    end
    return new_object
end


function cardMgr:setR(rr)
	R = rr
end

function cardMgr:setRuleHelp(rr)
	ruleHelp = rr
end

function cardMgr:init(myCards, allCards)
	self:reset()
	
	local handedTmp = {}
	for k,v in pairs(myCards) do
		handedTmp[#handedTmp+1] = v
	end
	cardMgr.handed = ruleHelp:tidyHandCards(handedTmp)
	cardMgr.owncards = handedTmp

	for k,v in pairs(allCards) do cardMgr.all[v.id] = v end
	
	table.sort(cardMgr.handed[R.rule.None], function(a,b)  return a < b end)
	
	for k,v in pairs(cardMgr.handed[R.rule.Ti_zimo]) do
		table.sort(v, function(v1, v2) return v1 < v2 end)
	end
	
	for k,v in pairs(cardMgr.handed[R.rule.Kan]) do
		table.sort(v, function(v1, v2) return v1 < v2 end)
	end
end

function cardMgr:reset()
	cardMgr.all = {}
	cardMgr.handed = {}
	cardMgr.handed[R.rule.Ti_zimo] = {}
	cardMgr.handed[R.rule.Kan] = {}
	cardMgr.handed[R.rule.None] = {}
	
	cardMgr.showed = {}
	cardMgr.showed[R.rule.Ti] = {}
	cardMgr.showed[R.rule.Ti_zimo] = {}
	cardMgr.showed[R.rule.Ti_kan] = {}
	cardMgr.showed[R.rule.Ti_wei] = {}
	cardMgr.showed[R.rule.Pao] = {}
	cardMgr.showed[R.rule.Pao_kan] = {}
	cardMgr.showed[R.rule.Pao_wei] = {}
	cardMgr.showed[R.rule.Pao_peng] = {}
	cardMgr.showed[R.rule.Wei_chou] = {}
	cardMgr.showed[R.rule.Kan] = {}
	cardMgr.showed[R.rule.Wei] = {}
	cardMgr.showed[R.rule.Peng] = {}
	cardMgr.showed[R.rule.Chi] = {}
	cardMgr.showed[R.rule.None] = {}
	
	cardMgr.PengRuleSingleCard = {}
	
	cardMgr.choupaid = {}
	cardMgr.choupaid[R.rule.Chi] = {}
	cardMgr.choupaid[R.rule.Peng] = {}
	
	cardMgr.wufuBaojingIndex = false
	cardMgr.wantWufuBaojingIndex = 0
	cardMgr.history={}
	
end

function cardMgr:getHandCards()
	local cards = {}
	for k,v in pairs(cardMgr.handed) do
		for kk,vv in pairs(v) do
			if type(vv) == "number" then
				table.insert(cards, cardMgr.all[vv])
			else
				for kkk,vvv in pairs(vv) do
					table.insert(cards, cardMgr.all[vvv])
				end
			end
		end
	end
	return cards
end

function cardMgr:getShowRuleCards()
	local cards = {}
	for k,v in pairs(cardMgr.showed) do
		if k ~= R.rule.None then
			cards[k] = {}
			for kk,vv in pairs(v) do
				local clist = {}
				for kkk,vvv in pairs(vv) do
					clist[#clist+1] = cardMgr.all[vvv]
				end
				table.insert(cards[k], clist)
			end
		end
	end
	return cards
end

function cardMgr:getShowSingleCards()
	local cards = {}
	
	for k,v in pairs(cardMgr.showed) do
		if k == R.rule.None then
			
			for kk,vv in pairs(v) do
				table.insert(cards, cardMgr.all[vv])
			end
			break
		end
	end
	return cards
end

function cardMgr:get_Ti_zimo()

	local pays = {}
	if #card.rules[R.rule.Ti_zimo] > 0 then
		for k,v in pairs(card.rules[R.rule.Ti_zimo]) do
			table.insert(pays, v)
		end
	end
	
	return pays
end



function cardMgr:payCards(rt, cards, othercard)
	if not cards and not othercard then
		return true
	end
	table.sort(cards, function(v1,v2)  return v1 < v2 end)
	local payrule, victrule = cardMgr:payCard(rt, cards, othercard)
	if payrule then
		cardMgr:pushHistory(payrule, victrule, cards, othercard)
	end
	
	local res = payrule and true or false
	return res
end

function cardMgr:pushHistory(payrule, victrule, cards, othercard)
	table.insert(cardMgr.history, {payrule=payrule, victrule=victrule, cards=SimpleCopy(cards), othercard=othercard})
	
end

function cardMgr:popHistory()
	local history = cardMgr.history[#cardMgr.history]
	table.remove(cardMgr.history)
	
	if 	R.rule.Chi == history.payrule or 
		R.rule.Peng == history.payrule or 
		R.rule.Wei == history.payrule or
		R.rule.Wei_chou == history.payrule or
		R.rule.None == history.payrule then
		for k,v in pairs(history.cards) do
			table.insert(cardMgr.handed[R.rule.None], v)
		end
		table.sort(cardMgr.handed[R.rule.None], function(a,b)  return a < b end)
		table.remove(cardMgr.showed[history.payrule])
		
		
	elseif R.rule.Kan == history.payrule then
		table.sort(history.cards, function(a,b)  return a < b end)
		table.insert(cardMgr.handed[R.rule.Kan], history.cards)
		table.remove(cardMgr.showed[history.payrule])
	
	elseif 	R.rule.Pao_kan == history.payrule or 
			R.rule.Pao_wei == history.payrule or 
			R.rule.Pao_peng == history.payrule then
		table.sort(history.cards, function(a,b)  return a < b end)
		table.insert(cardMgr.showed[history.victrule], history.cards)
		table.remove(cardMgr.showed[history.payrule])
		
	elseif 	R.rule.Ti_zimo == history.payrule then
		table.sort(history.cards, function(a,b)  return a < b end)
		table.insert(cardMgr.handed[history.victrule], history.cards)
		table.remove(cardMgr.showed[history.payrule])
		
	elseif 	R.rule.Ti_kan == history.payrule or 
			R.rule.Ti_wei == history.payrule then
		table.sort(history.cards, function(a,b)  return a < b end)
		table.insert(cardMgr.showed[history.victrule], history.cards)
		table.remove(cardMgr.showed[history.payrule])
	end
	
	
end

--提出牌rt:ruleType, cards(my card ,order(a<b) item:id), dispatchcard(item:id)
function cardMgr:payCard(rt, cards, dispatchcard)

	if R.rule.Chi == rt then
		if #cards >= 2 then
			local cc={}
			local ck={}
			for k,v in pairs(cardMgr.handed[R.rule.None]) do
				for kk,vv in pairs(cards) do
					if v == vv then cc[#cc+1]=v ck[#ck+1]=k break end
				end
			end
			if #cc == #cards then
				cc[#cc+1]=dispatchcard
				--if ruleHelp:testRulesCard(R.rule.Chi, cardMgr.all, cc) then
					table.insert(cardMgr.showed[R.rule.Chi], cc)
					table.sort(ck, function(a,b)return a>b end)
					for i=1, #ck do 
						table.remove(cardMgr.handed[R.rule.None], ck[i])
					end
					return rt, R.rule.None
				--end
			end
		end
	
	elseif R.rule.Peng == rt then
		if #cards == 2 then
			local c1, c2
			for k,v in pairs(cardMgr.handed[R.rule.None]) do
				if v == cards[1] then c1 = k end
				if v == cards[2] then c2 = k break end
			end
			if c1 and c2 then
				local testCards = {cards[1], cards[2], dispatchcard}
				if ruleHelp:testRulesCard(R.rule.Peng, cardMgr.all, testCards) then
					table.sort(testCards, function(a,b) return a<b end)
					table.insert(cardMgr.showed[R.rule.Peng], testCards)
					table.remove(cardMgr.handed[R.rule.None], c2)
					table.remove(cardMgr.handed[R.rule.None], c1)
					return rt, R.rule.None
				end
			end
		end
		
	elseif R.rule.Wei == rt then
		if #cards == 2 then
			local c1, c2
			for k,v in pairs(cardMgr.handed[R.rule.None]) do
				if v == cards[1] then c1 = k end
				if v == cards[2] then c2 = k break end
			end
			if c1 and c2 then
				local testCards = {cards[1], cards[2], dispatchcard}
				if ruleHelp:testRulesCard(R.rule.Wei, cardMgr.all, testCards) then
					table.sort(testCards, function(a,b) return a<b end)
					table.insert(cardMgr.showed[R.rule.Wei], testCards)
					table.remove(cardMgr.handed[R.rule.None], c2)
					table.remove(cardMgr.handed[R.rule.None], c1)
					return rt, R.rule.None
				end
			end
		end
	
	elseif R.rule.Kan == rt then
		if #cards == 3 then
			local c1, c2, c3
			local kanIndex
			for k,v in pairs(cardMgr.handed[R.rule.Kan]) do
				for kk,vv in pairs(v) do
					if vv == cards[1] then c1 = k end
					if vv == cards[2] then c2 = k end
					if vv == cards[3] then c3 = k end
				end
				if c1 and c2 and c3 then
					kanIndex = k
					break
				end
			end
			if c1 and c2 and c3 then
				local testCards = {cards[1], cards[2], cards[3]}
				if ruleHelp:testRulesCard(R.rule.Kan, cardMgr.all, testCards) then
					table.sort(testCards, function(a,b) return a<b end)
					table.insert(cardMgr.showed[R.rule.Kan], testCards)
					table.remove(cardMgr.handed[R.rule.Kan], kanIndex)
					return rt, R.rule.Kan
				end
			end
		end
		
	elseif R.rule.Wei_chou == rt then
		if #cards == 2 then
			local c1, c2
			for k,v in pairs(cardMgr.handed[R.rule.None]) do
				if v == cards[1] then c1 = k end
				if v == cards[2] then c2 = k break end
			end
			if c1 and c2 then
				local testCards = {cards[1], cards[2], dispatchcard}
				if ruleHelp:testRulesCard(R.rule.Wei, cardMgr.all, testCards) then
					table.sort(testCards, function(a,b) return a<b end)
					table.insert(cardMgr.showed[R.rule.Wei_chou], testCards)
					table.remove(cardMgr.handed[R.rule.None], c2)
					table.remove(cardMgr.handed[R.rule.None], c1)
					return rt, R.rule.None
				end
			end
		end
	
	elseif R.rule.Pao_kan == rt or R.rule.Pao_wei == rt or R.rule.Pao_peng == rt then
		if #cards == 3 then
			local showmap = {}
			showmap[R.rule.Pao_kan] = R.rule.Kan
			showmap[R.rule.Pao_wei] = R.rule.Wei
			showmap[R.rule.Pao_peng] = R.rule.Peng
			
			local ok
			table.sort(cards,function(a,b) return a<b end)
			for k,v in pairs(cardMgr.showed[showmap[rt]]) do				
				if cards[1] == v[1] and cards[2] == v[2] and cards[3] == v[3] then
					ok = k
					break
				end
			end
			
			if ok then
				local testCards = {cards[1], cards[2], cards[3], dispatchcard}
				if ruleHelp:testRulesCard(R.rule.Pao, cardMgr.all, testCards) then
					table.insert(cardMgr.showed[rt], testCards)
					table.remove(cardMgr.showed[showmap[rt]], ok)
					return rt, showmap[rt]
				end
			end
		end
		
	elseif R.rule.Ti_zimo == rt then
		if #cards == 4 then
			local ok
			table.sort(cards,function(v1,v2) return v1 < v2 end)
			for k,v in pairs(cardMgr.handed[R.rule.Ti_zimo]) do
				if cards[1] == v[1] and cards[2] == v[2] and cards[3] == v[3] and cards[4] == v[4] then
					ok = k
					break
				end
			end
			if ok then
				local testCards = {cards[1], cards[2], cards[3], cards[4]}
				if ruleHelp:testRulesCard(R.rule.Ti, cardMgr.all, testCards) then
					table.insert(cardMgr.showed[R.rule.Ti_zimo], testCards)
					table.remove(cardMgr.handed[R.rule.Ti_zimo], ok)
					return rt, R.rule.Ti_zimo
				end
			end
		end
	
	elseif R.rule.Ti_kan == rt or R.rule.Ti_wei == rt then
		if #cards == 3 then
			local showmap = {}
			showmap[R.rule.Ti_kan] = R.rule.Kan
			showmap[R.rule.Ti_wei] = R.rule.Wei
			local ok 
			table.sort(cards,function(v1,v2) return v1 < v2 end)
			for k,v in pairs(cardMgr.showed[showmap[rt]]) do
				if cards[1] == v[1] and cards[2] == v[2] and cards[3] == v[3] then
					ok = k
					break
				end
			end
			
			if ok then
				local testCards = {cards[1], cards[2], cards[3], dispatchcard}
				if ruleHelp:testRulesCard(R.rule.Ti, cardMgr.all, testCards) then
					table.insert(cardMgr.showed[rt], testCards)
					table.remove(cardMgr.showed[showmap[rt]], ok)
					return rt, showmap[rt]
				end
			end
		end
	
	elseif R.rule.None then
		if #cards == 1 then
			for k,v in pairs(cardMgr.handed[R.rule.None]) do
				if cards[1] == v then
					table.insert(cardMgr.showed[R.rule.None], v)
					table.remove(cardMgr.handed[R.rule.None], k)
					return rt, R.rule.None
				end
			end
		end
	end
end

function cardMgr:dispatchMyCard(card, isSystemCard)
	local res = {}	
	if #cardMgr.history == 0 and not isSystemCard then
		if #cardMgr.handed[R.rule.Ti_zimo] > 0 then
			res[R.rule.Ti_zimo] = {}
			for l,v in pairs(cardMgr.handed[R.rule.Ti_zimo]) do
				table.insert(res[R.rule.Ti_zimo], {v[1], v[2], v[3], v[4]})
			end
		end
		
		if #cardMgr.handed[R.rule.Kan] > 0 then
			res[R.rule.Kan] = {}
			for l,v in pairs(cardMgr.handed[R.rule.Kan]) do
				table.insert(res[R.rule.Kan], {v[1], v[2], v[3]})
			end
		end
		
	else
		local rulemap = {}
		if cardMgr.wufuBaojingIndex then
			rulemap[#rulemap+1] = {R.rule.Ti_kan, R.rule.Ti, cardMgr.showed[R.rule.Kan]}
			rulemap[#rulemap+1] = {R.rule.Ti_wei, R.rule.Ti, cardMgr.showed[R.rule.Wei]}
			if isSystemCard then rulemap[#rulemap+1] = {R.rule.Pao_peng, R.rule.Pao, cardMgr.showed[R.rule.Peng]} end
			
			local isWeichou
			for k,v in pairs(cardMgr.choupaid[R.rule.Peng]) do
				if v.value == cardMgr.all[card].value and v.capital == cardMgr.all[card].capital then
					rulemap[#rulemap+1] = {R.rule.Wei_chou, R.rule.Wei, cardMgr.handed[R.rule.None]}
					isWeichou = true
					break
				end
			end
			if not isWeichou then rulemap[#rulemap+1] = {R.rule.Wei, R.rule.Wei, cardMgr.handed[R.rule.None]} end
		else
			rulemap[#rulemap+1] = {R.rule.Ti_kan, R.rule.Ti, cardMgr.showed[R.rule.Kan]}
			rulemap[#rulemap+1] = {R.rule.Ti_wei, R.rule.Ti, cardMgr.showed[R.rule.Wei]}
			if isSystemCard then rulemap[#rulemap+1] = {R.rule.Pao_peng, R.rule.Pao, cardMgr.showed[R.rule.Peng]} end
			rulemap[#rulemap+1] = {R.rule.Chi, R.rule.Chi, cardMgr.handed[R.rule.None]}
			
			local isWeichou
			for k,v in pairs(cardMgr.choupaid[R.rule.Peng]) do
				if v.value == cardMgr.all[card].value and v.capital == cardMgr.all[card].capital then
					rulemap[#rulemap+1] = {R.rule.Wei_chou, R.rule.Wei, cardMgr.handed[R.rule.None]}
					isWeichou = true
					break
				end
			end
			if not isWeichou then rulemap[#rulemap+1] = {R.rule.Wei, R.rule.Wei, cardMgr.handed[R.rule.None]} end
		end
		
		
		for k,v in pairs(rulemap) do
			local rulecards = ruleHelp:makeRulesCard(v[2], cardMgr.all, v[3], card)
			if #rulecards > 0 then
				res[v[1]] = {}
				for kk,vv in pairs(rulecards) do 
					table.insert(res[v[1]], vv)
				end
			end
		end
	end
	
	return res
end

function cardMgr:dispatchOtherCard(localsite, cardSite, card, isSystemCard)
	local res = {}

	local rulemap = {}
	if cardMgr.wufuBaojingIndex then 
		rulemap[#rulemap+1] = {R.rule.Peng, R.rule.Peng, cardMgr.handed[R.rule.None]}
		rulemap[#rulemap+1] = {R.rule.Pao_kan, R.rule.Pao, cardMgr.showed[R.rule.Kan]}
		rulemap[#rulemap+1] = {R.rule.Pao_wei, R.rule.Pao, cardMgr.showed[R.rule.Wei]}
		if isSystemCard then rulemap[#rulemap+1] = {R.rule.Pao_peng, R.rule.Pao, cardMgr.showed[R.rule.Peng]} end
	else
		rulemap[#rulemap+1] = {R.rule.Peng, R.rule.Peng, cardMgr.handed[R.rule.None]}
		rulemap[#rulemap+1] = {R.rule.Pao_kan, R.rule.Pao, cardMgr.showed[R.rule.Kan]}
		rulemap[#rulemap+1] = {R.rule.Pao_wei, R.rule.Pao, cardMgr.showed[R.rule.Wei]}
		if isSystemCard then rulemap[#rulemap+1] = {R.rule.Pao_peng, R.rule.Pao, cardMgr.showed[R.rule.Peng]} end
		rulemap[#rulemap+1] = {R.rule.Chi, R.rule.Chi, cardMgr.handed[R.rule.None]}
	end
	
	for k,v in pairs(rulemap) do
		local rulecards = ruleHelp:makeRulesCard(v[2], cardMgr.all, v[3], card)
		if #rulecards > 0 then
			res[v[1]] = {}
			for kk,vv in pairs(rulecards) do 
				table.insert(res[v[1]], vv)
			end
		end
	end
	
	return res
end

function cardMgr:getHupaiType(isZhuang, addCards)
	--if cardMgr.showed[R.rule.Ti_zimo] and #cardMgr.showed[R.rule.Ti_zimo] >= 2 and dispatchCardCount == 1 then
	--	return isZhuang and R.wintype.wufu or R.wintype.dihu
	--	
	--else
	--	return R.wintype.none
	--end

	return ruleHelp:getHupaiType(self, cardMgr.all, isZhuang, addCards)
end

function cardMgr:checkWufuBaojing()
	if cardMgr.wantWufuBaojingIndex == 0 then
		local res = ruleHelp:checkWufuBaojing(cardMgr.history, cardMgr.handed[R.rule.None], cardMgr.all)
		return res
	end
	return false
end

function cardMgr:isWufuBaojing()
	return cardMgr.wufuBaojingIndex
end
function cardMgr:neverWufuBaojing(baojing)
	cardMgr.wantWufuBaojingIndex = baojing and 1 or -1
	cardMgr.wufuBaojingIndex = baojing
end

function cardMgr:canPayCardAfterRule(r)
	if r == R.rule.Ti or r == R.rule.Ti_zimo or r == R.rule.Ti_kan or r == R.rule.Ti_wei or
		r == R.rule.Pao or r == R.rule.Pao_kan or r == R.rule.Pao_wei or r == R.rule.Pao_peng then
		local cnt = #cardMgr.showed[R.rule.Ti] + #cardMgr.showed[R.rule.Ti_zimo] + #cardMgr.showed[R.rule.Ti_kan] + #cardMgr.showed[R.rule.Ti_wei]
		cnt = cnt + #cardMgr.showed[R.rule.Pao] + #cardMgr.showed[R.rule.Pao_kan] + #cardMgr.showed[R.rule.Pao_wei] + #cardMgr.showed[R.rule.Pao_peng]
		return cnt <= 1
	end
	
	return true
end

function cardMgr:choupai(rule, paycard)
	if cardMgr.choupaid[rule] then
		local card = cardMgr.all[paycard]
		if card then
			table.insert(cardMgr.choupaid[rule], {value=card.value, capital=card.capital})
		end
	end
end

function cardMgr:canChiWithPay(cards, playerSite, curPaysite)
	local function checkChoupai()
		if #cardMgr.choupaid[R.rule.Chi] == 0 then
			return false
		end
		for k,v in pairs(cards) do
			for kk,vv in pairs(v) do
				for ck,cv in pairs(cardMgr.choupaid[R.rule.Chi]) do
					if cv.value == cardMgr.all[vv].value and cv.capital == cardMgr.all[vv].capital then
						return true
					end
				end
			end
		end
	end
	
	if playerSite == curPaysite then
		return not checkChoupai()
	end
	
	local nextSite = (curPaysite + 1)%(R.MAX_PLAYER_COUNT)
	nextSite = nextSite == 0 and 4 or nextSite
	if playerSite == nextSite then
		return not checkChoupai()
	end
end

function cardMgr:getBestHupaiType()
	return ruleHelp:getBestHupaiType(cardMgr.owncards, #cardMgr.handed[R.rule.Ti_zimo])
end

function cardMgr:removeSingleShowCard(cid)
	if cid and cid > 0 then
		for i=1,#cardMgr.showed[R.rule.None] do
			if cardMgr.showed[R.rule.None][i] == cid then
				table.remove(cardMgr.showed[R.rule.None], i)
				return true
			end
		end
	end
	return false
end

function cardMgr:addPengRuleSingleCard(cid)
	table.insert(cardMgr.PengRuleSingleCard, cid)
end
function cardMgr:getPengRuleSingleCard()
	local res = {}
	for k,v in pairs(cardMgr.PengRuleSingleCard) do
		res[#res+1] = v
	end
	return res
end


return cardMgr
