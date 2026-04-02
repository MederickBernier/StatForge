# StatForge

A stat optimization sandbox for World of Warcraft.

StatForge lets you plan gear swaps, gems, enchants, and consumables without leaving the game — and see the resulting stat totals update in real time. No SimC, no browser tabs, no spreadsheets.

---

## Features

- **Gear swap sandbox** — Compare bag alternatives against your equipped gear per slot. Swapped slots are highlighted; slots with missing gems or enchants are flagged in orange.
- **Applied sources** — Toggle gems, enchants, and consumables on/off individually, with R1/R2 quality switching. The stat vector updates immediately.
- **Stat totals with priority coloring** — Stats are colored by their rank in your spec's priority list (gold → blue → green) so the most important numbers stand out.
- **Auto spec detection** — Detects your active spec and hero talent path via `IsPlayerSpell`, then applies the matching priority list automatically.
- **Saved setups** — Snapshot the full sandbox state (gear overrides + applied sources) under a name. Load or delete setups across sessions.
- **Shopping list** — Generates a prioritized list of the gems, enchants, and consumables you have enabled. One-click copy to clipboard.
- **Import / Export** — Share a setup string with guildmates or alts. No external tools needed; the format is a compact base64 payload prefixed with `SF:1:`.
- **Minimap button** — Draggable around the minimap rim; also shows in the Addon Compartment.

---

## Installation

**CurseForge / WoWUp (recommended)**

Search for *StatForge* and install normally.

**Manual**

1. Download the latest release zip.
2. Extract the `StatForge` folder into `World of Warcraft/_retail_/Interface/Addons/`.
3. Reload the game or log in.

---

## Usage

| Command | Action |
|---|---|
| `/statforge` or `/sf` | Open the Optimizer tab |
| `/statforge setups` | Open the Setups tab |
| `/statforge list` | Open the Shopping List tab |
| `/statforge export` | Open the Export panel |
| `/statforge import` | Open the Import panel |
| `/statforge reset` | Reset the sandbox to baseline |
| `/statforge debug` | Print spec detection info to chat |

The window is also accessible from the minimap button or the Addon Compartment menu.

### Optimizer tab

- **Gear Slots** — Click the `v` button on any slot to see a dropdown of bag alternatives. Selecting an item swaps it into the sandbox (gold text). Select *[Reset]* to go back to your equipped item.
- **Applied Sources** — Click `[ ]` to enable a source; the bracket fills to `[x]` when active. Click `R1` or `R2` to switch quality tiers.
- **Stat Totals** — Updates automatically whenever you change anything. Stats are sorted by priority rank for your spec. Grey stats are unranked secondary stats.

### Setups tab

Type a name in the box and click **Save** to snapshot the current sandbox. **Load** restores a setup into the sandbox. **Delete** asks for confirmation before removing it permanently.

### Shopping List tab

Shows all currently-enabled gems, enchants, and consumables grouped by type. Click **Copy to Clipboard** to paste the list anywhere.

### Import / Export tab

**Export** — Click *Export Current* to generate a share string from the live sandbox, or type a saved setup name and click *Export* to export that instead. Click *Copy* to put the string in your clipboard.

**Import** — Paste a share string into the box and click *Preview* to decode it. Review the summary, enter a name, then click *Save Setup* to add it to your setup list.

---

## Spec & Hero Talent Detection

StatForge detects your spec via `GetSpecializationInfo()` and your hero talent path via `IsPlayerSpell()` against a sentinel spell ID unique to each tree. Priority lists cover all specs and hero talent combinations.

If your spec is detected but the hero talent shows `(?)`, the sentinel spell ID for that path hasn't been populated yet. Run `/statforge debug` and share the output in an issue so the missing ID can be added to `Data/SpecData.lua`.

---

## Compatibility

| Version | Status |
|---|---|
| The War Within (11.x) | Supported |
| Midnight (12.x) | Supported |

StatForge uses only public, non-protected WoW APIs. It reads stat and item data but never touches the combat log, unit health/power values, or any protected frame.

---

## Contributing

Pull requests are welcome for:

- Correcting or adding stat priority lists (`Data/SpecData.lua`)
- Filling in missing sentinel spell IDs (`sentinelSpellId` fields in `Data/SpecData.lua`)
- Updating gem/enchant/consumable values after a patch (`Data/AppliedData.lua`)

Please open an issue before submitting anything that touches architecture or the share string format.

---

## License

MIT
