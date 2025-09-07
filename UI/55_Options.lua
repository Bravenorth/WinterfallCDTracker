-- UI/55_Options.lua
-- Panneau d'options (Blizzard + mini popup interne) : lock + reset + filtres + affichage (MoP Classic)

local RCDT = RaidCDTracker
local ADDON_NAME  = (RCDT and RCDT.ADDON) or "RaidCDTracker"
local TITLE_TEXT  = ADDON_NAME .. " - Options"

------------------------------------------------------------
-- Helpers DB / Filtres / Affichage
------------------------------------------------------------
local function EnsureDB()
  if not RCDT.db and RCDT.DBInit then RCDT.DBInit() end
end

-- Retourne la table de données (cd.lua) quel que soit l'ordre de chargement
local function GetTrackedByClass()
  return _G.RaidCDTracker_Cooldowns or RCDT.TRACKED_BY_CLASS or {}
end

-- Filtres (par classe/spell) : défaut = visible
function RCDT.FiltersEnsureDefaults()
  EnsureDB()
  local db = RCDT.db; if not db then return end
  db.filters = db.filters or {}
  local BY = GetTrackedByClass()
  for class, spells in pairs(BY) do
    db.filters[class] = db.filters[class] or {}
    for spellID in pairs(spells) do
      if db.filters[class][spellID] == nil then
        db.filters[class][spellID] = true
      end
    end
  end
end

-- Affichage par contexte : défaut = tout ON
local function DisplayEnsureDefaults()
  EnsureDB()
  if not RCDT.db then return end
  RCDT.db.display = RCDT.db.display or {}
  local d = RCDT.db.display
  if d.instance == nil then d.instance = true end
  if d.raid     == nil then d.raid     = true end
  if d.party    == nil then d.party    = true end
  if d.solo     == nil then d.solo     = true end
end

-- Query filtre local (UI-only)
function RCDT.IsSpellEnabledForClass(classToken, spellID)
  EnsureDB()
  local f = RCDT.db and RCDT.db.filters
  if not f then return true end
  local cf = f[classToken]
  if not cf then return true end
  local v = cf[spellID]
  if v == nil then return true end
  return not not v
end

local function ApplyLock(checked)
  EnsureDB()
  if not RCDT.db then return end
  RCDT.db.ui.locked = not not checked
  if RCDT.ApplyConfigUI then RCDT.ApplyConfigUI() end
end

local function ResetPosition()
  if not RCDT.db then return end
  RCDT.db.ui.pos = nil
  RCDT.ui:ClearAllPoints()
  RCDT.ui:SetPoint("CENTER")
end

local function CreateCheckbox(parent, label, tooltip)
  local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
  cb.Text:SetText(label or "")
  if tooltip then
    cb.tooltipText = label
    cb.tooltipRequirement = tooltip
  end
  return cb
end

local function CreateButton(parent, label, width, height)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(width or 120, height or 22)
  b:SetText(label)
  return b
end

-- Applique l’état d’affichage d’après 4 checkboxes données
local function ApplyDisplayFromWidgets(wInstance, wRaid, wParty, wSolo)
  EnsureDB(); DisplayEnsureDefaults()
  if not RCDT.db then return end
  local d = RCDT.db.display
  if wInstance then d.instance = wInstance:GetChecked() and true or false end
  if wRaid     then d.raid     = wRaid:GetChecked()     and true or false end
  if wParty    then d.party    = wParty:GetChecked()    and true or false end
  if wSolo     then d.solo     = wSolo:GetChecked()     and true or false end
  if RCDT.UpdateUI then RCDT.UpdateUI() end
end

------------------------------------------------------------
-- 1) Mini Popup interne (toujours dispo via /raidcd config)
------------------------------------------------------------
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

-- Fond simple
cfg.bg = cfg:CreateTexture(nil, "BACKGROUND")
cfg.bg:SetAllPoints()
cfg.bg:SetColorTexture(0, 0, 0, 0.75)

cfg.title = cfg:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
cfg.title:SetPoint("TOPLEFT", 12, -10)
cfg.title:SetText(TITLE_TEXT)

