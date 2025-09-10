-- UI/45_Display.lua
-- Gestion des réglages d'affichage (contextes) + helpers

local RCDT = RaidCDTracker

-- Assure les valeurs par défaut d'affichage dans la DB
function RCDT.DisplayEnsureDefaults()
  if not RCDT.db then return end
  RCDT.db.display = RCDT.db.display or {}
  local d = RCDT.db.display
  if d.instance == nil then d.instance = true end
  if d.raid     == nil then d.raid     = true end
  if d.party    == nil then d.party    = true end
  if d.solo     == nil then d.solo     = true end
end

-- Déduit le contexte d'affichage (instance, raid, party, solo)
function RCDT.GetDisplayContext()
  local inInstance = IsInInstance() -- bool (premier retour)
  if inInstance then return "instance" end
  if IsInRaid() then return "raid" end
  if IsInGroup() then return "party" end
  return "solo"
end

-- Faut-il afficher la fenêtre en fonction du contexte ?
function RCDT.ShouldDisplayUI()
  if (RCDT.IsEditEnabled and RCDT.IsEditEnabled()) then return true end
  if not RCDT.db then return true end -- avant DBInit: afficher
  RCDT.DisplayEnsureDefaults()
  local ctx = RCDT.GetDisplayContext()
  local d = RCDT.db.display
  local v = d and d[ctx]
  if v == nil then return true end
  return v
end
