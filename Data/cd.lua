-- cd.lua
-- Catalogue des cooldowns par classe (MoP)

local TRACKED_BY_CLASS = {
    SHAMAN = {
        [32182]  = {},             -- Heroism
        [2825]   = {},             -- Bloodlust
        [20608]  = {},             -- Reincarnation
        [114049] = {},             -- Stormlash Totem
        [108281] = { active = 8 }, -- Ancestral Guidance
        [2894]   = { active = 60}, -- Fire Elemental Totem
        [2062]   = { active = 60}, -- Earth Elemental Totem
        [108280] = { active = 10}, -- Healing Tide Totem
        [16190]  = { active = 12}, -- Mana Tide Totem
        [98008]  = { active = 6 }, -- Spirit Link Totem
        [114052] = { active = 15}, -- Ascendance (heal)
    },
    DRUID = {
        [740]    = { active = 8 },  -- Tranquility
        [102342] = { active = 12},  -- Ironbark
        [33891]  = { active = 30},  -- Incarnation: Tree of Life
        [61336]  = { active = 12},  -- Survival Instincts
        [22812]  = { active = 12},  -- Barkskin
        [20484]  = {},              -- Rebirth
        [29166]  = {},              -- Innervate
        [77761]  = {},              -- Stampeding Roar
    },
    PALADIN = {
        [31821]  = { active = 6 },  -- Devotion Aura
        [31884]  = { active = 20},  -- Avenging Wrath
        [86659]  = { active = 12},  -- Guardian of Ancient Kings
        [105809] = { active = 18},  -- Holy Avenger
        [498]    = { active = 10},  -- Divine Protection
        [642]    = { active = 8 },  -- Divine Shield
        [6940]   = { active = 12},  -- Hand of Sacrifice
        [1022]   = { active = 10},  -- Hand of Protection
    },
    MONK = {
        [115310] = { active = 3 },  -- Revival
        [116849] = { active = 12},  -- Life Cocoon
        [115203] = { active = 20},  -- Fortifying Brew
        [115176] = { active = 8 },  -- Zen Meditation
    },
    WARRIOR = {
        [97462]  = { active = 10},  -- Rallying Cry
        [118038] = { active = 8 },  -- Die by the Sword
        [12975]  = { active = 20},  -- Last Stand
        [871]    = { active = 12},  -- Shield Wall
    },
    ROGUE = {
        [31224]  = { active = 5 },  -- Cloak of Shadows
        [5277]   = { active = 10},  -- Evasion
        [1856]   = { active = 3 },  -- Vanish
        [57934]  = { active = 6 },  -- Tricks of the Trade
    },
    DEATHKNIGHT = {
        [51052]  = { active = 10},  -- Anti-Magic Zone
        [48792]  = { active = 12},  -- Icebound Fortitude
        [55233]  = { active = 10},  -- Vampiric Blood
        [49222]  = { active = 12},  -- Bone Shield
        [48707]  = { active = 5 },  -- Anti-Magic Shell
    },
    MAGE = {
        [45438]  = { active = 10},  -- Ice Block
        [12042]  = { active = 15},  -- Arcane Power
        [12472]  = { active = 20},  -- Icy Veins
        [80353]  = {},              -- Time Warp
    },
    HUNTER = {
        [19263]  = { active = 5 },  -- Deterrence
        [34477]  = {},              -- Misdirection
    },
    PRIEST = {
        [62618]  = { active = 10},  -- Power Word: Barrier
        [64843]  = { active = 8 },  -- Divine Hymn
        [33206]  = { active = 8 },  -- Pain Suppression
        [47788]  = { active = 10},  -- Guardian Spirit
        [47585]  = { active = 6 },  -- Dispersion
        [10060]  = { active = 20},  -- Power Infusion
        [19236]  = { active = 10},  -- Desperate Prayer
    },
}

-- exposer la table
RaidCDTracker_Cooldowns = TRACKED_BY_CLASS