-- Lock
cfg.lock = CreateCheckbox(cfg, "Verrouiller la fenêtre", "Empêche le déplacement de la fenêtre.")
cfg.lock:SetPoint("TOPLEFT", cfg.title, "BOTTOMLEFT", -2, -12)
cfg.lock:SetScript("OnClick", function(self) ApplyLock(self:GetChecked()) end)

-- Section Affichage (contexte) — AJOUTÉE AU POPUP
cfg.affTitle = cfg:CreateFontString(nil, "ARTWORK", "GameFontNormal")
cfg.affTitle:SetPoint("TOPLEFT", cfg.lock, "BOTTOMLEFT", 0, -14)
cfg.affTitle:SetText("|cffffd200Affichage (contexte)|r")

cfg.affInstance = CreateCheckbox(cfg, "Afficher en instance", "Affiche la fenêtre dans les instances (LFG/LFR/etc.).")
cfg.affInstance:SetPoint("TOPLEFT", cfg.affTitle, "BOTTOMLEFT", 0, -8)
cfg.affInstance:SetScript("OnClick", function() ApplyDisplayFromWidgets(cfg.affInstance, cfg.affRaid, cfg.affParty, cfg.affSolo) end)

cfg.affRaid = CreateCheckbox(cfg, "Afficher en raid", "Affiche la fenêtre quand vous êtes en raid (hors instance).")
cfg.affRaid:SetPoint("TOPLEFT", cfg.affInstance, "BOTTOMLEFT", 0, -6)
cfg.affRaid:SetScript("OnClick", function() ApplyDisplayFromWidgets(cfg.affInstance, cfg.affRaid, cfg.affParty, cfg.affSolo) end)

cfg.affParty = CreateCheckbox(cfg, "Afficher en groupe", "Affiche la fenêtre quand vous êtes en groupe (hors raid/instance).")
cfg.affParty:SetPoint("TOPLEFT", cfg.affRaid, "BOTTOMLEFT", 0, -6)
cfg.affParty:SetScript("OnClick", function() ApplyDisplayFromWidgets(cfg.affInstance, cfg.affRaid, cfg.affParty, cfg.affSolo) end)

cfg.affSolo = CreateCheckbox(cfg, "Afficher en solo", "Affiche la fenêtre quand vous êtes seul(e).")
cfg.affSolo:SetPoint("TOPLEFT", cfg.affParty, "BOTTOMLEFT", 0, -6)
cfg.affSolo:SetScript("OnClick", function() ApplyDisplayFromWidgets(cfg.affInstance, cfg.affRaid, cfg.affParty, cfg.affSolo) end)

-- Reset + Filtres
cfg.reset = CreateButton(cfg, "Réinitialiser la position", 180, 22)
cfg.reset:SetPoint("TOPLEFT", cfg.affSolo, "BOTTOMLEFT", 0, -14)
cfg.reset:SetScript("OnClick", ResetPosition)

cfg.filtersBtn = CreateButton(cfg, "Filtres…", 100, 22)
cfg.filtersBtn:SetPoint("LEFT", cfg.reset, "RIGHT", 8, 0)

cfg.close = CreateFrame("Button", nil, cfg, "UIPanelCloseButton")
cfg.close:SetPoint("TOPRIGHT", 4, 4)
cfg.close:SetScript("OnClick", function() cfg:Hide() end)

cfg:SetScript("OnShow", function()
  EnsureDB()
  RCDT.FiltersEnsureDefaults()
  DisplayEnsureDefaults()
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

------------------------------------------------------------
-- 2) Popup Filtres par classe (liste propre)
------------------------------------------------------------
local filter = CreateFrame("Frame", "RaidCDTrackerFilterPopup", UIParent)
filter:SetSize(500, 500)
filter:SetPoint("CENTER", 20, 0)
filter:Hide()
filter:EnableMouse(true)
filter:SetMovable(true)
filter:RegisterForDrag("LeftButton")
filter:SetScript("OnDragStart", filter.StartMoving)
filter:SetScript("OnDragStop",  filter.StopMovingOrSizing)
if UISpecialFrames then table.insert(UISpecialFrames, filter:GetName()) end

