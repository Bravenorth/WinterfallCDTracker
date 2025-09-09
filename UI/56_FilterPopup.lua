-- UI/56_FilterPopup.lua
-- Popup filtres par classe

local RCDT = RaidCDTracker
local ADDON_NAME  = (RCDT and RCDT.ADDON) or "RaidCDTracker"

local function EnsureDB()
  if not RCDT.db and RCDT.DBInit then RCDT.DBInit() end
end

local function GetTrackedByClass()
  return (RCDT.GetTrackedByClass and RCDT.GetTrackedByClass()) or {}
end

-- Frame principale
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
filter.checkAll = RCDT.UI_CreateButton(filter, "Tout cocher", 110, 22)
filter.checkAll:SetPoint("LEFT", classDD, "RIGHT", 30, 2)
filter.uncheckAll = RCDT.UI_CreateButton(filter, "Tout décocher", 110, 22)
filter.uncheckAll:SetPoint("LEFT", filter.checkAll, "RIGHT", 8, 0)

-- Scrollframe
local scroll = CreateFrame("ScrollFrame", "RaidCDTrackerFilterScroll", filter, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", classDD, "BOTTOMLEFT", 16, -8)
scroll:SetPoint("BOTTOMRIGHT", -28, 16)

local list = CreateFrame("Frame", nil, scroll)
list:SetHeight(1)
scroll:SetScrollChild(list)

local function UpdateListWidth()
  local w = scroll:GetWidth()
  if not w or w <= 0 then w = 360 end
  list:SetWidth(math.max(120, w - 4))
end
scroll:SetScript("OnSizeChanged", function() UpdateListWidth() end)
filter:SetScript("OnShow", function(self) UpdateListWidth() end)

-- Rows
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
  RCDT.db.filters = RCDT.db.filters or {}
  RCDT.db.filters[classToken] = RCDT.db.filters[classToken] or {}
  RCDT.db.filters[classToken][spellID] = enabled and true or false
  if RCDT.UpdateUI then RCDT.UpdateUI() end
end

local function BuildClassSpellList()
  EnsureDB()
  if RCDT.FiltersEnsureDefaults then RCDT.FiltersEnsureDefaults() end
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
    row.cb:SetChecked(not not (RCDT.IsSpellEnabledForClass and RCDT.IsSpellEnabledForClass(currentClass, spellID)))

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
  EnsureDB(); if RCDT.FiltersEnsureDefaults then RCDT.FiltersEnsureDefaults() end
  local BY = GetTrackedByClass()[currentClass] or {}
  RCDT.db.filters = RCDT.db.filters or {}
  RCDT.db.filters[currentClass] = RCDT.db.filters[currentClass] or {}
  for spellID in pairs(BY) do RCDT.db.filters[currentClass][spellID] = true end
  BuildClassSpellList()
  if RCDT.UpdateUI then RCDT.UpdateUI() end
end)

filter.uncheckAll:SetScript("OnClick", function()
  EnsureDB(); if RCDT.FiltersEnsureDefaults then RCDT.FiltersEnsureDefaults() end
  local BY = GetTrackedByClass()[currentClass] or {}
  RCDT.db.filters = RCDT.db.filters or {}
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
  if RCDT.FiltersEnsureDefaults then RCDT.FiltersEnsureDefaults() end
  if not GetTrackedByClass()[currentClass] then
    for token in pairs(GetTrackedByClass()) do currentClass = token; break end
  end
  UIDropDownMenu_SetSelectedValue(classDD, currentClass)
  UIDropDownMenu_SetText(classDD, GetLocalizedClassName(currentClass))
  BuildClassSpellList()
end)

-- Expose open/close
function RCDT.ToggleFilters()
  if filter:IsShown() then filter:Hide() else filter:Show() end
end

