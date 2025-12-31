TM              = TM or {}
TM.State        = TM.State or {}
TM.State.Active = TM.State.Active or {}
-- TM.State.ActiveSpeakerDevices = TM.State.ActiveSpeakerDevices or {}//Testing with DevTest.lua

TM.State.Const  = {
    SPEAKER_MAX_DIST = 18,  -- Tiles
    LEAK_MAX_DIST    = 3,   -- Tiles
    LEAK_VOL         = 0.02 -- Volume at what we can hear the headphones near someone listening to music
}

function TM.State.setSession(key, session)
    TM.State.Active[key] = session
end

function TM.State.removeSession(key)
    local session = TM.State.Active[key]
    TM.State.Active[key] = nil

    if TM.Runtime and TM.Runtime.stopLocal then
        TM.Runtime.stopLocal(key)
        TM.Runtime.dropDeviceKey(key)
    end
end

function TM.State.getActiveSpeakerDevices()
    local out = {}
    for k, s in ipairs(TM.State.Active) do
        if s.mode ~= "headphones" then
            out[k] = s
        end
    end
    return out
end
