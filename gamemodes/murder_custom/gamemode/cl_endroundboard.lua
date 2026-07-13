
local menu
local awardText = {
	caseClosed = {"endroundAwardCaseClosed", "endroundAwardCaseClosedDetail"},
	clutchShot = {"endroundAwardClutchShot", "endroundAwardClutchShotDetail"},
	perfectCrime = {"endroundAwardPerfectCrime", "endroundAwardPerfectCrimeDetail"},
	coldOpen = {"endroundAwardColdOpen", "endroundAwardColdOpenDetail"},
	lootGoblin = {"endroundAwardLootGoblin", "endroundAwardLootGoblinDetail"},
	oshaViolation = {"endroundAwardOshaViolation", "endroundAwardOshaViolationDetail"},
	speedrun = {"endroundAwardSpeedrun", "endroundAwardSpeedrunDetail"}
}

function GM:DisplayEndRoundBoard(data)
	if IsValid(menu) then
		menu:Remove()
	end

	menu = vgui.Create("DFrame")
	menu:SetSize(ScrW() * 0.8, ScrH() * 0.8)
	menu:Center()
	menu:SetTitle("")
	menu:MakePopup()
	menu:SetKeyboardInputEnabled(false)
	menu:SetDeleteOnClose(false)

	function menu:Paint()
		surface.SetDrawColor(Color(40,40,40,255))
		surface.DrawRect(0, 0, menu:GetWide(), menu:GetTall())
	end

	local winnerPnl = vgui.Create("DPanel", menu)
	winnerPnl:DockPadding(24,24,24,24)
	winnerPnl:Dock(TOP)
	function winnerPnl:PerformLayout()
		self:SizeToChildren(false, true)
	end
	function winnerPnl:Paint(w, h) 
		surface.SetDrawColor(Color(50,50,50,255))
		surface.DrawRect(2, 2, w - 4, h - 4)
	end

	local winner = vgui.Create("DLabel", winnerPnl)
	winner:Dock(TOP)
	winner:SetFont("MersRadialBig")
	winner:SetAutoStretchVertical(true)

	if data.reason == 3 then
		winner:SetText(translate.endroundMurdererQuit)
		winner:SetTextColor(Color(255, 255, 255))
	elseif data.reason == 2 then
		winner:SetText(translate.endroundBystandersWin)
		winner:SetTextColor(Color(20, 120, 255))
	elseif data.reason == 1 then
		winner:SetText(translate.endroundMurdererWins)
		winner:SetTextColor(Color(190, 20, 20))
	end

	local murdererPnl = vgui.Create("DPanel", winnerPnl)
	murdererPnl:Dock(TOP)
	murdererPnl:SetTall(draw.GetFontHeight("MersRadialSmall"))
	function murdererPnl:Paint()
	end

	if data.murdererName then
		local col = data.murdererColor
		local msgs = Translator:AdvVarTranslate(translate.endroundMurdererWas, {
			murderer = {text = data.murdererName, color = Color(col.x * 255, col.y * 255, col.z * 255)}
		})

		for k, msg in pairs(msgs) do
			local was = vgui.Create("DLabel", murdererPnl)
			was:Dock(LEFT)
			was:SetText(msg.text)
			was:SetFont("MersRadialSmall")
			was:SetTextColor(msg.color or color_white)
			was:SetAutoStretchVertical(true)
			was:SizeToContentsX()
		end
	end

	local highlightsPnl = vgui.Create("DPanel", menu)
	highlightsPnl:Dock(FILL)
	highlightsPnl:DockPadding(24,24,24,24)
	function highlightsPnl:Paint(w, h)
		surface.SetDrawColor(Color(50,50,50,255))
		surface.DrawRect(2, 2, w - 4, h - 4)
	end

	local desc = vgui.Create("DLabel", highlightsPnl)
	desc:Dock(TOP)
	desc:SetFont("MersRadial")
	desc:SetAutoStretchVertical(true)
	desc:SetText(translate.endroundHighlights)
	desc:SetTextColor(color_white)

	local awardList = vgui.Create("DPanelList", highlightsPnl)
	awardList:Dock(FILL)
	awardList:SetSpacing(4)

	if #data.awards == 0 then
		local empty = vgui.Create("DLabel", awardList)
		empty:SetTall(draw.GetFontHeight("MersRadialSmall") + 24)
		empty:SetFont("MersRadialSmall")
		empty:SetText(translate.endroundNoHighlights)
		empty:SetTextColor(Color(180, 180, 180))
		empty:SetContentAlignment(5)
		awardList:AddItem(empty)
	end

	for k, v in ipairs(data.awards) do
		local text = awardText[v.id]
		if !text then continue end

		local pnl = vgui.Create("DPanel")
		pnl:SetTall(draw.GetFontHeight("MersRadial") + draw.GetFontHeight("MersRadialSmall") + 24)
		function pnl:Paint(w, h)
			surface.SetDrawColor(Color(44, 44, 44, 255))
			surface.DrawRect(0, 2, w, h - 4)
		end
		function pnl:PerformLayout()
			if self.NamePnl then
				self.NamePnl:SetWidth(self:GetWide() * 0.6)
			end
		end

		local title = vgui.Create("DLabel", pnl)
		title:Dock(TOP)
		title:DockMargin(12, 6, 12, 0)
		title:SetFont("MersRadial")
		title:SetText(translate[text[1]])
		title:SetTextColor(v.id == "oshaViolation" and Color(220, 80, 80) or Color(255, 190, 70))
		title:SetAutoStretchVertical(true)

		if v.playerName != "" then
			local name = vgui.Create("DButton", pnl)
			pnl.NamePnl = name
			name:Dock(LEFT)
			name:DockMargin(12, 0, 0, 6)
			name:SetText(v.playerName)
			name:SetFont("MersRadialSmall")
			local col = v.playerColor
			name:SetTextColor(Color(col.x * 255, col.y * 255, col.z * 255))
			name:SetContentAlignment(4)
			function name:Paint() end
			function name:DoClick()
				if IsValid(v.player) then
					GAMEMODE:DoScoreboardActionPopup(v.player)
				end
			end
		end

		local detail = vgui.Create("DLabel", pnl)
		detail:Dock(FILL)
		detail:DockMargin(12, 0, 12, 6)
		detail:SetFont("MersRadialSmall")
		detail:SetText(Translator:VarTranslate(translate[text[2]], {
			count = tostring(v.value),
			seconds = tostring(v.value)
		}))
		detail:SetTextColor(Color(210, 210, 210))
		detail:SetContentAlignment(6)

		awardList:AddItem(pnl)
	end

end

net.Receive("reopen_round_board", function ()
	if IsValid(menu) then
		menu:SetVisible(true)
	end
end)
