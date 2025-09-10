-- Core/05_DB.lua
-- Gestion SavedVariables + application des réglages UI

RaidCDTracker = RaidCDTracker or {}
local RCDT = RaidCDTracker

-- Defaults
RCDT.defaults = {
  debug = false,
  ui = {
    locked = false,
    scale  = 1.0,
    tick   = 0.10,          -- fréquence de refresh UI (s)
    pos    = nil,           -- {point, relPoint, x, y}
    style  = {
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

      -- Icons (icon-only mode)
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
    },
  },
}

local function deepCopy(src)
  if type(src) ~= "table" then return src end
  local t = {}
  for k,v in pairs(src) do t[k] = deepCopy(v) end
  return t
end

local function applyDefaults(dst, defs)
  for k,v in pairs(defs) do
    if type(v) == "table" then
      dst[k] = applyDefaults(dst[k] or {}, v)
    elseif dst[k] == nil then
      dst[k] = v
    end
  end
  return dst
end

-- Public: init DB (appelé sur ADDON_LOADED)
function RCDT.DBInit()
  RaidCDTrackerDB = RaidCDTrackerDB or {}
  RCDT.db = applyDefaults(RaidCDTrackerDB, deepCopy(RCDT.defaults))
  -- flag debug
  RCDT.DEBUG_MODE = not not RCDT.db.debug
end

-- Public: applique visuellement les réglages UI (si frame déjà créée)
function RCDT.ApplyConfigUI()
  if not RCDT.ui or not RCDT.db then return end
  local ui = RCDT.db.ui

  -- scale
  RCDT.ui:SetScale(ui.scale or 1)

  -- lock (drag)
  local locked = not not ui.locked
  RCDT.ui:EnableMouse(not locked)
  if locked then
    RCDT.ui:RegisterForDrag()
  else
    RCDT.ui:RegisterForDrag("LeftButton")
  end

  -- position
  if ui.pos and ui.pos.point then
    RCDT.ui:ClearAllPoints()
    RCDT.ui:SetPoint(ui.pos.point, UIParent, ui.pos.relPoint or ui.pos.point, ui.pos.x or 0, ui.pos.y or 0)
  else
    -- première fois : rien à faire, déjà CENTER
  end

  -- UI ticker
  if RCDT.StartUITicker then
    RCDT.StartUITicker(ui.tick or 0.10)
  end
  if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end
end

