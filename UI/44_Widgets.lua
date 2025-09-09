-- UI/44_Widgets.lua
-- Petits helpers de widgets partagés (checkbox, bouton)

local RCDT = RaidCDTracker

function RCDT.UI_CreateCheckbox(parent, label, tooltip)
  local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
  if cb.Text then cb.Text:SetText(label or "") end
  if tooltip then
    cb.tooltipText = label
    cb.tooltipRequirement = tooltip
  end
  return cb
end

function RCDT.UI_CreateButton(parent, label, width, height)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(width or 120, height or 22)
  b:SetText(label)
  return b
end

