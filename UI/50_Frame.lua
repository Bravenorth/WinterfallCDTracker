-- UI/50_Frame.lua
-- Main UI frame and scroll/content container

local RCDT = RaidCDTracker

-- Main window
RCDT.ui = CreateFrame("Frame", "RaidCDTrackerUIFrame", UIParent)
RCDT.ui:SetSize(320, 400)
RCDT.ui:SetPoint("CENTER")
RCDT.ui:SetMovable(true)
RCDT.ui:EnableMouse(true)
RCDT.ui:RegisterForDrag("LeftButton")
RCDT.ui:SetScript("OnDragStart", RCDT.ui.StartMoving)
RCDT.ui:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  local point, _, relPoint, x, y = self:GetPoint()
  RaidCDTracker.db = RaidCDTracker.db or RaidCDTracker.defaults
  RaidCDTracker.db.ui = RaidCDTracker.db.ui or {}
  RaidCDTracker.db.ui.pos = { point = point, relPoint = relPoint, x = x, y = y }
end)

-- Scrollable container
local scroll = CreateFrame("ScrollFrame", nil, RCDT.ui, "UIPanelScrollFrameTemplate")
scroll:SetAllPoints(RCDT.ui)
if scroll.ScrollBar then
  scroll.ScrollBar:Hide()
  scroll.ScrollBar.Show = function() end
end
local content = CreateFrame("Frame", nil, scroll)
content:SetSize(1, 1)
scroll:SetScrollChild(content)

-- Expose content for other modules (rows/layout)
RCDT.uiContent = content

