TM = TM or {}
TM.Debug = TM.Debug or {}

local function dump(value, depth, maxItems, seen)
    depth =  depth or 2 --What depth to print
    maxItems = maxItems or 50 --Limit the amount of items to debug log for optimization
    seen = seen or {} --If we already saw this item

    local text =  type(value)
    if text ~= "table" then
        if text == "string" then return value end
        return tostring(value)
    end

    if seen[value] then return "<cycle>" end -- Meaning it's repeated
    if depth <= 0 then return "{...}" end -- There is more depth
    seen[value] = true

    local parts = {}
    local count = 0

    -- Try to detect arrayed tables and if so the number of items in it
    local isArray = true
    local maxIndex = 0
    for k, _ in pairs(value) do
        if type(k) ~= "number" then isArray = false break end
        if k > maxIndex then maxIndex = k end
    end
    
    if isArray and maxIndex > 0 then
        for i = 1, maxIndex do
            count = count + 1
            if count > maxItems then parts[#parts + 1] = "..." break end -- There is more in that array
            parts[#parts + 1] = dump(value[i], depth - 1, maxItems, seen)
        end
        return "[" .. table.concat(parts, ", ") .. "]"
    end
    
    for k, v in pairs(value) do
        count = count + 1
        if count > maxItems then parts[#parts + 1] = "..." break end -- There is more in that array
        parts[#parts + 1] = tostring(k) .. "=" .. dump(v, depth - 1, maxItems, seen)
    end

    return "{" .. table.concat(parts, ", ") .. "}"
end

local function fmtArgs(...)
    local out = {}
    local depth = (TM.Config and TM.Config.DebugDepth) or 2
    local maxItems = (TM.Config and TM.Config.DebugMaxItems) or 50

    for i = 1, select("#", ...) do
        out[#out + 1] = dump(select(i, ...), depth, maxItems)
    end
    return table.concat(out, " ")
end

function TM.Debug.log(...)
    if not (TM.Config and TM.Config.Debug) then return end
    print("[TM] " .. fmtArgs(...))    
end

function TM.Debug.warn(...)
    print("[TM][WARN] " .. fmtArgs(...))    
end

function TM.Debug.err(...)
    print("[TM][ERROR] " .. fmtArgs(...))    
end