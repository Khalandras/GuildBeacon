# GuildBeacon

Standalone World of Warcraft addon for guild officers: recruitment beacon, whisper inbox, and candidate pipeline.

## Quick start

1. Install in `Interface/AddOns/GuildBeacon`
2. `/reload` and enable the addon
3. `/gb dashboard` to open the officer panel
4. `/gb beacon start` to begin scheduled recruitment posts (officer rank required)

## Commands

| Command | Action |
|---|---|
| `/gb` or `/guildbeacon` | Help |
| `/gb dashboard` | Officer dashboard |
| `/gb config` | Settings |
| `/gb beacon start\|stop\|preview\|now` | Recruitment beacon |
| `/gb export` | Export candidates JSON |
| `/gb status` | Module status |

## Features

- **Beacon** - Scheduled posts with template/channel rotation, jitter, anti-spam, instance/combat pause
- **Inbox** - Whisper and guild keyword capture
- **Candidates** - Pipeline statuses, Raider.IO enrichment (optional), local store ready for sync
- **UI** - Dashboard + settings panel (Khalandras gold/bordeaux palette)

## Architecture

```
Core/       Bootstrap, EventBus, profiles, widgets
Modules/    Beacon, Inbox, Candidates
UI/         Dashboard, ConfigPanel, slash commands
```

SavedVariables: `GuildBeaconDB`

Future sync: companion app reads export JSON → khalandras.eu dashboard + Discord bot.

## Releases

- [CHANGELOG.md](CHANGELOG.md)
- Discord : `#patchnotes` (embed à chaque push sur `main`, auteur **GuildBeacon · Addon WoW**, secret `DISCORD_WEBHOOK_URL`)

## License

All rights reserved - Khalandras.
