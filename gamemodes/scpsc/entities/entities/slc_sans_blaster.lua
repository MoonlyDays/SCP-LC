AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Gaster Blaster"
ENT.Spawnable = false
ENT.AdminOnly = false

ENT.ChargeTime = 0.5
ENT.BeamDuration = 0.3
ENT.BeamRange = 800
ENT.BeamDamage = 5
ENT.BeamWidth = 50

function ENT:Initialize()
    if SERVER then
        self:SetModel("models/props_junk/cardboard_box001a.mdl") -- Placeholder
        self:SetModelScale(0.5, 0)
        self:PhysicsInit(SOLID_NONE)
        self:SetMoveType(MOVETYPE_NONE)
        self:SetSolid(SOLID_NONE)
        self:SetNoDraw(true)

        self.SpawnTime = CurTime()
        self.Fired = false
        self.BeamStartTime = nil
    end

    if CLIENT then
        self.BlasterMaterial = Material("sprites/light_glow02_add")
        self.BeamMaterial = Material("sprites/laserbeam")
        self.ChargeProgress = 0
        self.SpawnTime = CurTime()
        self:SetRenderBounds(Vector(-200, -200, -200), Vector(200, 200, 200))
    end
end

function ENT:Think()
    if SERVER then
        local elapsed = CurTime() - self.SpawnTime

        -- Charge phase
        if not self.Fired and elapsed >= self.ChargeTime then
            self:FireBeam()
            self.Fired = true
            self.BeamStartTime = CurTime()
        end

        -- Remove after beam finishes
        if self.Fired and CurTime() - self.BeamStartTime > self.BeamDuration + 0.2 then
            self:Remove()
            return
        end
    end

    self:NextThink(CurTime())
    return true
end

function ENT:FireBeam()
    if CLIENT then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local pos = self:GetPos()
    local ang = self:GetAngles()
    local dir = ang:Forward()

    -- Emit beam sound
    self:EmitSound("ambient/energy/zap" .. math.random(1, 9) .. ".wav", 85, math.random(80, 100))

    -- Trace for beam hit
    local trace = {}
    trace.start = pos
    trace.endpos = pos + dir * self.BeamRange
    trace.filter = {self, owner}
    trace.mask = MASK_SHOT

    local tr = util.TraceLine(trace)

    -- Store trace result for client rendering
    self:SetNWVector("BeamEnd", tr.HitPos)
    self:SetNWBool("BeamActive", true)

    -- Find all players in beam path (cylinder check)
    local hitPlayers = {}
    for _, ply in ipairs(player.GetAll()) do
        if ply == owner then continue end
        if ply:SCPTeam() == TEAM_SPEC then continue end
        if not ply:Alive() then continue end

        -- Check if player is in beam cylinder
        local plyPos = ply:GetPos() + Vector(0, 0, 36) -- Center mass
        local toPlayer = plyPos - pos
        local alongBeam = toPlayer:Dot(dir)

        if alongBeam < 0 or alongBeam > self.BeamRange then continue end

        local nearestPoint = pos + dir * alongBeam
        local distFromBeam = (plyPos - nearestPoint):Length()

        if distFromBeam <= self.BeamWidth then
            table.insert(hitPlayers, ply)
        end
    end

    -- Damage all hit players
    for _, ply in ipairs(hitPlayers) do
        if IsValid(self.Weapon) then
            self.Weapon:DealSinDamage(ply, self.BeamDamage, owner, self)
        else
            local dmg = DamageInfo()
            dmg:SetDamage(self.BeamDamage)
            dmg:SetDamageType(DMG_ENERGYBEAM)
            dmg:SetAttacker(owner)
            dmg:SetInflictor(self)
            ply:TakeDamageInfo(dmg)
        end
    end

    -- Damage doors/props at end point
    if IsValid(tr.Entity) then
        local dmg = DamageInfo()
        dmg:SetDamage(50)
        dmg:SetDamageType(DMG_ENERGYBEAM)
        dmg:SetAttacker(owner)
        dmg:SetInflictor(self)
        tr.Entity:TakeDamageInfo(dmg)
    end
end

function ENT:Draw()
    local pos = self:GetPos()
    local ang = self:GetAngles()
    local elapsed = CurTime() - (self.SpawnTime or CurTime())
    local chargeProgress = math.Clamp(elapsed / self.ChargeTime, 0, 1)

    -- Draw blaster head (skull-like shape)
    if self.BlasterMaterial then
        render.SetMaterial(self.BlasterMaterial)

        -- Main head
        local headSize = 40 + chargeProgress * 20
        render.DrawSprite(pos, headSize, headSize, Color(255, 255, 255, 200))

        -- Eyes
        local eyeOffset = 12
        local eyeSize = 15 + chargeProgress * 10
        local right = ang:Right()
        local up = ang:Up()

        render.DrawSprite(pos + right * eyeOffset + up * 5, eyeSize, eyeSize, Color(0, 200, 255, 255))
        render.DrawSprite(pos - right * eyeOffset + up * 5, eyeSize, eyeSize, Color(0, 200, 255, 255))

        -- Mouth charge glow
        if chargeProgress > 0 then
            local mouthSize = chargeProgress * 30
            render.DrawSprite(pos + ang:Forward() * 20, mouthSize, mouthSize, Color(0, 255, 255, 255 * chargeProgress))
        end
    end

    -- Draw beam
    if self:GetNWBool("BeamActive", false) and self.BeamMaterial then
        local beamEnd = self:GetNWVector("BeamEnd", pos + ang:Forward() * self.BeamRange)
        local beamStart = pos + ang:Forward() * 25

        render.SetMaterial(self.BeamMaterial)
        render.DrawBeam(beamStart, beamEnd, self.BeamWidth, 0, 1, Color(0, 200, 255, 255))

        -- Glow at beam start
        if self.BlasterMaterial then
            render.SetMaterial(self.BlasterMaterial)
            render.DrawSprite(beamStart, 60, 60, Color(0, 255, 255, 200))
        end

        -- Impact flash
        render.DrawSprite(beamEnd, 80, 80, Color(0, 200, 255, 150))
    end
end

function ENT:OnRemove()
    -- Cleanup
end
