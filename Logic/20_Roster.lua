-- Logic/20_Roster.lua
-- Récup classe, purge roster, filtrage des sorts

local RCDT = RaidCDTracker

-- Retourne la classe (token) d’un joueur, en raid/party/solo
function RCDT.GetClassForPlayer(playerFull)
    if IsInRaid() then
        for i=1, GetNumGroupMembers() do
            local name, _, _, _, _, fileName = GetRaidRosterInfo(i)
            if name == playerFull then return fileName end
        end
    elseif IsInGroup() then
        for i=1, GetNumSubgroupMembers() do
            local u = "party"..i
            local full = RCDT.FullUnitName(u)
            if full == playerFull then local _, c = UnitClass(u); return c end
        end
        if RCDT.FullUnitName("player") == playerFull then
            local _, c = UnitClass("player"); return c
        end
    else
        if RCDT.FullUnitName("player") == playerFull then
            local _, c = UnitClass("player"); return c
        end
    end
    return nil
end

-- Purge les entrées d’anciens membres
function RCDT.PruneRoster()
    local present = {}
    if IsInRaid() then
        for i=1, GetNumGroupMembers() do
            local name = GetRaidRosterInfo(i)
            if name then present[name] = true end
        end
    elseif IsInGroup() then
        for i=1, GetNumSubgroupMembers() do
            local u = "party"..i
            local full = RCDT.FullUnitName(u)
            if full then present[full] = true end
        end
        present[RCDT.FullUnitName("player")] = true
    else
        present[RCDT.FullUnitName("player")] = true
    end
    for player in pairs(RCDT.raidState) do
        if not present[player] then RCDT.raidState[player] = nil end
    end
end

-- Est-ce un sort suivi pour la classe du joueur ciblé ?
function RCDT.IsTrackedFor(playerFull, spellID)
    local class = RCDT.GetClassForPlayer(playerFull)
    local perClass = class and RCDT.TrackedByClass()[class]
    return perClass and perClass[spellID] ~= nil
end
