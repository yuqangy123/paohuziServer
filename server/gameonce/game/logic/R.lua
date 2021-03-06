local R = {}
R.value = {
	v1 = 1,
	v2 = 2,
	v3 = 3,
	v4 = 4,
	v5 = 5,
	v6 = 6,
	v7 = 7,
	v8 = 8,
	v9 = 9,
	v10 = 10,
}

R.GAME_STATE = {
	none = 0,
	waiting = 1,
	playing = 2,
	gameover = 3,
	gamefinish = 4
}

R.rule = {
	None = "0",
	Ti = "1",
	Ti_zimo = "2",
	Ti_kan = "3",
	Ti_wei = "4",
	Wei = "5",
	Wei_chou = "6",
	Kan = "7",
	Hupai = "8",
	Pao = "9",
	Pao_kan = "10",
	Pao_wei = "11",
	Pao_peng = "12",
	Chi = "13",
	Peng = "14",
	Chiyibisan = "15",
}

R.sMsg = {
	playerEnter = "playerEnter",
	playerReEnter = "playerReEnter",
	playerReady = "playerReady",
	startGame = "startGame",
	playerInitCards = "playerInitCards",
	playerReInitCards = "playerReInitCards",
	hupai = "hupai",
	hupaiReload = "hupaiReload",
	gameFinish = "gameFinish",
	turnPlayer = "turnPlayer",
	payCardPlayer = "payCardPlayer",
	payCardSystem = "payCardSystem",
	payRuleCardPlayer = "payRuleCardPlayer",
	ruleCardsPossible = "ruleCardsPossible",
	payBill = "payBill",
	playerChat = "playerChat",
	masterCheckoutRoom = "masterCheckoutRoom",
	wufuBaojing = "wufuBaojing",
	canWufuBaojing = "canWufuBaojing",
	playerOnlineChange = "playerOnlineChange",
	reloadInfo = "reloadInfo",
	voice = "voice",
}

R.wintype = {
	none = "none",
	hongzhuang = "hongzhuang",
	wufu = "wufu",
	paoshuang = "paoshuang",
	qidui = "qidui",
	shuanglong = "shuanglong",
	pinghu = "pinghu",
	zimo = "zimo",
	penghu = "penghu",
	paohu = "paohu",
	tihu = "tihu",
	tianhu = "tianhu",
	dihu = "dihu",
	sandalianhu = "sandalianhu",
	saosandalianhu = "saosandalianhu",
	siqinglianhu = "siqinglianhu",
	saosiqinglianhu = "saosiqinglianhu",
}

R.MAX_PLAYER_COUNT = 4

return R