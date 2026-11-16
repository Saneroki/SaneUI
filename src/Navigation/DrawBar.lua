local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - DrawBar
--  The button and the palette of drawing and planning on the map (Saneroki, 2026-11-15: "I want a button somwhere
--  that helps me to activate menues and helpers to drop pins and draw on the map and save those drawings and map
--  pins together so they can be shared or grouped together"):
--
--      Sketches     the dropdown on the full map's bar (TopBar.lua; Saneroki, 2026-11-15: "The penciel icon should
--                   be replaced with a dropdown menu. When it is not active it says Sketches and when you click it
--                   it shows all the sketches with a checkbox in front that toggle if the sketch is shown and the
--                   fold out to see more options for those sketches"): it says Sketches, and while you draw the
--                   sketch you draw in; its menu every sketch with its checkbox (shown or hidden) and its own menu
--                   folding out (Draw in it, Rename, Share, Delete), then Draw on the map (the palette open or
--                   closed) and New sketch
--      the palette  a small window in the kit's bronze under the bar at its right, dragged by its head:
--                     the tools: marker, pen, line, arrow, circle, eraser (Draw.lua), the one on lit; a click on the
--                     one on puts it away (the map's mouse its own again)
--                     the colours and the two widths
--                     the plan: a dropdown of every plan (the active one ticked), each with its own menu: shown,
--                     rename, share with your party or raid or your guild, delete; and New plan (Plans.lua)
--                     Undo (the active plan's newest drawing) and Clear (its drawings on the map shown, asked first)
--                   closed (its X, Esc, the map going small) every tool is put away
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Look = Core.Look
local DrawBar = {}
ns.DrawBar = DrawBar

DrawBar.WIDTH_MENU = 130 -- the bar's dropdown Sketches
DrawBar.TOOL = 32        -- a tool's square
DrawBar.SWATCH = 22      -- a colour's
DrawBar.GAP = 4
DrawBar.WIDTH = 8 * (32 + 4) - 4 + 2 * Look.INSIDE -- the palette: eight tools in a row
-- What players read calls a plan a sketch (Saneroki, 2026-11-15: "I don't like the word "plan" in front of each drawing";
-- he chose Sketch); the code keeps plan (Plans.lua).
DrawBar.TEXT = {
    button = "Draw",
    sketches = "Sketches",
    drawing = "Drawing: %s",
    drawOn = "Draw on the map",
    drawIn = "Draw in it",
    buttonTip = "Markers and drawings of your own on the map and on dungeon maps, grouped in sketches you can show, hide and share. While a tool is on the left button draws and a right-drag moves the map. Alt and a click puts a marker at any time.",
    title = "Draw",
    tools = {
        marker = { "Marker", "A click: a marker there, its card open to write in." },
        pen = { "Pen", "Drag: a line as the mouse goes." },
        line = { "Line", "Drag: a straight line from where you begin to where you let go." },
        arrow = { "Arrow", "Drag: an arrow pointing where you let go." },
        circle = { "Circle", "Drag: a circle round where you begin, as wide as you drag." },
        route = { "Route", "Clicks: a numbered stop at each, a line between them. Choose the tool again for a new route." },
        text = { "Text", "A click: words on the map there." },
        erase = { "Eraser", "A click on a drawing or words: away. With any other tool, drag what is on the map to move it." },
    },
    thin = "Thin", thick = "Thick",
    plan = "Sketch: %s",
    shown = "Shown",
    rename = "Rename...",
    renameAsk = "The sketch's new name:",
    share = "Share",
    shareParty = "Party", shareRaid = "Raid", shareGuild = "Guild", shareSomeone = "Someone...",
    shareTip = "To your party or raid, to your guild, or to someone you name: they are asked whether to keep it.",
    shareWith = "Share the sketch %s with someone",
    shared = "The sketch %s sent to your %s (%d %s).",
    sharedTo = "The sketch %s sent to %s (%d %s).",
    part = "part", parts = "parts",
    tooLarge = "The sketch %s is too large to share: split it into smaller sketches.",
    delete = "Delete...",
    deleteAsk = "Delete the sketch %s with all its markers and drawings?",
    new = "New sketch...",
    newAsk = "The new sketch's name:",
    paste = "Paste from %s...",
    pasteAsk = "Paste a drawing copied from %s (its Export, or its Backup for all of them):",
    pasteAccept = "Keep",
    pasteTip = "A drawing copied from %s's dungeon maps or world map becomes a sketch of yours, on the same place of our maps. Its players get the sketches you share too, and you get theirs.",
    undo = "Undo",
    clear = "Clear",
    clearAsk = "Clear the drawings of %s on this map?",
    clearWhere = "Zoom in onto a zone, or open a dungeon's map, to clear its drawings.",
    from = "from %s",
}

local button, palette, tools, swatches, widths, planMenu

-------------------------------------------------------------------------------
--  Glyphs
-------------------------------------------------------------------------------
-- A tool's picture drawn of the game's lines on its square (white, as the drawings): points from its middle.
local GLYPHS = {
    pen = { { -9, -5, -4, 4 }, { -4, 4, 1, -3 }, { 1, -3, 5, 4 }, { 5, 4, 9, -1 } },
    line = { { -9, -9, 9, 9 } },
    arrow = { { -9, -9, 9, 9 }, { 9, 9, 2, 9 }, { 9, 9, 9, 2 } },
    erase = { { -7, -7, 7, 7 }, { -7, 7, 7, -7 } },
    route = { { -9, -6, -2, 5 }, { -2, 5, 3, -3 }, { 3, -3, 9, 6 } },
    text = { { -7, 8, 7, 8 }, { 0, 8, 0, -8 }, { -3, -8, 3, -8 } },
}
local function Glyph(square, key)
    if key == "marker" then
        local star = square:CreateTexture(nil, "ARTWORK")
        star:SetSize(DrawBar.TOOL - 12, DrawBar.TOOL - 12)
        star:SetPoint("CENTER")
        star:SetTexture(ns.Markers.ICONS[1].texture)
        return
    end
    local segments = GLYPHS[key]
    if key == "circle" then
        segments = {}
        for side = 0, 15 do
            local a, b = side * math.pi / 8, (side + 1) * math.pi / 8
            segments[#segments + 1] = { 8 * math.cos(a), 8 * math.sin(a), 8 * math.cos(b), 8 * math.sin(b) }
        end
    end
    for _, seg in ipairs(segments or {}) do
        local line = square:CreateLine(nil, "ARTWORK")
        line:SetTexture(ns.Draw.WHITE)
        line:SetThickness(2)
        line:SetVertexColor(key == "erase" and 1 or 1, key == "erase" and 0.5 or 1, key == "erase" and 0.5 or 1, 1)
        line:SetStartPoint("CENTER", square, seg[1], seg[2])
        line:SetEndPoint("CENTER", square, seg[3], seg[4])
    end
end

-------------------------------------------------------------------------------
--  The plan's menu
-------------------------------------------------------------------------------
-- Your raid or party (a group the game's group finder made too), as Markers.Group says.
local function Group()
    return ns.Markers.Group()
end

local function Shared(plan, count, word, someone)
    if count == 0 then
        return ns.Print(DrawBar.TEXT.tooLarge:format(plan.name or ""))
    end
    ns.Print((someone and DrawBar.TEXT.sharedTo or DrawBar.TEXT.shared):format(plan.name or "", word, count,
        count == 1 and DrawBar.TEXT.part or DrawBar.TEXT.parts))
end

-- A plan's Share (Saneroki, 2026-11-15: "Share option should have the party, guild and someone options"): Party (or
-- Raid, in one), Guild (each greyed outside one), Someone: the player asked for (Core.AskPlayer: the game's search of
-- the players it knows as the name is typed), the plan sent to them alone.
local function ShareMenu(item, plan)
    local Plans = ns.Plans
    local share = item:CreateButton(DrawBar.TEXT.share)
    local channel, word = Group()
    local raid = word == ns.Markers.TEXT.raid
    local group = share:CreateButton(raid and DrawBar.TEXT.shareRaid or DrawBar.TEXT.shareParty,
        ns.Guard(function() Shared(plan, Plans.Share(plan, channel), word) end))
    if not channel and group.SetEnabled then group:SetEnabled(false) end
    local guild = Core.Ask(rawget(_G, "IsInGuild")) and "GUILD" or nil
    local toGuild = share:CreateButton(DrawBar.TEXT.shareGuild,
        ns.Guard(function() Shared(plan, Plans.Share(plan, guild), ns.Markers.TEXT.guild) end))
    if not guild and toGuild.SetEnabled then toGuild:SetEnabled(false) end
    share:CreateButton(DrawBar.TEXT.shareSomeone, ns.Guard(function()
        Core.AskPlayer(DrawBar.TEXT.shareWith:format(plan.name or ""), ns.Guard(function(name)
            Shared(plan, Plans.Share(plan, "WHISPER", name), name, true)
        end))
    end))
    return share
end
DrawBar.ShareMenu = ShareMenu

-- A sketch's name in the menus: from whom it came, where it came from someone.
local function Named(plan)
    local name = plan.name or "?"
    if plan.from then name = name .. " (" .. DrawBar.TEXT.from:format(plan.from) .. ")" end
    return name
end

-- A sketch's own options, under it in a menu: Rename, Share, Delete.
local function Options(item, plan)
    local Plans = ns.Plans
    item:CreateButton(DrawBar.TEXT.rename, ns.Guard(function()
        Core.AskText(DrawBar.TEXT.renameAsk, nil, nil, plan.name, ns.Guard(function(text) Plans.Rename(plan, text) end), 60)
    end))
    ShareMenu(item, plan)
    item:CreateButton(DrawBar.TEXT.delete, ns.Guard(function()
        Core.Confirm(DrawBar.TEXT.deleteAsk, plan.name or "", ns.Guard(function() Plans.Remove(plan) end))
    end))
end

-- A drawing pasted from the dungeon map addon Sane UI knows (Exchange.lua: its Export or Backup, copied): each
-- of its drawings kept as a sketch, what lies on maps we have no match for said.
local function Pasted(text)
    local Exchange = ns.Exchange
    local title = Exchange.words.title
    local kept, left = Exchange.Paste(text)
    if not kept then
        return ns.Print((left == "damaged" and Exchange.TEXT.damaged or Exchange.TEXT.format):format(title))
    end
    local names = {}
    for _, plan in ipairs(kept) do names[#names + 1] = plan.name or "?" end
    if #names > 0 then ns.Print(Exchange.TEXT.kept:format(title, table.concat(names, ", "))) end
    if left > 0 then ns.Print(Exchange.TEXT.left:format(left)) end
    if #names == 0 and left == 0 then ns.Print(Exchange.TEXT.nothing) end
end

local function NewSketch(root)
    root:CreateButton(DrawBar.TEXT.new, ns.Guard(function()
        Core.AskText(DrawBar.TEXT.newAsk, nil, nil, "", ns.Guard(function(text) ns.Plans.New(text) end), 60)
    end))
    local Exchange = ns.Exchange
    if Exchange and Exchange.on then
        local paste = root:CreateButton(DrawBar.TEXT.paste:format(Exchange.words.title), ns.Guard(function()
            Core.AskText(DrawBar.TEXT.pasteAsk, Exchange.words.title, DrawBar.TEXT.pasteAccept, "", ns.Guard(Pasted), 0)
        end))
        if paste.SetTooltip then
            paste:SetTooltip(ns.Guard(function(tooltip)
                tooltip:SetText(DrawBar.TEXT.paste:format(Exchange.words.title))
                tooltip:AddLine(DrawBar.TEXT.pasteTip:format(Exchange.words.title), 1, 1, 1, true)
            end))
        end
    end
end
DrawBar.Pasted = Pasted

-- The palette's dropdown: each sketch a radio (the one drawn in), its own menu under it; then a new one.
local function PlanMenu(_, root)
    local Plans = ns.Plans
    for _, plan in ipairs(Plans.List()) do
        local item = root:CreateRadio(Named(plan), ns.Guard(function() return Plans.Active() == plan end),
            ns.Guard(function() Plans.SetActive(plan) end))
        item:CreateCheckbox(DrawBar.TEXT.shown, ns.Guard(function() return plan.shown ~= false end),
            ns.Guard(function() Plans.Show(plan, plan.shown == false) end))
        Options(item, plan)
    end
    root:CreateDivider()
    NewSketch(root)
end

-- The bar's dropdown Sketches: each sketch with its checkbox (shown or hidden) and its own menu folding out (Draw in
-- it: the one drawn in, the palette open; Rename, Share, Delete); then Draw on the map (the palette open or closed)
-- and New sketch.
local function SketchesMenu(_, root)
    local Plans = ns.Plans
    for _, plan in ipairs(Plans.List()) do
        local item = root:CreateCheckbox(Named(plan), ns.Guard(function() return plan.shown ~= false end),
            ns.Guard(function() Plans.Show(plan, plan.shown == false) end))
        item:CreateButton(DrawBar.TEXT.drawIn, ns.Guard(function()
            Plans.SetActive(plan)
            DrawBar.Open()
        end))
        Options(item, plan)
    end
    root:CreateDivider()
    root:CreateCheckbox(DrawBar.TEXT.drawOn, ns.Guard(function() return palette ~= nil and palette:IsShown() end),
        ns.Guard(function() DrawBar.Toggle() end))
    NewSketch(root)
end

-------------------------------------------------------------------------------
--  The palette
-------------------------------------------------------------------------------
-- The map whose drawings Clear takes: the dungeon's floor shown, else the zone in the view's middle.
local function Here()
    local floor = ns.Dungeons.Shown()
    if floor then return floor end
    local view = ns.Canvas.view
    return view and view.zone
end

local function Clear()
    local map = Here()
    if not map then return UIErrorsFrame:AddMessage(DrawBar.TEXT.clearWhere, 1, 0.1, 0.1) end
    local plan = ns.Plans.Active()
    Core.Confirm(DrawBar.TEXT.clearAsk, plan.name or "", ns.Guard(function() ns.Plans.Clear(map) end))
end

local function Square(parent, size, title, tip, click)
    local square = Look.Square(parent, size)
    square:SetScript("OnClick", ns.Guard(click))
    Core.Tip(square, title, tip, "ANCHOR_BOTTOM")
    square.box = Look.Outline(square, "OVERLAY")
    for _, line in ipairs(square.box.lines) do line:SetAlpha(0) end
    square.box.fill:SetAlpha(0)
    return square
end

-- A square lit (its golden outline strong) or not.
local function Lit(square, on)
    for _, line in ipairs(square.box.lines) do line:SetAlpha(on and 1 or 0) end
    if on then square:LockHighlight() else square:UnlockHighlight() end
end

local function Build()
    if palette then return palette end
    local canvas = ns.Canvas.frame
    palette = CreateFrame("Frame", nil, canvas and canvas:GetParent() or UIParent)
    palette:SetWidth(DrawBar.WIDTH)
    palette:SetFrameStrata("DIALOG")
    palette:SetToplevel(true)
    palette:SetClampedToScreen(true)
    palette:EnableMouse(true)
    palette:SetMovable(true)
    local bar = ns.TopBar
    palette:SetPoint("TOPRIGHT", canvas or UIParent, "TOPRIGHT", -bar.INSET, -(bar.Top() + bar.INSET))
    local look = Look.Dress(palette, DrawBar.TEXT.title)
    look.close:SetScript("OnClick", ns.Guard(DrawBar.Close))
    look.head:EnableMouse(true)
    look.head:RegisterForDrag("LeftButton")
    look.head:SetScript("OnDragStart", ns.Guard(function() palette:StartMoving() end))
    look.head:SetScript("OnDragStop", ns.Guard(function() palette:StopMovingOrSizing() end))
    palette:SetScript("OnShow", ns.Guard(function() Core.Escape(palette, DrawBar.Close) end))
    palette:SetScript("OnHide", ns.Guard(function()
        Core.Escape(palette, nil)
        ns.Draw.SetTool(nil)
    end))
    local content = look.content
    local y = 0
    -- the tools
    tools = {}
    for index, key in ipairs(ns.Draw.TOOLS) do
        local words = DrawBar.TEXT.tools[key]
        local square = Square(content, DrawBar.TOOL, words[1], words[2], function()
            ns.Draw.SetTool(ns.Draw.Tool() ~= key and key or nil)
        end)
        square:SetPoint("TOPLEFT", (index - 1) * (DrawBar.TOOL + DrawBar.GAP), y)
        Glyph(square, key)
        square.key = key
        tools[index] = square
    end
    y = y - DrawBar.TOOL - 8
    -- the colours and the widths
    swatches = {}
    for index, colour in ipairs(ns.Plans.COLOURS) do
        local swatch = CreateFrame("Button", nil, content)
        swatch:SetSize(DrawBar.SWATCH, DrawBar.SWATCH)
        swatch:SetPoint("TOPLEFT", (index - 1) * (DrawBar.SWATCH + DrawBar.GAP), y)
        swatch.fill = swatch:CreateTexture(nil, "ARTWORK")
        swatch.fill:SetPoint("TOPLEFT", 3, -3)
        swatch.fill:SetPoint("BOTTOMRIGHT", -3, 3)
        swatch.fill:SetColorTexture(colour.rgb[1], colour.rgb[2], colour.rgb[3], 1)
        swatch.box = Look.Outline(swatch)
        swatch.key = colour.key
        swatch:SetScript("OnClick", ns.Guard(function() ns.Draw.SetColour(colour.key) end))
        swatches[index] = swatch
    end
    widths = {}
    for index, width in ipairs({ 1, 2 }) do
        local square = Square(content, DrawBar.SWATCH, width == 1 and DrawBar.TEXT.thin or DrawBar.TEXT.thick, nil,
            function() ns.Draw.SetWidth(width) end)
        square:SetPoint("TOPRIGHT", -(2 - index) * (DrawBar.SWATCH + DrawBar.GAP), y)
        local line = square:CreateLine(nil, "ARTWORK")
        line:SetTexture(ns.Draw.WHITE)
        line:SetThickness(ns.Draw.THICK[width] / 1.5)
        line:SetStartPoint("CENTER", square, -6, 0)
        line:SetEndPoint("CENTER", square, 6, 0)
        square.width = width
        widths[index] = square
    end
    y = y - DrawBar.SWATCH - 10
    -- the plan
    planMenu = CreateFrame("DropdownButton", nil, content, "WowStyle1DropdownTemplate")
    planMenu:SetPoint("TOPLEFT", 0, y)
    planMenu:SetPoint("RIGHT")
    planMenu:SetupMenu(ns.Guard(PlanMenu))
    y = y - 30 - 8
    -- undo and clear
    local undo = Look.Red(content, DrawBar.TEXT.undo, 100)
    undo:SetPoint("TOPLEFT", 0, y)
    undo:SetScript("OnClick", ns.Guard(function() ns.Plans.Undo() end))
    local clear = Look.Red(content, DrawBar.TEXT.clear, 100)
    clear:SetPoint("LEFT", undo, "RIGHT", 8, 0)
    clear:SetScript("OnClick", ns.Guard(Clear))
    y = y - 28
    palette:SetHeight(-y + Look.DRESS_HEAD + 4 + Look.INSIDE + 4)
    palette.tools, palette.swatches, palette.widths, palette.plan = tools, swatches, widths, planMenu
    palette.undo, palette.clear = undo, clear
    DrawBar.palette = palette -- (for the tests)
    palette:Hide()
    return palette
end

-- The palette as the choices are now: the tool on lit, the colour and width chosen outlined, the plan named.
function DrawBar.Update()
    if not palette then return end
    local tool, colour, width = ns.Draw.Tool(), ns.Draw.Colour(), ns.Draw.Width()
    for _, square in ipairs(tools) do Lit(square, square.key == tool) end
    for _, swatch in ipairs(swatches) do swatch.box:SetStrong(swatch.key == colour) end
    for _, square in ipairs(widths) do Lit(square, square.width == width) end
    local plan = ns.Plans.Active()
    if planMenu.OverrideText then planMenu:OverrideText(DrawBar.TEXT.plan:format(plan.name or "")) end
    DrawBar.Said()
end

-- The bar's dropdown says Sketches, and while you draw the sketch you draw in.
function DrawBar.Said()
    if not (button and button.OverrideText) then return end
    local drawing = palette and palette:IsShown()
    button:OverrideText(drawing and DrawBar.TEXT.drawing:format(ns.Plans.Active().name or "") or DrawBar.TEXT.sketches)
end

function DrawBar.Open()
    Build()
    palette:Show()
    if not ns.Draw.Tool() then ns.Draw.SetTool("pen") end
    DrawBar.Update()
end

function DrawBar.Close()
    if palette then palette:Hide() end
    ns.Draw.SetTool(nil)
    DrawBar.Update()
end

function DrawBar.Toggle()
    if palette and palette:IsShown() then DrawBar.Close() else DrawBar.Open() end
end

-- The dropdown Sketches on the full map's bar (TopBar.lua), the game's own (WowStyle1DropdownTemplate), in place of
-- the pencil button that was there.
function DrawBar.Menu(bar, height)
    button = CreateFrame("DropdownButton", nil, bar, "WowStyle1DropdownTemplate")
    button:SetSize(DrawBar.WIDTH_MENU, height or 24)
    button:SetupMenu(ns.Guard(SketchesMenu))
    DrawBar.button = button
    DrawBar.Said()
    return button
end

-- The bar gone (the map small or on its way): the palette and its tool with it.
function DrawBar.Hide()
    if palette and palette:IsShown() then DrawBar.Close() end
end
