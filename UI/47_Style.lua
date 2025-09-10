-- UI/47_Style.lua
-- Gestion du style (tailles, textures, couleurs)

local RCDT = RaidCDTracker

function RCDT.StyleEnsureDefaults()
  if not RCDT.db then return end
  local ui = RCDT.db.ui or {}
  ui.style = ui.style or {}
  RCDT.db.ui = ui
  local s = ui.style
  local defs = {
    -- Preview / edit mode
    editMode = false,
    -- Mode d'affichage
    displayMode = "bars", -- "bars" ou "icons"

    -- Barres
    rowHeight = 18,
    rowSpacing = 0,
    barIconSize = 18,
    barWidth = 220,
    barTexture = "Interface\\TARGETINGFRAME\\UI-StatusBar",
    fontSize = 11,
    showTimer = true,
    showPlayer = true,
    iconOnRight = false,
    growUp = false,
    useClassColorWhenReady = true,
    readyColor = { r = 0.2, g = 0.8, b = 0.2 },
    activeColor = { r = 0.0, g = 0.7, b = 1.0 },
    onCDColor   = { r = 1.0, g = 0.0, b = 0.0 },

    -- Icônes
    iconColumns = 8,
    iconSpacing = 4,
    iconShowSpellName = false,
    iconShowPlayerName = false,
    iconUseNumbers = true,
    iconFontSize = 11,
    iconDesaturateOnCD = true,
    iconBorder = false,
    iconBorderSize = 1,
    icons = {
      size = 18,
      columns = 8,
      spacing = 4,
      showSpellName = false,
      showPlayerName = false,
      useNumbers = true,
      fontSize = 11,
      desaturateOnCD = true,
      border = false,
      borderSize = 1,
    },
  }
  for k,v in pairs(defs) do
    if s[k] == nil then
      if type(v) == "table" then s[k] = { r=v.r, g=v.g, b=v.b, a=v.a } else s[k] = v end
    end
  end
  -- Backward-compat: if legacy fields exist, hydrate nested icons + barIconSize
  s.icons = s.icons or {}
  local function ensureIcons(toKey, fromKey)
    if s.icons[toKey] == nil and s[fromKey] ~= nil then s.icons[toKey] = s[fromKey] end
  end
  ensureIcons('size', 'iconSize')
  ensureIcons('columns', 'iconColumns')
  ensureIcons('spacing', 'iconSpacing')
  ensureIcons('showSpellName', 'iconShowSpellName')
  ensureIcons('showPlayerName', 'iconShowPlayerName')
  ensureIcons('useNumbers', 'iconUseNumbers')
  ensureIcons('fontSize', 'iconFontSize')
  ensureIcons('desaturateOnCD', 'iconDesaturateOnCD')
  ensureIcons('border', 'iconBorder')
  ensureIcons('borderSize', 'iconBorderSize')
  if s.barIconSize == nil and s.iconSize ~= nil then s.barIconSize = s.iconSize end
end

function RCDT.GetStyle()
  if RCDT.db then RCDT.StyleEnsureDefaults() end
  return (RCDT.db and RCDT.db.ui and RCDT.db.ui.style) or {}
end

-- Preview / Edit mode toggle
function RCDT.SetEditMode(on)
  if not RCDT.db then return end
  RCDT.db.ui = RCDT.db.ui or {}
  RCDT.db.ui.style = RCDT.db.ui.style or {}
  RCDT.db.ui.style.editMode = not not on
  if RCDT.UpdateUI then RCDT.UpdateUI() end
end

function RCDT.IsEditEnabled()
  local s = (RCDT.GetStyle and RCDT.GetStyle()) or {}
  return not not s.editMode
end

