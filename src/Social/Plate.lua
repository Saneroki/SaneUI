local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social - Plate
--  A plain fill with round corners and nothing else: no border, no ornament.
--  What a bubble and the line to write in stand on. And the round mask that
--  makes its corners and the class icons round (Round).
--
--  The game has no such art that takes any colour, so it is put together from
--  plain colour: a square in each corner, a bar between the two upper corners,
--  one between the two lower ones, and the middle. No piece lies over another,
--  so the plate can be see-through. Everything hangs on the frame's corners,
--  so the plate follows the frame's size by itself.
--
--  A corner is round because the game's round portrait mask lies on its
--  square: the whole mask, twice the square's size, put on the frame's corner,
--  so the square sees just the quarter of the circle that belongs there. (A
--  quarter of the mask picked by texture coordinates does not work: the game
--  draws the whole circle into the square.)
--
--  Instead of a colour it can show one of the game's background textures
--  (Tile), repeated over the whole plate. Each piece shows the part of the
--  texture that lies where it lies, by texture coordinates measured from the
--  plate's top left, so the pieces meet without a seam; they are measured anew
--  whenever the plate changes its size.
-------------------------------------------------------------------------------
local ROUND = "Interface\\CharacterFrame\\TempPortraitAlphaMask" -- the game's round mask for portraits
local CORNERS = { "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT" }

-- The game's round mask over a texture (a mask of frame). Returns the mask, to place it: over the
-- whole texture for a round icon, larger for a plate's corner.
function ns.Round(frame, texture)
    local mask = frame:CreateMaskTexture()
    mask:SetTexture(ROUND, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    texture:AddMaskTexture(mask)
    return mask
end

-- alpha: 1 (or none) solid, 0 nothing.
local function Color(plate, r, g, b, alpha)
    plate.size = nil
    for _, piece in ipairs(plate) do piece:SetColorTexture(r, g, b, alpha or 1) end
end

-- Each piece shows the part of the texture where it lies in the plate (place: x, y, width, height).
local function Lay(plate)
    local size = plate.size
    if not size then return end
    local width, height = plate.frame:GetSize()
    width, height = width or 0, height or 0
    for index, piece in ipairs(plate) do
        local x, y, w, h = plate.places[index](width, height)
        piece:SetTexCoord(x / size, (x + w) / size, y / size, (y + h) / size)
    end
end

-- One of the game's textures, repeated every size points over the whole plate. alpha as for Color.
local function Tile(plate, file, size, alpha)
    plate.size = size
    for _, piece in ipairs(plate) do
        piece:SetTexture(file, "REPEAT", "REPEAT")
        piece:SetVertexColor(1, 1, 1, alpha or 1)
    end
    Lay(plate)
end

-- Fills frame, behind what else it shows. Returns the plate: plate:Color(r, g, b, alpha),
-- plate:Tile(file, size, alpha).
function ns.Plate(frame, radius)
    local plate = { Color = Color, Tile = Tile, frame = frame, places = {} }
    local function Piece(place)
        local piece = frame:CreateTexture(nil, "BACKGROUND")
        plate[#plate + 1] = piece
        plate.places[#plate] = place
        return piece
    end
    local top = Piece(function(w) return radius, 0, w - 2 * radius, radius end)
    local middle = Piece(function(w, h) return 0, radius, w, h - 2 * radius end)
    local bottom = Piece(function(w, h) return radius, h - radius, w - 2 * radius, radius end)
    top:SetPoint("TOPLEFT", radius, 0)
    top:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -radius, -radius)
    middle:SetPoint("TOPLEFT", 0, -radius)
    middle:SetPoint("BOTTOMRIGHT", 0, radius)
    bottom:SetPoint("BOTTOMLEFT", radius, 0)
    bottom:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", -radius, radius)
    for _, corner in ipairs(CORNERS) do
        local right, low = corner:find("RIGHT") ~= nil, corner:find("BOTTOM") ~= nil
        local square = Piece(function(w, h)
            return right and w - radius or 0, low and h - radius or 0, radius, radius
        end)
        square:SetSize(radius, radius)
        square:SetPoint(corner)
        local mask = ns.Round(frame, square)
        mask:SetSize(2 * radius, 2 * radius)
        mask:SetPoint(corner)
    end
    frame:HookScript("OnSizeChanged", function() Lay(plate) end)
    return plate
end
