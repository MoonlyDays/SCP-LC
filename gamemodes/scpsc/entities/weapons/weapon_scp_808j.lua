SWEP.Base = "weapon_scp_base"
SWEP.PrintName = "SCP-808-J"
SWEP.HoldType = "normal"
SWEP.ScoreOnDamage = true

-- Primary attack parameters
SWEP.PrimaryDamage = 30
SWEP.PrimaryCooldown = 3
SWEP.PrimaryRange = 80

-- Good Kanye: Secondary Attack - spawn random item
SWEP.ItemSpawnCooldown = 60 -- 1 minute
SWEP.SpawnableItems = {
	"item_slc_medkit",
	"item_slc_battery",
	"item_slc_flashlight",
	"item_slc_radio",
	"item_slc_gasmask",
	"item_slc_nvg",
	"item_slc_adrenaline",
	"item_slc_morphine",
}

-- Good Kanye: Special Attack - drain stamina
SWEP.StaminaDrainCooldown = 180 -- 3 minutes
SWEP.StaminaDrainRadius = 300 -- ~5 meters (Source units)

-- Evil Kanye: Secondary Attack - deafen players
SWEP.DeafenCooldown = 180 -- 3 minutes
SWEP.DeafenDuration = 30
SWEP.DeafenRadius = 600

-- Evil Kanye: Special Attack - Cancel Culture
SWEP.CancelCultureCooldown = 45
SWEP.CancelCultureDuration = 15
SWEP.CancelCultureDamageBonus = 0.25 -- 25% more damage

-- Mode swap timing
SWEP.ModeSwapMin = 60 -- 1 minute
SWEP.ModeSwapMax = 300 -- 5 minutes

-- Good Kanye: Passive - Sunday Service (regen while standing still)
SWEP.SundayServiceHeal = 5
SWEP.SundayServiceInterval = 3
SWEP.SundayServiceStandTime = 1 -- Must stand still for 1 second before regen kicks in

-- Evil Kanye: Passive - Paparazzi (wallhack on closest enemy)
SWEP.PaparazziUpdateInterval = 0.5

--[[
	GOOD KANYE:
		Passive - Sunday Service: Regenerate 5 HP every 3 seconds while standing still
		LMB - Melee attack: 30 damage, 3 second cooldown
		RMB - Item Spawn: Spawn a random useful item (5 minute cooldown)
		Special - Stamina Drain: Drain stamina of players within 5m radius (3 minute cooldown)

	EVIL KANYE:
		Passive - Paparazzi: See closest enemy through walls
		LMB - Melee attack: 30 damage, 3 second cooldown
		RMB - Deafen: Play audio that blocks all other sounds for 30s (3 minute cooldown)
		Special - Cancel Culture: Mark target for 25% increased damage for 15s (45s cooldown)
]]

function SWEP:SetupDataTables()
	self:CallBaseClass("SetupDataTables")
	self:NetworkVar("Bool", "EvilMode")
	self:NetworkVar("Float", "NextModeSwap")
	self:NetworkVar("Float", "NextSecondaryAttack")
	self:NetworkVar("Entity", "CanceledTarget")
	self:NetworkVar("Float", "CanceledEndTime")
	self:NetworkVar("Entity", "PaparazziTarget")
end

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
	self:InitializeLanguage("SCP808J")
	self:InitializeHUD()

	if SERVER then
		self:SetEvilMode(false)
		self:ScheduleNextModeSwap()
		self.LastPosition = nil
		self.StandStillTime = 0
		self.NextSundayService = 0
		self.NextPaparazzi = 0
	end
end

function SWEP:ScheduleNextModeSwap()
	local delay = math.random(self.ModeSwapMin, self.ModeSwapMax)
	self:SetNextModeSwap(CurTime() + delay)
end

