# Sane UI on CurseForge

Each module is a CurseForge project of its own, and so is Core (*SaneUI Core*), which every module's
upload names its required dependency, so the CurseForge app installs Core with any module (Saneroki,
2026-11-15: Navigation first, alone). The pipeline is `dev/tools/release` (`saneui promote`, `makepackage`,
`publish`, `checkcurseforge`); `.claude`'s git rules and `Doc/agent/development.md` say how it works.

| File | The project |
| --- | --- |
| [Core.md](Core.md) | SaneUI Core: name, summary, category, description |
| [Navigation.md](Navigation.md) | SaneUI Navigation (`SaneUI_Navigation`): the same, and its gallery |
| [changelogs/](changelogs/) | Each project's own CurseForge changelog: `Core.md`, `Navigation.md` (a part per version, only that addon's changes) |

The logos and banners are drawn by `saneui makelogos` (`dev/tools/logo-art`) into `assets/generated/logos/`:
one family, the gold ring with its diamond and the dark middle shared, the symbol and a thin ring of the
module's colour its own. `<name>-avatar.png` is the project's avatar, `<name>-banner.png` heads its description.

## Setting it up

1. On authors.curseforge.com, make the project *SaneUI Core* (category Libraries) and the project of each
   module to release (*SaneUI Navigation*), with the summary, description and avatar of its file here.
2. On the module's project, under Relations, add *SaneUI Core* as a Required Dependency (each upload names it
   too).
3. Into `~/.config/saneui/curseforge.json` (only on this computer, readable by its owner alone): the API token
   (authors.curseforge.com, Settings, API Tokens), each project's id, Core's slug, the files' names:
   `{"token": "...", "gameVersions": [...], "projects": {"Core": {"id": ..., "slug": "...", "name": "Sane UI
   Core"}, "Navigation": {"id": ..., "name": "SaneUI Navigation"}}}`.
4. `saneui checkcurseforge`: the token tried, CurseForge's game versions listed (put Forever's into
   `gameVersions`), what is still missing said. Nothing is uploaded.
5. The players' words for each upload into that project's own CurseForge changelog,
   [changelogs/](changelogs/)`<Module>.md` (`Core.md`, `Navigation.md`): a part `## <version> (<date>)` per
   version, newest first, only that addon's changes, uploaded as the file's changelog (Markdown), committed.
   `saneui makechangelog alpha Navigation` drafts the missing parts from the commits that changed each addon
   since its last upload; rewrite them for players and delete their `DRAFT:` line (publish refuses a draft).
   `Doc/changelog.txt` stays the whole suite's changelog (GitHub's readers); CurseForge never gets it.
6. `saneui publish alpha Navigation --dry`, then without `--dry`: Core first, then Navigation, each tagged
   `published/<Module>/<version>-alpha`. Push the tags with main.

## CurseForge's moderation policies

From CurseForge's support article *Moderation Policies* (read 2026-11-15; it has no section of its own for
World of Warcraft, so its general rules apply), and how Sane UI meets them:

| Rule | How |
| --- | --- |
| A name in English, functional, without the game's name or a version | *SaneUI Core*, *SaneUI Navigation*; versions only in the files' names |
| A summary: a short TL;DR, about one sentence, not copied from the description | the *Summary* of each file here |
| A clear description of what it adds or changes, English first | the *Description* of each file here: what each part does, how to use it |
| An avatar of 400 x 400, not one colour, no copyrighted imagery, not WebP | `<name>-avatar.png`, a PNG drawn by `dev/tools/logo-art` from shapes and Noto Serif Display (SIL Open Font License): none of the game's art or fonts |
| Every file with a changelog of what changed since the one before | `publish` refuses a file without its part in its project's own changelog (`changelogs/<Module>.md`), a part with a heading only, and a draft; `makechangelog` drafts a part from the commits since the addon's last upload, a person rewrites it |
| No re-uploads without changes, nothing uploaded only to be seen | `publish` uploads only what is not on CurseForge at that channel or higher: Core only when its code changed. The same code up a channel (an alpha made beta) goes again only as that, its changelog saying so first ("Unchanged since 0.4.0 (alpha), now beta.") |
| No external download links | none: the files are on CurseForge, the descriptions link only to GitHub's issues and the Discord server |
| Several similar projects merged into one (variants) | each module does something else; Core is the library they share |
| Copyrighted content only with leave, credited | the logos are our own. Point for Saneroki: Navigation ships textures made from the game's own map art (the terrain overview, the zone outlines, the stitched zone maps, the sea's waves) |
| AI-made showcase images marked as such | the gallery holds real screenshots only (Navigation.md) |
| Follow the game's terms (Blizzard's UI add-on policy) | free, plain Lua (nothing hidden or minified), no ads, no in-game donation asks |
| A way for players to give feedback (recommended) | GitHub issues and the Discord server in each description |
| A rejected file or project is fixed in place, never deleted and uploaded again | in place: a new version through `publish` |
