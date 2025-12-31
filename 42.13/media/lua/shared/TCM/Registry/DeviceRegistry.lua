TCM = TCM or {}
TCM.DeviceRegistry = TCM.DeviceRegistry or {}

local _entries = {}

function TCM.DeviceRegistry.register(deviceKind, matcher, factory, options)
    options = options or {}
    table.insert(_entries, {
        deviceKind = deviceKind,
        matcher = matcher,
        factory = factory,
        priority = options.priority or 0,
        modId = options.modId or "unkown",
        contractVersion = options.contractVersion or (TCM.Contracts and TCM.Contracts.CONTRACT_VERSION) or 1,
    })
end

function TCM.DeviceRegistry._entries()
    return _entries
end

return TCM.DeviceRegistry