-- Apply current style to an existing row
function RCDT.ApplyStyleToRow(row)
  local s = (RCDT.GetStyle and RCDT.GetStyle()) or {}
  local rh = s.rowHeight or 18
  local iszBar = s.barIconSize or 18
  local bw  = s.barWidth or 220

  if s.displayMode == "icons" then
    local iconSize = (s.icons and s.icons.size) or 18
    local fs = (s.icons and s.icons.fontSize) or s.fontSize or 11
    local topExtra = ((s.icons and s.icons.showSpellName) and (fs + 2)) or 0
    local bottomExtra = ((s.icons and s.icons.showPlayerName) and (fs + 2)) or 0
    row:SetHeight(iconSize + topExtra + bottomExtra)
    row:SetWidth(iconSize)
    row.icon:SetSize(iconSize, iconSize)
    row.icon:ClearAllPoints()
    row.icon:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -topExtra)
    -- Constrain label widths to icon, disable wrapping and center
    if row.nameTop then
      row.nameTop:SetWidth(iconSize)
      row.nameTop:SetJustifyH("CENTER")
      if row.nameTop.SetWordWrap then row.nameTop:SetWordWrap(false) end
    end
    if row.nameBottom then
      row.nameBottom:SetWidth(iconSize)
      row.nameBottom:SetJustifyH("CENTER")
      if row.nameBottom.SetWordWrap then row.nameBottom:SetWordWrap(false) end
    end
    row.bar:Hide()
    local fsz = (s.icons and s.icons.fontSize) or s.fontSize
    if fsz then
      local font = (GameFontHighlightSmall and GameFontHighlightSmall:GetFont()) or (STANDARD_TEXT_FONT or nil)
      if font then
        row.nameTop:SetFont(font, math.max(8, fsz))
        row.nameBottom:SetFont(font, math.max(8, fsz))
        local tfs = (s.icons and (s.icons.timerFontSize or s.icons.fontSize)) or fsz
        row.iconTimerText:SetFont(font, math.max(8, tfs))
      end
    end
    -- Invalidate truncation caches (font/size changed)
    row._cacheTop, row._cacheBottom = nil, nil
    return
  end

  row:SetHeight(rh)
  row.icon:SetSize(iszBar, iszBar)
  row.bar:SetHeight(math.max(1, rh - 2))
  row.bar:SetWidth(bw)
  if s.barTexture then row.bar:SetStatusBarTexture(s.barTexture) end

  if s.fontSize then
    local font = (GameFontHighlightSmall and GameFontHighlightSmall:GetFont()) or (STANDARD_TEXT_FONT or nil)
    if font then
      row.bar.playerText:SetFont(font, s.fontSize)
      row.bar.timerText:SetFont(font, s.fontSize)
    end
  end

  row.bar:ClearAllPoints()
  row.icon:ClearAllPoints()
  if s.iconOnRight then
    row.bar:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.icon:SetPoint("LEFT", row.bar, "RIGHT", 4, 0)
  else
    row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.bar:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
  end
  -- Invalidate truncation caches (font/size changed)
  row._cacheTop, row._cacheBottom = nil, nil
end

-- Reapply style to all rows and reposition according to spacing/growth
function RCDT.ApplyStyleUI()
  local s = (RCDT.GetStyle and RCDT.GetStyle()) or {}
  local spacing = s.rowSpacing or 0
  local growUp  = not not s.growUp

  local rowPool = (RCDT.UIRowPool and RCDT.UIRowPool.pool) or {}
  for i, row in ipairs(rowPool) do
    if row then
      RCDT.ApplyStyleToRow(row)
      if s.displayMode ~= "icons" then
        row:ClearAllPoints()
        if i == 1 then
          if growUp then
            row:SetPoint("BOTTOMLEFT", 0, 0)
          else
            row:SetPoint("TOPLEFT", 0, 0)
          end
        else
          if growUp then
            row:SetPoint("BOTTOMLEFT", rowPool[i - 1], "TOPLEFT", 0, spacing)
          else
            row:SetPoint("TOPLEFT", rowPool[i - 1], "BOTTOMLEFT", 0, -spacing)
          end
        end
      end
    end
  end
  if RCDT.UpdateUI then RCDT.UpdateUI() end
end
