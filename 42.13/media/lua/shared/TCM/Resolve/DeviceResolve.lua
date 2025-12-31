TCM = TCM or {}
TCM.Device = TCM.Device or {}

function TCM.Device.resolve(item)
    if not item or not TCM.DeviceRegistry or not TCM.DeviceRegistry._entries then
        return nil
    end

    local best = nil
    local bestPriority = -999

    for _, e in ipairs(TCM.DeviceRegistry._entries()) do
        local ok, match = pcall(e.matcher, item)
        if ok and match then
            local priority = e.priority or 0
            if priority > bestPriority then
                local ok2, desc = pcall(e.factory, item)
                if ok2 and desc then
                    desc.deviceKind = desc.deviceKind or e.deviceKind
                    best = desc
                    bestPriority = priority
                end
            end
        end
    end

    return best
end

return TCM.Device
