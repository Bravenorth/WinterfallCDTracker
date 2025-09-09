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

  -- Appliquer le style courant au row nouvellement créé
  if RCDT.ApplyStyleToRow then RCDT.ApplyStyleToRow(row) end
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

        local style = (RCDT.GetStyle and RCDT.GetStyle()) or {}
        local color
        if data.status==RCDT.STATUS.Ready then
          if style.useClassColorWhenReady ~= false then
            color = {classColor.r, classColor.g, classColor.b}
          else
            local c = style.readyColor or {r=1,g=1,b=1}
            color = {c.r or 1, c.g or 1, c.b or 1}
          end
        elseif data.status == RCDT.STATUS.Active then
          local c = style.activeColor or {r=0,g=0.7,b=1}
          color = {c.r or 0, c.g or 0.7, c.b or 1}
        else -- OnCD
          local c = style.onCDColor or {r=1,g=0,b=0}
          color = {c.r or 1, c.g or 0, c.b or 0}
        end

        row.icon:SetTexture(spellIcon or "Interface\\Icons\\INV_Misc_QuestionMark")
        row.bar:SetValue(frac or 0)
        row.bar:SetStatusBarColor(unpack(color))
        row.bar.playerText:SetText(RCDT.ShortName(player))
        if style.showPlayer ~= nil then row.bar.playerText:SetShown(style.showPlayer) end
        if style.showTimer  ~= nil then row.bar.timerText:SetShown(style.showTimer) end
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

-- Applique le style courant à un row existant
function RCDT.ApplyStyleToRow(row)
  local s = (RCDT.GetStyle and RCDT.GetStyle()) or {}
  local rh = s.rowHeight or 18
  local isz = s.iconSize or 18
  local bw  = s.barWidth or 220

  row:SetHeight(rh)
  row.icon:SetSize(isz, isz)
  row.bar:SetHeight(math.max(1, rh-2))
  row.bar:SetWidth(bw)
  if s.barTexture then row.bar:SetStatusBarTexture(s.barTexture) end

  if s.fontSize then
    local font = (GameFontHighlightSmall and GameFontHighlightSmall:GetFont()) or (STANDARD_TEXT_FONT or nil)
    if font then
      row.bar.playerText:SetFont(font, s.fontSize)
      row.bar.timerText:SetFont(font, s.fontSize)
    end
  end

  -- Position bar/icon selon préférence
  row.bar:ClearAllPoints()
  row.icon:ClearAllPoints()
  if s.iconOnRight then
    row.bar:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.icon:SetPoint("LEFT", row.bar, "RIGHT", 4, 0)
  else
    row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.bar:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
  end
end

-- Réapplique le style à toutes les rows et repositionne selon l'espacement et la croissance
function RCDT.ApplyStyleUI()
  local s = (RCDT.GetStyle and RCDT.GetStyle()) or {}
  local spacing = s.rowSpacing or 0
  local growUp  = not not s.growUp

  for i,row in ipairs(rowPool) do
    if row then
      RCDT.ApplyStyleToRow(row)
      row:ClearAllPoints()
      if i == 1 then
        if growUp then
          row:SetPoint("BOTTOMLEFT", 0, 0)
        else
          row:SetPoint("TOPLEFT", 0, 0)
        end
      else
        if growUp then
          row:SetPoint("BOTTOMLEFT", rowPool[i-1], "TOPLEFT", 0, spacing)
        else
          row:SetPoint("TOPLEFT", rowPool[i-1], "BOTTOMLEFT", 0, -spacing)
        end
      end
    end
  end
  if RCDT.UpdateUI then RCDT.UpdateUI() end
end
