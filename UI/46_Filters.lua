-- UI/46_Filters.lua
-- Gestion des filtres par classe/spell

local RCDT = RaidCDTracker

-- Récupère la table des CDs suivis (peut dépendre de l'ordre de chargement)
local function GetTrackedByClass()
  return _G.RaidCDTracker_Cooldowns or RCDT.TRACKED_BY_CLASS or {}
end

RCDT.GetTrackedByClass = GetTrackedByClass

-- Assure les valeurs par défaut des filtres (visible par défaut)
function RCDT.FiltersEnsureDefaults()
  if not RCDT.db then return end
  RCDT.db.filters = RCDT.db.filters or {}
  local BY = GetTrackedByClass()
  for class, spells in pairs(BY) do
    RCDT.db.filters[class] = RCDT.db.filters[class] or {}
    for spellID in pairs(spells) do
      if RCDT.db.filters[class][spellID] == nil then
        RCDT.db.filters[class][spellID] = true
      end
    end
  end
end

-- Query filtre local (UI-only)
function RCDT.IsSpellEnabledForClass(classToken, spellID)
  if not RCDT.db then return true end
  local f = RCDT.db.filters
  if not f then return true end
  local cf = f[classToken]
  if not cf then return true end
  local v = cf[spellID]
  if v == nil then return true end
  return not not v
end