filter.bg = filter:CreateTexture(nil, "BACKGROUND")
filter.bg:SetAllPoints()
filter.bg:SetColorTexture(0, 0, 0, 0.80)

filter.title = filter:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
filter.title:SetPoint("TOPLEFT", 12, -10)
filter.title:SetText(ADDON_NAME .. " - Filtres")

-- Dropdown classes
local classDD = CreateFrame("Frame", "RaidCDTrackerClassDropdown", filter, "UIDropDownMenuTemplate")
classDD:SetPoint("TOPLEFT", filter.title, "BOTTOMLEFT", -14, -6)

local currentClass = select(2, UnitClass("player")) or "PRIEST"

-- Boutons Tout cocher / Tout décocher
filter.checkAll = CreateButton(filter, "Tout cocher", 110, 22)
filter.checkAll:SetPoint("LEFT", classDD, "RIGHT", 30, 2)
filter.uncheckAll = CreateButton(filter, "Tout décocher", 110, 22)
filter.uncheckAll:SetPoint("LEFT", filter.checkAll, "RIGHT", 8, 0)

-- Scrollframe
local scroll = CreateFrame("ScrollFrame", "RaidCDTrackerFilterScroll", filter, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", classDD, "BOTTOMLEFT", 16, -8)
scroll:SetPoint("BOTTOMRIGHT", -28, 16)

local list = CreateFrame("Frame", nil, scroll)
list:SetHeight(1)
scroll:SetScrollChild(list)

-- Ajuste dynamiquement la largeur utile
local function UpdateListWidth()
  local w = scroll:GetWidth()
  if not w or w <= 0 then w = 360 end
  list:SetWidth(math.max(120, w - 4))
end
scroll:SetScript("OnSizeChanged", function() UpdateListWidth() end)
filter:SetScript("OnShow", function(self) UpdateListWidth() end)

-- Rows (Frame + icône + UICheckButton + label)
local ROW_H = 22
local rows = {}

local function GetLocalizedClassName(token)
  return (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token]) or token
end

local function RowFactory(i)
  local row = CreateFrame("Button", nil, list)
  row:SetHeight(ROW_H)

  if i == 1 then
    row:SetPoint("TOPLEFT", 0, 0)
  else
    row:SetPoint("TOPLEFT", rows[i-1], "BOTTOMLEFT", 0, -2)
  end
  row:SetPoint("RIGHT", list, "RIGHT", 0, 0)
  row:EnableMouse(true)

  row.hl = row:CreateTexture(nil, "HIGHLIGHT")
  row.hl:SetAllPoints()
  row.hl:SetColorTexture(1, 1, 1, 0.08)

  row.icon = row:CreateTexture(nil, "ARTWORK")
  row.icon:SetSize(18, 18)
  row.icon:SetPoint("LEFT", 2, 0)

  row.cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
  row.cb:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
  row.cb:SetSize(18, 18)
  if row.cb.Text then row.cb.Text:Hide() end

  row.text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  row.text:SetPoint("LEFT", row.cb, "RIGHT", 8, 0)
  row.text:SetPoint("RIGHT", -6, 0)
  row.text:SetJustifyH("LEFT")
  if row.text.SetWordWrap then row.text:SetWordWrap(false) end
  if row.text.SetNonSpaceWrap then row.text:SetNonSpaceWrap(false) end
  if row.text.SetMaxLines then row.text:SetMaxLines(1) end

  rows[i] = row
  return row
end

local function GetRow(i)
  if not rows[i] then return RowFactory(i) end
  rows[i]:Show()
  return rows[i]
end

local function SetFilterValue(classToken, spellID, enabled)
  EnsureDB()
  RCDT.db.filters[classToken] = RCDT.db.filters[classToken] or {}
  RCDT.db.filters[classToken][spellID] = enabled and true or false
  if RCDT.UpdateUI then RCDT.UpdateUI() end
end

