-- Logic/30_Cooldown.lua
-- Évaluation des cooldowns, mise à jour d’état, scan périodique

local RCDT = RaidCDTracker

-- Calcule le statut d’un sort donné (Ready/Active/OnCD)
function RCDT.EvaluateCooldown(spellID, cfg)
    local now = GetTime()

    -- Gestion des charges (si dispo)
    if GetSpellCharges then
        local charges, maxCharges, chargeStart, chargeDur = GetSpellCharges(spellID)
        if maxCharges and maxCharges > 1 then
            if (charges or 0) > 0 then
                return RCDT.STATUS.Ready, 0, chargeDur or 0, (cfg and cfg.active) or 0
            else
                local remain = (chargeStart + chargeDur) - now
                if remain < 0 then remain = 0 end
                return RCDT.STATUS.OnCD, remain, chargeDur or 0, (cfg and cfg.active) or 0
            end
        end
    end

    local start, duration, enabled = GetSpellCooldown(spellID)
    local state, remain = RCDT.STATUS.Ready, 0
    local activeDur = (cfg and cfg.active) or 0

    -- OnCD (ignore GCD)
    if enabled == 1 and start and start > 0 and duration and duration > RCDT.GCD_THRESHOLD then
        remain = (start + duration) - now
        if remain < 0 then remain = 0 end
        state = RCDT.STATUS.OnCD
    end

    -- Active
    if state == RCDT.STATUS.OnCD and activeDur > 0 and remain >= (duration - activeDur) then
        state = RCDT.STATUS.Active
        remain = activeDur - (duration - remain)
        if remain < 0 then remain = 0 end
    end

    return state, remain, duration or 0, activeDur
end

-- Met à jour l’état local pour un joueur
function RCDT.UpdateLocalState(playerFull, spellID, state, remain, totalCD, activeDur)
    RCDT.raidState[playerFull] = RCDT.raidState[playerFull] or {}
    RCDT.raidState[playerFull][spellID] = {
        status    = state,
        endTime   = (remain and remain > 0) and (GetTime() + remain) or 0,
        totalCD   = totalCD or 0,
        activeDur = activeDur or 0,
    }
end

-- Vérifie si nos CDs changent, et envoie l’info si oui
function RCDT.CheckCooldowns()
    local classToken = select(2, UnitClass("player"))
    local TRACKED = RCDT.TrackedByClass()[classToken] or {}
    for spellID, cfg in pairs(TRACKED) do
        if IsPlayerSpell(spellID) then
            local state, remain, duration, active = RCDT.EvaluateCooldown(spellID, cfg)
            if RCDT._lastStates[spellID] ~= state then
                RCDT._lastStates[spellID] = state
                RCDT.SendStatus(spellID, state, remain, duration, active) -- Network
            end
        end
    end
end
