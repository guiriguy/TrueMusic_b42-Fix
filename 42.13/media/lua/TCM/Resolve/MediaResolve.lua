TCM = TCM or {}
TCM.Media = TCM.Media or {}

function TCM.Media.resolve(item)
    if not item or not TCM.MediaRegistry or not TCM.MediaRegistry._entries then
        return nil
    end

    local best = nil
    local bestPriority = -999

    for _, e in ipairs(TCM.MediaRegistry._entries()) do
        local ok, match = pcall(e.matcher, item)
        if ok and match then
            local priority = e.priority or 0
            if priority > bestPriority then
                local ok2, desc = pcall(e.factory, item)
                if ok2 and desc then
                    desc.mediaKind = desc.mediaKind or e.mediaKind
                    best = desc
                    bestPriority = priority
                end
            end
        end
    end

    return best
end

return TCM.Media
