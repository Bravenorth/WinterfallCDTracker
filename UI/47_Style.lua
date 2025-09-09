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
    rowHeight = 18,
    rowSpacing = 0,
    iconSize = 18,
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
  }
  for k,v in pairs(defs) do
    if s[k] == nil then
      if type(v) == "table" then s[k] = { r=v.r, g=v.g, b=v.b, a=v.a } else s[k] = v end
    end
  end
end

function RCDT.GetStyle()
  if RCDT.db then RCDT.StyleEnsureDefaults() end
  return (RCDT.db and RCDT.db.ui and RCDT.db.ui.style) or {}
end

