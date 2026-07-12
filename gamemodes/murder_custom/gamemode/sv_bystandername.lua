local EntityMeta = FindMetaTable("Entity")

function EntityMeta:GenerateBystanderName()
	self:SetBystanderName(self:Nick())
end

function EntityMeta:SetBystanderName(name)
	self:SetNWString("bystanderName", name)
	self.BystanderName = name
end

function EntityMeta:GetBystanderName()
	local name = self:GetNWString("bystanderName")
	if !name || name == "" then
		return self:IsPlayer() and self:Nick() or "Bystander"
	end
	return name
end

concommand.Add("mu_print_players", function (admin, com, args)
	if !admin:IsAdmin() then return end

	for k, ply in pairs(player.GetAll()) do
		local c = ChatText()
		c:Add(ply:Nick())
		c:Add(" " .. ply:SteamID())
		c:Add(" " .. team.GetName(ply:Team()), team.GetColor(ply:Team()))
		c:Send(admin)
	end
end)
