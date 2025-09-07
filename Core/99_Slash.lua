-- Core/99_Slash.lua
-- Commandes slash

local RCDT = RaidCDTracker

SLASH_RAIDCD1 = "/raidcd"
SlashCmdList["RAIDCD"] = function(msg)
    msg = (msg or ""):lower():trim()

    if msg == "dump" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff00--- "..RCDT.ADDON.." raidState dump ---|r")
        if not next(RCDT.raidState) then DEFAULT_CHAT_FRAME:AddMessage("  (aucune donnée connue)") return end

        for player, spells in RCDT.spairs(RCDT.raidState, function(a,b)
            return RCDT.ShortName(a) < RCDT.ShortName(b)
        end) do
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00"..RCDT.ShortName(player).."|r:")
            for spellID,data in RCDT.spairs(spells, function(a,b)
                local na = GetSpellInfo(a) or ""
                local nb = GetSpellInfo(b) or ""
                return na < nb
            end) do
                local name = GetSpellInfo(spellID) or ("Spell:"..spellID)
                local remain=(data.endTime and data.endTime>0) and math.max(0,data.endTime-GetTime()) or 0
                local durText=(remain>0) and (" ("..string.format("%.1f",remain).."/"..(data.totalCD or 0).."s)") or ""
                DEFAULT_CHAT_FRAME:AddMessage("  - "..name..": "..RCDT.STATUS_NAME[data.status]..durText)
            end
        end
        return
    end

    -- aide
    DEFAULT_CHAT_FRAME:AddMessage("|cffffff00Usage: /raidcd dump|r")
end

-- petit helper si trim n’existe pas (MoP)
if not string.trim then
    function string.trim(s)
        return (s:gsub("^%s*(.-)%s*$", "%1"))
    end
end
