TM = TM or {}
TM.Devices = TM.Devices or {}
TM.Devices.Square = TM.Devices.Square or {}

-- [Future] Allowed Attachment locations
TM.Devices.AllowedAttach = {
    ["Belt Left"] = true,
    ["Belt Right"] = true,
    ["Back"] = true,
}

function TM.Devices.fullType(item)
    if not item or not item.getFullType then return nil end
    return item:getFullType()
end

function TM.Devices.isRadioItem(item)
    return item and instanceof(item, "Radio")
end

function TM.Devices.isWalkman(item)
    local fullType = TM.Devices.fullType(item)
    return fullType and TCMusic and TCMusic.WalkmanPlayer and TCMusic.WalkmanPlayer[fullType] ~= nil
end

function TM.Devices.isBoombox(item)
    local fullType = TM.Devices.fullType(item)
    return fullType and TCMusic and TCMusic.ItemMusicPlayer and TCMusic.ItemMusicPlayer[fullType] ~= nil
end

function TM.Devices.isVinylPlayer(item)
    if not item or not (instanceof(item, "Radio")) then return false end
    local dd = item:getDeviceData()
    return dd and dd.getDeviceData and dd:getDeviceData() == 1
end

function TM.Devices.isOurDevice(item)
    if not TM.Devices.isRadioItem(item) then return false end

    local modData = item:getModData()
    if modData and modData.tcmusic and modData.tcmusic.deviceType then
        return true
    end

    local fullType = TM.Devices.fullType(item)
    if not fullType or not TCMusic then return false end
    if TM.Devices.isBoombox(item) then return true end
    if TM.Devices.isWalkman(item) then return true end
    if TM.Devices.isVinylPlayer(item) then return true end

    return false
end

function TM.Devices.canOpenUI(playerObj, item)
    if not playerObj or not item or not item.getID then return false end
    local id = item:getID()

    local primary = playerObj:getPrimaryHandItem()
    if primary and primary.getID and primary:getID() == id then return true end

    local secondary = playerObj:getSecondaryHandItem()
    if secondary and secondary.getID and secondary:getID() == id then return true end

    local isVinylPlayer = TM.Devices.isVinylPlayer(item)
    if isVinylPlayer then
        local container = item:getContainer()
        return container and container:getType() == "floor"
    end
    -- TODO future holsted item (TM.Devices.isInHolsterSlot(playerObj, item))
    return false
end

function TM.Devices.isOnGround(item)
    return item and item.getWorldItem and item:getWorldItem() ~= nil
end

function TM.Devices.ensureIsoForVinyl(player, invItem)
    if not invItem or not invItem.getWorldItem then return nil end
    local wI = invItem:getWorldItem()
    local square = wI and wI.getSquare and wI:getSquare()
    if not square then return nil end

    local dd = invItem:getDeviceData()
    if not dd or not dd.getMediaType or dd:getMediaType() ~= 1 then
        return nil
    end

    -- Remove WorldItem from the floor
    square:transmitRemoveItemFromSquare(wI)
    square:getWorldObjects():remove(wI)
    square:getObjects():remove(wI)
    invItem:setWorldItem(nil)

    local chunk = square:getChunk()
    if chunk and chunk.recalcHashCodeObjects then chunk:recalcHashCodeObjects() end

    -- Create a IsoRadio/IsoWaveSignal (as legacy but in helper)
    local spriteName = TCMusic.WorldMusicPlayer[invItem:getFullType()]
    local iso = IsoRadio.new(getCell(), square, getSprite(spriteName))
    square:AddTileObject(iso)

    -- Copy revelant states
    local tmSource = invItem:getModData().tcmusic or {}
    local tmDst = {}
    tmDst.deviceType = "IsoObject"
    tmDst.mediaItem = tmSource.mediaItem
    tmDst.mediaItemFullType = tmSource.mediaItemFullType
    tmDst.isPlaying = tmSource.isPlaying or false
    tmDst.playerTag = "tm_player_vinyl"
    iso:getModData().tcmusic = tmDst

    -- deviceData
    iso:getDeviceData():setDeviceVolume(dd:getDeviceVolume())
    iso:getDeviceData():setIsTurnedOn(dd:getIsTurnedOn())
    iso:getDeviceData():setHasBattery(false)

    TM.Net.transmitIsoObject(iso)
    return iso
end

function TM.Devices.Square.get(device, deviceType)
    if deviceType == "IsoObject" then return device:getSquare() end
    if deviceType == "InventoryItem" then
        local wI = device:getWorldItem()
        return wI and wI:getSquare() or nil
    end
    if deviceType == "VehiclePart" then
        local veh = device:getVehicle()
        return veh and veh:getSquare() or nil
    end
    return nil
end
