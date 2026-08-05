
GM.RoundStage = 0
GM.LootCollected = 0
GM.RoundSettings = {}
if GAMEMODE then
	GM.RoundStage = GAMEMODE.RoundStage
	GM.LootCollected = GAMEMODE.LootCollected
	GM.RoundSettings = GAMEMODE.RoundSettings
end

function GM:GetRound()
	return self.RoundStage or 0
end

net.Receive("SetRound", function (length)
	local r = net.ReadUInt(8)
	local start = net.ReadDouble()
	GAMEMODE.RoundStage = r
	GAMEMODE.RoundStart = start
	GAMEMODE.RoundEndTime = net.ReadDouble()
	if GAMEMODE.RoundEndTime == 0 then GAMEMODE.RoundEndTime = nil end

	GAMEMODE.RoundSettings = {}
	local settings = net.ReadUInt(8)
	if settings != 0 then
		GAMEMODE.RoundSettings.ShowAdminsOnScoreboard = net.ReadUInt(8) != 0
		GAMEMODE.RoundSettings.AdminPanelAllowed = net.ReadUInt(8) != 0
		GAMEMODE.RoundSettings.ShowSpectateInfo = net.ReadUInt(8) != 0
		GAMEMODE.RoundSettings.ShowPlayerNames = net.ReadUInt(8) != 0
	end

	if r == GAMEMODE.Round.RoundStarting then
		GAMEMODE.StartNewRoundTime = net.ReadDouble()
	end

	GAMEMODE.RoundStartUnfreezeTime = net.ReadFloat()

	if r == GAMEMODE.Round.Playing then
		timer.Simple(0.2, function ()
			local pitch = math.random(70, 140)
			if IsValid(LocalPlayer()) then
				LocalPlayer():EmitSound("ambient/creatures/town_child_scream1.wav", 100, pitch)
			end
		end)
		GAMEMODE.LootCollected = 0
	end
end)

net.Receive("DeclareWinner" , function (length)
	local data = {}
	data.reason = net.ReadUInt(8)
	data.murderer = net.ReadEntity()
	data.murdererColor = net.ReadVector()
	data.murdererName = net.ReadString()

	data.awards = {}
	local awardCount = net.ReadUInt(2)
	for i = 1, awardCount do
		local t = {}
		t.id = net.ReadString()
		t.player = net.ReadEntity()
		t.playerName = net.ReadString()
		t.playerColor = net.ReadVector()
		t.value = net.ReadUInt(16)
		table.insert(data.awards, t)
	end

	GAMEMODE:DisplayEndRoundBoard(data)

	local pitch = math.random(80, 120)
	if IsValid(LocalPlayer()) then
		LocalPlayer():EmitSound("ambient/alarms/warningbell1.wav", 100, pitch)
	end
end)

net.Receive("GrabLoot", function (length)
	GAMEMODE.LootCollected = net.ReadUInt(32)
end)

net.Receive("SetLoot", function (length)
	GAMEMODE.LootCollected = net.ReadUInt(32)
end)
