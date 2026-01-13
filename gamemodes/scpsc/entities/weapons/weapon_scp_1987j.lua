SWEP.Base = "weapon_scp_base"
SWEP.PrintName = "SCP-1987-J"
SWEP.HoldType = "normal"
SWEP.ScoreOnDamage = true
--Ability cooldowns and parameters
SWEP.JumpscareCooldown = 4
SWEP.JumpscareDamage = 35
SWEP.JumpscareRange = 80
SWEP.PowerOutageCooldown = 50
SWEP.PowerOutageRadius = 600
SWEP.PowerOutageDoorRadius = 400
SWEP.PowerOutageDischargeAmount = 50
SWEP.NightPerformerSpeedBonus = 1.15

--[[
	Passive - Night Performer: +15% speed in dark areas; Animatronic Stealth: quieter footsteps
	LMB - Jumpscare: close-range attack with frighten effect
	RMB - (unused)
	Special - Power Outage: blackout effect, force close nearby doors, discharge chargeable items
]]

function SWEP:SetupDataTables()
	self:CallBaseClass("SetupDataTables")
	self:NetworkVar("Float", "NightBonus")
end

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
	self:InitializeLanguage("SCP1987J")
	self:InitializeHUD()
end

function SWEP:Think()
	if ROUND.preparing or ROUND.post then return end
	local ct = CurTime()
	local owner = self:GetOwner()

	if SERVER and (not self.NextLightCheck or self.NextLightCheck <= ct) then
		self.NextLightCheck = ct + 0.5
		self:UpdateNightPerformer(owner)
	end
end

function SWEP:UpdateNightPerformer(owner)
	local light = render and render.GetLightColor and render.GetLightColor(owner:GetPos() + Vector(0, 0, 40)) or Vector(1, 1, 1)
	local brightness = (light.x + light.y + light.z) / 3
	if brightness < 0.3 then
		self:SetNightBonus(self.NightPerformerSpeedBonus)
		owner:PushSpeed(self.NightPerformerSpeedBonus, self.NightPerformerSpeedBonus, -1, "SLC_NightPerformer", 1, true)
	else
		self:SetNightBonus(1)
		owner:PopSpeed("SLC_NightPerformer")
	end
end

local attack_trace = {}
attack_trace.mins = Vector(-10, -10, -10)
attack_trace.maxs = Vector(10, 10, 10)
attack_trace.mask = MASK_SHOT
attack_trace.output = attack_trace
function SWEP:PrimaryAttack()
	if ROUND.preparing or ROUND.post then return end
	self:SetNextPrimaryFire(CurTime() + self.JumpscareCooldown * self:GetUpgradeMod("jumpscare_cd", 1))
	if not SERVER then return end
	local owner = self:GetOwner()
	local spos = owner:GetShootPos()
	attack_trace.start = spos
	attack_trace.endpos = spos + owner:GetAimVector() * self.JumpscareRange
	attack_trace.filter = owner
	owner:LagCompensation(true)
	util.TraceHull(attack_trace)
	owner:LagCompensation(false)
	local ent = attack_trace.Entity
	if IsValid(ent) and ent:IsPlayer() and self:CanTargetPlayer(ent) then
		owner:EmitSound("SCP1987J.Jumpscare")
		local dmg = DamageInfo()
		dmg:SetDamage(self.JumpscareDamage * self:GetUpgradeMod("jumpscare_dmg", 1))
		dmg:SetDamageType(DMG_SLASH)
		dmg:SetAttacker(owner)
		dmg:SetInflictor(self)
		ent:TakeDamageInfo(dmg)
		ent:ApplyEffect("frightened")
	else
		owner:EmitSound("SCP1987J.SwingMiss")
	end

	AddRoundStat("1987j")
end

function SWEP:SecondaryAttack()
end

function SWEP:SpecialAttack()
	if ROUND.preparing or ROUND.post then return end
	local ct = CurTime()
	if self:GetNextSpecialAttack() > ct then return end
	self:SetNextSpecialAttack(ct + self.PowerOutageCooldown * self:GetUpgradeMod("power_cd", 1))
	if not SERVER then return end
	local owner = self:GetOwner()
	local pos = owner:GetPos()
	local radius = self.PowerOutageRadius * self:GetUpgradeMod("power_radius", 1)
	local doorRadius = self.PowerOutageDoorRadius * self:GetUpgradeMod("power_door_radius", 1)
	local dischargeAmount = self.PowerOutageDischargeAmount * self:GetUpgradeMod("power_discharge", 1)

	owner:EmitSound("SCP1987J.PowerOutage")

	-- Apply blackout effect to nearby players and discharge their items
	for i, v in ipairs(player.GetAll()) do
		if not self:CanTargetPlayer(v) then continue end
		if v:GetPos():Distance(pos) > radius then continue end

		v:ApplyEffect("scp1987j_blackout")

		-- Discharge all battery-powered items in player's inventory
		for _, wep in ipairs(v:GetWeapons()) do
			if wep.HasBattery and wep.GetBattery and wep.SetBattery then
				local currentBattery = wep:GetBattery()
				local newBattery = math.max(0, currentBattery - dischargeAmount)
				wep:SetBattery(newBattery)
			end
		end
	end

	-- Force close nearby doors
	for _, ent in ipairs(ents.FindInSphere(pos, doorRadius)) do
		local class = ent:GetClass()
		if class == "func_door" or class == "func_door_rotating" then
			ent:Fire("close")
		end
	end
