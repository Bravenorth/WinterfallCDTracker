-- UI/52_Render.lua
-- Rendering: build rows based on state and layout

local RCDT = RaidCDTracker

-- Mise à jour UI (les filtres ne touchent QUE l’affichage)
function RCDT.UpdateUI()
  if not (RCDT.ShouldDisplayUI and RCDT.ShouldDisplayUI()) then
    local pool = (RCDT.UIRowPool and RCDT.UIRowPool.pool) or {}
    for j = 1, #pool do if pool[j] then pool[j]:Hide() end end
    if RCDT.ui then RCDT.ui:Hide() end
    return
  else
    if RCDT.ui then RCDT.ui:Show() end
  end

  local now, i = GetTime(), 1

  if RCDT.FiltersEnsureDefaults then RCDT.FiltersEnsureDefaults() end

  local edit = (RCDT.IsEditEnabled and RCDT.IsEditEnabled()) or false
  local pool = (RCDT.UIRowPool and RCDT.UIRowPool.pool) or {}
  local GetRow = (RCDT.UIRowPool and RCDT.UIRowPool.GetRow) or function(idx) return pool[idx] end

  if not edit then
    for player, spells in RCDT.spairs(RCDT.raidState, function(a, b)
      return RCDT.ShortName(a) < RCDT.ShortName(b)
    end) do
      local class = RCDT.GetClassForPlayer(player)
      local classColor = (class and RAID_CLASS_COLORS[class]) or { r = 1, g = 1, b = 1 }

      for spellID, data in RCDT.spairs(spells, function(a, b)
        local na = GetSpellInfo(a) or ""
        local nb = GetSpellInfo(b) or ""
        return na < nb
      end) do
        local show = true
        if class and RCDT.IsSpellEnabledForClass then
          show = RCDT.IsSpellEnabledForClass(class, spellID)
        end

        if show then
          local row = GetRow(i)
          local _, _, spellIcon = GetSpellInfo(spellID)
          local remain = (data.endTime and data.endTime > 0) and math.max(0, data.endTime - now) or 0

          local style = (RCDT.GetStyle and RCDT.GetStyle()) or {}
          local color
          if data.status == RCDT.STATUS.Ready then
            if style.useClassColorWhenReady ~= false then
              color = { classColor.r, classColor.g, classColor.b }
            else
              local c = style.readyColor or { r = 1, g = 1, b = 1 }
              color = { c.r or 1, c.g or 1, c.b or 1 }
            end
          elseif data.status == RCDT.STATUS.Active then
            local c = style.activeColor or { r = 0, g = 0.7, b = 1 }
            color = { c.r or 0, c.g or 0.7, c.b or 1 }
          else
            local c = style.onCDColor or { r = 1, g = 0, b = 0 }
            color = { c.r or 1, c.g or 0, c.b or 0 }
          end

          row.icon:SetTexture(spellIcon or "Interface\\Icons\\INV_Misc_QuestionMark")

          if (style.displayMode == "icons") then
            row.bar:Hide()
            row.icon:Show()
            row.cd:Show()

            do
              local fs = (style.icons and (style.icons.timerFontSize or style.icons.fontSize)) or style.fontSize or 11
              local topExtra = ((style.icons and style.icons.showSpellName) and (fs + 2)) or 0
              row.icon:ClearAllPoints()
              row.icon:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -topExtra)
              row.nameTop:ClearAllPoints(); row.nameBottom:ClearAllPoints()
              row.nameTop:SetPoint("BOTTOM", row.icon, "TOP", 0, 2)
              row.nameBottom:SetPoint("TOP", row.icon, "BOTTOM", 0, -2)
            end

            if data.status == RCDT.STATUS.Ready then
              if row.cd.Clear then row.cd:Clear() end
            else
              local dur, start
              if data.status == RCDT.STATUS.Active and (data.activeDur or 0) > 0 then
                dur = data.activeDur
                start = (data.endTime or now) - (data.activeDur or 0)
              elseif data.status == RCDT.STATUS.OnCD and (data.totalCD or 0) > 0 then
                dur = data.totalCD
                start = (data.endTime or now) - (data.totalCD or 0)
              end
              if start and dur and dur > 0 then
                row.cd:SetCooldown(start, dur)
              end
            end

            if row.icon.SetDesaturated then
              row.icon:SetDesaturated((style.icons and style.icons.desaturateOnCD) and (data.status == RCDT.STATUS.OnCD))
            end

            local showTop = not not (style.icons and style.icons.showSpellName)
            local showBottom = not not (style.icons and style.icons.showPlayerName)
            if showTop then
              local n = GetSpellInfo(spellID) or ""
              row.nameTop:SetText(n)
            else
              row.nameTop:SetText("")
            end
            if showBottom then
              if row.nameBottom and row.nameBottom.SetText then
                row.nameBottom:SetText(RCDT.ShortName(player) or "")
              end
            else
              row.nameBottom:SetText("")
            end
            row.nameTop:SetShown(showTop)
            row.nameBottom:SetShown(showBottom)

            local useNumbers = not ((style.icons and style.icons.useNumbers) == false)
            if row.cd.SetHideCountdownNumbers then
              row.cd:SetHideCountdownNumbers((not useNumbers) or (style.showTimer == false))
            end
            if not useNumbers and (style.showTimer ~= false) then
              local r = remain or 0
              local txt
              if r >= 60 then
                txt = string.format("%d:%02d", math.floor(r / 60), math.floor(r % 60))
              elseif r >= 10 then
                txt = string.format("%d", math.floor(r))
              else
                txt = string.format("%.1f", r)
              end
              if (style.icons and (style.icons.timerFontSize or style.icons.fontSize)) then
                local font = (GameFontHighlight:GetFont())
                if font then row.iconTimerText:SetFont(font, (style.icons and (style.icons.timerFontSize or style.icons.fontSize))) end
              end
              row.iconTimerText:SetText(txt)
              row.iconTimerText:Show()
            else
              row.iconTimerText:SetText("")
              row.iconTimerText:Hide()
            end

            local showBorder = not not (style.icons and style.icons.border)
            local bt = math.max(0, (style.icons and style.icons.borderSize) or 1)
            local function placeBorder()
              row.ibTop:ClearAllPoints(); row.ibBottom:ClearAllPoints(); row.ibLeft:ClearAllPoints(); row.ibRight:ClearAllPoints()
              row.ibTop:SetPoint("TOPLEFT", row.icon, "TOPLEFT", -bt, bt)
              row.ibTop:SetPoint("TOPRIGHT", row.icon, "TOPRIGHT", bt, bt)
              row.ibTop:SetHeight(bt)

              row.ibBottom:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMLEFT", -bt, -bt)
              row.ibBottom:SetPoint("BOTTOMRIGHT", row.icon, "BOTTOMRIGHT", bt, -bt)
              row.ibBottom:SetHeight(bt)

              row.ibLeft:SetPoint("TOPLEFT", row.icon, "TOPLEFT", -bt, bt)
              row.ibLeft:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMLEFT", -bt, -bt)
              row.ibLeft:SetWidth(bt)

              row.ibRight:SetPoint("TOPRIGHT", row.icon, "TOPRIGHT", bt, bt)
              row.ibRight:SetPoint("BOTTOMRIGHT", row.icon, "BOTTOMRIGHT", bt, -bt)
              row.ibRight:SetWidth(bt)
            end
            if showBorder and bt > 0 then
              local br, bg, bb = color[1], color[2], color[3]
              row.ibTop:SetColorTexture(br, bg, bb, 1)
              row.ibBottom:SetColorTexture(br, bg, bb, 1)
              row.ibLeft:SetColorTexture(br, bg, bb, 1)
              row.ibRight:SetColorTexture(br, bg, bb, 1)
              placeBorder()
              row.ibTop:Show(); row.ibBottom:Show(); row.ibLeft:Show(); row.ibRight:Show()
            else
              row.ibTop:Hide(); row.ibBottom:Hide(); row.ibLeft:Hide(); row.ibRight:Hide()
            end

          else
            row.bar:Show()
            row.cd:Hide()
            row.nameTop:SetShown(false)
            row.nameBottom:SetShown(false)
            if row.iconTimerText then row.iconTimerText:Hide() end
            if row.ibTop then row.ibTop:Hide() end
            if row.ibBottom then row.ibBottom:Hide() end
            if row.ibLeft then row.ibLeft:Hide() end
            if row.ibRight then row.ibRight:Hide() end

            local frac
            if data.status == RCDT.STATUS.Ready then
              frac = 1; row.bar.timerText:SetText("Ready")
            elseif data.status == RCDT.STATUS.Active and (data.activeDur or 0) > 0 then
              frac = (data.activeDur > 0) and (remain / data.activeDur) or 0
              if frac < 0 then frac = 0 elseif frac > 1 then frac = 1 end
              row.bar.timerText:SetText(string.format("%.1fs", remain))
            elseif data.status == RCDT.STATUS.OnCD and (data.totalCD or 0) > 0 then
              frac = 1 - ((data.totalCD > 0) and (remain / data.totalCD) or 1)
              if frac < 0 then frac = 0 elseif frac > 1 then frac = 1 end
              row.bar.timerText:SetText(string.format("%.1fs", remain))
            else
              frac = 0; row.bar.timerText:SetText("")
            end
            row.bar:SetValue(frac or 0)
            row.bar:SetStatusBarColor(unpack(color))
            row.bar.playerText:SetText(RCDT.ShortName(player))
            if style.showPlayer ~= nil then row.bar.playerText:SetShown(style.showPlayer) end
            if style.showTimer ~= nil then row.bar.timerText:SetShown(style.showTimer) end
          end

          i = i + 1
        end
      end
    end
  end

  -- Edit mode preview tiles
  local style = (RCDT.GetStyle and RCDT.GetStyle()) or {}
  if edit then
    local sampleCount = 10
    for n = 1, sampleCount do
      local row = GetRow(i)
      local statusIdx = (n - 1) % 3
      if style.displayMode == "icons" then
        row.bar:Hide(); row.icon:Show(); row.cd:Show()
        do
          local fs = (style.icons and (style.icons.timerFontSize or style.icons.fontSize)) or style.fontSize or 11
          local topExtra = ((style.icons and style.icons.showSpellName) and (fs + 2)) or 0
          row.icon:ClearAllPoints(); row.icon:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -topExtra)
          row.nameTop:ClearAllPoints(); row.nameBottom:ClearAllPoints()
          row.nameTop:SetPoint("BOTTOM", row.icon, "TOP", 0, 2)
          row.nameBottom:SetPoint("TOP", row.icon, "BOTTOM", 0, -2)
        end
        row.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        if statusIdx == 0 then
          if row.cd.Clear then row.cd:Clear() end
          row.nameTop:SetText((style.icons and style.icons.showSpellName) and "Spell" or "")
          row.nameBottom:SetText((style.icons and style.icons.showPlayerName) and ("Player" .. n) or "")
        elseif statusIdx == 1 then
          local dur = 15; local start = now - ((n * 1.1) % dur)
          row.cd:SetCooldown(start, dur)
          row.nameTop:SetText((style.icons and style.icons.showSpellName) and "Active" or "")
          row.nameBottom:SetText((style.icons and style.icons.showPlayerName) and ("Player" .. n) or "")
        else
          local dur = 120; local start = now - ((n * 5.7) % dur)
          row.cd:SetCooldown(start, dur)
          row.nameTop:SetText((style.icons and style.icons.showSpellName) and "Cooldown" or "")
          row.nameBottom:SetText((style.icons and style.icons.showPlayerName) and ("Player" .. n) or "")
        end
        if row.cd.SetHideCountdownNumbers then
          local useNumbers = not ((style.icons and style.icons.useNumbers) == false)
          row.cd:SetHideCountdownNumbers((not useNumbers) or (style.showTimer == false))
        end
      else
        row.bar:Show(); row.cd:Hide(); row.nameTop:SetShown(false); row.nameBottom:SetShown(false)
        row.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        local frac = (statusIdx == 0) and 1 or ((statusIdx == 1) and 0.4 or 0.7)
        row.bar:SetValue(frac)
        row.bar.timerText:SetText((statusIdx == 0) and "Ready" or ((statusIdx == 1) and "15.0s" or "60.0s"))
        row.bar.playerText:SetText("Player" .. n)
        if style.showPlayer ~= nil then row.bar.playerText:SetShown(style.showPlayer) end
        if style.showTimer ~= nil then row.bar.timerText:SetShown(style.showTimer) end
      end
      i = i + 1
    end
  end

  -- Hide unused rows
  for j = i, #pool do if pool[j] then pool[j]:Hide() end end

  -- Layout and container sizing
  local s = style
  local shown = i - 1
  if s.displayMode == "icons" then
    local isz = (s.icons and s.icons.size) or 18
    local fs = (s.icons and s.icons.fontSize) or s.fontSize or 11
    local topExtra = ((s.icons and s.icons.showSpellName) and (fs + 2)) or 0
    local bottomExtra = ((s.icons and s.icons.showPlayerName) and (fs + 2)) or 0
    local tileH = isz + topExtra + bottomExtra
    local spacing = (s.icons and s.icons.spacing) or (s.rowSpacing or 0)
    local cols = math.max(1, (s.icons and s.icons.columns) or 8)
    local growUp = not not s.growUp

    local rows = math.ceil(math.max(1, shown) / cols)
    local idx = 1
    for r = 0, rows - 1 do
      for c = 0, cols - 1 do
        if idx > shown then break end
        local f = pool[idx]
        if f then
          f:ClearAllPoints()
          local x = c * (isz + spacing)
          local y = r * (tileH + spacing)
          local parent = RCDT.uiContent or RCDT.ui or UIParent
          if growUp then
            f:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", x, y)
          else
            f:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
          end
        end
        idx = idx + 1
      end
    end

    local usedCols = math.min(cols, math.max(1, shown))
    local usedRows = math.ceil(math.max(1, shown) / cols)
    local w = usedCols * isz + (usedCols - 1) * spacing + 10
    local h = usedRows * tileH + (usedRows - 1) * spacing + 10
    RCDT.ui:SetWidth(math.max(120, w))
    RCDT.ui:SetHeight(math.max(40, h))
  else
    local rh = (pool[1] and pool[1]:GetHeight() or 18)
    RCDT.ui:SetHeight((shown) * rh + 10)
    local isz2 = s.barIconSize or 18
    local w2 = (isz2 + 4) + (s.barWidth or 220) + 10
    RCDT.ui:SetWidth(math.max(160, w2))
  end
end
