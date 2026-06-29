# GuildBeacon

Standalone World of Warcraft addon for guild officers: recruitment beacon, whisper inbox, and candidate pipeline.

No dependency on KhalandrasUICore. Optional visual alignment with Khalandras palette (gold / bordeaux).

## Features (roadmap)

| Module | v0.1 | Next |
|---|---|---|
| **Beacon** | Templates, scheduler stub, `/gb beacon` | Anti-spam, channel rotation, instance rules |
| **Inbox** | Whisper capture | Guild chat keywords, filters |
| **Candidates** | Local store, statuses | Raider.IO hints, dashboard sync |

## Architecture

```
GuildBeacon/
├── Core/           Bootstrap, EventBus, profiles, modules
├── Modules/
│   ├── Beacon/     Scheduled recruitment messages
│   ├── Inbox/      Incoming whisper capture
│   └── Candidates/ Pipeline + export (future sync bridge)
└── UI/             Slash commands, config panel (WIP)
```

**SavedVariables:** `GuildBeaconDB` (profiles per character).

**Sync (future):** addon cannot call a custom API from WoW. Dashboard + Discord bot will use a companion export (`Store:ExportJSON`) or file bridge.

## Install

Copy `GuildBeacon` into `World of Warcraft/_retail_/Interface/AddOns/` and enable in the AddOns list.

## Commands

- `/gb` or `/guildbeacon`
- `/gb status` - module states
- `/gb beacon start|stop|preview` - recruitment beacon
- `/gb inbox` - inbox message count
- `/gb candidates` - tracked candidates count

## Releases

- [CHANGELOG.md](CHANGELOG.md)
- Patch notes: `docs/patchnotes/`
- Site (planned): https://khalandras.eu/guildbeacon
- Discord: `#guildbeacon-updates` (embed on push to `main`, needs `DISCORD_WEBHOOK_URL` secret)

## License

All rights reserved - Khalandras (adjust when you pick a license).
