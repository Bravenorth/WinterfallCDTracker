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

-- Slider (avec label et valeur)
function RCDT.UI_CreateSlider(parent, label, minV, maxV, step, width)
  local s = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
  s:SetMinMaxValues(minV or 0, maxV or 100)
  s:SetValueStep(step or 1)
  s:SetObeyStepOnDrag(true)
  s:SetWidth(width or 200)

  s.label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  s.label:SetText(label or "")
  s.label:SetPoint("BOTTOMLEFT", s, "TOPLEFT", 0, 4)

  s.valueText = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  s.valueText:SetPoint("BOTTOMRIGHT", s, "TOPRIGHT", 0, 4)

  s:SetScript("OnValueChanged", function(self, value)
    if self.valueText then self.valueText:SetText(string.format("%d", value)) end
  end)

  -- Nettoyage du template: masquer les labels Low/High et le Text interne
  if s.Low   then s.Low:Hide()   end
  if s.High  then s.High:Hide()  end
  if s.Text  then s.Text:Hide()  end
  s:SetHeight(18)

  s:HookScript("OnShow", function(self)
    if self.valueText then self.valueText:SetText(string.format("%d", self:GetValue() or 0)) end
  end)
  return s
end

-- Color swatch (ouvre ColorPickerFrame)
function RCDT.UI_CreateColorSwatch(parent, label, onChange)
  local f = CreateFrame("Frame", nil, parent)
  f:SetSize(140, 20)

  f.text = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  f.text:SetPoint("LEFT", 0, 0)
  f.text:SetText(label or "Color")

  f.swatch = CreateFrame("Button", nil, f)
  f.swatch:SetSize(18, 18)
  f.swatch:SetPoint("LEFT", f.text, "RIGHT", 8, 0)
  f.swatch.tex = f.swatch:CreateTexture(nil, "ARTWORK")
  f.swatch.tex:SetAllPoints()
  f.swatch.tex:SetColorTexture(1,1,1,1)

  function f:SetColor(r,g,b)
    f.r, f.g, f.b = r, g, b
    if f.swatch and f.swatch.tex then f.swatch.tex:SetColorTexture(r or 1, g or 1, b or 1, 1) end
  end
  function f:GetColor() return f.r or 1, f.g or 1, f.b or 1 end

  f.swatch:SetScript("OnClick", function()
    local r,g,b = f:GetColor()
    ColorPickerFrame:Hide() -- workaround taint
    local function callback(restore)
      local nr, ng, nb
      if restore then
        nr, ng, nb = restore.r, restore.g, restore.b
      else
        nr, ng, nb = ColorPickerFrame:GetColorRGB()
      end
      f:SetColor(nr, ng, nb)
      if type(onChange) == "function" then onChange(nr, ng, nb) end
    end
    ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = callback, callback, callback
    ColorPickerFrame:SetColorRGB(r,g,b)
    ColorPickerFrame:Show()
  end)

  return f
end
