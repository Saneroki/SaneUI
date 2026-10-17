local ADDON, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat
--  The module's own table (ns in all its files).
--
--  An addon of its own (SaneUI_Combat): it needs Core and nothing else, and is
--  switched on and off in the game's addon list.
--
--  Everything about the fight will be here, each part in files of its own:
--  the unit frames (you, your target, its target, your focus, your pet), the
--  party and the raid, your buffs and debuffs, the nameplates, and what goes
--  with them (cast bars, totems, bosses). The plan is Doc/ideas/Combat.md.
--
--  Nothing is built yet: the module loads and changes nothing, so the game's
--  own frames stay as they are. Each part, once built, falls back to the
--  game's own frame when it fails (Core's StandDown, GiveBack), and only reads
--  what it shows: the game's live unit data, and Core's data framework for
--  anything kept (Doc/ideas/Data.md).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
Core.NewModule(ADDON, "Combat", ns)
