-- A small XML reader for the game's UI files: elements with their attributes, children and text.
--   xml.parse(text) -> { tag = "Ui", attrs = {}, children = { ... }, text = "" }
local xml = {}

local entities = { lt = "<", gt = ">", amp = "&", quot = '"', apos = "'" }
local function unescape(s)
    return (s:gsub("&(#?x?%w+);", function(e)
        if e:sub(1, 2) == "#x" then return string.char(tonumber(e:sub(3), 16) % 256) end
        if e:sub(1, 1) == "#" then return string.char(tonumber(e:sub(2)) % 256) end
        return entities[e] or ("&" .. e .. ";")
    end))
end

function xml.parse(text)
    local root = { tag = "#document", attrs = {}, children = {}, text = "" }
    local stack = { root }
    local i = 1
    local n = #text
    while i <= n do
        local lt = text:find("<", i, true)
        if not lt then
            stack[#stack].text = stack[#stack].text .. unescape(text:sub(i))
            break
        end
        if lt > i then stack[#stack].text = stack[#stack].text .. unescape(text:sub(i, lt - 1)) end
        if text:sub(lt, lt + 3) == "<!--" then
            local e = text:find("-->", lt + 4, true)
            i = (e or n) + 3
        elseif text:sub(lt, lt + 8) == "<![CDATA[" then
            local e = text:find("]]>", lt + 9, true)
            stack[#stack].text = stack[#stack].text .. text:sub(lt + 9, (e or n + 1) - 1)
            i = (e or n) + 3
        elseif text:sub(lt, lt + 1) == "<?" or text:sub(lt, lt + 1) == "<!" then
            local e = text:find(">", lt, true)
            i = (e or n) + 1
        elseif text:sub(lt, lt + 1) == "</" then
            local e = text:find(">", lt, true)
            local tag = text:sub(lt + 2, e - 1):match("^%s*([^%s>]+)")
            local top = table.remove(stack)
            if not top or top.tag ~= tag then
                error(("xml: </%s> closes <%s>"):format(tostring(tag), top and top.tag or "nothing"))
            end
            i = e + 1
        else
            local tag, j = text:match("^<([%w_:%.%-]+)()", lt)
            if not tag then error("xml: bad tag at " .. lt) end
            local el = { tag = tag, attrs = {}, children = {}, text = "", line = select(2, text:sub(1, lt):gsub("\n", "")) + 1 }
            while true do
                local ws = text:match("^%s*()", j)
                j = ws
                local c = text:sub(j, j)
                if c == ">" then
                    local parent = stack[#stack]
                    parent.children[#parent.children + 1] = el
                    stack[#stack + 1] = el
                    i = j + 1
                    break
                elseif text:sub(j, j + 1) == "/>" then
                    local parent = stack[#stack]
                    parent.children[#parent.children + 1] = el
                    i = j + 2
                    break
                end
                local name, q, after = text:match("^([%w_:%.%-]+)%s*=%s*([\"'])()", j)
                if not name then error("xml: bad attribute in <" .. tag .. "> at " .. j) end
                local close = text:find(q, after, true)
                el.attrs[name] = unescape(text:sub(after, close - 1))
                j = close + 1
            end
        end
    end
    return root.children[1]
end

function xml.read(path)
    local f = io.open(path, "rb")
    if not f then return nil, "cannot open " .. path end
    local text = f:read("*a")
    f:close()
    local ok, doc = pcall(xml.parse, text)
    if not ok then return nil, doc end
    return doc
end

-- The children of an element with a tag (any case).
function xml.find(el, tag)
    tag = tag:lower()
    for _, c in ipairs(el.children) do
        if c.tag:lower() == tag then return c end
    end
end

return xml
