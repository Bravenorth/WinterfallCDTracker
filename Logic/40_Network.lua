-- Logic/40_Network.lua
-- Sérialisation, envoi réseau, réception/sync (MoP Classic)

local RCDT = RaidCDTracker

------------------------------------------------------------
-- Helpers
------------------------------------------------------------
local function GetTrackedForPlayer()
  local classToken = select(2, UnitClass("player"))
  local byClass =
      (RCDT.TrackedByClass and RCDT.TrackedByClass())
      or RCDT.TRACKED_BY_CLASS
      or _G.RaidCDTracker_Cooldowns
      or {}
  return (classToken and byClass[classToken]) or {}
end

local function UpdateMyLocalState(spellID, state, remain, totalCD, activeDur)
  local me = RCDT.FullUnitName("player") or UnitName("player") or "player"
  if RCDT.CanonicalizePlayerKey then
    me = RCDT.CanonicalizePlayerKey(me) or me
  end
  RCDT.UpdateLocalState(me, spellID, state, remain, totalCD, activeDur)
end

------------------------------------------------------------
-- Serialize / Send
------------------------------------------------------------
-- v3 inclut activeDur
function RCDT.SerializeStatus(spellID, state, remain, totalCD, activeDur)
  return ("S:%d:%d:%d:%0.2f:%0.2f:%0.2f"):format(RCDT.VERSION or 3, spellID, state, remain or 0, totalCD or 0, activeDur or 0)
end

function RCDT.SendStatus(spellID, state, remain, totalCD, activeDur)
  if not IsPlayerSpell(spellID) then return end

  -- Toujours mettre à jour localement
  UpdateMyLocalState(spellID, state, remain, totalCD, activeDur)

  -- Et envoyer si en groupe
  local chan = RCDT.Channel()
  if not chan then return end

  C_ChatInfo.SendAddonMessage(RCDT.PREFIX, RCDT.SerializeStatus(spellID, state, remain, totalCD, activeDur), chan)
  RCDT.DebugLog("SEND", spellID.." -> "..(RCDT.STATUS_NAME[state] or state))
end

function RCDT.SendFullStatus()
  local TRACKED = GetTrackedForPlayer()
  for spellID, cfg in pairs(TRACKED) do
    if IsPlayerSpell(spellID) then
      local state, remain, duration, active = RCDT.EvaluateCooldown(spellID, cfg)
      RCDT.SendStatus(spellID, state, remain, duration, active)
    end
  end
end

------------------------------------------------------------
-- Receive / Sync
------------------------------------------------------------
function RCDT.OnAddonMsg(prefix, msg, _, sender)
  if prefix ~= RCDT.PREFIX then return end

  -- Demande de synchro
  if msg == "SYNC_REQUEST" then
    local chan = RCDT.Channel()
    if chan then
      -- IMPORTANT: encapsuler le callback, au cas où SendFullStatus n’est pas encore défini
      local delay = math.random(0, 20) / 10 -- 0.0 à 2.0 s
      C_Timer.After(delay, function()
        if RCDT.SendFullStatus then RCDT.SendFullStatus() end
      end)
    end
    return
  end

  -- Ignore nos propres messages (on a déjà mis à jour localement à l’envoi)
  local meShort = RCDT.ShortName(RCDT.FullUnitName("player") or UnitName("player") or "")
  if meShort ~= "" and RCDT.ShortName(sender) == meShort then
    return
  end

  -- Version
  local ver = tonumber((msg:match("^S:(%d+):")))
  if not ver or ver < 2 or ver > (RCDT.VERSION or 3) then return end

  -- Parse v3: S:ver:spellID:state:remain:total:active
  local spellID, st, remain, total, active =
      msg:match("^S:%d+:(%d+):(%d+):([%d%.]+):([%d%.]+):([%d%.]+)$")
  if not spellID then
    -- Parse v2 (sans activeDur)
    spellID, st, remain, total =
        msg:match("^S:%d+:(%d+):(%d+):([%d%.]+):([%d%.]+)$")
  end

  spellID = tonumber(spellID); st = tonumber(st)
  remain  = tonumber(remain) or 0; total = tonumber(total) or 0
  active  = tonumber(active) or 0
  if not spellID or not RCDT.STATUS_NAME[st] then return end

  -- Filtre: ignorer si le sort n’est pas suivi pour la classe du joueur
  if not RCDT.IsTrackedFor(sender, spellID) then return end

  -- Canonicaliser la clé joueur (fusion Nom / Nom-Royaume)
  local who = (RCDT.CanonicalizePlayerKey and RCDT.CanonicalizePlayerKey(sender)) or sender

  RCDT.UpdateLocalState(who, spellID, st, remain, total, active)
  RCDT.DebugLog("RECV", (who or "?").." "..spellID.." -> "..(RCDT.STATUS_NAME[st] or st))
end
