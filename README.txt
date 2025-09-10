Winterfall - Raid CD Tracker (MoP Classic)

Overview
- Tracks major raid cooldowns across your group and shows them in bars or icons.
- Networked updates with protocol v3 (includes activeDur for accurate Active state).
- Per-class filters and rich styling options.

Compatibility
- Client: MoP Classic (Interface 50500)
- SavedVariables: RaidCDTrackerDB
- Optional: Ace3 (AceGUI-3.0) for the configuration window. Without Ace3, core tracking works, but /raidcd config/filters UI won’t open.

Installation
1) Unzip so the folder path is: Interface\AddOns\WinterfallCDTracker
2) Ensure the top-level folder name is exactly: WinterfallCDTracker
3) Enable the addon on the character select AddOns screen.

Usage
- Move the frame: drag when unlocked; position is saved.
- Bars or Icons mode: change in the Style tab.
- Filters: choose which class spells to show.
- Display contexts: control visibility in instance/raid/party/solo.

Slash Commands
- /raidcd config    -> Open settings (Ace3 required)
- /raidcd filters   -> Open class filters (Ace3 required)
- /raidcd dump      -> Print current state snapshot
- /raidcd lock      -> Lock frame
- /raidcd unlock    -> Unlock frame
- /raidcd debug on  -> Enable debug log
- /raidcd debug off -> Disable debug log

Notes
- Icons mode supports desaturation on cooldown, optional countdown numbers, and colored borders.
- Bars mode supports class-color on Ready, custom textures, and font sizing.
- Network sync auto-requests on zone enter and group changes.

Feedback
- This is a beta build (1.1.0-beta). Please report issues and suggestions.

