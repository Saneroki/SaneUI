# Leveling

The plan for Sane UI's own leveling routes: a tool that computes the fastest way from level 1 to 60
from Core's data, and the guide that leads the player along it. Nothing is built yet (2026-10-18); this
page prepares the work. How the guide is shown (the step, the waypoint, the item button) is Navigation's
plan (`Doc/ideas/Navigation.md`, *Leveling guide*); the guides are the set *Guides*
(`assets/data/Guides/schema.toml`).

**Decision (Saneroki, 2026-10-18):** the routes are our own, computed by our tool from our data, and good
enough to stand beside the best hand-made leveling guides. They are not written by hand step by step, and
not copied from any guide.

**Decision (Saneroki, 2026-10-25):** a module of its own, *Speed Leveling* (`SaneUI_SpeedLeveling`), with one key
for questing, pressed again and again: it loots the corpse beside you, finds what your quests and your leveling
guide want around you, marks it with a skull, and attacks it or talks to it. Its targets come from the quest log
(Core's data) and from the step at hand of the guide being followed; our own routes are a further source once they
are there. Nothing happens without a key press: an addon may target, mark, attack and interact only by the game's
secure ways, and looting a corpse needs the player's press.

**Decision (Saneroki, 2026-10-25), superseding the known-addon dependency:** Speed Leveling is independent of any
other addon at runtime. It runs leveling guides itself: the guides you paste as text, and the guides you bought,
opened for your own account from their import string (`Unlock.lua`; the string is locked to the buyer's account and
Sane UI opens it only for the account played). Of the leveling guide Sane UI knows it reads only the words of its
text format and the recipe its bought guides are locked by (`Core.Neighbours.Format`, `Core.Neighbours.Lock`,
copies), and nothing of the addon is called at runtime. The intended setup has no other leveling addon installed.

## Where it stands (2026-10-25)

- **Built: the questing key** (`src/SpeedLeveling/README.md`). A secure state driver picks loot, pick up, fight,
  talk, hearth or find at each press; the macro of Find targets the first wanted name around you. Its lists: the
  guide's step, the quests' open objectives (kill, then the likeliest droppers of an item to loot), creatures the
  game marks for a quest, the NPCs to hand finished quests in to; the quest objects beside you by ID.
- **Decision (Saneroki, 2026-10-30):** Speed Leveling sets Loot to take everything and answers the game's questions
  on equipping and destroying, by default; the key walks to corpses around you; a talk that is done closes and the
  key leaves that NPC alone. Selling junk and repairing are Inventory's (checkboxes in the bag). Same day: Always show
  upgrades stays (he wants to see an upgrade, the rest is taken); only the guide's quests are taken, all of them at one
  NPC; the reward chosen: the biggest upgrade, else the guide's, else the highest vendor or auction house value; new
  upgrades put on (Speed Leveling's switch, not Inventory's: a thing for leveling, by item level alone).
- **Decision (Saneroki, 2026-10-25):** the key only opens a corpse's loot, as a right click does; how and what is
  looted is the Loot module's (board card 34; built 2026-10-28, `src/Loot/README.md`). Quest items, the hearth and things of the world that cannot be
  targeted are the key's too: things your quests want are picked up beside you (the interact key's soft target), the
  hearth when the guide's step says so, and one quest item when nothing wanted is around.
- **Decision (Saneroki, 2026-10-25): the guide over the world, in Speed Leveling.** Its steps over the world, no
  window: the zone, how far, the steps at hand, the next steps fading; a click skips, a right click goes back. Its
  steps come from a guide run by our own engine (`Format.lua`, `Lines.lua`, `Run.lua`): guides you paste as text, and
  the guides you bought, opened for your own account (`Unlock.lua`). Our own routes, once there, are a further source.
- **Built: the guide over the world** (`src/SpeedLeveling/README.md`): the view, the guides kept and their window,
  the engine that runs a guide, the import string of bought guides opened for the account (checked offline against
  the real paid guide: 191 guides, 15,129 steps for a Horde character, all read and run with no error).
- **Decision (Saneroki, 2026-10-25), the same day:** the arrow to the step's place in the far herbs' leather ring
  with its point; the view's words in Expressway; the next steps greyed out. Built.
- **Decision (Saneroki, 2026-10-25), then:** the arrow a part of its own, placed in Edit Mode; in its hole a picture
  of what to do there (talk, kill, loot, use, ...); under it what to do, the yards and the time to get there; the
  targets and items as clean icons only over the guide's top, our own secure buttons. Built.
