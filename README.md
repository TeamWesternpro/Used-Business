# TW Used Dealership

A FiveM script for selling and buying businesses in-game with a modern tablet UI, admin dashboard, and NUI-based website.

## Features

- **In-Game Tablet UI** — Open via `/tablet` command, `F6` keybind, or near a business ped (press `E`)
- **Admin Dashboard** — Full CRUD for business listings with login protection
- **Modern Blue Glass Design** — Glass morphism cards with hover animations
- **Real-Time Sync** — Changes made in admin dashboard instantly update all players' tablets
- **Configurable Peds & Blips** — Add/remove business locations in `config.lua`
- **Ace Permission Auth** — Discord ID and FiveM license based admin access
- **Business Types** — Dealership, Mechanic, Shops
- **Listing Cards** — Title, Description, Tags (Available/Not Available), Type, Price, Thumbnail

## Installation

1. Place `tw-useddealership` folder into your `resources` directory
2. Add `ensure tw-useddealership` to your `server.cfg`
3. Configure admin permissions in `server.cfg`:

```cfg
# Discord-based admin access
add_ace resource.tw-useddealership admin allow
add_principal identifier.discord:YOUR_DISCORD_ID resource.tw-useddealership admin

# License-based admin access
add_principal identifier.license:YOUR_LICENSE resource.tw-useddealership admin
```

4. Restart your server

## Configuration

Edit `config.lua` to customize:

- **Ped Locations** — Add/remove business peds with coordinates, heading, and blip settings
- **Blip Settings** — Sprite, color, scale, and label per location
- **Keybind** — Default `F6`, changeable in config
- **Interaction Key** — Default `E` (key code 38)
- **Business Types** — Add new types to `Config.BusinessTypes`
- **Tag Options** — Customize available/ unavailable tags

### Example: Adding a New Ped Location

```lua
{
    model = 's_m_m_businessman_01',
    coords = vector4(x, y, z, heading),
    blip = {
        sprite = 474,
        color = 3,
        scale = 0.8,
        label = 'Used Business - Your Location'
    },
    name = 'Your Location Name'
}
```

## Admin Dashboard Login

Default credentials:
- **Username:** `admin`
- **Password:** `admin123`

> **IMPORTANT:** Change these in `html/js/admin.js` before deploying to production!

## Files Structure

```
tw-useddealership/
├── fxmanifest.lua          # Resource manifest
├── config.lua              # Ped locations, blips, settings
├── server/
│   ├── main.lua            # Server logic (data, auth, sync)
│   └── callbacks.lua       # Server callbacks (ESX/QBCore)
├── client/
│   ├── main.lua            # Client logic (peds, blips, NUI)
│   └── tablet.lua          # (merged into main.lua)
├── data/
│   └── listings.json       # Business listings data
├── html/
│   ├── tablet.html         # Tablet NUI page
│   ├── dashboard.html      # Admin dashboard page
│   ├── css/
│   │   └── style.css       # Blue glass theme
│   └── js/
│       ├── app.js          # Shared card rendering
│       ├── admin.js        # Admin dashboard logic
│       └── tablet.js       # Tablet UI logic
└── README.md
```

## Tablet Access Methods

| Method | Command/Key |
|--------|-------------|
| Command | `/tablet` |
| Keybind | `F6` (configurable) |
| Ped Interaction | Walk near a business ped and press `E` |

## Dependencies

- **Optional:** `es_extended` (ESX) or `qb-core` (QBCore) for player data callbacks
- **No required dependencies** — works standalone

## Data Storage

Listings are stored in `data/listings.json`. This file is auto-created and managed by the script. Back up this file to preserve your listings.

## Notes

- Admin access requires Ace permissions configured in `server.cfg`
- The dashboard uses a simple username/password login as a first layer; Ace permissions are the real access control
- All changes sync in real-time to all connected players
- The tablet and dashboard share the same modern blue glass CSS theme

