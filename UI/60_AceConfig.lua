-- UI/60_AceConfig.lua
-- AceGUI configuration window with tabs and scroll areas

local RCDT = RaidCDTracker
local ADDON_NAME = (RCDT and RCDT.ADDON) or "RaidCDTracker"

local AceGUI = (LibStub and LibStub("AceGUI-3.0", true))
if not AceGUI then return end

local function EnsureDB()
  if not RCDT.db and RCDT.DBInit then RCDT.DBInit() end
  if RCDT.StyleEnsureDefaults then RCDT.StyleEnsureDefaults() end
  if RCDT.DisplayEnsureDefaults then RCDT.DisplayEnsureDefaults() end
  if RCDT.FiltersEnsureDefaults then RCDT.FiltersEnsureDefaults() end
end

local function addHeading(parent, text)
  local h = AceGUI:Create("Heading")
  h:SetFullWidth(true)
  h:SetText(text or "")
  parent:AddChild(h)
end

local function addCheckbox(parent, label, get, set)
  local cb = AceGUI:Create("CheckBox")
  cb:SetLabel(label)
  cb:SetValue(get())
  cb:SetCallback("OnValueChanged", function(_, _, v) set(v and true or false) end)
  parent:AddChild(cb)
  return cb
end

local function addSlider(parent, label, minV, maxV, step, get, set)
  local s = AceGUI:Create("Slider")
  s:SetLabel(label)
  s:SetSliderValues(minV, maxV, step)
  s:SetValue(get())
  s:SetCallback("OnValueChanged", function(_, _, v) set(v) end)
  s:SetFullWidth(true)
  parent:AddChild(s)
  return s
end

local function addColor(parent, label, get, set)
  local c = AceGUI:Create("ColorPicker")
  c:SetLabel(label)
  local r,g,b = get()
  c:SetColor(r,g,b)
  c:SetCallback("OnValueConfirmed", function(_, _, r,g,b) set(r,g,b) end)
  parent:AddChild(c)
  return c
end

-- General tab
local function BuildTab_General(container)
  EnsureDB()
  addHeading(container, "General")

  addCheckbox(container, "Lock frame",
    function() return RCDT.db and RCDT.db.ui and RCDT.db.ui.locked end,
    function(v) if not RCDT.db then return end; RCDT.db.ui.locked = v; if RCDT.ApplyConfigUI then RCDT.ApplyConfigUI() end end)

  addSlider(container, "UI scale", 0.5, 2.0, 0.05,
    function() return (RCDT.db and RCDT.db.ui and RCDT.db.ui.scale) or 1.0 end,
    function(v) if not RCDT.db then return end; RCDT.db.ui.scale = v; if RCDT.ApplyConfigUI then RCDT.ApplyConfigUI() end end)

  local btn = AceGUI:Create("Button")
  btn:SetText("Reset position")
  btn:SetCallback("OnClick", function()
    if not RCDT.db then return end
    RCDT.db.ui.pos = nil
    if RCDT.ui then RCDT.ui:ClearAllPoints(); RCDT.ui:SetPoint("CENTER") end
  end)
  container:AddChild(btn)

  local btnFilters = AceGUI:Create("Button")
  btnFilters:SetText("Open filters...")
  btnFilters:SetCallback("OnClick", function() if RCDT.ToggleFilters then RCDT.ToggleFilters() end end)
  container:AddChild(btnFilters)
end

