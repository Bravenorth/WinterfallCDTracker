-- UI/57_BlizzardOptions.lua
-- Panneau d'options Blizzard + affichage par contexte

local RCDT = RaidCDTracker
local ADDON_NAME  = (RCDT and RCDT.ADDON) or "RaidCDTracker"
local TITLE_TEXT  = ADDON_NAME .. " - Options"

local function EnsureDB()
  if not RCDT.db and RCDT.DBInit then RCDT.DBInit() end
end

-- Frame panel
local panel = CreateFrame("Frame", "RaidCDTrackerOptionsPanel")
panel.name = ADDON_NAME
RCDT.optionsPanel = panel

panel.title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
panel.title:SetPoint("TOPLEFT", 16, -16)
panel.title:SetText(TITLE_TEXT)

-- Verrouillage / Reset
panel.lock = RCDT.UI_CreateCheckbox(panel, "Verrouiller la fenêtre", "Empêche le déplacement de la fenêtre.")
panel.lock:SetPoint("TOPLEFT", panel.title, "BOTTOMLEFT", 0, -12)
panel.lock:SetScript("OnClick", function(self) RCDT.Options_ApplyLock(self:GetChecked()) end)

panel.reset = RCDT.UI_CreateButton(panel, "Réinitialiser la position", 180, 22)
panel.reset:SetPoint("TOPLEFT", panel.lock, "BOTTOMLEFT", 0, -16)
panel.reset:SetScript("OnClick", function() RCDT.Options_ResetPosition() end)

panel.filtersBtn = RCDT.UI_CreateButton(panel, "Ouvrir les filtres…", 160, 22)
panel.filtersBtn:SetPoint("LEFT", panel.reset, "RIGHT", 8, 0)
panel.filtersBtn:SetScript("OnClick", function() if RCDT.ToggleFilters then RCDT.ToggleFilters() end end)

-- Section Affichage (où afficher la fenêtre ?)
panel.affTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
panel.affTitle:SetPoint("TOPLEFT", panel.reset, "BOTTOMLEFT", 0, -20)
panel.affTitle:SetText("|cffffd200Affichage (contexte)|r")

panel.affInstance = RCDT.UI_CreateCheckbox(panel, "Afficher en instance", "Affiche la fenêtre dans les instances (LFG/LFR/etc.).")
panel.affInstance:SetPoint("TOPLEFT", panel.affTitle, "BOTTOMLEFT", 0, -8)

panel.affRaid = RCDT.UI_CreateCheckbox(panel, "Afficher en raid", "Affiche la fenêtre quand vous êtes en raid (hors instance).")
panel.affRaid:SetPoint("TOPLEFT", panel.affInstance, "BOTTOMLEFT", 0, -8)

panel.affParty = RCDT.UI_CreateCheckbox(panel, "Afficher en groupe", "Affiche la fenêtre quand vous êtes en groupe (hors raid/instance).")
panel.affParty:SetPoint("TOPLEFT", panel.affRaid, "BOTTOMLEFT", 0, -8)

panel.affSolo = RCDT.UI_CreateCheckbox(panel, "Afficher en solo", "Affiche la fenêtre quand vous êtes seul(e).")
panel.affSolo:SetPoint("TOPLEFT", panel.affParty, "BOTTOMLEFT", 0, -8)

local function ApplyDisplayFromPanel()
  RCDT.Options_ApplyDisplayFromWidgets(panel.affInstance, panel.affRaid, panel.affParty, panel.affSolo)
end
panel.affInstance:SetScript("OnClick", ApplyDisplayFromPanel)
panel.affRaid:SetScript("OnClick", ApplyDisplayFromPanel)
panel.affParty:SetScript("OnClick", ApplyDisplayFromPanel)
panel.affSolo:SetScript("OnClick", ApplyDisplayFromPanel)

-- Callbacks standard
panel.okay = function(self)
  RCDT.Options_ApplyLock(panel.lock:GetChecked())
  ApplyDisplayFromPanel()
end
panel.cancel = function(self) end
panel.default = function(self)
  EnsureDB(); if RCDT.DisplayEnsureDefaults then RCDT.DisplayEnsureDefaults() end
  if not RCDT.db then return end
  RCDT.db.display.instance = true
  RCDT.db.display.raid     = true
  RCDT.db.display.party    = true
  RCDT.db.display.solo     = true
  RCDT.Options_ApplyLock(false)
  if panel.refresh then panel:refresh() end
  if RCDT.UpdateUI then RCDT.UpdateUI() end
end
panel.refresh = function(self)
  EnsureDB(); if RCDT.FiltersEnsureDefaults then RCDT.FiltersEnsureDefaults() end; if RCDT.DisplayEnsureDefaults then RCDT.DisplayEnsureDefaults() end
  if not RCDT.db then return end
  panel.lock:SetChecked(RCDT.db.ui and RCDT.db.ui.locked)
  local d = RCDT.db.display or {}
  panel.affInstance:SetChecked(d.instance ~= false)
  panel.affRaid:SetChecked(d.raid     ~= false)
  panel.affParty:SetChecked(d.party    ~= false)
  panel.affSolo:SetChecked(d.solo      ~= false)
end
panel:SetScript("OnShow", function() if panel.refresh then panel:refresh() end end)

-- Enregistrement du panneau (MoP Classic)
local function AddOptionsCategoryMoP(frame)
  if InterfaceOptions_AddCategory then
    RaidCDTracker._optionsCategory = InterfaceOptions_AddCategory(frame) ; return
  end
  if InterfaceOptionsFrame_AddCategory then
    RaidCDTracker._optionsCategory = InterfaceOptionsFrame_AddCategory(frame) ; return
  end
  DEFAULT_CHAT_FRAME:AddMessage("|cffff5555["..ADDON_NAME.."]|r Panneau Blizzard non enregistré (API indisponible). Utilisez /raidcd config.")
end

AddOptionsCategoryMoP(panel)

