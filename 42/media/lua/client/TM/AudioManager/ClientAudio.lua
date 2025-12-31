TM = TM or {}
TM.ClientAudio = TM.ClientAudio or {}

require "TM/Debug"
require "TM/State"
require "TM/AudioManager/Runtime"

local function dist2D(a, b)
    local dx = a:getX() - b.x
    local dy = a:getY() - b.y
    return math.sqrt(dx * dx + dy * dy)
end

local function volumeCurve(dist, maxDist)
    if dist >= maxDist then return 0 end
    local tile = 1 - (dist / maxDist)
    return tile * tile * tile -- Area is more natural tan linear
end

local function getActiveSpeakerDevices() -- Gets a list of entries
    if TM.State and TM.State.getActiveSpeakerDevices then
        return TM.State.getActiveSpeakerDevices()
    end
    return {}
end

local function ensurePlaying(device, player)
    if not device or not device.key or not device.sound then return end
    -- WalkmanPlayer logic
    if device.mode == "headphones" then
        local me = getSpecificPlayer(0)
        if not me then return end

        local myID = isClient() and me:getOnlineID() or 0
        if tostring(device.ownerId) ~= tostring(myID) then
            -- Future leak of audio for other to hear
            return
        end

        local key = device.key
        local entry = TM.Runtime.SoundByKey[key]
        if not entry then
            local emitter = me:getEmitter()
            local soundId
            if emitter.playSoundImpl then
                soundId = emitter:playSoundImpl(device.sound, nil)
            elseif emitter.playSound then
                soundId = emitter:playSound(device.sound)
            elseif emitter.playSoundLocal then
                soundId = emitter:playSoundLocal(device.sound)
            else
                return
            end
            if not soundId or soundId == 0 then return end

            entry = { emitter = emitter, soundId = soundId, lastVol = -1 }
            TM.Runtime.SoundByKey[key] = entry
        end

        local gain = (device.volume or 1.0)
        if entry.emitter.setVolume and (entry.lastVol < 0 or math.abs(gain - entry.lastVol) > 0.001) then
            entry.emitter:setVolume(entry.soundId, gain)
            entry.lastVol = gain
        end

        return
    end

    --General Logic
    if not device.pos or device.pos.x == nil or device.pos.y == nil then
        TM.Debug.err("Device missing pos", device)
        return
    end

    local key = device.key
    local entry = TM.Runtime.SoundByKey[key]

    if entry and entry.emitter and entry.emitter.isPlaying then
        if not entry.emitter:isPlaying(entry.soundId) then
            TM.Runtime.stopLocal(key)
            --TM.State.removeSession(key) //ToSessionUpdater
            return
        end
    end

    local maxDist = device.maxDist or TM.State.Const.SPEAKER_MAX_DIST
    local startDist = maxDist
    local stopDist = maxDist + 2

    local d = dist2D(player, device.pos)

    if not entry then
        if d > startDist then return end
    else
        if d > stopDist then
            TM.Runtime.stopLocal(device.key)
            return
        end
    end

    local gain = volumeCurve(d, maxDist) * (device.volume or 1.0)
    local silence = 0.001 -- 0.1%
    if gain < silence then
        if entry then
            TM.Runtime.stopLocal(key)
        end
        return
    end

    if not entry then
        local emitter = player and player.getEmitter and player:getEmitter()
        if not emitter then
            TM.Debug.err("No emitter available on player", player)
            return
        end

        local soundId
        if emitter.playSoundImpl then
            soundId = emitter:playSoundImpl(device.sound, nil)
        elseif emitter.playSound then
            soundId = emitter:playSound(device.sound)
        elseif emitter.playSoundLocal then
            soundId = emitter:playSoundLocal(device.sound)
        else
            TM.Debug.err("Emitter has no play method", device.sound)
            return
        end

        if soundId == nil or soundId == 0 then
            TM.Debug.err("Failed to play sound (bad id?)", device.sound, key, soundId)
            return
        end

        if emitter.set3D then
            emitter:set3D(soundId, true)
        end

        TM.Runtime.setLocal(key, emitter, soundId)
        TM.Runtime.SoundByKey[device.key] = entry
        entry.lastVol = -1
    end

    if (entry.lastVol < 0) or (math.abs(gain - entry.lastVol) > 0.001) then
        if entry.emitter and entry.emitter.setVolume then
            entry.emitter:setVolume(entry.soundId, gain)
        end
        entry.lastVol = gain
    end
end

local tick = 0
local function onTick()
    tick = tick + 1
    local interval = (TM.Config and TM.Config.TickInterval) or 10
    if tick % interval ~= 0 then return end

    local player = getSpecificPlayer(0)
    if not player then return end

    local devices = getActiveSpeakerDevices()

    local activeKeys = {}
    for _, dev in pairs(devices) do
        if dev and dev.key then
            activeKeys[dev.key] = true
            ensurePlaying(dev, player)
        end
    end
    for key, _ in pairs(TM.Runtime.SoundByKey) do
        if not activeKeys[key] then
            TM.Runtime.stopLocal(key)
        end
    end
end

local function init()
    if not Events or not Events.OnTick or not Events.OnTick.Add then
        if TM and TM.Debug then TM.Debug.err("Events.OnTick not available at init") end
        return
    end

    Events.OnTick.Add(onTick)
    if TM and TM.Debug then TM.Debug.log("ClientAudio tick registered") end
end

Events.OnGameBoot.Add(init)
