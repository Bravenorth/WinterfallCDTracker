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