function SWEP:SwapMode()
	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	local wasEvil = self:GetEvilMode()
	self:SetEvilMode(not wasEvil)
	self:ScheduleNextModeSwap()

	-- Notify player
	if self:GetEvilMode() then
		owner:EmitSound("SCP808J.EvilMode")
		owner:ChatPrint("[SCP-808-J] You feel the darkness taking over... (Evil Mode)")
	else
		owner:EmitSound("SCP808J.GoodMode")
		owner:ChatPrint("[SCP-808-J] A wave of peace washes over you... (Good Mode)")
	end

	-- Clear mode-specific states on swap
	self:SetCanceledTarget(NULL)
	self:SetCanceledEndTime(0)
	self:SetPaparazziTarget(NULL)
end

function SWEP:Think()
	if ROUND.preparing or ROUND.post then return end

	local ct = CurTime()
	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	if SERVER then
		-- Check for mode swap
		if self:GetNextModeSwap() > 0 and ct >= self:GetNextModeSwap() then
			self:SwapMode()
		end

		-- Clear expired Cancel Culture effect
		if IsValid(self:GetCanceledTarget()) and ct >= self:GetCanceledEndTime() then
			local target = self:GetCanceledTarget()
			if IsValid(target) then
				target:SetProperty("scp808j_canceled", nil)
			end
			self:SetCanceledTarget(NULL)
			self:SetCanceledEndTime(0)
		end

		-- Mode-specific passive updates
		if self:GetEvilMode() then
			self:UpdatePaparazzi(owner, ct)
		else
			self:UpdateSundayService(owner, ct)
		end
	end
end

-- Good Kanye Passive: Sunday Service - HP regen while standing still
function SWEP:UpdateSundayService(owner, ct)
	if self.NextSundayService > ct then return end

	local pos = owner:GetPos()

	if self.LastPosition and pos:DistToSqr(self.LastPosition) < 100 then -- Standing still (small tolerance)
		self.StandStillTime = self.StandStillTime + 0.5

		if self.StandStillTime >= self.SundayServiceStandTime then
			if self.NextSundayService <= ct then
				local maxHP = owner:GetMaxHealth()
				local currentHP = owner:Health()

				if currentHP < maxHP then
					local healAmount = math.min(self.SundayServiceHeal, maxHP - currentHP)
					owner:SetHealth(currentHP + healAmount)
				end

				self.NextSundayService = ct + self.SundayServiceInterval
			end
		end
	else
		self.StandStillTime = 0
	end

	self.LastPosition = pos
end

-- Evil Kanye Passive: Paparazzi - See closest enemy through walls
function SWEP:UpdatePaparazzi(owner, ct)
	if self.NextPaparazzi > ct then return end
	self.NextPaparazzi = ct + self.PaparazziUpdateInterval

	local ownerPos = owner:GetPos()
	local closestDist = math.huge
	local closestTarget = NULL

	for _, ply in ipairs(player.GetAll()) do
		if not self:CanTargetPlayer(ply) then continue end

		local dist = ply:GetPos():DistToSqr(ownerPos)
		if dist < closestDist then
			closestDist = dist
			closestTarget = ply
		end
	end

	self:SetPaparazziTarget(closestTarget)
end

-- Primary Attack: Melee (both modes)
local attack_trace = {}
attack_trace.mins = Vector(-10, -10, -10)
attack_trace.maxs = Vector(10, 10, 10)
attack_trace.mask = MASK_SHOT
attack_trace.output = attack_trace

function SWEP:PrimaryAttack()
	if ROUND.preparing or ROUND.post then return end

	self:SetNextPrimaryFire(CurTime() + self.PrimaryCooldown * self:GetUpgradeMod("primary_cd", 1))

	if not SERVER then return end

	local owner = self:GetOwner()
	local spos = owner:GetShootPos()

	attack_trace.start = spos
	attack_trace.endpos = spos + owner:GetAimVector() * self.PrimaryRange
	attack_trace.filter = owner

	owner:LagCompensation(true)
	util.TraceHull(attack_trace)
	owner:LagCompensation(false)

	local ent = attack_trace.Entity

	if IsValid(ent) and ent:IsPlayer() and self:CanTargetPlayer(ent) then
		owner:EmitSound("SCP808J.Hit")

		local dmg = DamageInfo()
		dmg:SetDamage(self.PrimaryDamage * self:GetUpgradeMod("primary_dmg", 1))
		dmg:SetDamageType(DMG_SLASH)
		dmg:SetAttacker(owner)
		dmg:SetInflictor(self)
		ent:TakeDamageInfo(dmg)
	else
		owner:EmitSound("SCP808J.Miss")
	end

	AddRoundStat("808j")
