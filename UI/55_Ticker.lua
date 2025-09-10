-- UI/55_Ticker.lua
-- UI ticker (fixed period) and retro-compat wrapper

local RCDT = RaidCDTracker
local UI_PERIOD = (RCDT and RCDT.UI_TICK_SEC) or 0.10

local function EnsureUITicker()
  if not RCDT._uiTicker then
    RCDT._uiTicker = C_Timer.NewTicker(UI_PERIOD, RCDT.UpdateUI)
  end
end

-- Start immediately on load
EnsureUITicker()

-- Retro-compat: ignore argument
function RCDT.StartUITicker(_)
  EnsureUITicker()
end
