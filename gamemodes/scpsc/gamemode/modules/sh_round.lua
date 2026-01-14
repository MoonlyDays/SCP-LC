ESCAPE_STATUS = 0
ESCAPE_TIMER = 0
ESCAPE_INACTIVE = 0
ESCAPE_ACTIVE = 1
ESCAPE_BLOCKED = 2
function IsRoundLive()
    return ROUND.active and not ROUND.infoscreen and not ROUND.preparing and not ROUND.post
end

function RemainingRoundTime()
    if not IsRoundLive() then return 0 end
    if CLIENT then
        local ct = CurTime()
        if not ROUND.time or ROUND.time < ct then return 0 end
        return ROUND.time - ct
    else
        local t = GetTimer("SLCRound")
        if not IsValid(t) then return 0 end
        return t:GetRemainingTime()
    end
end

function RoundDuration()
    if not IsRoundLive() then return 0 end
    if CLIENT then
        return ROUND.duration or 0
    else
        local t = GetTimer("SLCRound")
        if not IsValid(t) then return 0 end
        return t:GetTime()
    end
end
