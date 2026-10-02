# Shipping Kingjump

## Builds
Export presets for Windows, macOS, Linux, iOS and Android are in `export_presets.cfg`.
1. In Godot: Editor > Manage Export Templates > Download (4.3).
2. Project > Export, pick a preset, Export Project.
- iOS needs a Mac with Xcode and an Apple Developer account ($99/yr); fill `app_store_team_id` in the iOS preset.
- Android needs the Android SDK + a keystore for release (Editor Settings > Export > Android).

## Steam
1. Steamworks partner account + Steam Direct fee ($100 per game, recouped after $1,000 gross).
2. Install GodotSteam (GDExtension) from the Asset Library into `addons/godotsteam`. `scripts/steam.gd` activates automatically when it is present.
3. Create achievements in Steamworks with API names `ACH_<ID>` for every unlock in `scripts/profile.gd` (e.g. ACH_HATTRICK, ACH_ECHO, ACH_ARMY_MERCHANT) plus `ACH_WIN`.
4. Add `steam_appid.txt` with the app id next to the executable for local testing only.

## Before release (owner decisions)
- Final game name check (Steam/App Store search, trademark).
- Price (suggestion: $4.99 to $6.99 on Steam; premium $2.99 to $4.99 on iOS, no ads).
- Replace placeholder art, procedural sound and the system font with an original art/audio pass.
- Desktop layout: the game is portrait (letterboxed on PC). A landscape PC layout is a likely improvement before Steam launch.
- Store assets: capsule images (header 920x430, small 462x174, main 1232x706, vertical 748x896), 5+ screenshots, a 30-60s trailer.
