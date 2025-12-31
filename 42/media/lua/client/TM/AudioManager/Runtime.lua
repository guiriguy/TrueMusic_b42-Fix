TM = TM or {}
TM.Runtime = TM.Runtime or {}
TM.Runtime.DeviceByKey = TM.Runtime.DeviceByKey or {}
TM.Runtime.IsoByKey = TM.Runtime.IsoByKey or {}
TM.Runtime.VehicleByKey = TM.Runtime.VehicleByKey or {}
TM.Runtime.SoundByKey = TM.Runtime.SoundByKey or {}

function TM.Runtime.stopLocal(key)
    local r = TM.Runtime.SoundByKey[key]
    if not r then return end

    if r.emitter and r.soundId then
        pcall(function() r.emitter:stopSound(r.soundId) end)
    elseif r.emitter then
        pcall(function() r.emitter:stopAll() end)
    end

    TM.Runtime.SoundByKey[key] = nil
end

function TM.Runtime.setLocal(key, emitter, soundId)
    TM.Runtime.SoundByKey[key] = { emitter = emitter, soundId = soundId }
end

function TM.Runtime.dropDeviceKey(key)
    TM.Runtime.DeviceByKey[key] = nil
    TM.Runtime.IsoByKey[key] = nil
    TM.Runtime.VehicleByKey[key] = nil
end
