local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Spellbook
--  What a spellbook shows beyond the game's own spells, between the module that
--  knows it and the one whose book shows it (Saneroki, 2026-11-06: Abilities'
--  spells still to learn, its weapon skills, its Home page and its reservations
--  in Combat's spellbook on the full screen), so neither needs the other. The
--  module that knows them serves an offer; the book lays its entries out among
--  its own and is told when they changed. Nobody serving: the book shows the
--  game's spells alone.
--
--      Core.Spellbook.Serve(module, offer)  one offer (a later one replaces it), there while the module stands
--      Core.Spellbook.Offer()               that offer, or nil (nobody serves, or its module stood down)
--      Core.Spellbook.Changed()             what it shows changed: the books told on the next frame
--      Core.Spellbook.Watch(fn)             fn() whenever it changed (a book that shows it)
--
--  The offer, each part optional:
--      Spells(line, showRanks)        the entries still to learn of a tab (its skill line's index), after the tab's own
--      Sections(line, lines, hidePassives, showRanks)
--                                     sections of their own under them: { { text = heading, entries = { ... } }, ... };
--                                     lines: the player's skill lines in the book's order
--      Search(words, lines, showRanks)  what a search finds (words in lower case), each in its tab: { [line] = entries }
--      Make(parent) -> frame          an entry of the offer's own, a frame with its look, tooltip, drag and clicks
--      Set(frame, entry, width)       that frame drawn for one of the entries above, so wide
--      Home = { icon, name, tip, First() -> whether the book opens on it, Surface(parent, Header) -> surface,
--               Draw(surface, left, right) }
--                                     a page of its own behind a tab of its own in front of the book's: Surface once
--                                     per book, on a frame the book shows only while Home is chosen (Header(parent)
--                                     makes a heading in that book's look); Draw it on the book's two pages (right
--                                     nil: one page shown)
--      Menu(root)                     its lines in the book's settings menu (the game's menu description)
--      Switch = { text, tip, On(), Set(on) }   one switch of its own beside the book's page controls
-------------------------------------------------------------------------------
local Spellbook = {}
Core.Spellbook = Spellbook

local owner, offer
local watchers = {}

function Spellbook.Serve(module, served)
    owner, offer = module, served
    Spellbook.Changed()
end

function Spellbook.Offer()
    if not offer or (owner and owner.off) then return nil end
    return offer
end

function Spellbook.Watch(fn) watchers[#watchers + 1] = fn end

local function Tell()
    for _, fn in ipairs(watchers) do Core.Safe("spellbook", fn) end
end
Spellbook.Changed = Core.Later(Tell, nil, "spellbook")
