-- Logic/40_Network.lua
-- Sérialisation/émission/réception des messages addon

local RCDT = RaidCDTracker

-- Sérialise un statut (v3 inclut activeDur)
function RCDT.SerializeStatus(spellID, state, remain, totalCD, activeDur)
    return ("S:%d:%d:%d:%0.2f:%0.2f:%0.2f"):format(RCDT.VERSION, spellID, state, remain or 0, totalCD or 0, activeDur or 0)
end

-- Envoie un statut de CD au groupe (et met à jour localement)
function RCDT.SendStatus(spellID, state, remain, totalCD, activeDur)
    if not IsPlayerSpell(spellID) then return end
    local chan = RCDT.Channel()

    -- Toujours mettre à jour localement
    local me = RCDT.FullUnitName("player")
    if me then
        RCDT.UpdateLocalState(me, spellID, state, remain, totalCD, activeDur)
    end

    -- N’envoie que si en groupe
    if not chan then return end
    C_ChatInfo.SendAddonMessage(RCDT.PREFIX, RCDT.SerializeStatus(spellID, state, remain, totalCD, activeDur), chan)
    RCDT.DebugLog("SEND", spellID.." -> "..RCDT.STATUS_NAME[state])
end

-- Envoie l’état complet de tous nos CDs
function RCDT.SendFullStatus()
    local classToken = select(2, UnitClass("player"))
    local TRACKED = RCDT.TrackedByClass()[classToken] or {}
    for spellID, cfg in pairs(TRACKED) do
        if IsPlayerSpell(spellID) then
            local state, remain, duration, active = RCDT.EvaluateCooldown(spellID, cfg)
            RCDT.SendStatus(spellID, state, remain, duration, active)
        end
    end
end

-- Réception d’un message réseau
function RCDT.OnAddonMsg(prefix, msg, _, sender)
    if prefix ~= RCDT.PREFIX then return end

    -- Demande de synchro (uniquement si en groupe)
    if msg == "SYNC_REQUEST" then
        if RCDT.Channel() then
            C_Timer.After(math.random(0,2), RCDT.SendFullStatus)
        end
        return
    end

    -- Version du message
    local ver = tonumber((msg:match("^S:(%d+):")))
    if not ver or ver < 2 or ver > RCDT.VERSION then return end

    -- Parse v3: S:ver:spellID:state:remain:total:active
    local spellID, st, remain, total, active =
        msg:match("^S:%d+:(%d+):(%d+):([%d%.]+):([%d%.]+):([%d%.]+)$")

    if not spellID then
        -- Parse v2 (sans activeDur): S:ver:spellID:state:remain:total
        spellID, st, remain, total =
            msg:match("^S:%d+:(%d+):(%d+):([%d%.]+):([%d%.]+)$")
    end

    spellID = tonumber(spellID); st = tonumber(st)
    remain  = tonumber(remain) or 0; total = tonumber(total) or 0
    active  = tonumber(active) or 0
    if not spellID or not RCDT.STATUS_NAME[st] then return end

    local who = sender -- garder le nom complet (évite collisions cross-realm)

    -- Filtre: si le sort n’est pas suivi pour la classe du joueur, ignorer
    if not RCDT.IsTrackedFor(who, spellID) then return end

    RCDT.UpdateLocalState(who, spellID, st, remain, total, active)
end
