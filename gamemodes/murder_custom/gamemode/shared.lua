GM.Name 	= "MurderCustom"
GM.Author 	= "MechanicalMind"
-- credits to Minty Fresh for some styling on the scoreboard
-- credits to Waddlesworth for the logo and menu icon
GM.Email 	= ""
GM.Website 	= "www.codingconcoctions.com/murder/"
GM.Version = "30"

function GM:SetupTeams()
	team.SetUp(1, translate.teamSpectators, Color(150, 150, 150))
	team.SetUp(2, translate.teamPlayers, Color(26, 120, 245))
end
GM:SetupTeams()

GM.Round = {
	NotEnoughPlayers = 0, // not enough players
	Playing = 1,  // playing
	RoundEnd = 2, // 2 round ended, about to restart
	MapSwitch = 4, // 4 waiting for map switch
	RoundStarting = 5 // 5 waiting to start new round after enough players
}

function GM:GetNextLootReward(loot)
	loot = math.max(0, loot or 0)
	if loot < 5 then return 5 end
	return (math.floor(loot / 15) + 1) * 15
end

assert(GM:GetNextLootReward(0) == 5 && GM:GetNextLootReward(5) == 15 && GM:GetNextLootReward(15) == 30,
	"loot reward thresholds are invalid")
