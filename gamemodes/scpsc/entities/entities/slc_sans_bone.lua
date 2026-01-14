AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Sans Bone"
ENT.Spawnable = false
ENT.AdminOnly = false

ENT.LifeTime = 3
ENT.Damage = 1

function ENT:Initialize()
    if SERVER then
        self:SetModel("models/props_junk/cardboard_box001a.mdl") -- Placeholder, will be invisible
        self:SetModelScale(0.3, 0)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
            phys:SetMass(1)
            phys:EnableGravity(false)
            phys:SetDragCoefficient(0)
        end

        self.SpawnTime = CurTime()
        self:SetNoDraw(true)
    end

    -- Client-side bone rendering
    if CLIENT then
        self.BoneMaterial = Material("sprites/light_glow02_add")
    end
end

function ENT:Think()
    if SERVER then
        -- Remove after lifetime expires
        if CurTime() - self.SpawnTime > self.LifeTime then
            self:Remove()
            return
        end
    end

    self:NextThink(CurTime())
    return true
end

function ENT:PhysicsCollide(data, phys)
    if CLIENT then return end

    local ent = data.HitEntity

    if IsValid(ent) then
        local owner = self:GetOwner()

        if ent:IsPlayer() then
            -- Use weapon's sin damage system
            if IsValid(self.Weapon) then
                self.Weapon:DealSinDamage(ent, self.Damage, owner, self)
            else
                -- Fallback damage
                local dmg = DamageInfo()
                dmg:SetDamage(self.Damage)
                dmg:SetDamageType(DMG_SLASH)
                dmg:SetAttacker(IsValid(owner) and owner or self)
                dmg:SetInflictor(self)
                ent:TakeDamageInfo(dmg)
            end
        elseif ent:GetClass() == "prop_door_rotating" or ent:GetClass() == "func_door" or ent:GetClass() == "func_door_rotating" then
            -- Damage doors
            local dmg = DamageInfo()
            dmg:SetDamage(25)
            dmg:SetDamageType(DMG_SLASH)
            dmg:SetAttacker(IsValid(owner) and owner or self)
            dmg:SetInflictor(self)
            ent:TakeDamageInfo(dmg)
        end
    end

    -- Create hit effect
    local effectdata = EffectData()
    effectdata:SetOrigin(data.HitPos)
    effectdata:SetNormal(data.HitNormal)
    util.Effect("StunstickImpact", effectdata, true, true)

    self:EmitSound("physics/concrete/concrete_impact_bullet" .. math.random(1, 4) .. ".wav", 60, math.random(90, 110))
    self:Remove()
end

function ENT:Draw()
    if not self.BoneMaterial then return end

    local pos = self:GetPos()
    local ang = self:GetAngles()

    -- Draw bone as a glowing white elongated shape
    render.SetMaterial(self.BoneMaterial)

    local forward = ang:Forward()
    local boneLength = 40
    local boneWidth = 8

    -- Draw multiple sprites to form bone shape
    for i = -1, 1 do
        local offset = forward * (i * boneLength / 3)
        local size = boneWidth * (1 - math.abs(i) * 0.3)
        render.DrawSprite(pos + offset, size, size, Color(255, 255, 255, 255))
    end

    -- Draw end caps
    render.DrawSprite(pos - forward * (boneLength / 2), boneWidth * 1.5, boneWidth * 1.5, Color(255, 255, 255, 200))
    render.DrawSprite(pos + forward * (boneLength / 2), boneWidth * 1.5, boneWidth * 1.5, Color(255, 255, 255, 200))
end

function ENT:OnRemove()
    -- Cleanup
end
