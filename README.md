# TW Used Business

A standalone FiveM script for browsing and managing business-for-sale listings in-game via a tablet UI.

## Features

- **In-Game Tablet UI** — Glass-morphism design, open via `/tablet` or `/usedadmin`, `F6` keybind, or near a ped (press `E`)
- **Admin Dashboard** — Full CRUD for business listings inside the tablet (no separate page)
- **Ace Permission Auth** — Grant admin via `server.cfg` or `Config.AdminLicenses` in `config.lua`
- **Business Types** — Dealership, Mechanic, Shops, Houses
- **Configurable Peds & Blips** — Add/remove NPC locations with custom models, coords, blip colors, and labels
- **Local JSON Storage** — Listings saved in `data/listings.json`, no database required
- **No Dependencies** — Works standalone, no ESX/QBCore/ox_lib needed

## Installation

1. Copy `tw-useddealership` into your server's `resources/` directory
2. Add `ensure tw-useddealership` to your `server.cfg`
3. Grant admin access (pick one):

**Option A — Ace permission in `server.cfg`:**
```cfg
add_ace license:YOUR_LICENSE_ID useddealership.admin allow
```

**Option B — `Config.AdminLicenses` in `config.lua`:**
```lua
Config.AdminLicenses = { 'YOUR_LICENSE_ID' }
```

4. Restart your server

## Usage

| Action | Method |
|--------|--------|
| Open tablet | `/tablet` command, `F6` key, or walk near a ped and press `E` |
| Open admin dashboard | `/usedadmin` command or tap the lock icon in the tablet |
| Browse listings | Scroll the tablet home page |
| Book a business | Tap "Book Now" on any listing |
| Add / Edit / Delete | Requires admin — use the dashboard view |

## Configuration

Edit `config.lua`:

- `Config.AdminLicenses` — list of license IDs (without `license:` prefix) for admin access
- `Config.Debug` — set `true` to see spawn/sync logs in server console
- `Config.Peds` — array of NPC locations; each entry supports:
  - `model` — any FiveM ped model string
  - `coords` — `vector4(x, y, z, heading)`
  - `blip` — sprite, color, scale, label (set `enabled = false` to hide)
- `Config.Tablet` — command name, keybind, interaction key/distance, prompt text

### Adding a Ped

```lua
{
    model = 's_m_m_businessman_01',
    coords = vector4(1156.27, -775.95, 57.55, 27.8),
    blip = {
        enabled = true,
        sprite = 474,   -- 474 = Currency $ icon
        color = 3,       -- 3 = Green
        scale = 0.8,
        label = 'Used Business'
    }
}
```

## Admin Access

Two ways to grant admin:

1. **Ace permission** (recommended) — add to `server.cfg`:
   ```
   add_ace license:YOUR_LICENSE useddealership.admin allow
   ```
   The script checks `useddealership.admin` and `useddealership.owner` principals.

2. **Config list** — paste license IDs into `Config.AdminLicenses`:
   ```lua
   Config.AdminLicenses = {
       'abc123def456',  -- no "license:" prefix
   }
   ```

No hardcoded passwords, no login form — admin is granted server-side based on identity.

## File Structure

```
tw-useddealership/
├── fxmanifest.lua          # Resource manifest
├── config.lua              # Peds, blips, tablet settings, admin licenses
├── server/
│   └── main.lua            # Server logic: listings CRUD, auth, sync to clients
├── client/
│   └── main.lua            # Client logic: peds, blips, NUI callbacks, tablet control
├── data/
│   ├── listings.json       # Business listings (auto-managed)
│   ├── config.json         # Cached config (auto-managed)
│   └── bookings.json       # Booking requests (auto-managed)
├── html/
│   ├── tablet.html         # Main NUI page (tablet + dashboard combined)
│   ├── css/
│   │   └── style.css       # Blue glass-morphism theme
│   └── js/
│       ├── app.js          # Listing card rendering, notifications, helpers
│       ├── admin.js        # Admin dashboard CRUD UI
│       └── tablet.js       # Tablet home/browse UI
└── README.md
```

## Data Storage

All data is stored as JSON files in `data/`. No database required. Back up `data/listings.json` to preserve your listings.

## Notes

- The script is fully **standalone** — it does not require ESX, QBCore, or any other framework
- `/usedadmin` opens the tablet and triggers an admin permission check server-side
- Admin dashboard is embedded in the tablet UI (no separate HTML page)
- No external API calls, no Discord webhooks, no Vercel deployment needed
