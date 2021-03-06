local sprotoparser = require "sprotoparser"

local proto = {}

proto.c2s = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

heartbeat 1 {}


versionCheck 2{
	request {
		version	0 : integer
	}
	response {
        code 	0  : integer
	}
}

userLogin 3 {
	request {
		token 0 : string
	}
	response {
        code 	0  : integer
		pid		1  : integer
		nikename	2 : string
		ip 		3 : string
		roomid 	4 : integer
	}
}

userUnlogin 4 {
	request {
	}
}

errLog 5 {
	request {
		log		0 : string
	}
}

totalPush 6 {
	request {
		openid 		0 : string
		nickname 	1 : string
		sex 		2 : string
		headimgurl 	3 : string
		teststr 	4 : *string
		.PhoneNumber {
			number 0 : string
			type 1 : integer
		}
		testmsg		5 : *PhoneNumber
	}
	response {
        code 	0  : integer
		pid 	1  : integer
		nickname 	2 : string
		ip 		3 : string
		roomid 	4 : integer
	}
}

createRoom 7 {
	request {
		jushu 		0 : boolean
		zhongzhuang 	1 : boolean
		qiangzhihupai 	2 : boolean
	}
	response {
		code 	0  : integer
		roomid 	1 : integer
	}
}

roomExist 8 {
	request {
		roomid 	0 : integer
	}
	response {
		code 	0  : integer
	}
}

joinRoom 9 {
	request {
		roomid 	0 : integer
	}
}

rejoinRoom 10 {
	request {
	}
}

ready 11 {
	request {
	}
}

chat 12 {
	request {
	faceid 0 : integer
	}
}

payCard 13 {
	request {
		rule 	0 : string
		cid 	1 : string
	}
}

masterCheckoutRoom 14 {
	request {
	}
}

requestCheckoutRoom 15 {
	request {
	}
}

agreeCheckoutRoom 16 {
	request {
		code	0 : integer
	}
}

selectWufuBaojing 17 {
	request     {
		code 	0 : boolean
	}
}

playerStartGame 18 {
	request {
	}
}

gameRecord 19 {
	request {
	}
	response {
		rid		0 : string
		time	1 : string
		p1name	2 : string
		p1score	3 : string
		p2name	4 : string
		p2score	5 : string
		p3name	6 : string
		p3score	7 : string
		p4name	8 : string
		p4score	9 : string
	}
}

voice 20 {
	request {
		fileID	0 : string
		time	1 : integer
	}
}

]]

proto.s2c = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

heartbeat 1 {}

notice 2 {
	request     {
        noticeInfo 0 : string
	}
}

joinRoomNotify 3 {
	request     {
		code	0 : integer
		pid 	1 : *integer
		nickname 		2 : *string
		ip 				3 : *string
		sex 			4 : *string
		headimgurl 		5 : *string
		site 	6 : *string
		ready 	7 : *string
		score 	8 : *string
		totalScore 	9 : *string
		winCount	10 : *string
		zzCount 	11 : *string
		dpCount		12 : *string
		gameConfig 	13 : string
		roomid		14 : integer
		roommaster	15 : integer
		gamestate	16 : integer		
		isonline	17 : *string
	}
}

readyNotify 4 {
	request     {
		pid		0 : integer
		time 	1 : integer
	}
}

startNotify 5 {
	request     {
	}
}

roomCardInitNotify 6 {
	request     {
		pids 	0 : string
		hand 	1 : string
		rule 	2 : string
		single 	3 : string
		zhuangpid 	4 : integer
		remainsystemcards  	5 : integer
		reloadId 	6 : integer	
	}
}

reloadInfo 7 {
	request     {
		curPayPid	0 : integer
		lianzhuangCnt 	1 : integer
		gameCount	2 : integer
		curSystemPayCard	3 : integer
		pengSingleCard	4 : string
	}
}

chatNotify 8 {
	request     {
		faceid	0 : integer
		pid	1 : integer
	}
}

paySystemCardNotify 9 {
	request     {
		cid  	0 : integer
		pid	 	1 : integer
		show 	2 : boolean
	}
}

turnPlayerNotify 10 {
	request     {
		pid	 	0 : integer
	}
}

payCardNotify 11 {
	request     {
		pid	 	0 : integer
		cid  	1 : integer
		show 	2 : boolean
	}
}

ruleCardsPossible 12 {
	request     {
		pid	 	0 : integer
		rule  	1 : string
		cid  	2 : string
		ocid 	3 : string
	}
}

payRuleCardNotify 13 {
	request     {
		pid	 	0 : integer
		cid  	1 : string
		rule  	2 : string
		othercard	3 : integer
	}
}

payBillNotify 14 {
	request     {
		yieldPid	0 : integer
		yieldScore  1 : integer
		payBills  	2 : string
	}
}

wufuBaojingNotify 15 {
	request     {
		pid	 	0 : integer
	}
}

hupaiNotify 16 {
	request     {
		pid	 	0 : integer
		rule  	1 : string
		hupaiCard	2 : integer
		dpPid	3 : integer
		lianzhuangCount	4 : integer
		gameCount	5 : integer
		remaincards 6 : string
	}
}

hupaiReloadNotify 17 {
	request     {
		pid	 	0 : integer
		rule  	1 : string
		hupaiCard	2 : integer
		dpPid	3 : integer
		lianzhuangCount	4 : integer
		gameCount	5 : integer
		remaincards 6 : string
	}
}

gameFinishNotify 18 {
	request     {
	}
}

requestCheckoutRoomNotify 19 {
	request     {
	}
}

checkoutRoomNotify 20 {
	request     {
		code	0 : integer
	}
}

masterCheckoutRoomNotify 21 {
	request     {
	}
}

canWufuBaojing 22 {
	request     {
	}
}

playerOnlineChangeNotify 23 {
	request     {
		pid 	0 : integer
		code 	1 : integer
	}
}

voiceNotify 24{
	request {
		fileID	0 : string
		pid 	1 : integer
		time	2 : integer
	}
}

]]

return proto
