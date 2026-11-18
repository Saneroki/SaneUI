local _, ns = ...
local Macros = ns.Macros

-------------------------------------------------------------------------------
--  Sane UI - Abilities - Macros - Icons
--  The picture window (Saneroki, 2026-11-04): a click on the chosen macro's
--  picture opens Core's icon chooser (Core.Icons: the game's icons by group,
--  searched; Core's since 2026-11-15, for every module) over whatever shows,
--  the full screen too. A click gives the macro that picture and closes the
--  window; Steps' picture takes the macro's own away. A tick at the top
--  (Saneroki, 2026-11-09: "a choice to #showtooltip ... to show the icon of the
--  spell"), on at first: the macro's bar button shows the picture of the step
--  that comes next; off, its picture stays the whole time (Press.FacePicture).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Icons = {}
Macros.Icons = Icons

Icons.WAIT = Core.Icons.WAIT   -- seconds after the last key before a search runs (Spells.lua's too)
Icons.ROW = Core.Icons.ROW     -- a group's line (Spells.lua's too)

-- Opens the window for a macro: given(picture) with the file number clicked, or nil for Steps' picture.
function Icons.Open(which, given)
    if ns.off then return end
    local TEXT = Macros.TEXT
    Core.Icons.Open({
        label = "macros", title = TEXT.iconTitle, chosen = which and which.icon, pick = given,
        chosenWord = TEXT.iconChosen, clickWord = TEXT.iconClick,
        clear = { word = TEXT.iconClear, tip = TEXT.iconClearTip },
        tick = { word = TEXT.iconShow, tip = TEXT.iconShowTip, on = not (which and which.fixed), set = function(on)
            if not which then return end
            which.fixed = not on or nil
            Macros.Face.Paint()
        end },
    })
end

function Icons.Close()
    Core.Icons.Close()
end

function Icons.Shown()
    return Core.Icons.Shown()
end

-- For the test.
function Icons.Frame() return Core.Icons.Frame() end
function Icons.Groups() return Core.Icons.Groups() end
function Icons.Box() return Core.Icons.Box() end
function Icons.Search() return Core.Icons.Search() end
function Icons.GroupLine(index) return Core.Icons.GroupLine(index) end
function Icons.Clear() return Core.Icons.Clear() end
function Icons.Show() return Core.Icons.Tick() end
function Icons.Forget() Core.Icons.Forget() end
