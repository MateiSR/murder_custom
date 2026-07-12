if SERVER then
	AddCSLuaFile()
else
	function SWEP:DrawWeaponSelection( x, y, w, h, alpha )
	end
end

SWEP.Base = "weapon_mers_base"
SWEP.VariantConVar = "mu_magnum_variant"
SWEP.Slot = 1
SWEP.SlotPos = 1
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true

SWEP.ViewModel = "models/weapons/c_357.mdl"
SWEP.WorldModel = "models/weapons/w_357.mdl"
SWEP.ViewModelFlip = false

SWEP.Variants = {
	{
		name = "Magnum",
		view = "models/weapons/c_357.mdl",
		world = "models/weapons/w_357.mdl",
		fov = 50,
		hold = "revolver",
		draw = "draw",
		idle = "idle01",
		attack = "fire",
		reload = "reload",
		sound = "Weapon_357.Single",
		reloadSound = "Weapon_357.Reload"
	},
	{
		name = "Hunting Bow",
		view = "models/weapons/v_huntingbow.mdl",
		world = "models/weapons/w_huntingbow.mdl",
		fov = 68,
		hold = "crossbow",
		draw = "draw",
		idle = "idle_armed",
		attack = "shoot",
		reload = "lowered_to_idle",
		sound = "weapons/huntingbow/shoot_1.wav",
		reloadSound = "weapons/huntingbow/nock_1.wav"
	},
	{
		name = "Minecraft Bow",
		view = "models/weapons/c_crossbow.mdl",
		world = "models/weapons/w_crossbow.mdl",
		fov = 73,
		hold = "crossbow",
		draw = "deploy",
		idle = "idle",
		attack = "fire",
		reload = "reload",
		sound = "weapons/crossbow/fire1.wav",
		reloadSound = "weapons/crossbow/reload1.wav"
	},
	{
		name = "Desert Eagle Blaze",
		view = "models/weapons/v_glax_deagle.mdl",
		world = "models/weapons/w_glax_deagle.mdl",
		fov = 70,
		hold = "pistol",
		draw = "draw",
		idle = "idle1",
		attack = "shoot1",
		reload = "reload",
		sound = "weapons/glagle/deagle-1.wav",
		reloadSound = "weapons/glagle/de_clipin.wav"
	},
	{
		name = "USP-S Orion",
		view = "models/weapons/v_pist_usp.mdl",
		world = "models/weapons/w_pist_usp_silencer.mdl",
		fov = 60,
		hold = "pistol",
		draw = "draw",
		idle = "idle",
		attack = "shoot1",
		reload = "reload",
		sound = "weapons/usp/usp1.wav",
		reloadSound = "weapons/usp/usp_clipin.wav"
	},
	{
		name = "Five-SeveN Monkey Business",
		view = "models/weapons/c_csgo_fn.mdl",
		world = "models/weapons/csgo_world/w_pist_fiveseven.mdl",
		fov = 45,
		hold = "pistol",
		draw = "draw",
		idle = "idle",
		attack = "shoot1",
		reload = "reload",
		sound = "csgo/fiveseven/fiveseven-1.wav",
		reloadSound = "csgo/fiveseven/fiveseven_clipin.wav"
	}
}

SWEP.HoldType = "revolver"
SWEP.SequenceDraw = "draw"
SWEP.SequenceIdle = "idle01"
SWEP.SequenceHolster = "holster"

SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Automatic = false
SWEP.Primary.Sound = "Weapon_357.Single"
SWEP.Primary.Sequence = "fire"
-- SWEP.Primary.Delay = 0.
SWEP.Primary.Damage = 200
SWEP.Primary.Cone = 0
SWEP.Primary.DryFireSequence = "fireempty"
SWEP.Primary.DryFireSound = Sound("Weapon_Pistol.Empty")
SWEP.Primary.Recoil = 9
SWEP.Primary.InfiniteAmmo = true
SWEP.Primary.AutoReload = true


SWEP.ReloadSequence = "reload"
SWEP.ReloadSound = Sound("Weapon_357.Reload")

SWEP.PrintName = translate and translate.magnum or "Magnum"
function SWEP:Initialize()
	self.BaseClass.Initialize(self)
	self.PrintName = translate and translate.magnum or "Magnum"
	self:SetClip1(self:GetMaxClip1())
end

function SWEP:DoPrimaryAttackEffect(stats)
	local bullet = {}	-- Set up the shot
	bullet.Num = self.Primary.NumShots or 1
	bullet.Src = self.Owner:GetShootPos()
	bullet.Dir = self.Owner:GetAimVector()
	bullet.Spread = Vector(stats.cone or 0, stats.cone or 0, 0)
	bullet.Tracer = 1
	bullet.Force = self.Primary.Force or ((self.Primary.Damage or 1) * 3)
	bullet.Damage = stats.damage or 1
	self.Owner:FireBullets(bullet)
end
