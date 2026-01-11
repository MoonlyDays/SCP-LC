SWEP.Base 			= "weapon_scp_base"
SWEP.PrintName		= "SCP-1987-J"
SWEP.HoldType		= "normal"
SWEP.ScoreOnDamage 	= true

--Ability cooldowns and parameters
SWEP.JumpscareCooldown = 4
SWEP.JumpscareDamage = 35
SWEP.JumpscareRange = 80

SWEP.PowerOutageCooldown = 50
SWEP.PowerOutageRadius = 600

SWEP.ShowtimeCooldown = 100
SWEP.ShowtimeWindup = 3
SWEP.ShowtimeDamage = 150
SWEP.ShowtimeRadius = 350

SWEP.NightPerformerSpeedBonus = 1.15

/*
	Passive - Night Performer: +15% speed in dark areas; Animatronic Stealth: quieter footsteps
	LMB - Jumpscare: close-range attack with frighten effect
	RMB - Power Outage: blackout effect to nearby players
	Special - Showtime!: wind-up invulnerable burst attack
*/

function SWEP:SetupDataTables()
	self:CallBaseClass( "SetupDataTables" )
	self:NetworkVar( "Bool", "ShowtimeActive" )
	self:NetworkVar( "Float", "NextPowerOutage" )
	self:NetworkVar( "Float", "ShowtimeEnd" )
	self:NetworkVar( "Float", "NightBonus" )
end

function SWEP:Initialize()
	self:SetHoldType( self.HoldType )
	self:InitializeLanguage( "SCP1987J" )
	self:InitializeHUD()
end

function SWEP:Think()
	if ROUND.preparing or ROUND.post then return end

	local ct = CurTime()
	local owner = self:GetOwner()

	if self:GetShowtimeActive() and self:GetShowtimeEnd() <= ct then
		self:DoShowtimeBurst()
		self:SetShowtimeActive( false )
	end

	if SERVER and ( !self.NextLightCheck or self.NextLightCheck <= ct ) then
		self.NextLightCheck = ct + 0.5
		self:UpdateNightPerformer( owner )
	end
end

function SWEP:UpdateNightPerformer( owner )
	local light = render and render.GetLightColor and render.GetLightColor( owner:GetPos() + Vector( 0, 0, 40 ) ) or Vector( 1, 1, 1 )
	local brightness = ( light.x + light.y + light.z ) / 3

	if brightness < 0.3 then
		self:SetNightBonus( self.NightPerformerSpeedBonus )
		owner:PushSpeed( self.NightPerformerSpeedBonus, self.NightPerformerSpeedBonus, -1, "SLC_NightPerformer", 1, true )
	else
		self:SetNightBonus( 1 )
		owner:PopSpeed( "SLC_NightPerformer" )
	end
end

local attack_trace = {}
attack_trace.mins = Vector( -10, -10, -10 )
attack_trace.maxs = Vector( 10, 10, 10 )
attack_trace.mask = MASK_SHOT
attack_trace.output = attack_trace

function SWEP:PrimaryAttack()
	if ROUND.preparing or ROUND.post or self:GetShowtimeActive() then return end

	self:SetNextPrimaryFire( CurTime() + self.JumpscareCooldown * self:GetUpgradeMod( "jumpscare_cd", 1 ) )

	if !SERVER then return end

	local owner = self:GetOwner()
	local spos = owner:GetShootPos()

	attack_trace.start = spos
	attack_trace.endpos = spos + owner:GetAimVector() * self.JumpscareRange
	attack_trace.filter = owner

	owner:LagCompensation( true )
	util.TraceHull( attack_trace )
	owner:LagCompensation( false )

	local ent = attack_trace.Entity
	if IsValid( ent ) and ent:IsPlayer() and self:CanTargetPlayer( ent ) then
		owner:EmitSound( "SCP19870J.Jumpscare" )

		local dmg = DamageInfo()
		dmg:SetDamage( self.JumpscareDamage * self:GetUpgradeMod( "jumpscare_dmg", 1 ) )
		dmg:SetDamageType( DMG_SLASH )
		dmg:SetAttacker( owner )
		dmg:SetInflictor( self )
		ent:TakeDamageInfo( dmg )

		ent:ApplyEffect( "frightened" )
	else
		owner:EmitSound( "SCP1987J.SwingMiss" )
	end

	AddRoundStat( "1987j" )
end

