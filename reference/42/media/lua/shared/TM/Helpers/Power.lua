TM = TM or {}
TM.Power = TM.Power or {}

local function safeBool(fn)
    local ok, v = pcall(fn)
    if ok and type(v) == "boolean" then return v end
    return nil
end

function TM.Power.canPowerDeviceUI(deviceData, device, deviceType)
    if not deviceData then return false end

    if deviceData.canBePoweredHere then
        local v = safeBool(function() return deviceData:canBePoweredHere() end)
        if v ~= nil then return v end
    end

    local square = nil
    if TM.Devices and TM.Devices.Square and TM.Devices.Square.get then
        square = TM.Devices.Square.get(device, deviceType)
    end
    if not square and device and device.getSquare then
        square = device:getSquare()
    end
    if square and square.haveElectricity then
        local v = safeBool(function() return square:haveElectricity() end)
        if v ~= nil then return v end
    end

    return false
end