- **Decision (Saneroki, 2026-10-25), the rebuild:** Speed Leveling made independent of any other addon and able to
  import and open the paid guides itself (`Unlock.lua`); the key's order loot → talk → pick up → fight → find to
  match the game's own interact button; quest givers take and hand in the guide's quests (`Quests.lua`; Shift seen in a talk makes the rest of it the player's); what is
  found ordered nearest first by the zone you are in (the set *Spawns*); a quest Core lacks found by the game's own
  objective words; Find's macro chained for the 255-character limit. Built.
- **Built (Saneroki, 2026-10-25, board #163):** the key walks you to the NPC found (the game's Click-to-Move, lent
  only while such an NPC is your target) and uses a step's item on your target where the step's words say it is for
  that one (a corpse, or the creature or NPC they name), out of a fight. The game lets no addon walk to a map place.
- **Decision (Saneroki, 2026-10-26): the guides that come for each game, chosen by a right click.** The guides
  that come for each game are there from the start, in a guide pack per game (*Guides: Forever*, *Guides: Retail*,
  made apart from the code and put into the game; no guide's text in the repository); a right click on the guide's
  zone lists the guides for the character by group; the guide on, paused or off, also from the minimap's satchel
  (Core's quick switches, `Core.Offer`). Built.
- **Decision (Saneroki, 2026-10-29): gathering for the next zone.** Before the guide goes on to a harder zone, a
  warning while your Herbalism or Mining is lower than that zone asks, worked out from Core's herbs, ore and their
  spawns (half of a zone's spawns gathered). Built. Skinning is not looked at yet.
- **Not yet:** the routes and their planner (below), the guide's way on the map (board #158).

## What has to exist first

| Needed | Where | State (2026-10-18) |
| --- | --- | --- |
| Quests: givers, takers, objectives, levels, requirements, chains, breadcrumbs, rewards (XP, money) | set *Quests* (`Doc/ideas/Data.md`, *Quests*) | 4,796 quests in the master; objectives and XP to complete |
| Where objectives are done | sets *Spawns*, *QuestAreas*, *Drops*, *Objects* | schemas only |
| Creatures: level, elite, spawn density, respawn | sets *NPCs*, *CreatureSpawns* | partly |
| Getting around: walking times, flights, boats, hearthstone | sets *Walking*, *Travel* | schemas only |
| Class and race facts: trainers, class quests, starting areas | sets *Trainers*, *Zones* | partly |
| The game's XP rules: XP per kill by level difference, quest XP falling off by level, rested XP | Blizzard's code and the game | to gather |
| The character's state: level, completed quests, log, bags | Core's *Characters* | planned |
| The window and the waypoint | Navigation | planned |

The planner can only be as good as the quest and travel data: those come first.

## The planner (a tool, `dev/tools/route`)

The route is computed once, at build time, and shipped as data. The game only follows it.

1. **The quest graph.** Every quest of a side becomes a node with its giver's place, its objectives' places,
   its taker's place, its level band, its XP and what it needs first. Chains and breadcrumbs are edges.
2. **The cost of a quest.** Time to walk to it and through its objectives (from *Walking* and the spawn
   density of what is to be killed or looted), plus fight time from the level difference, against the XP it
   gives (with the kills on the way counted in). A quest is worth it when its XP per minute beats grinding
   at that level.
3. **Grouping.** Quests whose objectives lie together are done together: accept all in a hub, do the
   objectives in one loop, hand in all at once. A loop is a travelling-salesman problem over a few dozen
   points; a near-best solution (nearest neighbour, then 2-opt) is plenty.
4. **The order of hubs.** From hub to hub by level: the next hub is the one with the best XP per minute
   including the way there (flights, boats, hearthstone). The character's level at each point is followed,
   so a quest is not taken before it is offered and is left out once it gives too little.
5. **Leaving out.** Elite and group quests, escorts that fail often, long walks for little XP: off by
   default, a switch each (open: dungeons in the way).
6. **Output.** One guide per leg in the set *Guides*: places, actions, checks. Step texts are written by
   Navigation from the facts.

The tool reports per leg: the expected time, XP from quests against kills, quests left out and why. These
figures are how one route is compared with another.

## Measuring it

- **A simulator in the tool:** walks the route with a model character (walking speed, kill time by level
  difference, rested XP) and gives the time per level. Every change to the planner is measured against it.
- **The game's answer:** Core's data framework learns from play (time per step, where players stray, steps
  skipped). Those figures tune the simulator's numbers and show which steps are slow.
- **The target:** a time from 1 to 60 per side, set once the simulator runs, and lowered from there.

## Beyond a fixed route

What a computed route can do that a written one cannot:

- **Start anywhere:** the planner runs again from the character's level, place and completed quests (a
  small version in the game, or a set of precomputed entry points per level band).
- **Per class and race:** class quests and starting areas are placed where they cost least.
- **Fit the player:** dungeons in or out, professions on the way, group or alone.
- **After a patch:** the route is computed again from the changed data, not rewritten by hand.

## Order of work

1. Quest data complete: objectives, XP, requirements, levels (Data-build).
2. Places: spawns, quest areas, drops.
3. Travel: walking times, flights, boats.
4. The planner and its simulator for one starting area; compare with the time a good player needs.
5. All legs of one side to 60, then the other side.
6. Navigation's guide view follows the shipped routes (Navigation, build step 7).
7. Learned figures from play feed the simulator.

## Open questions

1. **Planner in the game too?** Only precomputed routes, or a small planner at login for a character that
   is off the route. *Proposal:* precomputed entry points every few levels first.
2. **Grinding steps:** where no quest is worth it, the route says where to kill and to which XP.
   *Proposal:* yes, from spawn density and creature level.
3. **One route or several** (fast, relaxed, with dungeons). *Proposal:* one route with switches.
