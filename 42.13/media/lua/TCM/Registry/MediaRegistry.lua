TCM = TCM or {}
TCM.MediaRegistry = TCM.MediaRegistry or {}

local _entries = {}

function TCM.MediaRegistry.register(mediaKind, matcher, factory, options)
    options = options or {}
    table.insert(_entries, {
        mediaKind = mediaKind,
        matcher = matcher,
        factory = factory,
        priority = options.priority or 0,
        modId = options.modId or "unkown",
        contractVersion = options.contractVersion or (TCM.Contracts and TCM.Contracts.CONTRACT_VERSION) or 1,
    })
end

function TCM.MediaRegistry._entries()
    return _entries
end

return TCM.MediaRegistry