function SWEP:SecondaryAttack()
	if ROUND.preparing or ROUND.post or self:GetShowtimeActive() then return end

	local ct = CurTime()
	if self:GetNextPowerOutage() > ct then return end

	self:SetNextPowerOutage( ct + self.PowerOutageCooldown * self:GetUpgradeMod( "power_cd", 1 ) )

	if !SERVER then return end

	local owner = self:GetOwner()
	local pos = owner:GetPos()
	local radius = self.PowerOutageRadius * self:GetUpgradeMod( "power_radius", 1 )

	owner:EmitSound( "SCP1987J.PowerOutage" )

	for i, v in ipairs( player.GetAll() ) do
		if self:CanTargetPlayer( v ) and v:GetPos():Distance( pos ) <= radius then
			v:ApplyEffect( "scp1987j_blackout" )
		end
	end
end

function SWEP:SpecialAttack()
	if ROUND.preparing or ROUND.post or self:GetShowtimeActive() then return end

	local ct = CurTime()
	if self:GetNextSpecialAttack() > ct then return end

	self:SetNextSpecialAttack( ct + self.ShowtimeCooldown * self:GetUpgradeMod( "showtime_cd", 1 ) )
	self:SetShowtimeActive( true )
	self:SetShowtimeEnd( ct + self.ShowtimeWindup )

	if !SERVER then return end

	local owner = self:GetOwner()
	owner:DisableControls( "scp1987j_showtime", CAMERA_MASK )
	owner:GodEnable()
	owner:EmitSound( "SCP1987J.Showtime" )
end

function SWEP:DoShowtimeBurst()
	if !SERVER then return end

	local owner = self:GetOwner()
	local pos = owner:GetPos()
	local radius = self.ShowtimeRadius * self:GetUpgradeMod( "showtime_radius", 1 )
	local damage = self.ShowtimeDamage * self:GetUpgradeMod( "showtime_dmg", 1 )

	owner:StopDisableControls( "scp1987j_showtime" )
	owner:GodDisable()
	owner:EmitSound( "SCP1987J.ShowtimeBurst" )

	for i, v in ipairs( player.GetAll() ) do
		if !self:CanTargetPlayer( v ) then continue end

		local dist = v:GetPos():Distance( pos )
		if dist > radius then continue end

		local scale = 1 - ( dist / radius ) * 0.5
		local dmg = DamageInfo()
		dmg:SetDamage( damage * scale )
		dmg:SetDamageType( DMG_SONIC )
		dmg:SetAttacker( owner )
		dmg:SetInflictor( self )

		v:TakeDamageInfo( dmg )
		v:ApplyEffect( "frightened" )
	end
end

function SWEP:OnRemove()
	if !SERVER then return end

	local owner = self:GetOwner()
	if !IsValid( owner ) then return end

	owner:PopSpeed( "SLC_NightPerformer" )
	owner:StopDisableControls( "scp1987j_showtime" )
	owner:GodDisable()
end

--[[-------------------------------------------------------------------------
SCP Hooks
---------------------------------------------------------------------------]]
SCPHook( "SCP1987J", "SLCPlayerFootstep", function( ply, foot, snd )
	if ply:SCPClass() != CLASSES.SCP1987J then return end
	ply:EmitSound( "SCP1987J.Footstep", 55 )
	return true
end )

SCPHook( "SCP1987J", "EntityTakeDamage", function( ent, dmg )
	if dmg:IsDamageType( DMG_DIRECT ) or !IsValid( ent ) or !ent:IsPlayer() or ent:SCPClass() != CLASSES.SCP1987J then return end

	local wep = ent:GetSCPWeapon()
	if IsValid( wep ) and wep:GetShowtimeActive() then
		return true
	end
end )

--[[-------------------------------------------------------------------------
Upgrade system
---------------------------------------------------------------------------]]
local icons = {}

if CLIENT then
	icons.jumpscare = GetMaterial( "slc/hud/upgrades/scp/1987j/jumpscare.png", "smooth" )
	icons.power = GetMaterial( "slc/hud/upgrades/scp/1987j/power.png", "smooth" )
	icons.showtime = GetMaterial( "slc/hud/upgrades/scp/1987j/showtime.png", "smooth" )
end

