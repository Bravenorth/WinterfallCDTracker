-- UI/55_Ticker.lua
-- UI ticker (fixed period) and retro-compat wrapper

local RCDT = RaidCDTracker
local DEFAULT_PERIOD = (RCDT and RCDT.UI_TICK_SEC) or 0.10

local function EnsureUITicker(period)
  local p = tonumber(period) or DEFAULT_PERIOD
  if RCDT._uiTickerPeriod and RCDT._uiTicker and math.abs((RCDT._uiTickerPeriod or 0) - p) < 1e-6 then
    return
  end
  if RCDT._uiTicker and RCDT._uiTicker.Cancel then
    RCDT._uiTicker:Cancel()
  end
  RCDT._uiTicker = C_Timer.NewTicker(p, function()
    if RCDT.UpdateUI then RCDT.UpdateUI() end
  end)
  RCDT._uiTickerPeriod = p
end

-- Start immediately on load with default period
EnsureUITicker(DEFAULT_PERIOD)

-- Retro-compat: accept optional custom period
function RCDT.StartUITicker(sec)
  EnsureUITicker(sec)
end
