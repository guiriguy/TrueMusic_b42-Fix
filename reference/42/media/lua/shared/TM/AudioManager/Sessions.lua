TM = TM or {}
TM.Sessions = TM.Sessions or {}

function TM.Sessions.keyWorldXYZ(x, y, z)
    return string.format("TM:WO:%d:%d:%d", x, y, z)
end

function TM.Sessions.keyWorld(deviceOrSquare)
    local x = deviceOrSquare:getX()
    local y = deviceOrSquare:getY()
    local z = deviceOrSquare:getZ()
    return TM.Sessions.keyWorldXYZ(x, y, z)
end

function TM.Sessions.keyPlayer(character, device)
    local playerID = (isClient() and character:getOnlineID()) or character:getUsername()
    local itemID = (device.getID and device:getID()) or 0
    return string.format("TM:P:%s:%d", tostring(playerID), itemID)
end

function TM.Sessions.keyItem(device)
    return string.format("TM:I:%d", device:getID())
end

function TM.Sessions.keyVehicle(vehicleID)
    return string.format("TM:V:%d", vehicleID)
end

function TM.Sessions.keyFromDevice(character, device, deviceData)
    if not device then return nil end
    if instanceof(device, "VehiclePart") or (device.getVehicle and device:getVehicle()) then
        local veh = device:getVehicle()
        return veh and TM.Sessions.keyVehicle(veh:getId()) or nil
    end

    if instanceof(device, "IsoWaveSignal") then
        return TM.Sessions.keyWorld(device)
    end

    if device.getID then
        return TM.Sessions.keyItem(device)
    end

    return nil
end

function TM.Sessions.sessionSpeaker(key, sound, volume, pos, maxDist, kind)
    return {
        key = key,
        kind = kind or "world",
        mode = "speaker",
        sound = sound,
        volume = volume or 1.0,
        pos = pos,
        maxDist = maxDist,
        lastSeen = getTimestampMs and getTimestampMs() or 0,
    }
end

function TM.Sessions.sessionHeadphones(key, sound, volume, ownerId, itemId)
    return {
        key = key,
        kind = "item",
        mode = "headphones",
        sound = sound,
        volume = volume or 1.0,
        ownerId = ownerId,
        itemId = itemId,
        leakMaxDist = TM.State.Const.LEAK_MAX_DIST,
        leakVol = TM.State.Const.LEAK_VOL,
        lastSeen = getTimestampMs and getTimestampMs() or 0,
    }
end
