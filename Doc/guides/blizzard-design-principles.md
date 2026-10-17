# Blizzard's UI design principles

What Blizzard has said about how it designs the World of Warcraft interface, and what each point means
for Sane UI. Read this before deciding **what** a feature shows and how it behaves.
For how to build it, read [gui-development.md](gui-development.md). For code rules, read
[addon-standards.md](addon-standards.md).

Blizzard has never published one design manifesto. The principles below are collected from talks,
developer posts and announcements between 2006 and 2025 ([sources](#sources)). Where a statement is old,
the date is given. The Blizzard code and art in `references/` stay the ground truth: when this guide and
the reference disagree, the reference wins.

## The principles

### 1. Play the game, not the interface
At BlizzCon 2008 the UI team said they want players "playing the game, not the interface". They avoid
designs that have the player watch bars and graphs. Their built-in threat meter was kept subtle on
purpose: enough to act on, not a spreadsheet.

**For Sane UI:** a feature must take attention away from the UI, not add to it. Ask what the player wants
to *do* and show only what that needs. Numbers and tables belong in a place the player opens on purpose.

### 2. Blend in until needed
The same panel: the best UI is one the player does not notice until they need it, and "a good HUD has to
not be flashy". The interface recedes when idle and draws the eye when something needs attention.

**For Sane UI:** no permanent decoration, glow or motion. Use highlight, pulse or sound only for a change
the player must react to, and stop it once they have seen it.

### 3. Show the most important things, put the rest deeper
Rob Pardo (2006): accessibility starts with the interface, and the HUD shows only the most important
information. Less critical functions sit deeper in the game. Dragonflight (2022) repeated it: a
clutter-free layout that frees screen space, with the key elements (minimap, health bar) made larger.

**For Sane UI:** one clear main thing per window. Secondary options go into a menu, a tooltip or the
options page. If everything is visible, nothing is important.

### 4. Easy to learn, difficult to master
Blizzard's oldest rule. Pardo's order matters: depth first, then make it approachable. A feature has to
be worth using for years, and a new player has to understand it without a manual.

**For Sane UI:** the default must work with no setup. Power features are fine, but they must not be in
the way of the simple use. If a feature needs an explanation to be used at all, redesign it.

### 5. Be consistent with what is already there
In 2008 the team rejected fly-out menus because the default UI had not used them before, and it refused
class-themed skins so the interface is familiar on every character. "Consistency guides all game design,
especially interface work."

**For Sane UI:** use the patterns the client already taught the player: the same window frames, tabs,
buttons, tooltips, sounds and wording. A new pattern needs a strong reason. Look in `references/` for how
Blizzard solved the same problem before inventing something.

### 6. Do not force features in
"Bolted-on additions feel unnatural, and players notice." To add the achievement button Blizzard merged
the lag meter into another icon and shrank the bag icons, instead of adding one more thing on top.

**For Sane UI:** a feature belongs where the player already looks for it (unlearned spells are in the
spellbook, not in a new window). Make room by merging, not by stacking.

### 7. Start simple, iterate, cut decoration
The Death Knight rune frame went from paper cut-outs to mock-ups; the flashy early versions lost to
simpler ones, and a sword background was removed because it was confusing. Pardo: prototype before
building, "make it fun, then make it big", and polish from the start, not at the end.

**For Sane UI:** build the plain version first and try it in the game. Add art only where it explains
something. Remove an element when nobody misses it.

### 8. Show, do not tell
The Shadowlands character creation redesign (2020) cut most text and showed a class by an animation
instead. The team named the danger "analysis paralysis": too much information stalls a simple choice.
They also chose each control by the data it holds (sliders only for opposing extremes, a multi-column
dropdown where options must be compared), reduced five categories to three after testing, hid rarely
needed details by default and removed banners that distracted from the character.

**For Sane UI:** prefer an icon, a state or a preview over a sentence. Few categories. Pick the control
that fits the data. Keep long text for tooltips.

### 9. Modernise, keep the charm
Dragonflight rebuilt the HUD with modern tools while "maintaining the original design's charm and
personality": the action bar was cleaned up but kept its iconic look.

**For Sane UI:** it must look like a part of WoW that Blizzard could have shipped. Use Blizzard's own art
and fonts. Clean, not sterile.

### 10. Let the player arrange it, within limits
2008: given the choice between several fixed styles and letting players customise, Blizzard takes the
second. Edit Mode (2022) made most HUD elements movable, with named layouts. But the default UI stays
safe: customisation happens in clear, bounded places so nobody breaks their interface by accident.

**For Sane UI:** sensible defaults first, then a small number of real options. Every option must have a
default that can be restored. No option that can make the UI unusable.

### 11. Accessibility comes first
Dragonflight called accessibility "at the forefront". Since patch 6.1 the colourblind mode adds words
such as "Rare" to tooltips, because colour alone does not reach everyone. Font and HUD scaling are
client features.

**For Sane UI:** never carry meaning by colour alone: add an icon, a word or a shape. Use the client's
font objects so text scaling and other languages keep working. Do not shrink text below the client's
small font (10), except a caption beside larger text, and never below 8 (Tooltips' `least`). Keep click
targets as large as Blizzard's.

### 12. Addons present, they do not decide
Midnight (2025): addons "should no longer offer a competitive advantage in WoW combat". They stay
welcome for how the game looks and how information is laid out. Blizzard's own answer to missing
features is to build them into the base UI. Combat data can be shown by an addon but not computed with
(see *secret values* in [addon-standards.md](addon-standards.md)).

**For Sane UI:** improve presentation, comfort and clarity. Never tell the player what to press in
combat, and never automate a decision. If a feature needs hidden combat data, it is the wrong feature.

### 13. It must feel right, on every machine
Pardo: small input delays make players leave without knowing why. The add-on policy forbids addons that
slow the frame rate. The housing team (2025) named performance on "a ton of different machines" a first
concern.

**For Sane UI:** a window opens at once, a click answers at once. Nothing may cost frames in combat.
See the performance rules in [addon-standards.md](addon-standards.md).

## Checklist for a new feature

1. Does it help the player play, or does it make them watch the UI? (1)
2. Is it quiet when nothing happens? (2)
3. What is the one main thing, and where did the rest go? (3)
4. Does it work with no setup, and can a new player understand it? (4)
5. Is there a Blizzard window that solves the same problem? Does ours behave like it? (5)
6. Does it live where the player already looks? (6)
7. Was the plain version tried first? Can any element be removed? (7)
8. Can an icon or a state replace text? Are there few categories? (8)
9. Would it pass as Blizzard's own? (9)
10. Does every option have a default that can be restored? (10)
11. Does it still read without colour, and with larger text? (11)
12. Does it only present, never decide? (12)
13. Is it instant, and free in combat? (13)

## Sources

| Source | Year | Used for |
| --- | --- | --- |
| [Rob Pardo, Austin Game Conference keynote (Game Developer)](https://www.gamedeveloper.com/pc/agc-blizzard-s-pardo-on-i-wow-i-s-success) | 2006 | 3, 4, 7, 13 |
| [BlizzCon UI panel recap (Engadget)](https://www.engadget.com/2008-10-24-the-creamy-gui-center-blizzcon-ui-wrapup-commentary-and-analysi.html) | 2008 | 1, 2, 5, 6, 7, 10 |
| [Shadowlands: An Inside Look at the Character Creation UI Redesign, Jeff Liu (mirror)](https://warcraft-secrets.com/news/shadowlands-an-inside-look-at-the-character-creation-ui-redesign) | 2020 | 8 |
| [Dragonflight HUD and UI Revamp (Blizzard)](https://news.blizzard.com/en-us/article/23841481/world-of-warcraft-dragonflight-hud-and-ui-revamp) | 2022 | 3, 9, 10, 11 |
| [Combat Philosophy and Addon Disarmament in Midnight (Blizzard)](https://news.blizzard.com/en-us/article/24246290/combat-philosophy-and-addon-disarmament-in-midnight) | 2025 | 12 |
| [UI Add-On Development Policy (Blizzard)](https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534) | 2009 | 13 |
| [New Colorblind Support in Patch 6.1 (Blizzard)](https://worldofwarcraft.blizzard.com/news/17964863) | 2015 | 11 (read as a search summary only) |
| [Housing interview with the design lead (inkl / GamesRadar+)](https://www.inkl.com/news/world-of-warcraft-design-lead-says-the-upcoming-housing-feature-is-a-challenge-for-performance-and-accessibility-because-it-s-not-anything-like-existing-zones-and-the-kinds-of-content-that-we-ve-had-before) | 2025 | 13 (read as a search summary only) |

The two oldest sources are reports of talks, not Blizzard's own text. The *For Sane UI* lines are our
reading, not Blizzard's words.
