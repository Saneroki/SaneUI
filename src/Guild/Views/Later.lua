local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Guild - Views - Later
--  A view still to come (Doc/ideas/Guild.md, *Build order*): its tab is there
--  so the window has its whole shape, and it says what it will hold.
-------------------------------------------------------------------------------
local Views, Kit, TEXT = ns.Views, ns.Kit, ns.TEXT
local made = {}

function Views.Later(name)
    if made[name] then return made[name] end
    local view = {}
    function view.Build(frame)
        local inset = Kit.Inset(frame)
        inset:SetAllPoints()
        local text = Kit.Empty(inset, "GameFontDisableLarge")
        text:SetText(TEXT.later:format(name))
    end
    made[name] = view
    return view
end
