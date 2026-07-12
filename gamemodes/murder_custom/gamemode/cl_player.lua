local PlayerMeta = FindMetaTable("Player")
local EntityMeta = FindMetaTable("Entity")

CreateClientConVar("mu_knife_variant", "1", true, true)
CreateClientConVar("mu_magnum_variant", "1", true, true)

local weaponMenu
local weaponPickers = {
	{
		label = "weaponPickerKnife",
		class = "weapon_mu_knife",
		convar = "mu_knife_variant",
		id = 0
	},
	{
		label = "weaponPickerMagnum",
		class = "weapon_mu_magnum",
		convar = "mu_magnum_variant",
		id = 1
	}
}

function GM:OpenWeaponMenu()
	if IsValid(weaponMenu) then
		weaponMenu:SetVisible(true)
		weaponMenu:MakePopup()
		return
	end

	weaponMenu = vgui.Create("DFrame")
	weaponMenu:SetSize(420, 210)
	weaponMenu:Center()
	weaponMenu:SetTitle(translate.weaponPickerTitle)
	weaponMenu:SetDeleteOnClose(false)
	weaponMenu:MakePopup()
	weaponMenu:DockPadding(12, 32, 12, 12)

	local help = vgui.Create("DLabel", weaponMenu)
	help:Dock(TOP)
	help:SetText(translate.weaponPickerHelp)
	help:SetTextColor(color_white)
	help:SizeToContentsY()
	help:DockMargin(0, 0, 0, 8)

	for k, config in ipairs(weaponPickers) do
		local class = config.class
		local convar = config.convar
		local id = config.id
		local stored = weapons.GetStored(class)
		local variants = stored && stored.Variants or {}
		local selected = GetConVar(convar):GetInt()

		local label = vgui.Create("DLabel", weaponMenu)
		label:Dock(TOP)
		label:SetText(translate[config.label])
		label:SetTextColor(color_white)
		label:SizeToContentsY()

		local combo = vgui.Create("DComboBox", weaponMenu)
		combo:Dock(TOP)
		combo:SetTall(24)
		combo:DockMargin(0, 2, 0, 8)

		for index, variant in ipairs(variants) do
			combo:AddChoice(variant.name, index)
		end

		local current = variants[selected]
		if !current then
			selected = 1
			current = variants[1]
			RunConsoleCommand(convar, "1")
		end
		combo:SetValue(current && current.name or "")

		function combo:OnSelect(index, value, data)
			RunConsoleCommand(convar, tostring(data))
			net.Start("mu_weapon_variant")
			net.WriteUInt(id, 1)
			net.WriteUInt(data, 8)
			net.SendToServer()
		end
	end
end

concommand.Add("mu_weapon_menu", function ()
	GAMEMODE:OpenWeaponMenu()
end)

hook.Add("InitPostEntity", "MurderWeaponMenu", function ()
	GAMEMODE:OpenWeaponMenu()
end)

function GM:PlayerFootstep(ply, pos, foot, sound, volume, filter)
	self:FootStepsFootstep(ply, pos, foot, sound, volume, filter)

end

function EntityMeta:GetPlayerColor()
	return self:GetNWVector("playerColor") or Vector()
end

function EntityMeta:GetBystanderName()
	local name = self:GetNWString("bystanderName")
	if !name || name == "" then
		return self:IsPlayer() and self:Nick() or "Bystander"
	end
	return name
end