end

-- Secondary Attack: Mode-dependent
function SWEP:SecondaryAttack()
	if ROUND.preparing or ROUND.post then return end

	local ct = CurTime()
	if self:GetNextSecondaryAttack() > ct then return end

	if not SERVER then return end

	if self:GetEvilMode() then
		self:DeafenAttack()
	else
		self:SpawnItemAttack()
	end
end

-- Good Kanye Secondary: Spawn random item
function SWEP:SpawnItemAttack()
	local ct = CurTime()
	self:SetNextSecondaryAttack(ct + self.ItemSpawnCooldown * self:GetUpgradeMod("item_cd", 1))

	local owner = self:GetOwner()
	local itemClass = self.SpawnableItems[math.random(#self.SpawnableItems)]

	local item = ents.Create(itemClass)
	if IsValid(item) then
		local pos = owner:GetPos() + owner:GetForward() * 50 + Vector(0, 0, 20)
		item:SetPos(pos)
		item:Spawn()

		owner:EmitSound("SCP808J.ItemSpawn")
		owner:ChatPrint("[SCP-808-J] You spawned: " .. (item.PrintName or itemClass))
	end
end

-- Evil Kanye Secondary: Deafen nearby players
function SWEP:DeafenAttack()
	local ct = CurTime()
	self:SetNextSecondaryAttack(ct + self.DeafenCooldown * self:GetUpgradeMod("deafen_cd", 1))

	local owner = self:GetOwner()
	local pos = owner:GetPos()
	local radius = self.DeafenRadius * self:GetUpgradeMod("deafen_radius", 1)

	owner:EmitSound("SCP808J.Deafen")

	local affected = 0
	for _, ply in ipairs(player.GetAll()) do
		if not self:CanTargetPlayer(ply) then continue end
		if ply:GetPos():Distance(pos) > radius then continue end

		ply:ApplyEffect("scp808j_deafened", self.DeafenDuration)
		affected = affected + 1
	end

	if affected > 0 then
		owner:ChatPrint("[SCP-808-J] Deafened " .. affected .. " player(s)!")
	end
end

-- Special Attack: Mode-dependent
function SWEP:SpecialAttack()
	if ROUND.preparing or ROUND.post then return end

	local ct = CurTime()
	if self:GetNextSpecialAttack() > ct then return end

	if not SERVER then return end

	if self:GetEvilMode() then
		self:CancelCultureAttack()
	else
		self:StaminaDrainAttack()
	end
end

-- Good Kanye Special: Drain stamina of nearby players
function SWEP:StaminaDrainAttack()
	local ct = CurTime()
	self:SetNextSpecialAttack(ct + self.StaminaDrainCooldown * self:GetUpgradeMod("stamina_cd", 1))

	local owner = self:GetOwner()
	local pos = owner:GetPos()
	local radius = self.StaminaDrainRadius * self:GetUpgradeMod("stamina_radius", 1)

	owner:EmitSound("SCP808J.StaminaDrain")

	local affected = 0
	for _, ply in ipairs(player.GetAll()) do
		if not self:CanTargetPlayer(ply) then continue end
		if ply:GetPos():Distance(pos) > radius then continue end

		-- Drain all stamina
		if ply.SetStamina then
			ply:SetStamina(0)
		end
		affected = affected + 1
	end

	if affected > 0 then
		owner:ChatPrint("[SCP-808-J] Drained stamina from " .. affected .. " player(s)!")
	end
end

-- Evil Kanye Special: Cancel Culture - mark target for increased damage
function SWEP:CancelCultureAttack()
	local ct = CurTime()
	local owner = self:GetOwner()

	-- Find target in crosshair
	local spos = owner:GetShootPos()
	local tr = util.TraceLine({
		start = spos,
		endpos = spos + owner:GetAimVector() * 2000,
		filter = owner,
		mask = MASK_SHOT
	})

	local target = tr.Entity

	if not IsValid(target) or not target:IsPlayer() or not self:CanTargetPlayer(target) then
		owner:ChatPrint("[SCP-808-J] No valid target in sight!")
		return
	end

	self:SetNextSpecialAttack(ct + self.CancelCultureCooldown * self:GetUpgradeMod("cancel_cd", 1))

	-- Clear previous target
	local oldTarget = self:GetCanceledTarget()
	if IsValid(oldTarget) then
		oldTarget:SetProperty("scp808j_canceled", nil)
	end

	-- Apply Cancel Culture
	local duration = self.CancelCultureDuration * self:GetUpgradeMod("cancel_duration", 1)
	target:SetProperty("scp808j_canceled", self.CancelCultureDamageBonus)
	target:ApplyEffect("scp808j_canceled", duration)

	self:SetCanceledTarget(target)
	self:SetCanceledEndTime(ct + duration)

	owner:EmitSound("SCP808J.CancelCulture")
	owner:ChatPrint("[SCP-808-J] " .. target:Nick() .. " has been CANCELED!")
	target:ChatPrint("[SCP-808-J] You have been CANCELED! You take 25% more damage!")
end

function SWEP:OnRemove()
	if not SERVER then return end

	-- Clear canceled target
	local target = self:GetCanceledTarget()
	if IsValid(target) then
		target:SetProperty("scp808j_canceled", nil)
	end
end

--[[-------------------------------------------------------------------------
SCP Hooks - Cancel Culture damage modifier
---------------------------------------------------------------------------]]
SCPHook("SCP808J", "EntityTakeDamage", function(target, dmginfo)
	if not IsValid(target) or not target:IsPlayer() then return end

	local cancelBonus = target:GetProperty("scp808j_canceled")
	if cancelBonus then
		local newDamage = dmginfo:GetDamage() * (1 + cancelBonus)
		dmginfo:SetDamage(newDamage)
	end
end)

--[[-------------------------------------------------------------------------
Upgrade system
---------------------------------------------------------------------------]]
local icons = {}
if CLIENT then
	icons.primary = GetMaterial("slc/hud/upgrades/scp/808j/primary.png", "smooth")
	icons.good = GetMaterial("slc/hud/upgrades/scp/808j/good.png", "smooth")
	icons.evil = GetMaterial("slc/hud/upgrades/scp/808j/evil.png", "smooth")
end

DefineUpgradeSystem("scp808j", {
	grid_x = 3,
	grid_y = 3,
	upgrades = {
		{
			name = "primary1",
			cost = 1,
			req = {},
			reqany = false,
			pos = {1, 1},
			mod = {
				primary_cd = 0.85
			},
			icon = icons.primary
		},
		{
			name = "primary2",
			cost = 2,
			req = {"primary1"},
			reqany = false,
			pos = {1, 2},
			mod = {
				primary_dmg = 1.2
			},
			icon = icons.primary
		},
		{
			name = "good1",
			cost = 1,
			req = {},
			reqany = false,
			pos = {2, 1},
			mod = {
				item_cd = 0.8,
				stamina_radius = 1.25
			},
			icon = icons.good
		},
		{
			name = "evil1",
			cost = 1,
			req = {},
			reqany = false,
			pos = {3, 1},
			mod = {
				deafen_cd = 0.85,
				cancel_cd = 0.85
			},
			icon = icons.evil
		},
		{
			name = "evil2",
			cost = 2,
			req = {"evil1"},
			reqany = false,
			pos = {3, 2},
			mod = {
				cancel_duration = 1.3,
				deafen_radius = 1.25
			},
			icon = icons.evil
		},
		{
			name = "outside_buff",
			cost = 1,
			req = {},
			reqany = false,
			pos = {2, 3},
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
	local hud = SCPHUDObject("SCP808J", SWEP)
	hud:AddCommonSkills()

	hud:AddSkill("attack")
		:SetButton("attack")
		:SetMaterial("slc/hud/scp/049/choke.png", "smooth")
		:SetCooldownFunction("GetNextPrimaryFire")

	hud:AddSkill("secondary")
		:SetButton("attack2")
		:SetMaterial("slc/hud/scp/049/choke.png", "smooth")
		:SetCooldownFunction("GetNextSecondaryAttack")

	hud:AddSkill("special")
		:SetButton("scp_special")
		:SetMaterial("slc/hud/scp/049/choke.png", "smooth")
		:SetCooldownFunction("GetNextSpecialAttack")

	hud:AddBar("mode")
		:SetMaterial("slc/hud/scp/049/choke.png", "smooth")
		:SetColor(Color(255, 200, 50))
		:SetTextFunction(function(swep)
			return swep:GetEvilMode() and "EVIL KANYE" or "GOOD KANYE"
		end)
		:SetProgressFunction(function(swep)
			local remaining = swep:GetNextModeSwap() - CurTime()
			local total = swep:GetEvilMode() and swep.ModeSwapMax or swep.ModeSwapMax
			return math.Clamp(remaining / total, 0, 1)
		end)
		:SetVisibleFunction(function(swep) return true end)

	-- Paparazzi wallhack rendering for Evil Kanye
	hook.Add("PreDrawHalos", "SCP808J_Paparazzi", function()
		local ply = LocalPlayer()
		if not IsValid(ply) then return end

		local wep = ply:GetActiveWeapon()
		if not IsValid(wep) or wep:GetClass() ~= "weapon_scp_808j" then return end
		if not wep:GetEvilMode() then return end

		local target = wep:GetPaparazziTarget()
		if IsValid(target) then
			halo.Add({target}, Color(255, 0, 0), 2, 2, 2, true, true)
		end
	end)
end

--[[-------------------------------------------------------------------------
Sounds
---------------------------------------------------------------------------]]
sound.Add({
	name = "SCP808J.Hit",
	volume = 1,
	level = 80,
	pitch = {95, 105},
	sound = "physics/body/body_medium_impact_hard1.wav",
	channel = CHAN_WEAPON,
})

sound.Add({
	name = "SCP808J.Miss",
	volume = 0.8,
	level = 70,
	pitch = {90, 110},
	sound = "npc/zombie/claw_miss1.wav",
	channel = CHAN_WEAPON,
})

sound.Add({
	name = "SCP808J.EvilMode",
	volume = 1,
	level = 75,
	pitch = 80,
	sound = "ambient/atmosphere/cave_hit1.wav",
	channel = CHAN_STATIC,
})

sound.Add({
	name = "SCP808J.GoodMode",
	volume = 1,
	level = 75,
	pitch = 120,
	sound = "ambient/atmosphere/cave_hit1.wav",
	channel = CHAN_STATIC,
})

sound.Add({
	name = "SCP808J.ItemSpawn",
	volume = 1,
	level = 70,
	pitch = 100,
	sound = "items/ammo_pickup.wav",
	channel = CHAN_ITEM,
})

sound.Add({
	name = "SCP808J.StaminaDrain",
	volume = 1,
	level = 85,
	pitch = 90,
	sound = "ambient/energy/whiteflash.wav",
	channel = CHAN_STATIC,
})

sound.Add({
	name = "SCP808J.Deafen",
	volume = 1,
	level = 90,
	pitch = 100,
	sound = "scp_lc/scp/808/kanye.ogg",
	channel = CHAN_STATIC,
})

sound.Add({
	name = "SCP808J.CancelCulture",
	volume = 1,
	level = 80,
	pitch = 100,
	sound = "buttons/button10.wav",
	channel = CHAN_STATIC,
})