DefineUpgradeSystem( "scp1987j", {
	grid_x = 3,
	grid_y = 3,
	upgrades = {
		{ name = "jumpscare1", cost = 1, req = {}, reqany = false, pos = { 1, 1 },
			mod = { jumpscare_cd = 0.8 }, icon = icons.jumpscare },
		{ name = "jumpscare2", cost = 2, req = { "jumpscare1" }, reqany = false, pos = { 1, 2 },
			mod = { jumpscare_dmg = 1.25 }, icon = icons.jumpscare },

		{ name = "power1", cost = 1, req = {}, reqany = false, pos = { 2, 1 },
			mod = { power_cd = 0.85 }, icon = icons.power },
		{ name = "power2", cost = 2, req = { "power1" }, reqany = false, pos = { 2, 2 },
			mod = { power_radius = 1.25 }, icon = icons.power },

		{ name = "showtime1", cost = 2, req = {}, reqany = false, pos = { 3, 1 },
			mod = { showtime_cd = 0.85 }, icon = icons.showtime },
		{ name = "showtime2", cost = 2, req = { "showtime1" }, reqany = false, pos = { 3, 2 },
			mod = { showtime_dmg = 1.3, showtime_radius = 1.2 }, icon = icons.showtime },

		{ name = "outside_buff", cost = 1, req = {}, reqany = false, pos = { 2, 3 }, mod = {}, active = false },
	},
	rewards = {
		{ 100, 1 },
		{ 200, 1 },
		{ 350, 1 },
		{ 500, 1 },
		{ 700, 1 },
	}
}, SWEP )

--[[-------------------------------------------------------------------------
SCP HUD
---------------------------------------------------------------------------]]
if CLIENT then
	local hud = SCPHUDObject( "SCP1987J", SWEP )
	hud:AddCommonSkills()

	hud:AddSkill( "jumpscare" )
		:SetButton( "attack" )
		:SetMaterial( "slc/hud/scp/1987j/jumpscare.png", "smooth" )
		:SetCooldownFunction( "GetNextPrimaryFire" )

	hud:AddSkill( "power_outage" )
		:SetButton( "attack2" )
		:SetMaterial( "slc/hud/scp/1987j/power.png", "smooth" )
		:SetCooldownFunction( "GetNextPowerOutage" )

	hud:AddSkill( "showtime" )
		:SetButton( "scp_special" )
		:SetMaterial( "slc/hud/scp/1987j/showtime.png", "smooth" )
		:SetCooldownFunction( "GetNextSpecialAttack" )

	hud:AddBar( "showtime_bar" )
		:SetMaterial( "slc/hud/scp/1987j/showtime.png", "smooth" )
		:SetColor( Color( 255, 180, 0 ) )
		:SetTextFunction( function( swep )
			local time = swep:GetShowtimeEnd() - CurTime()
			return string.format( "%.1fs", math.max( time, 0 ) )
		end )
		:SetProgressFunction( function( swep )
			return ( swep:GetShowtimeEnd() - CurTime() ) / swep.ShowtimeWindup
		end )
		:SetVisibleFunction( "GetShowtimeActive" )

	hud:AddBar( "night_bonus" )
		:SetMaterial( "slc/hud/scp/1987j/night.png", "smooth" )
		:SetColor( Color( 100, 100, 200 ) )
		:SetTextFunction( function( swep )
			local bonus = swep:GetNightBonus()
			return bonus > 1 and ( "+" .. math.Round( ( bonus - 1 ) * 100 ) .. "%" ) or ""
		end )
		:SetProgressFunction( function( swep )
			return swep:GetNightBonus() > 1 and 1 or 0
		end )
		:SetVisibleFunction( function( swep )
			return swep:GetNightBonus() > 1
		end )
end

--[[-------------------------------------------------------------------------
Sounds
---------------------------------------------------------------------------]]
sound.Add( {
	name = "SCP1987J.Jumpscare",
	volume = 1,
	level = 80,
	pitch = { 95, 105 },
	sound = "ambient/machines/thumper_hit.wav",
	channel = CHAN_WEAPON,
} )

sound.Add( {
	name = "SCP1987J.SwingMiss",
	volume = 0.8,
	level = 70,
	pitch = { 90, 110 },
	sound = "npc/zombie/claw_miss1.wav",
	channel = CHAN_WEAPON,
} )

sound.Add( {
	name = "SCP1987J.PowerOutage",
	volume = 1,
	level = 85,
	pitch = 100,
	sound = "ambient/energy/spark6.wav",
	channel = CHAN_STATIC,
} )

sound.Add( {
	name = "SCP1987J.Showtime",
	volume = 1,
	level = 90,
	pitch = 100,
	sound = "ambient/machines/combine_shield_touch_loop1.wav",
	channel = CHAN_STATIC,
} )

sound.Add( {
	name = "SCP1987J.ShowtimeBurst",
	volume = 1,
	level = 100,
	pitch = { 90, 100 },
	sound = "ambient/explosions/explode_8.wav",
	channel = CHAN_STATIC,
} )

sound.Add( {
	name = "SCP1987J.Footstep",
	volume = 0.5,
	level = 55,
	pitch = { 85, 95 },
	sound = "npc/zombie/foot1.wav",
	channel = CHAN_BODY,
} )
