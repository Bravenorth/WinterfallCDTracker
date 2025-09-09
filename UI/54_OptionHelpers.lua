-- UI/54_OptionHelpers.lua
-- Helpers communs pour les options (lock/reset/affichage)

local RCDT = RaidCDTracker

function RCDT.Options_ApplyLock(checked)
  if not RCDT.db then return end
  RCDT.db.ui.locked = not not checked
  if RCDT.ApplyConfigUI then RCDT.ApplyConfigUI() end
end

function RCDT.Options_ResetPosition()
  if not RCDT.db then return end
  RCDT.db.ui.pos = nil
  if RCDT.ui then
    RCDT.ui:ClearAllPoints()
    RCDT.ui:SetPoint("CENTER")
  end
end

function RCDT.Options_ApplyDisplayFromWidgets(wInstance, wRaid, wParty, wSolo)
  if not RCDT.db then return end
  if RCDT.DisplayEnsureDefaults then RCDT.DisplayEnsureDefaults() end
  local d = RCDT.db.display
  if wInstance then d.instance = wInstance:GetChecked() and true or false end
  if wRaid     then d.raid     = wRaid:GetChecked()     and true or false end
  if wParty    then d.party    = wParty:GetChecked()    and true or false end
  if wSolo     then d.solo     = wSolo:GetChecked()     and true or false end
  if RCDT.UpdateUI then RCDT.UpdateUI() end
end