end

function SWEP:OnRemove()
	if not SERVER then return end
	local owner = self:GetOwner()
	if not IsValid(owner) then return end
	owner:PopSpeed("SLC_NightPerformer")
end

--[[-------------------------------------------------------------------------
SCP Hooks
---------------------------------------------------------------------------]]
SCPHook("SCP1987J", "SLCPlayerFootstep", function(ply, foot, snd)
	if ply:SCPClass() ~= CLASSES.SCP1987J then return end
	ply:EmitSound("MetalVent.StepLeft", 55)
	return true
end)

--[[-------------------------------------------------------------------------
Upgrade system
---------------------------------------------------------------------------]]
local icons = {}
if CLIENT then
	icons.jumpscare = GetMaterial("slc/hud/upgrades/scp/1987j/jumpscare.png", "smooth")
	icons.power = GetMaterial("slc/hud/upgrades/scp/1987j/power.png", "smooth")
end

DefineUpgradeSystem("scp1987j", {
	grid_x = 3,
	grid_y = 3,
	upgrades = {
		{
			name = "jumpscare1",
			cost = 1,
			req = {},
			reqany = false,
			pos = {1, 1},
			mod = {
				jumpscare_cd = 0.8
			},
			icon = icons.jumpscare
		},
		{
			name = "jumpscare2",
			cost = 2,
			req = {"jumpscare1"},
			reqany = false,
			pos = {1, 2},
			mod = {
				jumpscare_dmg = 1.25
			},
			icon = icons.jumpscare
		},
		{
			name = "power1",
			cost = 1,
			req = {},
			reqany = false,
			pos = {2, 1},
			mod = {
				power_cd = 0.85
			},
			icon = icons.power
		},
		{
			name = "power2",
			cost = 2,
			req = {"power1"},
			reqany = false,
			pos = {2, 2},
			mod = {
				power_radius = 1.25,
				power_door_radius = 1.25
			},
			icon = icons.power
		},
		{
			name = "power3",
			cost = 2,
			req = {"power2"},
			reqany = false,
			pos = {2, 3},
			mod = {
				power_discharge = 1.5
			},
			icon = icons.power
		},
		{
			name = "outside_buff",
			cost = 1,
			req = {},
			reqany = false,
			pos = {3, 2},
			mod = {},
			active = false
		},
	},
	rewards = {{100, 1}, {200, 1}, {350, 1}, {500, 1}, {700, 1},}
}, SWEP)

--[[-------------------------------------------------------------------------
SCP HUD
---------------------------------------------------------------------------]]
if CLIENT then
	local hud = SCPHUDObject("SCP1987J", SWEP)
	hud:AddCommonSkills()
	hud:AddSkill("jumpscare"):SetButton("attack"):SetMaterial("slc/hud/scp/049/choke.png", "smooth"):SetCooldownFunction("GetNextPrimaryFire")
	hud:AddSkill("power_outage"):SetButton("scp_special"):SetMaterial("slc/hud/scp/049/choke.png", "smooth"):SetCooldownFunction("GetNextSpecialAttack")

	hud:AddBar("night_bonus"):SetMaterial("slc/hud/scp/049/choke.png", "smooth"):SetColor(Color(100, 100, 200)):SetTextFunction(function(swep)
		local bonus = swep:GetNightBonus()
		return bonus > 1 and ("+" .. math.Round((bonus - 1) * 100) .. "%") or ""
	end):SetProgressFunction(function(swep) return swep:GetNightBonus() > 1 and 1 or 0 end):SetVisibleFunction(function(swep) return swep:GetNightBonus() > 1 end)
end

--[[-------------------------------------------------------------------------
Sounds
---------------------------------------------------------------------------]]
sound.Add({
	name = "SCP1987J.Jumpscare",
	volume = 1,
	level = 80,
	pitch = {95, 105},
	sound = "ambient/machines/thumper_hit.wav",
	channel = CHAN_WEAPON,
})

sound.Add({
	name = "SCP1987J.SwingMiss",
	volume = 0.8,
	level = 70,
	pitch = {90, 110},
	sound = "npc/zombie/claw_miss1.wav",
	channel = CHAN_WEAPON,
})

sound.Add({
	name = "SCP1987J.PowerOutage",
	volume = 1,
	level = 85,
	pitch = 100,
	sound = "ambient/energy/spark6.wav",
	channel = CHAN_STATIC,
})

sound.Add({
	name = "SCP1987J.Footstep",
	volume = 0.5,
	level = 55,
	pitch = {85, 95},
	sound = "npc/zombie/foot1.wav",
	channel = CHAN_BODY,
})