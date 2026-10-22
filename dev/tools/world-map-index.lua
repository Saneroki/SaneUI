-- The blocks of an Atlas pack, read by the Atlas module itself as the game reads them (dev/tools/world-map runs it
-- under Lua 5.1): src/Atlas/Atlas.lua and the pack's Index.lua are loaded as the game loads the addon's files, then
-- every block the module says it has (Has(Key(...))) is printed, a line each: continent level row column.
--   lua5.1 dev/tools/world-map-index.lua <Sane UI's folder> <the pack's Index.lua>
local root, indexFile = ...
SaneUI = { Core = { NewModule = function() end } }   -- all the module asks of Core when it loads
local private = {}
assert(loadfile(root .. "/src/Atlas/Atlas.lua"))("SaneUI_Atlas", private)
assert(loadfile(indexFile))("SaneUI_Atlas", private)
if not private.Ready() then return end
for continent = 0, 15 do
    for level = 0, private.Levels() - 1 do
        local last = private.Cells(level) - 1
        for row = 0, last do
            for column = 0, last do
                if private.Has(private.Key(continent, level, row, column)) then
                    io.write(continent, " ", level, " ", row, " ", column, "\n")
                end
            end
        end
    end
end
