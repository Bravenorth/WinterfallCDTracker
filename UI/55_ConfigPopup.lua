-- UI/55_ConfigPopup.lua
-- Mini popup de configuration: lock, affichage, reset, lien filtres

local RCDT = RaidCDTracker
local ADDON_NAME  = (RCDT and RCDT.ADDON) or "RaidCDTracker"
local TITLE_TEXT  = ADDON_NAME .. " - Options"

local function EnsureDB()
  if not RCDT.db and RCDT.DBInit then RCDT.DBInit() end
end

-- Frame principale
local cfg = CreateFrame("Frame", "RaidCDTrackerConfigPopup", UIParent)
cfg:SetSize(360, 260)
cfg:SetPoint("CENTER")
cfg:Hide()
cfg:EnableMouse(true)
cfg:SetMovable(true)
cfg:RegisterForDrag("LeftButton")
cfg:SetScript("OnDragStart", cfg.StartMoving)
cfg:SetScript("OnDragStop",  cfg.StopMovingOrSizing)
if UISpecialFrames then table.insert(UISpecialFrames, cfg:GetName()) end

-- Fond
cfg.bg = cfg:CreateTexture(nil, "BACKGROUND")
cfg.bg:SetAllPoints()
cfg.bg:SetColorTexture(0, 0, 0, 0.75)

cfg.title = cfg:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
cfg.title:SetPoint("TOPLEFT", 12, -10)
cfg.title:SetText(TITLE_TEXT)

-- Lock
cfg.lock = RCDT.UI_CreateCheckbox(cfg, "Verrouiller la fenêtre", "Empêche le déplacement de la fenêtre.")
cfg.lock:SetPoint("TOPLEFT", cfg.title, "BOTTOMLEFT", -2, -12)
cfg.lock:SetScript("OnClick", function(self) RCDT.Options_ApplyLock(self:GetChecked()) end)

-- Section Affichage (contexte)
cfg.affTitle = cfg:CreateFontString(nil, "ARTWORK", "GameFontNormal")
cfg.affTitle:SetPoint("TOPLEFT", cfg.lock, "BOTTOMLEFT", 0, -14)
cfg.affTitle:SetText("|cffffd200Affichage (contexte)|r")

cfg.affInstance = RCDT.UI_CreateCheckbox(cfg, "Afficher en instance", "Affiche la fenêtre dans les instances (LFG/LFR/etc.).")
cfg.affInstance:SetPoint("TOPLEFT", cfg.affTitle, "BOTTOMLEFT", 0, -8)
cfg.affInstance:SetScript("OnClick", function() RCDT.Options_ApplyDisplayFromWidgets(cfg.affInstance, cfg.affRaid, cfg.affParty, cfg.affSolo) end)

cfg.affRaid = RCDT.UI_CreateCheckbox(cfg, "Afficher en raid", "Affiche la fenêtre quand vous êtes en raid (hors instance).")
cfg.affRaid:SetPoint("TOPLEFT", cfg.affInstance, "BOTTOMLEFT", 0, -6)
cfg.affRaid:SetScript("OnClick", function() RCDT.Options_ApplyDisplayFromWidgets(cfg.affInstance, cfg.affRaid, cfg.affParty, cfg.affSolo) end)

cfg.affParty = RCDT.UI_CreateCheckbox(cfg, "Afficher en groupe", "Affiche la fenêtre quand vous êtes en groupe (hors raid/instance).")
cfg.affParty:SetPoint("TOPLEFT", cfg.affRaid, "BOTTOMLEFT", 0, -6)
cfg.affParty:SetScript("OnClick", function() RCDT.Options_ApplyDisplayFromWidgets(cfg.affInstance, cfg.affRaid, cfg.affParty, cfg.affSolo) end)

cfg.affSolo = RCDT.UI_CreateCheckbox(cfg, "Afficher en solo", "Affiche la fenêtre quand vous êtes seul(e).")
cfg.affSolo:SetPoint("TOPLEFT", cfg.affParty, "BOTTOMLEFT", 0, -6)
cfg.affSolo:SetScript("OnClick", function() RCDT.Options_ApplyDisplayFromWidgets(cfg.affInstance, cfg.affRaid, cfg.affParty, cfg.affSolo) end)

-- Reset + Filtres
cfg.reset = RCDT.UI_CreateButton(cfg, "Réinitialiser la position", 180, 22)
cfg.reset:SetPoint("TOPLEFT", cfg.affSolo, "BOTTOMLEFT", 0, -14)
cfg.reset:SetScript("OnClick", function() RCDT.Options_ResetPosition() end)

cfg.filtersBtn = RCDT.UI_CreateButton(cfg, "Filtres…", 100, 22)
cfg.filtersBtn:SetPoint("LEFT", cfg.reset, "RIGHT", 8, 0)

cfg.close = CreateFrame("Button", nil, cfg, "UIPanelCloseButton")
cfg.close:SetPoint("TOPRIGHT", 4, 4)
cfg.close:SetScript("OnClick", function() cfg:Hide() end)

cfg:SetScript("OnShow", function()
  EnsureDB()
  if RCDT.FiltersEnsureDefaults then RCDT.FiltersEnsureDefaults() end
  if RCDT.DisplayEnsureDefaults then RCDT.DisplayEnsureDefaults() end
  if RCDT.db and RCDT.db.ui then
    cfg.lock:SetChecked(RCDT.db.ui.locked)
  end
  local d = RCDT.db and RCDT.db.display or {}
  cfg.affInstance:SetChecked(d.instance ~= false)
  cfg.affRaid:SetChecked(d.raid     ~= false)
  cfg.affParty:SetChecked(d.party    ~= false)
  cfg.affSolo:SetChecked(d.solo      ~= false)
end)

-- Expose pour la commande /raidcd config
function RCDT.ToggleConfig()
  if cfg:IsShown() then cfg:Hide() else cfg:Show() end
end

-- Lien bouton depuis le petit panneau (handler défini ici; panel l'utilise aussi)
cfg.filtersBtn:SetScript("OnClick", function() if RCDT.ToggleFilters then RCDT.ToggleFilters() end end)

