-- RaidCDTracker.lua
-- Addon de suivi des cooldowns de raid (MoP)
-- Bravenorth 2025

local ADDON      = "RaidCDTracker"
local VERSION    = 3              -- version du protocole réseau (v3 ajoute activeDur)
local DEBUG_MODE = false          -- affiche logs debug si activé

-- Constantes
local GCD_THRESHOLD = 1.5
local UI_TICK_SEC   = 0.10

------------------------------------------------------------
-- Namespace
------------------------------------------------------------
RaidCDTracker = {}                -- namespace global (exposé)
local RCDT = RaidCDTracker        -- alias local plus court

local f = CreateFrame("Frame")    -- frame racine pour écouter les events

------------------------------------------------------------
-- Catalogue global de cooldowns (MoP)
------------------------------------------------------------
-- Défini dans cd.lua et injecté comme global `RaidCDTracker_Cooldowns`
RCDT.TRACKED_BY_CLASS = _G.RaidCDTracker_Cooldowns or {}

------------------------------------------------------------
-- State & constantes
------------------------------------------------------------
-- Note: on ne “fige” pas TRACKED à la classe du joueur, car on veut valider les sorts reçus pour TOUTES classes.
local PREFIX = "BraveRaidCD"                          -- préfixe des messages addon
do
    local ok = C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
    if not ok then
        -- Impossible d’enregistrer le préfixe (rare). On log si debug.
        DEFAULT_CHAT_FRAME:AddMessage("|cffff5555["..ADDON.."] Impossible d’enregistrer le prefix '"..PREFIX.."'|r")
    end
end

-- Statuts possibles
RCDT.STATUS      = { Ready = 0, Active = 1, OnCD = 2 }
RCDT.STATUS_NAME = { [0] = "Ready", [1] = "Active", [2] = "OnCD" }

-- État partagé (tous les joueurs)
RCDT.raidState   = {}             -- [playerFullName][spellID] = { status, endTime, totalCD, activeDur }
RaidCDTracker_RaidState = RCDT.raidState -- exposé global (pour debug/UI)
local lastStates = {}             -- garde en mémoire le dernier statut de nos propres CDs

------------------------------------------------------------
-- Utils
------------------------------------------------------------
-- Nom complet "Nom-Royaume" du unit (ou nil)
function RCDT.FullUnitName(unit)
    local name, realm = UnitName(unit)
    if not name then return nil end
    if realm and realm ~= "" then return name.."-"..realm end
    return name
end

-- Nom court (sans le "-Serveur") pour l’affichage
function RCDT.ShortName(name)
    return name and name:match("^[^-]+") or name
end

-- Choisit le bon canal de groupe; nil si solo
function RCDT.Channel()
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
    if IsInRaid() then return "RAID" end
    if IsInGroup() then return "PARTY" end
    return nil
end

-- Affiche log de debug si activé
function RCDT.DebugLog(tag, msg)
    if DEBUG_MODE then
        DEFAULT_CHAT_FRAME:AddMessage("|cffa0a0a0["..ADDON.." "..tag.."]|r "..tostring(msg))
    end
end

-- Tri itérable (spairs)
local function spairs(t, cmp)
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

------------------------------------------------------------
-- Roster
------------------------------------------------------------
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
local function PruneRoster()
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
local function IsTrackedFor(playerFull, spellID)
    local class = RCDT.GetClassForPlayer(playerFull)
    local perClass = class and RCDT.TRACKED_BY_CLASS[class]
    return perClass and perClass[spellID] ~= nil
end

