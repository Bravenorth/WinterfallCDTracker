-- Logic/20_Roster.lua
-- Récup classe, purge roster, filtrage des sorts (tolérant Nom vs Nom-Royaume)

local RCDT = RaidCDTracker

-- Retourne la classe (token) d’un joueur, en comparant sur le ShortName
function RCDT.GetClassForPlayer(playerName)
    if not playerName then return nil end
    local want = RCDT.ShortName(playerName)

    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local name, _, _, _, _, classToken = GetRaidRosterInfo(i)
            if name and RCDT.ShortName(name) == want then
                return classToken
            end
        end
    elseif IsInGroup() then
        for i = 1, GetNumSubgroupMembers() do
            local u = "party"..i
            local full = RCDT.FullUnitName(u)
            if full and RCDT.ShortName(full) == want then
                local _, c = UnitClass(u)
                return c
            end
        end
        local me = RCDT.FullUnitName("player")
        if me and RCDT.ShortName(me) == want then
            local _, c = UnitClass("player")
            return c
        end
    else
        local me = RCDT.FullUnitName("player")
        if me and RCDT.ShortName(me) == want then
            local _, c = UnitClass("player")
            return c
        end
    end

    return nil
end

-- Purge les entrées d’anciens membres (compare sur ShortName pour ignorer le suffixe de royaume)
function RCDT.PruneRoster()
    local presentShort = {}

    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local name = GetRaidRosterInfo(i)
            if name then presentShort[RCDT.ShortName(name)] = true end
        end
    elseif IsInGroup() then
        for i = 1, GetNumSubgroupMembers() do
            local u = "party"..i
            local full = RCDT.FullUnitName(u)
            if full then presentShort[RCDT.ShortName(full)] = true end
        end
        local me = RCDT.FullUnitName("player")
        if me then presentShort[RCDT.ShortName(me)] = true end
    else
        local me = RCDT.FullUnitName("player")
        if me then presentShort[RCDT.ShortName(me)] = true end
    end

    for playerKey in pairs(RCDT.raidState) do
        if not presentShort[RCDT.ShortName(playerKey)] then
            RCDT.raidState[playerKey] = nil
        end
    end
end

-- Est-ce un sort suivi pour la classe du joueur ciblé ?
function RCDT.IsTrackedFor(playerFull, spellID)
    local class = RCDT.GetClassForPlayer(playerFull)
    if not class then return false end

    -- Récupération robuste du catalogue par classe (peu importe l’ordre de chargement)
    local byClass =
        (RCDT.TrackedByClass and RCDT.TrackedByClass())
        or RCDT.TRACKED_BY_CLASS
        or _G.RaidCDTracker_Cooldowns
        or {}

    local perClass = byClass[class]
    return perClass and perClass[spellID] ~= nil
end
