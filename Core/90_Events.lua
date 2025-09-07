-- Core/90_Events.lua
-- Frame d’événements, dispatch, tickers logiques

local RCDT = RaidCDTracker

RCDT.frame = CreateFrame("Frame")

RCDT.frame:SetScript("OnEvent", function(_, event, ...)
  if event == "ADDON_LOADED" then
    -- Init une seule fois, quel que soit le nom de dossier/pack (WinterfallCDTracker, etc.)
    if not RCDT._dbInited then
      if RCDT.DBInit then RCDT.DBInit() end
      if RCDT.ApplyConfigUI then RCDT.ApplyConfigUI() end
      RCDT._dbInited = true
    end

  elseif event == "CHAT_MSG_ADDON" then
    RCDT.OnAddonMsg(...)
  elseif event == "PLAYER_ENTERING_WORLD" then
    wipe(RCDT.raidState); wipe(RCDT._lastStates)
    RCDT.PruneRoster()
    local chan = RCDT.Channel()
    if chan then C_ChatInfo.SendAddonMessage(RCDT.PREFIX, "SYNC_REQUEST", chan) end
    RCDT.CheckCooldowns()
  elseif event == "GROUP_ROSTER_UPDATE" then
    RCDT.PruneRoster()
    local chan = RCDT.Channel()
    if chan then C_ChatInfo.SendAddonMessage(RCDT.PREFIX, "SYNC_REQUEST", chan) end
  elseif event == "SPELLS_CHANGED" then
    wipe(RCDT._lastStates)
    RCDT.CheckCooldowns()
  end
end)

RCDT.frame:RegisterEvent("ADDON_LOADED")
RCDT.frame:RegisterEvent("CHAT_MSG_ADDON")
RCDT.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
RCDT.frame:RegisterEvent("GROUP_ROSTER_UPDATE")
RCDT.frame:RegisterEvent("SPELLS_CHANGED")

-- Tick logique (scan des CDs)
C_Timer.NewTicker(1, RCDT.CheckCooldowns)

-- Tick de resync périodique (si en groupe)
C_Timer.NewTicker(60, function()
  local chan = RCDT.Channel()
  if chan then C_ChatInfo.SendAddonMessage(RCDT.PREFIX, "SYNC_REQUEST", chan) end
end)
