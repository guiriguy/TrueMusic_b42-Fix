-- v1: Fix-first compatibility layer.
-- Source of truth is the legacy public API:
--   - GlobalMusic[item:getType()] -> bankId
--   - TCMusic.*MusicPlayer[...]   -> bankId
-- See ISTCBoomboxAction validation logic

TCM = TCM or {}
TCM.Compat = TCM.Compat or {}

local function req(path)
    -- fail-soft: compat should not crash
    pcall(require, path)
end

req("TCM/Legacy/Bridge")

-- Helper: get bank for media item by item:getType()
local function mediaBank(item)
    if not item or not item.getType then return nil end
    if not GlobalMusic then return nil end
    return GlobalMusic[item:getType()]
end

-- Helper: get bank for device based on device ModData type (InventoryItem/IsoObject/VehiclePart)
local function deviceBank(device)
    if not device or not device.getModData then return nil end
    local md = device:getModData()
    local tcm = md and md.tcmusic
    local dtype = tcm and tcm.deviceType
    if not dtype then return nil end

    if dtype == "InventoryItem" then
        local ft = device.getFullType and device:getFullType()
        if not ft then return nil end
        return (TCMusic and TCMusic.ItemMusicPlayer and TCMusic.ItemMusicPlayer[ft])
            or (TCMusic and TCMusic.WalkmanPlayer and TCMusic.WalkmanPlayer[ft])
    elseif dtype == "IsoObject" then
        local sprite = device.getSprite and device:getSprite()
        local name = sprite and sprite.getName and sprite:getName()
        if not name then return nil end
        return (TCMusic and TCMusic.WorldMusicPlayer and TCMusic.WorldMusicPlayer[name])
    elseif dtype == "VehiclePart" then
        local inv = device.getInventoryItem and device:getInventoryItem()
        local ft = inv and inv.getFullType and inv:getFullType()
        if not ft then return nil end
        return (TCMusic and TCMusic.VehicleMusicPlayer and TCMusic.VehicleMusicPlayer[ft])
    end

    return nil
end

-- Public: legacy bank match check (device + media item)
function TCM.Compat.canPlayLegacy(device, mediaItem)
    local db = deviceBank(device)
    if not db then return false end

    local mb = mediaBank(mediaItem)
    if not mb then return false end

    return db == mb
end

-- Public: contract-style check (deviceCaps + mediaDesc)
-- For v1, we still support the "new" signature, but we map to legacy behavior if possible.
function TCM.Compat.canPlay(deviceCaps, mediaDesc)
    -- If caller passed raw objects instead of descriptors, try legacy path.
    -- (We keep this permissive in v1 to avoid breaking old call sites.)
    if deviceCaps and deviceCaps.getModData and mediaDesc and mediaDesc.getType then
        return TCM.Compat.canPlayLegacy(deviceCaps, mediaDesc)
    end

    -- New-style fallback: acceptedMediaKinds check
    if not deviceCaps or not mediaDesc then return false end
    local accepted = deviceCaps.acceptedMediaKinds
    local kind = mediaDesc.mediaKind
    if not accepted or not kind then return false end

    for _, v in ipairs(accepted) do
        if v == kind then return true end
    end
    return false
end

return TCM.Compat
