-- Core/10_Utils.lua
-- Utilitaires génériques

local RCDT = RaidCDTracker

-- Nom complet "Nom-Royaume"
function RCDT.FullUnitName(unit)
    local name, realm = UnitName(unit)
    if not name then return nil end
    if realm and realm ~= "" then return name.."-"..realm end
    return name
end

-- Nom court (sans "-Royaume")
function RCDT.ShortName(name)
    return name and name:match("^[^-]+") or name
end

-- Choisit le bon canal; nil si solo
function RCDT.Channel()
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
    if IsInRaid() then return "RAID" end
    if IsInGroup() then return "PARTY" end
    return nil
end

-- Debug
function RCDT.DebugLog(tag, msg)
    if RCDT.DEBUG_MODE then
        DEFAULT_CHAT_FRAME:AddMessage("|cffa0a0a0["..RCDT.ADDON.." "..tag.."]|r "..tostring(msg))
    end
end

-- Iterateur trié
function RCDT.spairs(t, cmp)
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end
    table.sort(keys, cmp)
    local i = 0
    return function()
        i = i + 1
        local k = keys[i]
        if k then return k, t[k] end
    end
end