local function BuildClassSpellList()
  EnsureDB()
  RCDT.FiltersEnsureDefaults()
  UpdateListWidth()

  local BY = GetTrackedByClass()
  local spells = BY[currentClass] or {}

  local ids = {}
  for sid in pairs(spells) do table.insert(ids, sid) end
  table.sort(ids, function(a,b)
    local na = GetSpellInfo(a) or ""
    local nb = GetSpellInfo(b) or ""
    if na == nb then return a < b end
    return na < nb
  end)

  local i = 1
  for _, spellID in ipairs(ids) do
    local name, _, icon = GetSpellInfo(spellID)
    local row = GetRow(i)

    row.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    row.text:SetText((name or ("Spell "..spellID)) .. " |cff808080("..spellID..")|r")
    row.cb:SetChecked(RCDT.IsSpellEnabledForClass(currentClass, spellID))

    row.cb:SetScript("OnClick", function(self)
      SetFilterValue(currentClass, spellID, self:GetChecked())
    end)
    row:SetScript("OnClick", function()
      row.cb:SetChecked(not row.cb:GetChecked())
      SetFilterValue(currentClass, spellID, row.cb:GetChecked())
    end)

    i = i + 1
  end

  for j = i, #rows do rows[j]:Hide() end
  list:SetHeight((i-1) * (ROW_H + 2))
end

-- Dropdown init
local function ClassDropdown_Initialize(self, level)
  local BY = GetTrackedByClass()
  local tokens = {}
  for token in pairs(BY) do table.insert(tokens, token) end
  table.sort(tokens, function(a,b) return GetLocalizedClassName(a) < GetLocalizedClassName(b) end)

  for _, token in ipairs(tokens) do
    local info = UIDropDownMenu_CreateInfo()
    info.text  = GetLocalizedClassName(token)
    info.value = token
    info.func = function()
      currentClass = token
      UIDropDownMenu_SetSelectedValue(classDD, token)
      UIDropDownMenu_SetText(classDD, GetLocalizedClassName(token))
      BuildClassSpellList()
    end
    UIDropDownMenu_AddButton(info, level)
  end
end

UIDropDownMenu_Initialize(classDD, ClassDropdown_Initialize)
UIDropDownMenu_SetWidth(classDD, 180)
UIDropDownMenu_JustifyText(classDD, "LEFT")

filter.checkAll:SetScript("OnClick", function()
  EnsureDB(); RCDT.FiltersEnsureDefaults()
  local BY = GetTrackedByClass()[currentClass] or {}
  RCDT.db.filters[currentClass] = RCDT.db.filters[currentClass] or {}
  for spellID in pairs(BY) do RCDT.db.filters[currentClass][spellID] = true end
  BuildClassSpellList()
  if RCDT.UpdateUI then RCDT.UpdateUI() end
end)

filter.uncheckAll:SetScript("OnClick", function()
  EnsureDB(); RCDT.FiltersEnsureDefaults()
  local BY = GetTrackedByClass()[currentClass] or {}
  RCDT.db.filters[currentClass] = RCDT.db.filters[currentClass] or {}
  for spellID in pairs(BY) do RCDT.db.filters[currentClass][spellID] = false end
  BuildClassSpellList()
  if RCDT.UpdateUI then RCDT.UpdateUI() end
end)

filter.close = CreateFrame("Button", nil, filter, "UIPanelCloseButton")
filter.close:SetPoint("TOPRIGHT", 4, 4)
filter.close:SetScript("OnClick", function() filter:Hide() end)

filter:SetScript("OnShow", function()
  EnsureDB()
  RCDT.FiltersEnsureDefaults()
  if not GetTrackedByClass()[currentClass] then
    for token in pairs(GetTrackedByClass()) do currentClass = token; break end
  end
  UIDropDownMenu_SetSelectedValue(classDD, currentClass)
  UIDropDownMenu_SetText(classDD, GetLocalizedClassName(currentClass))
  BuildClassSpellList()
end)

-- Ouvre/ferme le popup filtres
function RCDT.ToggleFilters()
  if filter:IsShown() then filter:Hide() else filter:Show() end
end

