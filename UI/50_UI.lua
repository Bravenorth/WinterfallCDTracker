-- UI/50_UI.lua
-- Fenêtre, rows, rendering, ticker UI (avec filtres d’affichage + gating par contexte)

local RCDT = RaidCDTracker
local UI_PERIOD = 0.10  -- tick fixe pour l'UI

-- Helpers display
local function EnsureDisplayDefaults()
  if not RCDT.db then return end
  RCDT.db.display = RCDT.db.display or {}
  local d = RCDT.db.display
  if d.instance == nil then d.instance = true end
  if d.raid     == nil then d.raid     = true end
  if d.party    == nil then d.party    = true end
  if d.solo     == nil then d.solo     = true end
end

local function GetDisplayContext()
  local inInstance = IsInInstance()     -- bool (premier retour)
  if inInstance then return "instance" end
  if IsInRaid() then return "raid" end
  if IsInGroup() then return "party" end
  return "solo"
end

local function ShouldDisplayUI()
  if not RCDT.db then return true end        -- avant DBInit: on affiche
  EnsureDisplayDefaults()
  local ctx = GetDisplayContext()
  local d = RCDT.db.display
  local v = d and d[ctx]
  if v == nil then return true end           -- fallback sécurité
  return v
end

-- Fenêtre principale
RCDT.ui = CreateFrame("Frame", "RaidCDTrackerUIFrame", UIParent)
RCDT.ui:SetSize(320, 400)
RCDT.ui:SetPoint("CENTER")
RCDT.ui:SetMovable(true) RCDT.ui:EnableMouse(true)
RCDT.ui:RegisterForDrag("LeftButton")
RCDT.ui:SetScript("OnDragStart", RCDT.ui.StartMoving)
RCDT.ui:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  -- save pos
  local point, _, relPoint, x, y = self:GetPoint()
  RaidCDTracker.db = RaidCDTracker.db or RaidCDTracker.defaults  -- safety
  RaidCDTracker.db.ui.pos = { point = point, relPoint = relPoint, x = x, y = y }
end)

-- Scrollable container
local scroll = CreateFrame("ScrollFrame", nil, RCDT.ui, "UIPanelScrollFrameTemplate")
scroll:SetAllPoints(RCDT.ui)
if scroll.ScrollBar then scroll.ScrollBar:Hide(); scroll.ScrollBar.Show = function() end end
local content = CreateFrame("Frame", nil, scroll) content:SetSize(1,1) scroll:SetScrollChild(content)

-- Pool de rows
local rowPool = {}
local function CreateRow(i)
  local row = CreateFrame("Frame", nil, content)
  row:SetSize(300, 18)

  row.icon = row:CreateTexture(nil, "ARTWORK")
  row.icon:SetSize(18,18) row.icon:SetPoint("LEFT",0,0)

  row.bar = CreateFrame("StatusBar", nil, row)
  row.bar:SetSize(220,16) row.bar:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
  row.bar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
  row.bar:SetMinMaxValues(0,1)

  row.bar.playerText = row.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.bar.playerText:SetPoint("CENTER")

  row.bar.timerText = row.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.bar.timerText:SetPoint("RIGHT", -2, 0)

  if i == 1 then row:SetPoint("TOPLEFT",0,0) else row:SetPoint("TOPLEFT", rowPool[i-1], "BOTTOMLEFT", 0, 0) end
  rowPool[i] = row
  return row
end

local function GetRow(i)
  if not rowPool[i] then return CreateRow(i) end
  rowPool[i]:Show()
  return rowPool[i]
end

-- Couleurs (par statut)
local STATUS_COLORS = { [1]={0,0.7,1}, [2]={1,0,0} }

-- Mise à jour UI (les filtres ne touchent QUE l’affichage)
function RCDT.UpdateUI()
  -- Gating par contexte : si désactivé, on cache la frame et on stoppe ici
  if not (RCDT.ShouldDisplayUI and RCDT.ShouldDisplayUI()) then
    for j=1,#rowPool do if rowPool[j] then rowPool[j]:Hide() end end
    RCDT.ui:Hide()
    return
  else
    RCDT.ui:Show()
  end

  local now, i = GetTime(), 1

  -- S’assure que les filtres existent (si le module options est chargé)
  if RCDT.FiltersEnsureDefaults then RCDT.FiltersEnsureDefaults() end

  for player, spells in RCDT.spairs(RCDT.raidState, function(a,b)
    return RCDT.ShortName(a) < RCDT.ShortName(b)
  end) do
    local class = RCDT.GetClassForPlayer(player)
    local classColor = (class and RAID_CLASS_COLORS[class]) or { r=1, g=1, b=1 }

    for spellID, data in RCDT.spairs(spells, function(a,b)
      local na = GetSpellInfo(a) or ""
      local nb = GetSpellInfo(b) or ""
      return na < nb
    end) do
      -- Filtre d’affichage local (ne touche pas le réseau)
      local show = true
      if class and RCDT.IsSpellEnabledForClass then
        show = RCDT.IsSpellEnabledForClass(class, spellID)
      end

      if show then
        local row = GetRow(i)
        local _, _, spellIcon = GetSpellInfo(spellID)
        local remain = (data.endTime and data.endTime > 0) and math.max(0, data.endTime - now) or 0

        local frac
        if data.status == RCDT.STATUS.Ready then
          frac=1; row.bar.timerText:SetText("Ready")
        elseif data.status == RCDT.STATUS.Active and (data.activeDur or 0) > 0 then
          frac=(data.activeDur>0) and (remain/data.activeDur) or 0
          if frac < 0 then frac = 0 elseif frac > 1 then frac = 1 end
          row.bar.timerText:SetText(string.format("%.1fs", remain))
        elseif data.status == RCDT.STATUS.OnCD and (data.totalCD or 0) > 0 then
          frac=1-((data.totalCD>0) and (remain/data.totalCD) or 1)
          if frac < 0 then frac = 0 elseif frac > 1 then frac = 1 end
          row.bar.timerText:SetText(string.format("%.1fs", remain))
        else
          frac=0; row.bar.timerText:SetText("")
        end

        local color = (data.status==RCDT.STATUS.Ready)
          and {classColor.r, classColor.g, classColor.b}
          or STATUS_COLORS[data.status] or {1,1,1}

        row.icon:SetTexture(spellIcon or "Interface\\Icons\\INV_Misc_QuestionMark")
        row.bar:SetValue(frac or 0)
        row.bar:SetStatusBarColor(unpack(color))
        row.bar.playerText:SetText(RCDT.ShortName(player))
        i=i+1
      end
    end
  end

  for j=i,#rowPool do rowPool[j]:Hide() end
  RCDT.ui:SetHeight((i-1) * (rowPool[1] and rowPool[1]:GetHeight() or 18) + 10)
end

-- Ticker UI : fixe + rétro-compat StartUITicker
local function EnsureUITicker()
  if not RCDT._uiTicker then
    RCDT._uiTicker = C_Timer.NewTicker(UI_PERIOD, RCDT.UpdateUI)
  end
end
EnsureUITicker()

-- Rétro-compat : si du code appelle encore StartUITicker(sec), on ignore 'sec'
function RCDT.StartUITicker(_) EnsureUITicker() end
