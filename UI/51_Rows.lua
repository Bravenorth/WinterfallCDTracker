-- UI/51_Rows.lua
-- Row pool: creation and retrieval

local RCDT = RaidCDTracker

local pool = {}

local function CreateRow(i)
  local parent = RCDT.uiContent or UIParent
  local row = CreateFrame("Frame", nil, parent)
  row:SetSize(300, 18)

  row.icon = row:CreateTexture(nil, "ARTWORK")
  row.icon:SetSize(18, 18)
  row.icon:SetPoint("LEFT", 0, 0)

  -- Cooldown overlay for icon mode
  row.cd = CreateFrame("Cooldown", nil, row, "CooldownFrameTemplate")
  row.cd:SetAllPoints(row.icon)

  row.bar = CreateFrame("StatusBar", nil, row)
  row.bar:SetSize(220, 16)
  row.bar:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
  row.bar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
  row.bar:SetMinMaxValues(0, 1)

  row.bar.playerText = row.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.bar.playerText:SetPoint("CENTER")

  row.bar.timerText = row.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.bar.timerText:SetPoint("RIGHT", -2, 0)

  -- Optional labels for icon mode
  row.nameTop = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.nameTop:SetPoint("BOTTOM", row.icon, "TOP", 0, 2)
  row.nameTop:SetText("")
  row.nameBottom = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.nameBottom:SetPoint("TOP", row.icon, "BOTTOM", 0, -2)
  row.nameBottom:SetText("")

  -- Optional timer text overlay for icon mode if not using built-in numbers
  row.iconTimerText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  row.iconTimerText:SetPoint("CENTER", row.icon, "CENTER", 0, 0)
  row.iconTimerText:SetText("")

  -- Simple 1px border using 4 textures for icon mode
  row.ibTop = row:CreateTexture(nil, "OVERLAY")
  row.ibBottom = row:CreateTexture(nil, "OVERLAY")
  row.ibLeft = row:CreateTexture(nil, "OVERLAY")
  row.ibRight = row:CreateTexture(nil, "OVERLAY")
  for _, t in ipairs({ row.ibTop, row.ibBottom, row.ibLeft, row.ibRight }) do
    t:SetColorTexture(1, 1, 1, 1)
    t:Hide()
  end

  if i == 1 then
    row:SetPoint("TOPLEFT", 0, 0)
  else
    row:SetPoint("TOPLEFT", pool[i - 1], "BOTTOMLEFT", 0, 0)
  end
  pool[i] = row

  if RCDT.ApplyStyleToRow then RCDT.ApplyStyleToRow(row) end
  return row
end

local function GetRow(i)
  if not pool[i] then return CreateRow(i) end
  pool[i]:Show()
  return pool[i]
end

RCDT.UIRowPool = {
  pool = pool,
  GetRow = GetRow,
}