-- Lien bouton depuis le petit panneau
cfg.filtersBtn:SetScript("OnClick", function() RCDT.ToggleFilters() end)

------------------------------------------------------------
-- 3) Panneau Blizzard (si l’UI Options fonctionne chez l’utilisateur) + Affichage par contexte
------------------------------------------------------------
local panel = CreateFrame("Frame", "RaidCDTrackerOptionsPanel")
panel.name = ADDON_NAME
RCDT.optionsPanel = panel

panel.title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
panel.title:SetPoint("TOPLEFT", 16, -16)
panel.title:SetText(TITLE_TEXT)

-- Verrouillage / Reset
panel.lock = CreateCheckbox(panel, "Verrouiller la fenêtre", "Empêche le déplacement de la fenêtre.")
panel.lock:SetPoint("TOPLEFT", panel.title, "BOTTOMLEFT", 0, -12)
panel.lock:SetScript("OnClick", function(self) ApplyLock(self:GetChecked()) end)

panel.reset = CreateButton(panel, "Réinitialiser la position", 180, 22)
panel.reset:SetPoint("TOPLEFT", panel.lock, "BOTTOMLEFT", 0, -16)
panel.reset:SetScript("OnClick", ResetPosition)

panel.filtersBtn = CreateButton(panel, "Ouvrir les filtres…", 160, 22)
panel.filtersBtn:SetPoint("LEFT", panel.reset, "RIGHT", 8, 0)
panel.filtersBtn:SetScript("OnClick", function() RCDT.ToggleFilters() end)

-- Section Affichage (où afficher la fenêtre ?)
panel.affTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
panel.affTitle:SetPoint("TOPLEFT", panel.reset, "BOTTOMLEFT", 0, -20)
panel.affTitle:SetText("|cffffd200Affichage (contexte)|r")

panel.affInstance = CreateCheckbox(panel, "Afficher en instance", "Affiche la fenêtre dans les instances (LFG/LFR/etc.).")
panel.affInstance:SetPoint("TOPLEFT", panel.affTitle, "BOTTOMLEFT", 0, -8)

panel.affRaid = CreateCheckbox(panel, "Afficher en raid", "Affiche la fenêtre quand vous êtes en raid (hors instance).")
panel.affRaid:SetPoint("TOPLEFT", panel.affInstance, "BOTTOMLEFT", 0, -8)

panel.affParty = CreateCheckbox(panel, "Afficher en groupe", "Affiche la fenêtre quand vous êtes en groupe (hors raid/instance).")
panel.affParty:SetPoint("TOPLEFT", panel.affRaid, "BOTTOMLEFT", 0, -8)

panel.affSolo = CreateCheckbox(panel, "Afficher en solo", "Affiche la fenêtre quand vous êtes seul(e).")
panel.affSolo:SetPoint("TOPLEFT", panel.affParty, "BOTTOMLEFT", 0, -8)

local function ApplyDisplayFromPanel()
  ApplyDisplayFromWidgets(panel.affInstance, panel.affRaid, panel.affParty, panel.affSolo)
end
panel.affInstance:SetScript("OnClick", ApplyDisplayFromPanel)
panel.affRaid:SetScript("OnClick", ApplyDisplayFromPanel)
panel.affParty:SetScript("OnClick", ApplyDisplayFromPanel)
panel.affSolo:SetScript("OnClick", ApplyDisplayFromPanel)

-- Callbacks standard
panel.okay = function(self)
  ApplyLock(panel.lock:GetChecked())
  ApplyDisplayFromPanel()
end
panel.cancel = function(self) end
panel.default = function(self)
  EnsureDB(); DisplayEnsureDefaults()
  if not RCDT.db then return end
  RCDT.db.display.instance = true
  RCDT.db.display.raid     = true
  RCDT.db.display.party    = true
  RCDT.db.display.solo     = true
  ApplyLock(false)
  if panel.refresh then panel:refresh() end
  if RCDT.UpdateUI then RCDT.UpdateUI() end
end
panel.refresh = function(self)
  EnsureDB(); RCDT.FiltersEnsureDefaults(); DisplayEnsureDefaults()
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
