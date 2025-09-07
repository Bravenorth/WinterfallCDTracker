-- Core/00_Init.lua
-- Namespace, constantes, état global, prefix

RaidCDTracker = RaidCDTracker or {}
local RCDT = RaidCDTracker

-- Métadonnées / flags
RCDT.ADDON       = "RaidCDTracker"
RCDT.VERSION     = 3         -- v3: ajoute activeDur au protocole
RCDT.DEBUG_MODE  = false

-- Constantes
RCDT.GCD_THRESHOLD = 1.5
RCDT.UI_TICK_SEC   = 0.10

-- Statuts
RCDT.STATUS      = { Ready = 0, Active = 1, OnCD = 2 }
RCDT.STATUS_NAME = { [0] = "Ready", [1] = "Active", [2] = "OnCD" }

-- État partagé
RCDT.raidState   = RCDT.raidState or {}     -- [playerFull][spellID] = {status,endTime,totalCD,activeDur}
RCDT._lastStates = RCDT._lastStates or {}   -- [spellID] = last state (local player)

-- Helper: source de vérité des cooldowns par classe (chargés depuis Data/cd.lua)
function RCDT.TrackedByClass()
    return _G.RaidCDTracker_Cooldowns or {}
end

-- Prefix réseau
RCDT.PREFIX = "BraveRaidCD"
do
    local ok = C_ChatInfo.RegisterAddonMessagePrefix(RCDT.PREFIX)
    if not ok then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff5555["..RCDT.ADDON.."] Impossible d’enregistrer le prefix '"..RCDT.PREFIX.."'|r")
    end
end

-- Expose pour debug si souhaité
RaidCDTracker_RaidState = RCDT.raidState
