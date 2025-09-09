-- UI/60_AceConfig.lua
-- Fenetre de configuration via AceGUI (propre, onglets)

local RCDT = RaidCDTracker
local ADDON_NAME = (RCDT and RCDT.ADDON) or "RaidCDTracker"

local AceGUI = (LibStub and LibStub("AceGUI-3.0", true))
if not AceGUI then
  -- AceGUI non dispo: on ne fait rien (fallback conserve l'ancien UI)
  return
end

local function EnsureDB()
  if not RCDT.db and RCDT.DBInit then RCDT.DBInit() end
  if RCDT.StyleEnsureDefaults then RCDT.StyleEnsureDefaults() end
  if RCDT.DisplayEnsureDefaults then RCDT.DisplayEnsureDefaults() end
  if RCDT.FiltersEnsureDefaults then RCDT.FiltersEnsureDefaults() end
end

-- Helpers de création
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
  c:SetCallback("OnValueConfirmed", function(_, _, r,g,b, a) set(r,g,b) end)
  parent:AddChild(c)
  return c
end

-- Onglet: General
local function BuildTab_General(container)
  EnsureDB()
  addHeading(container, "General")

  addCheckbox(container, "Verrouiller la fenetre",
    function() return RCDT.db and RCDT.db.ui and RCDT.db.ui.locked end,
    function(v) if not RCDT.db then return end; RCDT.db.ui.locked = v; if RCDT.ApplyConfigUI then RCDT.ApplyConfigUI() end end
  )

  local btn = AceGUI:Create("Button")
  btn:SetText("Reinitialiser la position")
  btn:SetCallback("OnClick", function()
    if not RCDT.db then return end
    RCDT.db.ui.pos = nil
    if RCDT.ui then RCDT.ui:ClearAllPoints(); RCDT.ui:SetPoint("CENTER") end
  end)
  container:AddChild(btn)

  local btnFilters = AceGUI:Create("Button")
  btnFilters:SetText("Ouvrir les filtres…")
  btnFilters:SetCallback("OnClick", function() if RCDT.ToggleFilters then RCDT.ToggleFilters() end end)
  container:AddChild(btnFilters)
end

-- Onglet: Style
local function BuildTab_Style(container)
  EnsureDB()
  local s = (RCDT.GetStyle and RCDT.GetStyle()) or {}

  addHeading(container, "Style")

  addCheckbox(container, "Afficher le nom du joueur",
    function() return s.showPlayer ~= false end,
    function(v) s.showPlayer = v; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)

  addCheckbox(container, "Afficher le texte du timer",
    function() return s.showTimer ~= false end,
    function(v) s.showTimer = v; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)

  addCheckbox(container, "Icone a droite",
    function() return s.iconOnRight == true end,
    function(v) s.iconOnRight = v; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)

  addCheckbox(container, "Croissance vers le haut",
    function() return s.growUp == true end,
    function(v) s.growUp = v; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)

  addCheckbox(container, "Pret: utiliser la couleur de classe",
    function() return s.useClassColorWhenReady ~= false end,
    function(v) s.useClassColorWhenReady = v; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)

  addSlider(container, "Hauteur de ligne", 12, 40, 1,
    function() return s.rowHeight or 18 end,
    function(v) s.rowHeight = v; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)

  addSlider(container, "Espacement entre lignes", 0, 12, 1,
    function() return s.rowSpacing or 0 end,
    function(v) s.rowSpacing = v; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)

  addSlider(container, "Taille d'icone", 12, 40, 1,
    function() return s.iconSize or 18 end,
    function(v) s.iconSize = v; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)

  addSlider(container, "Largeur de la barre", 120, 500, 5,
    function() return s.barWidth or 220 end,
    function(v) s.barWidth = v; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)

  addSlider(container, "Taille de police", 8, 18, 1,
    function() return s.fontSize or 11 end,
    function(v) s.fontSize = v; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)

  addHeading(container, "Couleurs")
  addColor(container, "Couleur: Pret",
    function() local c = s.readyColor or {r=0.2,g=0.8,b=0.2}; return c.r or 1, c.g or 1, c.b or 1 end,
    function(r,g,b) s.readyColor = {r=r,g=g,b=b}; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)

  addColor(container, "Couleur: Actif",
    function() local c = s.activeColor or {r=0.0,g=0.7,b=1.0}; return c.r or 0, c.g or 0.7, c.b or 1 end,
    function(r,g,b) s.activeColor = {r=r,g=g,b=b}; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)

  addColor(container, "Couleur: Rechargement",
    function() local c = s.onCDColor or {r=1.0,g=0.0,b=0.0}; return c.r or 1, c.g or 0, c.b or 0 end,
    function(r,g,b) s.onCDColor = {r=r,g=g,b=b}; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end end)

  addHeading(container, "Texture de barre")
  local textures = {
    {key = "Interface\\TARGETINGFRAME\\UI-StatusBar", label = "Par defaut"},
    {key = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill", label = "Raid HP Fill"},
    {key = "Interface\\BUTTONS\\WHITE8X8", label = "Blanc 8x8"},
  }
  for _, t in ipairs(textures) do
    local b = AceGUI:Create("Button")
    b:SetText(t.label)
    b:SetCallback("OnClick", function()
      s.barTexture = t.key; if RCDT.ApplyStyleUI then RCDT.ApplyStyleUI() end
    end)
    container:AddChild(b)
  end
end

-- Onglet: Affichage (contextes)
local function BuildTab_Display(container)
  EnsureDB()
  addHeading(container, "Affichage (contexte)")
  local d = RCDT.db.display or {}
  addCheckbox(container, "Afficher en instance", function() return d.instance ~= false end, function(v) d.instance = v; if RCDT.UpdateUI then RCDT.UpdateUI() end end)
  addCheckbox(container, "Afficher en raid",     function() return d.raid     ~= false end, function(v) d.raid     = v; if RCDT.UpdateUI then RCDT.UpdateUI() end end)
  addCheckbox(container, "Afficher en groupe",   function() return d.party    ~= false end, function(v) d.party    = v; if RCDT.UpdateUI then RCDT.UpdateUI() end end)
  addCheckbox(container, "Afficher en solo",     function() return d.solo     ~= false end, function(v) d.solo     = v; if RCDT.UpdateUI then RCDT.UpdateUI() end end)
end

-- Onglet: Filtres (ouvre la fenetre existante)
local function BuildTab_Filters(container)
  EnsureDB()
  addHeading(container, "Filtres par classe")

  local BY = (RCDT.GetTrackedByClass and RCDT.GetTrackedByClass()) or {}

  -- Build class list for dropdown
  local classList, classOrder = {}, {}
  for token in pairs(BY) do
    classList[token] = token
    table.insert(classOrder, token)
  end
  table.sort(classOrder)

  local currentClass = classOrder[1]

  local dd = AceGUI:Create("Dropdown")
  dd:SetLabel("Classe")
  dd:SetList(classList, classOrder)
  dd:SetValue(currentClass)
  container:AddChild(dd)

  local btns = AceGUI:Create("SimpleGroup")
  btns:SetLayout("Flow")
  btns:SetFullWidth(true)
  container:AddChild(btns)

  local checkAll = AceGUI:Create("Button")
  checkAll:SetText("Tout cocher")
  btns:AddChild(checkAll)

  local uncheckAll = AceGUI:Create("Button")
  uncheckAll:SetText("Tout decocher")
  btns:AddChild(uncheckAll)

  local scroll = AceGUI:Create("ScrollFrame")
  scroll:SetLayout("Flow")
  scroll:SetFullWidth(true)
  scroll:SetFullHeight(true)
  container:AddChild(scroll)

  local function SetFilterValue(classToken, spellID, enabled)
    RCDT.db.filters = RCDT.db.filters or {}
    RCDT.db.filters[classToken] = RCDT.db.filters[classToken] or {}
    RCDT.db.filters[classToken][spellID] = enabled and true or false
    if RCDT.UpdateUI then RCDT.UpdateUI() end
  end

  local function BuildList()
    scroll:ReleaseChildren()
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

      local cb = AceGUI:Create("CheckBox")
      cb:SetLabel(string.format("%s (%d)", name or ("Spell "..spellID), spellID))
      if cb.SetImage then cb:SetImage(icon or "Interface\\Icons\\INV_Misc_QuestionMark") end
      local enabled = true
      if RCDT.IsSpellEnabledForClass then enabled = RCDT.IsSpellEnabledForClass(currentClass, spellID) end
      cb:SetValue(enabled)
      cb:SetCallback("OnValueChanged", function(_,_,v) SetFilterValue(currentClass, spellID, v) end)
      row:AddChild(cb)
      scroll:AddChild(row)
    end
  end

  dd:SetCallback("OnValueChanged", function(_,_,val)
    currentClass = val
    dd:SetValue(val)
    BuildList()
  end)

  checkAll:SetCallback("OnClick", function()
    if not currentClass then return end
    RCDT.db.filters = RCDT.db.filters or {}
    RCDT.db.filters[currentClass] = RCDT.db.filters[currentClass] or {}
    for sid in pairs(BY[currentClass]) do RCDT.db.filters[currentClass][sid] = true end
    BuildList(); if RCDT.UpdateUI then RCDT.UpdateUI() end
  end)

  uncheckAll:SetCallback("OnClick", function()
    if not currentClass then return end
    RCDT.db.filters = RCDT.db.filters or {}
    RCDT.db.filters[currentClass] = RCDT.db.filters[currentClass] or {}
    for sid in pairs(BY[currentClass]) do RCDT.db.filters[currentClass][sid] = false end
    BuildList(); if RCDT.UpdateUI then RCDT.UpdateUI() end
  end)

  BuildList()
end

-- Onglet: A propos
local function BuildTab_About(container)
  local l = AceGUI:Create("Label")
  l:SetFullWidth(true)
  l:SetText("RaidCDTracker - Merci d'utiliser l'addon!\n\n- /raidcd config : ouvre cette fenetre\n- Onglet Style : personnalisez vos barres en direct\n- Onglet Filtres : choisissez les sorts a afficher par classe")
  container:AddChild(l)
end

-- Création / ouverture
function RCDT.OpenAceConfig(defaultTab)
  EnsureDB()
  if RCDT._aceWin and RCDT._aceWin.frame and RCDT._aceWin.frame:IsShown() then
    RCDT._aceWin:Hide()
    return
  end

  local frame = AceGUI:Create("Frame")
  frame:SetTitle(ADDON_NAME .. " - Configuration")
  frame:SetStatusText("")
  frame:SetLayout("Fill")
  frame:SetWidth(720)
  frame:SetHeight(540)
  frame:EnableResize(false)
  frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget); RCDT._aceWin = nil end)

  local tabs = {
    {text="Style", value="style"},
    {text="Affichage", value="display"},
    {text="Filtres", value="filters"},
    {text="General", value="general"},
    {text="A propos", value="about"},
  }

  local group = AceGUI:Create("TabGroup")
  group:SetTabs(tabs)
  group:SetLayout("Flow")
  group:SetCallback("OnGroupSelected", function(container, event, sel)
    container:ReleaseChildren()
    if sel == "style"   then BuildTab_Style(container)
    elseif sel == "display" then BuildTab_Display(container)
    elseif sel == "filters" then BuildTab_Filters(container)
    elseif sel == "general" then BuildTab_General(container)
    elseif sel == "about"   then BuildTab_About(container)
    end
  end)
  frame:AddChild(group)
  group:SelectTab(defaultTab or "style")

  RCDT._aceWin = frame
  RCDT._aceWinGroup = group
end

-- Remplace le ToggleConfig pour utiliser AceGUI
function RCDT.ToggleConfig()
  RCDT.OpenAceConfig("style")
end

function RCDT.ToggleFilters()
  RCDT.OpenAceConfig("filters")
end