-- Style tab
local function BuildTab_Style(container)
  EnsureDB()
  local s = (RCDT.GetStyle and RCDT.GetStyle()) or {}

  local function rebuild()
    container:ReleaseChildren()
    BuildTab_Style(container)
  end

  local grpMode = AceGUI:Create("InlineGroup"); grpMode:SetTitle("Mode"); grpMode:SetFullWidth(true)
  container:AddChild(grpMode)
  do
    local dd = AceGUI:Create("Dropdown")
    dd:SetLabel("Display mode")
    dd:SetList({ bars = "Bars", icons = "Icons" }, { "bars", "icons" })
    dd:SetValue(s.displayMode == "icons" and "icons" or "bars")
    dd:SetCallback("OnValueChanged", function(_,_,val)
      s.displayMode = (val == "icons") and "icons" or "bars"
      if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end
      rebuild()
    end)
    grpMode:AddChild(dd)
  end
  addCheckbox(grpMode, "Edit mode (preview)",
    function() return (RCDT.IsEditEnabled and RCDT.IsEditEnabled()) or false end,
    function(v) if RCDT.SetEditMode then RCDT.SetEditMode(v) end end)
  addCheckbox(grpMode, "Grow upwards",
    function() return s.growUp == true end,
    function(v) s.growUp = v; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)

  if s.displayMode == "icons" then
    s.icons = s.icons or {}
    local grpIcons = AceGUI:Create("InlineGroup"); grpIcons:SetTitle("Icons"); grpIcons:SetFullWidth(true)
    container:AddChild(grpIcons)
    addSlider(grpIcons, "Icon size", 12, 64, 1,
      function() return s.icons.size or 18 end,
      function(v) s.icons.size = v; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)
    addSlider(grpIcons, "Icon columns", 1, 20, 1,
      function() return s.icons.columns or 8 end,
      function(v) s.icons.columns = v; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)
    addSlider(grpIcons, "Icon spacing", 0, 20, 1,
      function() return s.icons.spacing or (s.rowSpacing or 0) end,
      function(v) s.icons.spacing = v; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)
    addSlider(grpIcons, "Label font size", 8, 18, 1,
      function() return s.icons.fontSize or s.fontSize or 11 end,
      function(v) s.icons.fontSize = v; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)

    local slTimer = addSlider(grpIcons, "Timer font size", 8, 24, 1,
      function() return s.icons.timerFontSize or s.icons.fontSize or s.fontSize or 11 end,
      function(v) s.icons.timerFontSize = v; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)
    local lblTimerInfo = AceGUI:Create("Label"); lblTimerInfo:SetFullWidth(true)
    lblTimerInfo:SetText("Note: built-in numbers cannot be resized. Uncheck to use custom text size.")
    grpIcons:AddChild(lblTimerInfo)
    addCheckbox(grpIcons, "Spell name (above)",
      function() return s.icons.showSpellName == true end,
      function(v) s.icons.showSpellName = v; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)
    addCheckbox(grpIcons, "Player name (below)",
      function() return s.icons.showPlayerName == true end,
      function(v) s.icons.showPlayerName = v; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)
    addCheckbox(grpIcons, "Use built-in numbers",
      function() return s.icons.useNumbers ~= false end,
      function(v)
        s.icons.useNumbers = v
        if slTimer and slTimer.SetDisabled then slTimer:SetDisabled(v and true or false) end
        if lblTimerInfo and lblTimerInfo.frame and lblTimerInfo.frame.Show and lblTimerInfo.frame.Hide then
          if v then lblTimerInfo.frame:Show() else lblTimerInfo.frame:Hide() end
        end
        if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end
      end)
    addCheckbox(grpIcons, "Desaturate icon on cooldown",
      function() return s.icons.desaturateOnCD ~= false end,
      function(v) s.icons.desaturateOnCD = v; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)
    local slBorder = addSlider(grpIcons, "Border thickness", 0, 6, 1,
      function() return s.icons.borderSize or 1 end,
      function(v) s.icons.borderSize = v; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)
    local cbBorder = addCheckbox(grpIcons, "Show colored border",
      function() return s.icons.border == true end,
      function(v) s.icons.border = v; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)
    if slTimer and slTimer.SetDisabled then slTimer:SetDisabled(s.icons.useNumbers ~= false) end
    if lblTimerInfo and lblTimerInfo.frame and lblTimerInfo.frame.Show and lblTimerInfo.frame.Hide then
      if s.icons.useNumbers ~= false then lblTimerInfo.frame:Show() else lblTimerInfo.frame:Hide() end
    end
    if slBorder and slBorder.SetDisabled then slBorder:SetDisabled(not (s.icons.border == true)) end
  end

  if s.displayMode == "bars" then
    local grpBars = AceGUI:Create("InlineGroup"); grpBars:SetTitle("Bars"); grpBars:SetFullWidth(true)
    container:AddChild(grpBars)
    addCheckbox(grpBars, "Show player name",
      function() return s.showPlayer ~= false end,
      function(v) s.showPlayer = v; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)
    addCheckbox(grpBars, "Show timer text",
      function() return s.showTimer ~= false end,
      function(v) s.showTimer = v; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)
    addCheckbox(grpBars, "Icon on right",
      function() return s.iconOnRight == true end,
      function(v) s.iconOnRight = v; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)
    addCheckbox(grpBars, "Ready: use class color",
      function() return s.useClassColorWhenReady ~= false end,
      function(v) s.useClassColorWhenReady = v; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)
    addSlider(grpBars, "Row height", 12, 40, 1,
      function() return s.rowHeight or 18 end,
      function(v) s.rowHeight = v; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)
    addSlider(grpBars, "Row spacing", 0, 20, 1,
      function() return s.rowSpacing or 0 end,
      function(v) s.rowSpacing = v; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)
    addSlider(grpBars, "Row icon size", 12, 40, 1,
      function() return s.barIconSize or 18 end,
      function(v) s.barIconSize = v; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)
    addSlider(grpBars, "Bar width", 120, 500, 5,
      function() return s.barWidth or 220 end,
      function(v) s.barWidth = v; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)
    addSlider(grpBars, "Font size", 8, 18, 1,
      function() return s.fontSize or 11 end,
      function(v) s.fontSize = v; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)

    local grpTex = AceGUI:Create("InlineGroup"); grpTex:SetTitle("Bar texture"); grpTex:SetFullWidth(true)
    container:AddChild(grpTex)
    local textures = {
      {key = "Interface\\TARGETINGFRAME\\UI-StatusBar", label = "Default"},
      {key = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill", label = "Raid HP Fill"},
      {key = "Interface\\BUTTONS\\WHITE8X8", label = "White 8x8"},
    }
    for _, t in ipairs(textures) do
      local b = AceGUI:Create("Button")
      b:SetText(t.label)
      b:SetCallback("OnClick", function()
        s.barTexture = t.key; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end
      end)
      grpTex:AddChild(b)
    end
  end

  local grpColors = AceGUI:Create("InlineGroup"); grpColors:SetTitle("Colors"); grpColors:SetFullWidth(true)
  container:AddChild(grpColors)
  addColor(grpColors, "Color: Ready",
    function() local c = s.readyColor or {r=0.2,g=0.8,b=0.2}; return c.r or 1, c.g or 1, c.b or 1 end,
    function(r,g,b) s.readyColor = {r=r,g=g,b=b}; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)
  addColor(grpColors, "Color: Active",
    function() local c = s.activeColor or {r=0.0,g=0.7,b=1.0}; return c.r or 0, c.g or 0.7, c.b or 1 end,
    function(r,g,b) s.activeColor = {r=r,g=g,b=b}; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)
  addColor(grpColors, "Color: Cooldown",
    function() local c = s.onCDColor or {r=1.0,g=0.0,b=0.0}; return c.r or 1, c.g or 0, c.b or 0 end,
    function(r,g,b) s.onCDColor = {r=r,g=g,b=b}; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)
end

-- Display tab
local function BuildTab_Display(container)
  EnsureDB()
  addHeading(container, "Display (context)")
  local d = RCDT.db.display or {}
  addCheckbox(container, "Show in instances", function() return d.instance ~= false end, function(v) d.instance = v; if RCDT.UpdateUI then RCDT.UpdateUI() end end)
  addCheckbox(container, "Show in raid",     function() return d.raid     ~= false end, function(v) d.raid     = v; if RCDT.UpdateUI then RCDT.UpdateUI() end end)
  addCheckbox(container, "Show in party",    function() return d.party    ~= false end, function(v) d.party    = v; if RCDT.UpdateUI then RCDT.UpdateUI() end end)
  addCheckbox(container, "Show when solo",   function() return d.solo     ~= false end, function(v) d.solo     = v; if RCDT.UpdateUI then RCDT.UpdateUI() end end)
end

-- Filters tab (class spell filters)
local function BuildTab_Filters(container)
  EnsureDB()
  addHeading(container, "Class filters")

  local BY = (RCDT.GetTrackedByClass and RCDT.GetTrackedByClass()) or {}
  local classList, classOrder = {}, {}
  for token in pairs(BY) do classList[token] = token; table.insert(classOrder, token) end
  table.sort(classOrder)

  local currentClass = classOrder[1]
  local dd = AceGUI:Create("Dropdown")
  dd:SetLabel("Class")
  dd:SetList(classList, classOrder)
  dd:SetValue(currentClass)
  container:AddChild(dd)

  local btns = AceGUI:Create("SimpleGroup"); btns:SetLayout("Flow"); btns:SetFullWidth(true); container:AddChild(btns)
  local checkAll = AceGUI:Create("Button"); checkAll:SetText("Check all"); btns:AddChild(checkAll)
  local uncheckAll = AceGUI:Create("Button"); uncheckAll:SetText("Uncheck all"); btns:AddChild(uncheckAll)

  -- Use the outer TabGroup's scroll; create a growing list group
  local list = AceGUI:Create("SimpleGroup"); list:SetLayout("Flow"); list:SetFullWidth(true); container:AddChild(list)

  local function SetFilterValue(classToken, spellID, enabled)
    RCDT.db.filters = RCDT.db.filters or {}
    RCDT.db.filters[classToken] = RCDT.db.filters[classToken] or {}
    RCDT.db.filters[classToken][spellID] = enabled and true or false
    if RCDT.UpdateUI then RCDT.UpdateUI() end
  end

  local function BuildList()
    list:ReleaseChildren()
    if not currentClass or not BY[currentClass] then return end
    local ids = {}
    for sid in pairs(BY[currentClass]) do table.insert(ids, sid) end
    table.sort(ids, function(a,b)
      local na = GetSpellInfo(a) or ""; local nb = GetSpellInfo(b) or ""; if na==nb then return a<b end; return na<nb
    end)
    for _, spellID in ipairs(ids) do
      local name, _, icon = GetSpellInfo(spellID)
      local row = AceGUI:Create("SimpleGroup")
      row:SetLayout("Flow")
      row:SetFullWidth(true)
      if row.frame and row.frame.SetHeight then row.frame:SetHeight(28) end

      local cb = AceGUI:Create("CheckBox")
      cb:SetLabel(string.format("%s (%d)", name or ("Spell "..spellID), spellID))
      if cb.SetImage then cb:SetImage(icon or "Interface\\Icons\\INV_Misc_QuestionMark") end
      if cb.SetImageSize then cb:SetImageSize(20,20) end
      local enabled = true
      if RCDT.IsSpellEnabledForClass then enabled = RCDT.IsSpellEnabledForClass(currentClass, spellID) end
      cb:SetValue(enabled)
      if cb.SetFullWidth then cb:SetFullWidth(true) end
      if cb.frame and cb.frame.SetHeight then cb.frame:SetHeight(24) end
      cb:SetCallback("OnValueChanged", function(_,_,v) SetFilterValue(currentClass, spellID, v) end)
      row:AddChild(cb)
      list:AddChild(row)
    end
  end

  dd:SetCallback("OnValueChanged", function(_,_,val) currentClass = val; dd:SetValue(val); BuildList() end)
  checkAll:SetCallback("OnClick", function()
    if not currentClass then return end
    RCDT.db.filters = RCDT.db.filters or {}; RCDT.db.filters[currentClass] = RCDT.db.filters[currentClass] or {}
    for sid in pairs(BY[currentClass]) do RCDT.db.filters[currentClass][sid] = true end
    BuildList(); if RCDT.UpdateUI then RCDT.UpdateUI() end
  end)
  uncheckAll:SetCallback("OnClick", function()
    if not currentClass then return end
    RCDT.db.filters = RCDT.db.filters or {}; RCDT.db.filters[currentClass] = RCDT.db.filters[currentClass] or {}
    for sid in pairs(BY[currentClass]) do RCDT.db.filters[currentClass][sid] = false end
    BuildList(); if RCDT.UpdateUI then RCDT.UpdateUI() end
  end)

  BuildList()
end

-- About
local function BuildTab_About(container)
  local l = AceGUI:Create("Label")
  l:SetFullWidth(true)
  l:SetText("RaidCDTracker - Thanks for using the addon!\n\n- /raidcd config: open this window\n- Style tab: customize bars and icons\n- Filters tab: choose which spells to show per class")
  container:AddChild(l)
end

function RCDT.OpenAceConfig(defaultTab)
  EnsureDB()
  if RCDT._aceWin and RCDT._aceWin.frame and RCDT._aceWin.frame:IsShown() then
    RCDT._aceWin:Hide(); return
  end
  local frame = AceGUI:Create("Frame")
  frame:SetTitle(ADDON_NAME .. " - Settings")
  frame:SetStatusText("")
  frame:SetLayout("Fill")
  frame:SetWidth(720); frame:SetHeight(540)
  frame:EnableResize(false)
  frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget); RCDT._aceWin = nil end)

  local tabs = {
    {text="Style", value="style"},
    {text="Display", value="display"},
    {text="Filters", value="filters"},
    {text="General", value="general"},
    {text="About", value="about"},
  }

  local group = AceGUI:Create("TabGroup")
  group:SetTabs(tabs)
  group:SetLayout("Flow")
  group:SetFullWidth(true)
  group:SetFullHeight(true)
  group:SetCallback("OnGroupSelected", function(container, event, sel)
    container:ReleaseChildren()
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("Flow")
    scroll:SetFullWidth(true)
    scroll:SetFullHeight(true)
    container:AddChild(scroll)
    if sel == "style"   then BuildTab_Style(scroll)
    elseif sel == "display" then BuildTab_Display(scroll)
    elseif sel == "filters" then BuildTab_Filters(scroll)
    elseif sel == "general" then BuildTab_General(scroll)
    elseif sel == "about"   then BuildTab_About(scroll)
    end
  end)
  frame:AddChild(group)
  group:SelectTab(defaultTab or "style")

  RCDT._aceWin = frame
  RCDT._aceWinGroup = group
end

function RCDT.ToggleConfig() RCDT.OpenAceConfig("style") end
function RCDT.ToggleFilters() RCDT.OpenAceConfig("filters") end