------------------------------------------------------------
-- Cooldown logic
------------------------------------------------------------
-- Calcule le statut d’un sort donné (Ready/Active/OnCD)
function RCDT.EvaluateCooldown(spellID, cfg)
    local now = GetTime()

    -- Gestion des charges (si API dispo)
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

    -- Cas cooldown en cours (ignore GCD)
    if enabled == 1 and start and start > 0 and duration and duration > GCD_THRESHOLD then
        remain = (start + duration) - now
        if remain < 0 then remain = 0 end
        state = RCDT.STATUS.OnCD
    end

    -- Cas "Active" (période d'effet du sort)
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

------------------------------------------------------------
-- Networking
------------------------------------------------------------
-- Sérialise un statut de CD en message réseau (v3 inclut activeDur)
function RCDT.SerializeStatus(spellID, state, remain, totalCD, activeDur)
    return ("S:%d:%d:%d:%0.2f:%0.2f:%0.2f"):format(VERSION, spellID, state, remain or 0, totalCD or 0, activeDur or 0)
end

-- Envoie un statut de CD au groupe
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
    C_ChatInfo.SendAddonMessage(PREFIX, RCDT.SerializeStatus(spellID, state, remain, totalCD, activeDur), chan)
    RCDT.DebugLog("SEND", spellID.." -> "..RCDT.STATUS_NAME[state])
end

-- Envoie l’état complet de tous nos CDs
function RCDT.SendFullStatus()
    local classToken = select(2, UnitClass("player"))
    local TRACKED = RCDT.TRACKED_BY_CLASS[classToken] or {}
    for spellID, cfg in pairs(TRACKED) do
        if IsPlayerSpell(spellID) then
            local state, remain, duration, active = RCDT.EvaluateCooldown(spellID, cfg)
            RCDT.SendStatus(spellID, state, remain, duration, active)
        end
    end
end

------------------------------------------------------------
-- Periodic checks
------------------------------------------------------------
-- Vérifie si nos CDs changent de statut, et envoie l’info si oui
function RCDT.CheckCooldowns()
    local classToken = select(2, UnitClass("player"))
    local TRACKED = RCDT.TRACKED_BY_CLASS[classToken] or {}
    for spellID, cfg in pairs(TRACKED) do
        if IsPlayerSpell(spellID) then
            local state, remain, duration, active = RCDT.EvaluateCooldown(spellID, cfg)
            if lastStates[spellID] ~= state then
                lastStates[spellID] = state
                RCDT.SendStatus(spellID, state, remain, duration, active)
            end
        end
    end
end

------------------------------------------------------------
-- Events
------------------------------------------------------------
-- Réception d’un message réseau
local function OnAddonMsg(prefix, msg, _, sender)
    if prefix ~= PREFIX then return end

    -- Demande de synchro (uniquement si en groupe)
    if msg == "SYNC_REQUEST" then
        if RCDT.Channel() then
            C_Timer.After(math.random(0,2), RCDT.SendFullStatus)
        end
        return
    end

    -- Version du message
    local ver = tonumber((msg:match("^S:(%d+):")))
    if not ver or ver < 2 or ver > VERSION then return end

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
    if not IsTrackedFor(who, spellID) then return end

    RCDT.UpdateLocalState(who, spellID, st, remain, total, active)
end

-- Gestion globale des events
f:SetScript("OnEvent", function(_, event, ...)
    if event == "CHAT_MSG_ADDON" then
        OnAddonMsg(...)
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Reset état local + prune
        wipe(RCDT.raidState); wipe(lastStates)
        PruneRoster()
        -- Demande synchro (si en groupe)
        local chan = RCDT.Channel()
        if chan then C_ChatInfo.SendAddonMessage(PREFIX, "SYNC_REQUEST", chan) end
        RCDT.CheckCooldowns()
    elseif event == "GROUP_ROSTER_UPDATE" then
        PruneRoster()
        local chan = RCDT.Channel()
        if chan then C_ChatInfo.SendAddonMessage(PREFIX, "SYNC_REQUEST", chan) end
    elseif event == "SPELLS_CHANGED" then
        wipe(lastStates)
        RCDT.CheckCooldowns()
    end
end)
f:RegisterEvent("CHAT_MSG_ADDON")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("SPELLS_CHANGED")

-- Tick régulier
C_Timer.NewTicker(1, RCDT.CheckCooldowns)   -- vérifie nos CDs toutes les secondes
C_Timer.NewTicker(60, function()             -- redemande synchro toutes les minutes (si en groupe)
    local chan = RCDT.Channel()
    if chan then C_ChatInfo.SendAddonMessage(PREFIX, "SYNC_REQUEST", chan) end
end)

------------------------------------------------------------
-- UI
------------------------------------------------------------
-- Fenêtre principale
RCDT.ui = CreateFrame("Frame", "RaidCDTrackerUIFrame", UIParent)
RCDT.ui:SetSize(320, 400)
RCDT.ui:SetPoint("CENTER")
RCDT.ui:SetMovable(true) RCDT.ui:EnableMouse(true)
RCDT.ui:RegisterForDrag("LeftButton")
RCDT.ui:SetScript("OnDragStart", RCDT.ui.StartMoving)
RCDT.ui:SetScript("OnDragStop", RCDT.ui.StopMovingOrSizing)

-- Scrollable container
local scroll = CreateFrame("ScrollFrame", nil, RCDT.ui, "UIPanelScrollFrameTemplate")
scroll:SetAllPoints(RCDT.ui)
if scroll.ScrollBar then scroll.ScrollBar:Hide(); scroll.ScrollBar.Show = function() end end
local content = CreateFrame("Frame", nil, scroll) content:SetSize(1,1) scroll:SetScrollChild(content)

-- Pool de rows (réutilisés)
local rowPool = {}
local function CreateRow(i)
    local row = CreateFrame("Frame", nil, content)
    row:SetSize(300, 18)

    -- Icône du sort
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(18,18) row.icon:SetPoint("LEFT",0,0)

    -- Barre de progression
    row.bar = CreateFrame("StatusBar", nil, row)
    row.bar:SetSize(220,16) row.bar:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
    row.bar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    row.bar:SetMinMaxValues(0,1)

    -- Texte du joueur (centre)
    row.bar.playerText = row.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.bar.playerText:SetPoint("CENTER")

    -- Timer (droite)
    row.bar.timerText = row.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.bar.timerText:SetPoint("RIGHT", -2, 0)

    -- Positionnement
    if i == 1 then row:SetPoint("TOPLEFT",0,0) else row:SetPoint("TOPLEFT", rowPool[i-1], "BOTTOMLEFT", 0, 0) end
    rowPool[i] = row
    return row
end

local function GetRow(i)
    if not rowPool[i] then return CreateRow(i) end
    rowPool[i]:Show()
    return rowPool[i]
end

-- Couleurs (par statut)
local STATUS_COLORS = { [1]={0,0.7,1}, [2]={1,0,0} }

-- Met à jour l’UI (tri par joueur puis par nom de sort)
function RCDT.UpdateUI()
    local now, i = GetTime(), 1
    for player, spells in spairs(RCDT.raidState, function(a,b)
        return RCDT.ShortName(a) < RCDT.ShortName(b)
    end) do
        local class = RCDT.GetClassForPlayer(player)
        local classColor = (class and RAID_CLASS_COLORS[class]) or { r=1, g=1, b=1 }

        for spellID, data in spairs(spells, function(a,b)
            local na = GetSpellInfo(a) or ""
            local nb = GetSpellInfo(b) or ""
            return na < nb
        end) do
            local row = GetRow(i)
            local _, _, spellIcon = GetSpellInfo(spellID)
            local remain = (data.endTime and data.endTime > 0) and math.max(0, data.endTime - now) or 0

            -- Progression
            local frac
            if data.status == RCDT.STATUS.Ready then
                frac=1; row.bar.timerText:SetText("Ready")
            elseif data.status == RCDT.STATUS.Active and (data.activeDur or 0) > 0 then
                frac=(data.activeDur>0) and (remain/data.activeDur) or 0
                row.bar.timerText:SetText(string.format("%.1fs", remain))
            elseif data.status == RCDT.STATUS.OnCD and (data.totalCD or 0) > 0 then
                frac=1-((data.totalCD>0) and (remain/data.totalCD) or 1)
                if frac < 0 then frac = 0 end
                row.bar.timerText:SetText(string.format("%.1fs", remain))
            else
                frac=0; row.bar.timerText:SetText("")
            end

            -- Couleur de la barre
            local color = (data.status==RCDT.STATUS.Ready)
                and {classColor.r, classColor.g, classColor.b}
                or STATUS_COLORS[data.status] or {1,1,1}

            -- Application à la row
            row.icon:SetTexture(spellIcon or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.bar:SetValue(frac or 0)
            row.bar:SetStatusBarColor(unpack(color))
            row.bar.playerText:SetText(RCDT.ShortName(player))
            i=i+1
        end
    end
    for j=i,#rowPool do rowPool[j]:Hide() end
    RCDT.ui:SetHeight((i-1) * (rowPool[1] and rowPool[1]:GetHeight() or 18) + 10)
end
C_Timer.NewTicker(UI_TICK_SEC, RCDT.UpdateUI)

------------------------------------------------------------
-- Slash command
------------------------------------------------------------
SLASH_RAIDCD1 = "/raidcd"
SlashCmdList["RAIDCD"] = function(msg)
    if msg=="dump" then
        -- Affiche état courant
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff00--- "..ADDON.." raidState dump ---|r")
        if not next(RCDT.raidState) then DEFAULT_CHAT_FRAME:AddMessage("  (aucune donnée connue)") return end
        for player, spells in spairs(RCDT.raidState, function(a,b)
            return RCDT.ShortName(a) < RCDT.ShortName(b)
        end) do
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00"..RCDT.ShortName(player).."|r:")
            for spellID,data in spairs(spells, function(a,b)
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
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff00Usage: /raidcd dump|r")
    end
end
