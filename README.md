# Enchanting Atlas — WoW Forever

A community-created World of Warcraft Forever addon for browsing enchanting recipes and their reported acquisition sources.

## Features
- Search the included enchanting recipe catalog
- Filter recipes and mark favorites
- Automatically detect known recipes when the Enchanting tradeskill window is opened (where supported)
- View reported sources and confidence labels

## Install
1. Download this repository as a ZIP or download a release.
2. Copy the `EnchantingAtlas` folder into your WoW Forever `Interface/AddOns` directory.
3. Reload the UI and type `/ea` or `/enchantatlas`.

## Data quality
This repository currently includes the **0.2.2 research catalog**, not a fully verified database. The catalog has approximately 260 entries, some of which may require reconciliation with the current game client. Sources and drop rates may be missing or incorrect. Confidence labels are not a guarantee of in-game verification.

## Sources and attribution
The included 0.2.2 dataset cites published guides from [Zockify](https://www.zockify.com/forever/professions/enchanting/recipes/) and [Playfulls](https://playfulls.com/professions/enchanting/recipes). Their content is not included under this repository's code license.

**ForeverDB attribution (planned integration):** [ForeverDB.net](https://foreverdb.net) — prospective source of recipe and acquisition data. **No ForeverDB API export has been integrated into this release.** Before using their data, obtain API authorization and follow their attribution and usage terms. Any future UI that displays ForeverDB data should visibly credit ForeverDB as required by their terms.

## Development
The addon is an independent community project, not affiliated with or endorsed by WoW Forever, Blizzard, or the listed data providers.

If you spot an incorrect recipe or source, open an Issue with the recipe name, game build, source NPC/location, and a screenshot or other evidence.

## License
The original addon code and repository documentation are provided under the MIT License (see `LICENSE`). Third-party game data, names, trademarks, and sourced facts are not relicensed by this notice.
