local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Guild - Art
--  The module's pictures, by name. Its own are still to be drawn
--  (Doc/ideas/Guild.md, *Pictures*; the sketches: dev/imagegen/sets/guild/):
--  until then each name stands for a placeholder of the game's own art. A view
--  only asks Art.Set(texture, name), so a drawn picture takes a placeholder's
--  place here alone, with its size and texture coordinates.
--
--      ns.Art.Set(texture, "crestRing")   -- the picture on the texture (its file and coordinates); false: none
-------------------------------------------------------------------------------
local Art = {}
ns.Art = Art

-- [name] = { file, coords, tint }: the placeholders, the game's art.
Art.PICTURES = {
    icon = { file = "Interface\\Icons\\INV_Epicguildtabard" },
    crestRing = { file = "Interface\\Minimap\\MiniMap-TrackingBorder", coords = { 0, 0.6, 0, 0.6 } },
    noEmblem = { file = "Interface\\GuildFrame\\GuildLogo-NoLogo" },
    laurel = { file = "Interface\\Minimap\\MiniMap-TrackingBorder", coords = { 0, 0.6, 0, 0.6 } },
    emblemRing = { file = "Interface\\Minimap\\MiniMap-TrackingBorder", coords = { 0, 0.6, 0, 0.6 } },
    medalGold = { file = "Interface\\COMMON\\Indicator-Yellow" },
    medalSilver = { file = "Interface\\COMMON\\Indicator-Gray" },
    medalBronze = { file = "Interface\\COMMON\\Indicator-Red" },
    bisStar = { file = "Interface\\COMMON\\ReputationStar", coords = { 0, 0.5, 0, 0.5 } },
    pinRing = { file = "Interface\\Minimap\\MiniMap-TrackingBorder", coords = { 0, 0.6, 0, 0.6 } },
}

-- The picture of that name on a texture: true when it was found.
function Art.Set(texture, name)
    local picture = Art.PICTURES[name]
    if not picture then return false end
    local found = texture:SetTexture(picture.file)
    if picture.coords then texture:SetTexCoord(unpack(picture.coords)) else texture:SetTexCoord(0, 1, 0, 1) end
    return found ~= false
end
