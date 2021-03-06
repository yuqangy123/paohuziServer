local ruleHelp = {}
local R = {}
local ruleMake = {}

function ruleHelp:setR(r)
	R=r
end

--根据散牌整理出规则牌
function ruleHelp:tidyHandCards(handcards)
	
	table.sort(handcards,function(v1,v2)
		return v1:values() < v2:values()
    end)
	
	
	local ruleCards = {}
	ruleCards[R.rule.Ti_zimo] = {}--提
	ruleCards[R.rule.Kan] = {}--坎
	ruleCards[R.rule.None] = {}
	
	
	--1,4,5,9,9,9,10
	local i = 1
	local handCnt = #handcards
	while(i <= (handCnt-3) )
	do
		local ok = true
		local card = handcards[i]
		local kanIndex = 0
		for j=1, 3 do
			if handcards[i+j].value ~= card.value or handcards[i+j].capital ~= card.capital then
				ok = false
				break
			end
			
			if j == 2 then
				kanIndex = i+j
			end
		end
		
		if ok then
			table.insert(ruleCards[R.rule.Ti_zimo], {handcards[i].id, handcards[i+1].id, handcards[i+2].id, handcards[i+3].id})
			i = i + 3
		elseif kanIndex ~= 0 then
			table.insert(ruleCards[R.rule.Kan], {handcards[kanIndex-2].id, handcards[kanIndex-1].id, handcards[kanIndex-0].id})
			i = i + 2
		else
			i = i + 1
		end
	end	
	if handcards[handCnt-2]:equal(handcards[handCnt-1]) and handcards[handCnt-1]:equal(handcards[handCnt-0]) then
		table.insert(ruleCards[R.rule.Kan], {handcards[handCnt-2].id, handcards[handCnt-1].id, handcards[handCnt-0].id})
	end
	
	local tmpCards = {}
	for i=1, handCnt do
		local r = false
		for k,v in pairs(ruleCards[R.rule.Ti_zimo]) do
			for kk,vv in pairs(v) do
				if handcards[i].id == vv then 
					r = true 
					break 
				end
			end
			if r then
				break
			end
		end
		if not r then
			for k,v in pairs(ruleCards[R.rule.Kan]) do
				for kk,vv in pairs(v) do
					if handcards[i].id == vv then 
						r = true 
						break 
					end
				end
				if r then
					break
				end
			end
		end
		if not r then
			ruleCards[R.rule.None][#ruleCards[R.rule.None]+1] = handcards[i].id
		end
	end
	
	
	
	return ruleCards
end



function ruleMake:findChi(ids, cards, card)
	local tmpCards = {}
	local valueList = {}
	local res = {}
	local keyId = card
	
	local ccnt = #cards
	if keyId then ccnt=ccnt+1 end
	if ccnt < 3 then
		return res
	end
	
	for k,v in pairs(cards) do
		if not tmpCards[ids[v].value] then tmpCards[ids[v].value] = {} valueList[#valueList+1]=ids[v].value end
		table.insert(tmpCards[ids[v].value], ids[v])
	end
	if keyId then
		if not tmpCards[ids[keyId].value] then  tmpCards[ids[keyId].value] = {} valueList[#valueList+1]=ids[keyId].value end
		table.insert(tmpCards[ids[keyId].value], ids[keyId])
	end
	
	table.sort(valueList, function(a,b)return a<b end)
	
	for i=1,#valueList do
		local clist = tmpCards[valueList[i]]
		
		if #clist >= 3 then
			for j=1, #clist-2 do
				for k=j+1, #clist-1 do
					for n=k+1, #clist do
						if clist[j].capital ~= clist[k].capital or clist[j].capital ~= clist[n].capital then
							table.insert(res, {clist[j].id, clist[k].id, clist[n].id})
						end
					end
				end
			end
		end
		
		local a = tmpCards[valueList[i]+0]
		local b = tmpCards[valueList[i]+1]
		local c = tmpCards[valueList[i]+2]
		local fcap = nil
		if b and c then
			for k,v in pairs(a) do
				fcap = v.capital
				local bcard = nil
				for bk,bv in pairs(b) do
					if fcap == bv.capital then
						bcard = bv
						for ck,cv in pairs(c) do
							if fcap == cv.capital then
								ccard = cv
								table.insert(res, {v.id, bcard.id, ccard.id})
							end
						end
					end
				end
				
			end
		end
	end
	
	if tmpCards[R.value.v2] and tmpCards[R.value.v7] and tmpCards[R.value.v10] then
		for k,v in pairs(tmpCards[R.value.v2]) do
			local cap = v.capital
			local bcard = nil
			for k7,v7 in pairs(tmpCards[R.value.v7]) do
				if v7.capital == cap then
					bcard = v7
					break
				end
			end
			local ccard = nil
			for k10,v10 in pairs(tmpCards[R.value.v10]) do
				if v10.capital == cap then
					ccard = v10
					break
				end
			end
			if bcard and ccard then
				table.insert(res, {v.id, bcard.id, ccard.id})
			end
		end
	end
	
	--移除跟key不相关的
	local pos = 0
	while keyId and true do
		pos = pos + 1
		if pos > #res then 
			break
		end
		if res[pos][1] ~= keyId and res[pos][2] ~= keyId and res[pos][3] ~= keyId then
			table.remove(res, pos)
			pos = 0
		end
	end
	
	--移除重复的组合
	table.sort(res, function(a,b) return ids[a[1]].value < ids[b[1]].value end)
	pos = 0
	while true do
		pos = pos + 1
		if pos > #res-1 then break end
		
		if ids[res[pos][1]]:equal(ids[res[pos+1][1]]) and 
			ids[res[pos][2]]:equal(ids[res[pos+1][2]]) and
				ids[res[pos][3]]:equal(ids[res[pos+1][3]]) then
			table.remove(res, pos)
			pos = 0
		end
	end
	
	return res	
end

function ruleMake:Chi(ids, cards, card)
	local resrule = {}
	local keyCardCnt = 1
	for k,v in pairs(cards) do
		if ids[v]:equal(ids[card]) then
			keyCardCnt = keyCardCnt+1
		end
	end
	
	
	local rulelist = ruleMake:findChi(ids, cards, card)
	for k,v in pairs(rulelist) do
		local rulekeyCnt = 0
		for kk,vv in pairs(v) do
			if ids[vv]:equal(ids[card]) then rulekeyCnt = rulekeyCnt+1 end
		end
		if rulekeyCnt == keyCardCnt then resrule[#resrule+1]={v[1],v[2],v[3]} end
	end
	
	if keyCardCnt == 1 then
		return resrule
		
	elseif keyCardCnt == 3 then
		resrule = {}
		for k,v in pairs(rulelist) do
			local subcards = {}
			for i=1,#cards do subcards[#subcards+1]=cards[i] end
			for kk,vv in pairs(v) do
				for i=1,#subcards do if subcards[i] == vv then table.remove(subcards,i) break end end
			end
			local ecard = 0
			for i=1,#subcards do if ids[subcards[i]]:equal(ids[card]) then ecard = subcards[i] table.remove(subcards,i) break end end
			local subres = ruleMake:Chi(ids, subcards, ecard)
			for kk,vv in pairs(subres) do
				if #vv == 6 then
					resrule[#resrule+1] = {v[1],v[2],v[3],vv[1],vv[2],vv[3],vv[4],vv[5],vv[6]}
					return resrule
				end
			end
		end
		return resrule
	else
		local frule = ruleMake:findChi(ids, cards)
		
		for k,v in pairs(frule) do
			for ck,cv in pairs(v) do
				if ids[cv]:equal(ids[card]) then
					local filterCards = {}
					for csk,csv in pairs(cards) do
						if csv ~= v[1] and csv ~= v[2] and csv ~= v[3] then
							table.insert(filterCards, csv)
						end
					end
					local subrule = ruleMake:findChi(ids, filterCards, card)
					if #subrule > 0 then
						resrule[#resrule+1] = {v[1], v[2], v[3], subrule[1][1], subrule[1][2], subrule[1][3]}
					end
					break
				end
			end
		end
		
		
		local i = #resrule
		--[[
		while true do
			if i < 1 then break end
			if #resrule[i] ~= keyCardCnt*3 then
				table.remove(resrule, i)
				i = #resrule
			else
				i=i-1
			end
		end
		]]--
		i = 1
		local j = i+1
		while true do
			if j > #resrule then
				i=i+1
				j=i+1
			end
			if #resrule < 2 or i >= #resrule then break end
			
			local ca = 0
			local cb = 0
			for k,v in pairs(resrule[j]) do ca = ca + ids[v]:values()  end
			for k,v in pairs(resrule[i]) do cb = cb + ids[v]:values()  end
			
			if ca ~= 0 and ca == cb then
				table.remove(resrule, j)
				j=i+1
			else
				j=j+1
			end
		end
		
		return resrule
	end
end

function ruleMake:Peng(ids, cards, card)
	local tmpCards = {}
	local res = {}
	local keyId = card
	
	for k,v in pairs(cards) do table.insert(tmpCards, ids[v]) end
	table.insert(tmpCards, ids[keyId])
	
	table.sort(tmpCards,function(v1,v2)
		return v1:values() < v2:values()
    end)
	
	local pos = 1
	while pos <= (#tmpCards-2) do
        if tmpCards[pos].value == tmpCards[pos+1].value and tmpCards[pos].value == tmpCards[pos+2].value then
			if tmpCards[pos].capital == tmpCards[pos+1].capital and tmpCards[pos].capital == tmpCards[pos+2].capital then
				table.insert(res, {tmpCards[pos].id, tmpCards[pos+1].id, tmpCards[pos+2].id})
			end
		end
        pos = pos + 1
    end
	
	pos = 0
	while true do
		pos = pos + 1
		if pos > #res then 
			break
		end
		if res[pos][1] ~= keyId and res[pos][2] ~= keyId and res[pos][3] ~= keyId then
			table.remove(res, pos)
			pos = 0
		end
	end
	return res
end

function ruleMake:TiPao(ids, cards, card)
	local res = {}
	
	for k,v in pairs(cards) do
		if ids[v[1]]:equal(ids[card]) and ids[v[2]]:equal(ids[card]) and ids[v[3]]:equal(ids[card]) then
			table.insert(res, {v[1], v[2], v[3], card})
		end
	end
	
	return res
end


function ruleHelp:getHupaiType(cardMgr, ids, isZhuang, addCards)
	local res = {}
	local handcards = {}
	for k,v in pairs(cardMgr.handed[R.rule.None]) do 
		table.insert(handcards, ids[v]) 
	end
	if addCards then
		for k,v in pairs(addCards) do
			table.insert(handcards, ids[v])
		end
	end
	table.sort(handcards, function (v1,v2) return v1:values() < v2:values() end)
	
	
	local cardthree = 0
	for k,v in pairs(cardMgr.history) do
		if v.payrule == R.rule.Kan or v.payrule == R.rule.Wei or v.payrule == R.rule.Wei_chou or v.payrule == R.rule.Peng or v.payrule == R.rule.Ti or v.payrule == R.rule.Ti_zimo then
			cardthree = cardthree + 1
		end
	end
	--[[
	print("cardthree", cardMgr.wufuBaojingIndex, cardthree)
	local desc = ""
	for k,v in pairs(handcards) do
		desc = desc .. (v.capital and "B" or "S") .. v.value .. ","
	end
	print(desc)
	]]--
	--五福
	if cardMgr.wufuBaojingIndex and cardthree == 5 then
		return R.wintype.wufu
	end

	--五福跑双
	--if cardMgr.wufuBaojingIndex and cardthree == 4 and ruleHelp:noneSingle(handcards) then
	--	return R.wintype.paoshuang
	--end

	if not cardMgr.wufuBaojingIndex and cardthree == 4 and ruleHelp:noneSingle(handcards) then
		return R.wintype.siqinglianhu
	end	
	
	--平胡
	if not cardMgr.wufuBaojingIndex and ruleHelp:noneSingle(handcards) then
		if cardthree == 3 then
			return R.wintype.sandalianhu
		else
			return R.wintype.pinghu
		end
	end
	
	return R.wintype.none
end

function ruleHelp:getBestHupaiType(handcards, TizimoCnt)
	--qidui
	if #handcards >= 14 then
		local cardtwo = 0
		local noneCards = {}
		for k,v in pairs(handcards) do 
			local values = v:values()
			if not noneCards[values] then noneCards[values] = {} end
			table.insert(noneCards[values],v)
		end
		for k,v in pairs(noneCards) do if #v >= 2 then cardtwo=cardtwo+1 end end
		if cardtwo >= 7 then
			return R.wintype.qidui
		end
	end
	
	--tianhu
	if ruleHelp:noneSingle(handcards) then
		return R.wintype.tianhu
	end
	
	--shuanglong
	if TizimoCnt == 2 then
		return R.wintype.shuanglong
	end
	
	return R.wintype.none
end

function ruleHelp:noneSingle(cards, haveYidui)
	table.sort(cards, function(a,b) return a.value<b.value end)
	local cardcnt = #cards
	if cardcnt == 0 then return true  end
	if cardcnt == 1 then return false  end
	
	local remains = {}
	local idx=1
	local acard = cards[idx]
	local bcard = {value=acard.value+1, capital=acard.capital, id=0}
	local ccard = {value=acard.value+2, capital=acard.capital, id=0}
	idx=2
	while( idx <= cardcnt ) do--顺序吃，组合成员固定
		if bcard.id == 0 then
			if cards[idx].value == bcard.value and cards[idx].capital == bcard.capital then
				bcard.id = cards[idx].id
			else
				remains[#remains+1]=cards[idx]
			end			
		elseif ccard.id == 0 then
			if cards[idx].value == ccard.value and cards[idx].capital == ccard.capital then
				ccard.id = cards[idx].id
				break
			else
				remains[#remains+1]=cards[idx]
			end
		end
		idx=idx+1
	end
	if bcard.id > 0 and ccard.id > 0 then
		for i=idx+1,cardcnt do remains[#remains+1]=cards[i] end
		if ruleHelp:noneSingle(remains, haveYidui) then return true end
	end
	
	local keyvalue = R.value.v2
	if acard.value == R.value.v2 then--2710，组合成员固定
		idx=2
		local keycapital = acard.capital
		keyvalue = R.value.v7
		remains = {}
		while( idx <= cardcnt ) do
			if keycapital == cards[idx].capital and keyvalue == cards[idx].value then
				if keyvalue == R.value.v7 then
					keyvalue = R.value.v10
				elseif keyvalue == R.value.v10 then
					keyvalue = nil
					break
				end
			else
				remains[#remains+1]=cards[idx]
			end
			idx=idx+1
		end
	end
	if not keyvalue then
		for i=idx+1,cardcnt do remains[#remains+1]=cards[i] end
		if ruleHelp:noneSingle(remains, haveYidui) then return true end
	end
	
	
	acard = cards[1]
	idx=2
	local vlist = {}
	remains = {}
	while( idx <= cardcnt and cards[idx].value == acard.value ) do--大小三搭，组合成员bu固定，例如d1d1s1,d1s1s1，碰也可以一起检测
		vlist[#vlist+1] = cards[idx]
		idx = idx + 1
	end
	
	
	for i=idx,cardcnt do remains[#remains+1]=cards[i] end	
	for i=1, #vlist do
		for j=i+1, #vlist do
			local checklist={}
			for k=1, #vlist do
				if k ~= i and k ~= j then
					remains[#remains+1]=cards[k]
					checklist[#checklist+1]=cards[k]
				end
			end
			
			if ruleHelp:noneSingle(remains, haveYidui) then
				return true
			else
				for is=1,#checklist do
					for js=1,#remains do
						if checklist[is].id == remains[js].id then
							table.remove(remains, js)
							break
						end
					end
				end
			end
		end
	end
	
	if cards[1].value == cards[2].value and cards[1].capital == cards[2].capital then--唯一一对
		remains = {}
		for i=3,cardcnt do remains[#remains+1]=cards[i] end
		if not haveYidui then
			haveYidui = true
			if ruleHelp:noneSingle(remains, haveYidui) then return true end
		end
	end
end
--[[
function ruleHelp:testHupai(handed, ids, payCard)
	local headCards = {}
	
	for k,v in pairs(handed) do
		table.insert(headCards, ids[v])
	end
	if payCard then table.insert(headCards, ids[payCard]) end
		
	table.sort(headCards, function (v1, v2)
		return v1:values() < v2:values()
	end)
	
	return ruleHelp:noneSingle(headCards)
end
--]]

--增加一张addcard牌，放到cards里面，能否产出rule的规则牌
function ruleHelp:makeRulesCard(rule, ids, cards, addcard)
	if R.rule.Chi == rule then
		return ruleMake:Chi(ids, cards, addcard)
		
	elseif R.rule.Peng == rule then
		return ruleMake:Peng(ids, cards, addcard)
		
	elseif R.rule.Wei == rule then
		return ruleMake:Peng(ids, cards, addcard)
		
	elseif R.rule.Ti == rule or R.rule.Pao == rule then
		return ruleMake:TiPao(ids, cards, addcard)

	--elseif R.rule.Hupai == rule then
		--return ruleMake:Hupai(ids, cardMgr, addcard)
		
	end
	
	return {}
end

function ruleMake:Chi_test(ids, cards)
	local res = ruleMake:findChi(ids, cards)
	return #res > 0
end

function ruleMake:Peng_test(ids, cards)
	local tmpCards = {}
	
	if #cards ~= 3 then
		return false
	end
		
	for k,v in pairs(cards) do table.insert(tmpCards, ids[v]) end
	table.sort(tmpCards,function(v1,v2)
			return v1:values() < v2:values()
		end)
	
	if tmpCards[1].value == tmpCards[2].value and tmpCards[1].value == tmpCards[3].value then
		if tmpCards[1].capital == tmpCards[2].capital and tmpCards[1].capital == tmpCards[3].capital then
			return true
		end
	end
end

function ruleMake:TiPao_test(ids, cards)
	local tmpCards = {}
	local res = {}
	
	for k,v in pairs(cards) do table.insert(tmpCards, ids[v]) end
	table.sort(tmpCards,function(v1,v2)
			return v1:values() < v2:values()
		end)
	
	
	if #cards == 4 then
		if tmpCards[1].value == tmpCards[2].value and tmpCards[1].value == tmpCards[3].value and tmpCards[1].value == tmpCards[4].value then
			if tmpCards[1].capital == tmpCards[2].capital and tmpCards[1].capital == tmpCards[3].capital and tmpCards[1].capital == tmpCards[4].capital then
				return true
			end
		end
	end
end

function ruleHelp:testRulesCard(rule, ids, cards)
	
	if R.rule.Chi == rule then
		return ruleMake:Chi_test(ids, cards)
		
	elseif R.rule.Peng == rule or R.rule.Wei == rule or R.rule.Kan == rule then
		return ruleMake:Peng_test(ids, cards)
		
	elseif R.rule.Ti == rule or R.rule.Pao == rule then
		return ruleMake:TiPao_test(ids, cards, card)

	end
	
end

function ruleHelp:isForceRule1(rule)
	return 	rule == R.rule.Ti or 
			rule == R.rule.Ti_zimo or
			rule == R.rule.Ti_kan or
			rule == R.rule.Ti_wei or
			rule == R.rule.Kan or
			rule == R.rule.Wei or 
			rule == R.rule.Wei_chou
end
function ruleHelp:isForceRule2(rule)
	return 	rule == R.rule.Pao or 
			rule == R.rule.Pao_kan or 
			rule == R.rule.Pao_wei or 
			rule == R.rule.Pao_peng
end

function ruleHelp:compareRuleLevel(r1, r2)
	return tonumber(r1) > tonumber(r2)
end

--是否需要显示系统发的牌
function ruleHelp:hideSystemCard(rule)
	return rule == R.rule.Ti_zimo or
			rule == R.rule.Wei or
			rule == R.rule.Wei_chou
end

function ruleHelp:checkWufuBaojing(history, hands, ids)
	local threeCnt = 0
	for k,v in pairs(history) do
		if v.payrule == R.rule.Ti_zimo or v.payrule == R.rule.Kan or v.payrule == R.rule.Wei or v.payrule == R.rule.Wei_chou or v.payrule == R.rule.Peng then
			threeCnt = threeCnt + 1
		end
	end
	
	local twoIndex = nil
	local tmpcards = {}
	for i=1, #hands do
		if not tmpcards[ids[hands[i]]:values()] then tmpcards[ids[hands[i]]:values()] = 0 end
		tmpcards[ids[hands[i]]:values()] = tmpcards[ids[hands[i]]:values()] + 1
		if tmpcards[ids[hands[i]]:values()] > 1 then
			twoIndex = true
			break
		end
	end
	
	return threeCnt == 4 and twoIndex
end

return ruleHelp
