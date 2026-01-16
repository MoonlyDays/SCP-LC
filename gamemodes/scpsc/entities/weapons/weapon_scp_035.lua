SWEP.Base = "weapon_scp_base"
SWEP.PrintName = "SCP-035"
SWEP.HoldType = "normal"
SWEP.DisableDamageEvent = true
SWEP.ScoreOnDamage = true
SWEP.ScoreOnKill = true
SWEP.AttackCooldown = 2
SWEP.AttackRange = 75
SWEP.AttackDamage = 25
SWEP.CorrosionDuration = 8
SWEP.CorrosionDamage = 3
local CORROSION_DURATION = SWEP.CorrosionDuration
local CORROSION_DAMAGE = SWEP.CorrosionDamage
function SWEP:SetupDataTables()
    self:CallBaseClass("SetupDataTables")
end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
    self:InitializeLanguage("SCP035")
    self:InitializeHUD()
end

function SWEP:Think()
    if CLIENT or ROUND.preparing or ROUND.post then return end
end

function SWEP:Holster(wep)
    return true
end

local attack_trace = {}
attack_trace.mask = MASK_SHOT
attack_trace.output = attack_trace
function SWEP:PrimaryAttack()
    if CLIENT or ROUND.preparing or ROUND.post then return end
    local ct = CurTime()
    local owner = self:GetOwner()
    self:SetNextPrimaryFire(ct + self.AttackCooldown)
    attack_trace.start = owner:GetShootPos()
    attack_trace.endpos = attack_trace.start + owner:GetAimVector() * self.AttackRange
    attack_trace.filter = owner
    owner:LagCompensation(true)
    util.TraceLine(attack_trace)
    owner:LagCompensation(false)
    local ent = attack_trace.Entity
    if not IsValid(ent) then return end
    owner:EmitSound("SCP035.Attack")
    if not ent:IsPlayer() then
        self:SCPDamageEvent(ent, 50)
        return
    end

    if not self:CanTargetPlayer(ent) then return end
    local dmg = DamageInfo()
    dmg:SetDamage(self.AttackDamage)
    dmg:SetDamageType(DMG_SLASH)
    dmg:SetAttacker(owner)
    dmg:SetInflictor(self)
    ent:TakeDamageInfo(dmg)
    ent:ApplyEffect("scp035_corrosion", owner)
end

function SWEP:OnPlayerKilled(ply)
    AddRoundStat("035")
end

--[[-------------------------------------------------------------------------
Effects
---------------------------------------------------------------------------]]
EFFECTS.RegisterEffect("scp035_corrosion", {
    duration = CORROSION_DURATION,
    stacks = 0,
    tiers = {
        {
            icon = Material("slc/hud/effects/poison.png")
        },
    },
    cantarget = scp_spec_filter,
    begin = function(self, ply, tier, args, refresh)
        if IsValid(args[1]) then
            self.attacker = args[1]
            self.signature = args[1]:TimeSignature()
        end

        if SERVER then ply:PushSpeed(0.9, 0.9, -1, "SLC_Corrosion", 1) end
    end,
    finish = function(self, ply, tier, args, interrupt) if SERVER then ply:PopSpeed("SLC_Corrosion") end end,
    think = function(self, ply, tier, args)
        if CLIENT then return end
        local dmg = DamageInfo()
        dmg:SetDamage(CORROSION_DAMAGE)
        dmg:SetDamageType(DMG_ACID)
        if IsValid(self.attacker) and self.attacker:CheckSignature(self.signature) then dmg:SetAttacker(self.attacker) end
        ply:TakeDamageInfo(dmg)
    end,
    wait = 1,
})

--[[-------------------------------------------------------------------------
SCP HUD
---------------------------------------------------------------------------]]
if CLIENT then
    local hud = SCPHUDObject("SCP035", SWEP)
    hud:AddCommonSkills()
    hud:AddSkill("attack"):SetButton("attack"):SetMaterial("slc/hud/scp/035/attack.png", "smooth"):SetCooldownFunction("GetNextPrimaryFire")
end

--[[-------------------------------------------------------------------------
Sounds
---------------------------------------------------------------------------]]
sound.Add{
    name = "SCP035.Attack",
    sound = "npc/zombie/claw_strike1.wav",
    volume = 1,
    level = 75,
    pitch = 100,
    channel = CHAN_WEAPON,
}
