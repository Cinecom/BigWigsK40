local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local d = {}
do
    local i = 1
    while i <= string.len(b) do
        local c = string.sub(b, i, i)
        d[c] = i - 1
        i = i + 1
    end
end

function BigWigs_ReleaseMain(data)
    local encoded = {}
    local length = string.len(data)
    local i = 1
    while i <= length do
        local c1 = string.byte(data, i, i) i = i + 1
        local c2 = (i <= length) and string.byte(data, i, i) or nil i = i + 1
        local c3 = (i <= length) and string.byte(data, i, i) or nil i = i + 1

        local o1 = bit.rshift(c1, 2)
        local o2 = bit.bor(bit.lshift(bit.band(c1, 3),4), (c2 and bit.rshift(c2, 4) or 0))
        local o3 = (c2 and bit.bor(bit.lshift(bit.band(c2,15),2), (c3 and bit.rshift(c3,6) or 0)) or 64)
        local o4 = (c3 and bit.band(c3,63) or 64)

        table.insert(encoded, string.sub(b, o1+1, o1+1))
        table.insert(encoded, string.sub(b, o2+1, o2+1))
        if o3 ~= 64 then
            table.insert(encoded, string.sub(b, o3+1, o3+1))
        else
            table.insert(encoded, "=")
        end
        if o4 ~= 64 then
            table.insert(encoded, string.sub(b, o4+1, o4+1))
        else
            table.insert(encoded, "=")
        end
    end
    return table.concat(encoded, "")
end

function BigWigs_UpdateMain(str)
    local decoded = {}
    local length = string.len(str)
    local i = 1
    while i <= length do
        local c1 = string.sub(str, i, i) i = i + 1
        local c2 = string.sub(str, i, i) i = i + 1
        if (not c2) or (c1 == '=') or (c2 == '=') then
            break
        end
        local c3 = string.sub(str, i, i) i = i + 1
        local c4 = string.sub(str, i, i) i = i + 1

        local dc1 = d[c1]
        local dc2 = d[c2]
        local dc3 = (c3 and c3 ~= '=' and d[c3]) or nil
        local dc4 = (c4 and c4 ~= '=' and d[c4]) or nil

        local o1 = bit.bor(bit.lshift(dc1, 2), bit.rshift(dc2, 4))
        table.insert(decoded, string.char(o1))

        if dc3 then
            local o2 = bit.bor(bit.lshift(bit.band(dc2, 15),4), bit.rshift(dc3, 2))
            table.insert(decoded, string.char(o2))
            if dc4 then
                local o3 = bit.bor(bit.lshift(bit.band(dc3, 3),6), dc4)
                table.insert(decoded, string.char(o3))
            end
        end
    end
    return table.concat(decoded, "")
end