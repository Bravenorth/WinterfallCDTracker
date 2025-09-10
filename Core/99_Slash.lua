-- Core/99_Slash.lua
-- Commandes slash

local RCDT = RaidCDTracker

-- string.trim helper (MoP/Classic)
if not string.trim then
    function string.trim(s) return (s:gsub("^%s*(.-)%s*$", "%1")) end
end

-- Ouvre le panneau d'options (focus AddOns > notre catégorie)
local function OpenOptionsCategoryCompat()
    -- Retail 10.x Settings API
    if type(Settings) == "table" and Settings.OpenToCategory then
        Settings.OpenToCategory("AddOns")
        return
    end

    -- Classic API
    if InCombatLockdown and InCombatLockdown() then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff5555[RaidCDTracker]|r Cannot open options in combat.")
        return
    end

    -- Charger l'UI options si besoin
    if UIParentLoadAddOn and not IsAddOnLoaded("Blizzard_InterfaceOptions") then
        pcall(UIParentLoadAddOn, "Blizzard_InterfaceOptions")
    end

    if not InterfaceOptionsFrame then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff5555[RaidCDTracker]|r InterfaceOptionsFrame unavailable.")
        return
    end

    InterfaceOptionsFrame:Show()

    -- try to switch to AddOns tab
    if InterfaceOptionsFrameTab2 and InterfaceOptionsFrameTab2.Click then
        InterfaceOptionsFrameTab2:Click()
    end

    local target = RCDT._optionsCategory or RCDT.optionsPanel or UIParent
    local name   = (RCDT.optionsPanel and RCDT.optionsPanel.name) or (RCDT.ADDON or "RaidCDTracker")

    local function openTo(x)
        if InterfaceOptionsFrame_OpenToCategory then
            InterfaceOptionsFrame_OpenToCategory(x)
        end
    end

    -- Séquence robuste: plusieurs appels espacés (certains clients "perdent" la cible)
    C_Timer.After(0.00,
        function()
            if InterfaceOptionsFrameTab2 and InterfaceOptionsFrameTab2.Click then InterfaceOptionsFrameTab2:Click() end; openTo(
            target)
        end)
    C_Timer.After(0.10,
        function()
            if InterfaceOptionsFrameTab2 and InterfaceOptionsFrameTab2.Click then InterfaceOptionsFrameTab2:Click() end; openTo(
            target)
        end)
    C_Timer.After(0.20,
        function()
            if InterfaceOptionsFrameTab2 and InterfaceOptionsFrameTab2.Click then InterfaceOptionsFrameTab2:Click() end; openTo(
            name)
        end)
end

-- S’assure que la DB est prête si ADDON_LOADED n'a pas encore initialisé
local function EnsureDB()
    if not RCDT.db and RCDT.DBInit then
        RCDT.DBInit()
        if RCDT.ApplyConfigUI then RCDT.ApplyConfigUI() end
    end
end

SLASH_RAIDCD1 = "/raidcd"
SlashCmdList["RAIDCD"] = function(msg)
    msg = (msg or ""):lower():trim()

    if msg == "dump" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff00--- " .. (RCDT.ADDON or "RaidCDTracker") .. " raidState dump ---|r")
        if not next(RCDT.raidState) then
            DEFAULT_CHAT_FRAME:AddMessage("  (no known data)")
            return
        end
        for player, spells in RCDT.spairs(RCDT.raidState, function(a, b) return RCDT.ShortName(a) < RCDT.ShortName(b) end) do
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00" .. RCDT.ShortName(player) .. "|r:")
            for spellID, data in RCDT.spairs(spells, function(a, b)
                local na = GetSpellInfo(a) or ""; local nb = GetSpellInfo(b) or ""; return na < nb
            end) do
                local name = GetSpellInfo(spellID) or ("Spell:" .. spellID)
                local remain = (data.endTime and data.endTime > 0) and math.max(0, data.endTime - GetTime()) or 0
                local durText = (remain > 0) and (" (" .. string.format("%.1f", remain) .. "/" .. (data.totalCD or 0) .. "s)") or
                ""
                DEFAULT_CHAT_FRAME:AddMessage("  - " .. name .. ": " .. (RCDT.STATUS_NAME[data.status] or "?") .. durText)
            end
        end
        return
    end

    if msg == "config" or msg == "options" then
        if RCDT.ToggleConfig then
            RCDT.ToggleConfig()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff5555[RaidCDTracker]|r Config unavailable.")
        end
        return
    end

    if msg == "filters" then
        if RCDT.ToggleFilters then
            RCDT.ToggleFilters()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff5555[RaidCDTracker]|r Filters unavailable.")
        end
        return
    end
    if msg == "debug on" then
        EnsureDB(); if not RCDT.db then return end
        RCDT.db.debug = true; RCDT.DEBUG_MODE = true
        DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[RaidCDTracker]|r Debug: ON")
        return
    elseif msg == "debug off" then
        EnsureDB(); if not RCDT.db then return end
        RCDT.db.debug = false; RCDT.DEBUG_MODE = false
        DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[RaidCDTracker]|r Debug: OFF")
        return
    end

    if msg == "lock" then
        EnsureDB(); if not RCDT.db then return end
        RCDT.db.ui.locked = true; RCDT.ApplyConfigUI()
        DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[RaidCDTracker]|r Frame locked.")
        return
    elseif msg == "unlock" then
        EnsureDB(); if not RCDT.db then return end
        RCDT.db.ui.locked = false; RCDT.ApplyConfigUI()
        DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[RaidCDTracker]|r Frame unlocked.")
        return
    end

    DEFAULT_CHAT_FRAME:AddMessage("|cffffff00Usage:|r /raidcd dump | config | filters | debug on|off | lock | unlock")
end



