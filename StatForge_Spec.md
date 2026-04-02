# StatForge — WoW Addon Specification

## Overview

StatForge is a World of Warcraft addon for in-game stat optimization. It operates as a sandbox using napkin math — not a simulator, not a spreadsheet. It reads the character's current gear, allows hypothetical swaps from bag items, layers gems/enchants/consumables at any quality rank, and evaluates the resulting stat vector against a chosen optimization path. All calculations update in real time.

---

## Optimization Paths

The user selects one of three optimization paths. The path determines how the aggregated stat vector is evaluated.

- **Stat Priority** — evaluates the stat vector against a ranked priority list defined per spec and hero talent build
- **Percentage Breakpoints** — checks whether the stat vector is hitting or missing specific stat thresholds
- **Budget Allocation** — treats the total stat budget as a finite resource and evaluates optimal distribution

---

## Stat Sources

### Gear

- Equipped items are read automatically from the WoW API on addon load and whenever `UNIT_INVENTORY_CHANGED` fires
- Bag items are scanned on load and on bag update events
- In the Optimizer frame each gear slot shows the equipped item plus any bag alternatives for that slot as selectable options
- Selecting a bag item as a hypothetical swap updates the full stat vector in real time
- A swapped item gets its own applied layer — the user can assign hypothetical gems, enchants, and ranks to it
- Empty sockets and unenchanted slots are flagged visually as a passive audit

### Applied Layer

All non-gear sources share a uniform data shape and are toggleable on/off with a rank 1 or rank 2 selector:

```
{
  name: string,
  slot: string,
  rank1: { [statKey: string]: number },
  rank2: { [statKey: string]: number }
}
```

Applied source types:
- **Gems** — pure or hybrid, assigned per socket
- **Enchants** — assigned per gear slot
- **Consumables** — food, flasks, weapon buffs

Gear items (weapons, armor) have 5 quality tiers but quality is already baked into the stats returned by the API — no quality modeling needed for gear. All applied sources (gems, enchants, consumables) have exactly 2 ranks.

---

## Sandbox Behavior

- Toggle any applied source on or off
- Switch between rank 1 and rank 2 per item
- Swap any gear slot to a bag alternative
- Stat vector recalculates live on every change
- Group toggle to enable or disable all consumables at once — instant baseline vs fully buffed comparison
- All changes are hypothetical until the user commits — used for planning before spending gold or crafting materials

---

## Spec Data

- 40 specs × 2 hero talent builds = 80 stat priority lists
- Sourced from Wowhead and maintained in a single data file bundled with the addon
- Hero talent build is auto-detected from the WoW API — no manual selection required
- The data file is updated and pushed to CurseForge at season starts or after major tuning patches
- Priority lists are user-editable locally as an escape hatch for edge cases or ahead of an official update

### Priority List Data Shape

```
{
  specId: string,
  heroTalent: string,
  priority: [statKey, statKey, ...]
}
```

---

## Saved Setups

- The user can save any sandbox state (gear selections, gem/enchant/consumable choices, ranks, active toggles) as a named setup
- Operations: save, load, rename, duplicate, delete
- The Shopping List is derived from whichever setup is currently loaded
- Setups are persisted via WoW's `SavedVariables` mechanism

---

## Import / Export

- Any saved setup can be exported as a base64 encoded share string
- The share string can be copied to clipboard and shared anywhere (Discord, guild forums, class discords, content descriptions)
- Importing accepts a pasted share string, shows a preview of its contents (spec, hero talent, items, ranks), and prompts confirmation before saving locally
- No external server or backend required — fully peer to peer via copy/paste

---

## Shopping List

- Derived from the current active sandbox state
- Lists every non-gear applied item that is toggled on, with its selected rank
- Copyable to chat for easy communication with crafters or the auction house
- Updates automatically when the sandbox state changes

---

## UI Structure

Single main window opened via minimap button or slash command. Navigation via tabs or sidebar.

### Tabs

**Optimizer**
- Gear slot panel — each slot shows equipped item and bag alternatives as a dropdown/selector
- Applied sources panel — all sockets, enchant slots, consumable slots with rank toggles and on/off state
- Optimization path selector
- Live stat vector display
- Empty socket and unenchanted slot audit indicators

**Setups**
- List of saved setups
- Actions: load, save current state, rename, duplicate, delete

**Shopping List**
- Itemized list of all active applied sources and their ranks
- Copy to chat button

**Import / Export**
- Export: setup selector, generated share string, copy to clipboard button
- Import: paste field, preview panel, confirm button

### Minimap Button

Opens the main window to the Optimizer tab by default.

---

## Slash Commands

All slash commands open the main window at the corresponding tab. Every command has a direct UI equivalent — slash commands are shortcuts, not a parallel interface.

| Command | Behavior |
|---|---|
| `/statforge` | Opens main window to Optimizer tab |
| `/statforge setups` | Opens main window to Setups tab |
| `/statforge list` | Opens main window to Shopping List tab |
| `/statforge import` | Opens Import/Export tab with focus on import field |
| `/statforge export` | Opens Import/Export tab with current setup pre-exported |
| `/statforge reset` | Clears sandbox state back to baseline |

---

## Icons

Using existing in-game Blizzard assets — no external files required, always available in the client, matches the WoW UI aesthetic natively.

| Usage | Asset Path | Notes |
|---|---|---|
| Minimap button | `Interface\\Icons\\Trade_Engraving` | Crafting tool icon, reads cleanly at 32x32 |
| Main window header | `Interface\\Icons\\INV_Misc_Gear_01` | Mechanical gear, fits the optimization theme |

---

## Technical Notes

- Language: Lua
- Distribution: CurseForge
- Gear state tracked via `UNIT_INVENTORY_CHANGED` and bag update events
- Spec and hero talent build auto-detected via the WoW API
- Saved setups and sandbox state persisted via `SavedVariables`
- All stat math is pure addition — no simulation, no proc modeling, no uptime assumptions
- Stat priority lists and applied item data maintained in a single external data file for easy patching
- Export strings use base64 encoding
- The addon has no external server dependencies — fully self-contained
