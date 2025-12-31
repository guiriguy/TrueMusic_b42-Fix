TCM = TCM or {}
TCM.Game = TCM.Game or {}
TCM.Game.DeviceModData = TCM.Game.DeviceModData or {}

local function _key()
    if TCM.Contracts and TCM.Contracts.MODDATA_KEY then
        return TCM.Contracts.MODDATA_KEY
    end
    return "tcmusic"
end

-- Returns the tcmusic moddata table for this device, creating defaults if missing.
-- device: InventoryItem / IsoObject / whatever supports getModData()
-- options: { deviceType=string, contractCache=boolean }
function TCM.Game.DeviceModData.ensure(device, options)
    if not device or not device.getModData then
        return nil
    end

    options = options or {}
    local modData = device:getModData()
    local k = _key()

    modData[k] = modData[k] or {}
    local t = modData[k]

    -- legacy fields commonly expected by existing code
    if t.isPlaying == nil then t.isPlaying = false end
    if t.mediaItem == nil then t.mediaItem = nil end
    if t.deviceType == nil then t.deviceType = options.deviceType or nil end

    -- contract cache (optional, non-breaking)
    if options.contractCache then
        t.contract = t.contract or { v = (TCM.Contracts and TCM.Contracts.CONTRACT_VERSION) or 1 }
    end

    return t
end

return TCM.Game.DeviceModData
