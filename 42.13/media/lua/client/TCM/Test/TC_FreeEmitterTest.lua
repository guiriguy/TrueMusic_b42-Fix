-- TC_FreeEmitterTest.lua (B42) - FreeEmitter Test + selección de device + overlay
-- HOME   = Scan devices cerca
-- END    = Siguiente device (de la lista)
-- INSERT = Toggle attach Player <-> Device
-- PGUP   = Play/Stop sonido test
do return end
TCFET                  = TCFET or {}

TCFET.keyScan          = Keyboard.KEY_HOME
TCFET.keyNext          = Keyboard.KEY_END
TCFET.keyToggleAttach  = Keyboard.KEY_INSERT
TCFET.keyToggleSound   = Keyboard.KEY_PRIOR -- PageUp
TCFET.keyInPlace       = Keyboard.KEY_SPACE -- PageUp

-- Pega aquí tu soundName EXACTO
TCFET.TEST_SOUND       = "CassetteMichaelJacksonBillieJean(1982)"

TCFET.debug            = false

-- IMPORTANT: esto es el fix del “15 tiles” raruno
-- true = usa el emitter del player (no se cullea igual)
-- false = usa getWorld():getFreeEmitter(...)
TCFET.usePlayerEmitter = true

-- Visuals
TCFET.drawOverlay      = true
TCFET.emitterMarker    = nil -- {x,y,z}
TCFET.deviceMarker     = nil -- {x,y,z}

-- Runtime
TCFET.emitter          = nil
TCFET.soundId          = nil
TCFET.attachMode       = "player" -- "player" | "device"
TCFET.boundDevice      = nil      -- { obj=IsoObject }
TCFET.candidates       = {}
TCFET.selIndex         = 1

local function p0()
    return (getSpecificPlayer and getSpecificPlayer(0)) or getPlayer()
end

local function say(msg)
    local p = p0()
    if p then p:Say(msg) end
    if TCFET.debug then print("[TCFET] " .. tostring(msg)) end
end

local function playerCenter()
    local p = p0()
    if not p then return nil end
    return p:getX(), p:getY(), p:getZ()
end

local function ensureEmitter()
    if TCFET.emitter then return end
    local p = p0()
    if not p then return end

    local x, y, z = playerCenter()
    if not x then return end
    local world = getWorld()
    if not world then return end
    TCFET.emitter = world:getFreeEmitter(x, y, z)
end

local function setEmitterPos(x, y, z)
    if not TCFET.emitter or not x then return end
    TCFET.emitter:setPos(x, y, z)
end

local function refreshEmitterAnchor()
    if not TCFET.emitter then return end
    ensureEmitter()
    TCM.Debug.log("Hahhsahas")
    if not TCFET.emitter then return end

    if TCFET.attachMode == "player" then
        TCM.Debug.log("Attached to player")
        local x, y, z = playerCenter()
        setEmitterPos(x, y, z)
        return
    else
        TCM.Debug.log("Attached to floor")
        local x, y, z = playerCenter()
        setEmitterPos(x, y, z)
        return
    end

    -- fallback
    TCFET.attachMode = "player"
    say("Device inválido -> vuelvo a PLAYER")
    local x, y, z = playerCenter()
    setEmitterPos(x, y, z)
end

local function playOrStop()
    ensureEmitter()
    if not TCFET.emitter then
        say("No emitter.")
        return
    end

    if TCFET.soundId then
        local stopped = TCFET.emitter:stopSoundLocal(TCFET.soundId)
        TCFET.soundId = nil
        TCFET.emitter = nil
        say("STOP (ok=" .. tostring(stopped) .. ")")
        return
    end

    refreshEmitterAnchor()

    say("Trying PLAY: " .. tostring(TCFET.TEST_SOUND) .. " | emitter=" .. tostring(TCFET.emitter))

    local sid = TCFET.emitter:playSoundImpl(TCFET.TEST_SOUND, p0():getSquare())
    TCM.Debug.log("Emitter", TCFET.emitter, sid)

    if sid ~= nil and sid ~= 0 then
        TCFET.soundId = sid
        local playing = TCFET.emitter:isPlaying(sid)
        TCFET.emitter:set3D(sid, true)
        say("PLAY OK sid=" .. tostring(sid) .. " | isPlaying=" .. tostring(playing))
    else
        say("PLAY FAILED (sid=" .. tostring(sid) .. ")")
    end
end

Events.OnGameStart.Add(function()
    ensureEmitter()
    refreshEmitterAnchor()
end)
function startTestTick()
    if TCFET.soundId then
    end
end

Events.OnTick.Add(function()
    if TCFET.attachMode == "player" then
        refreshEmitterAnchor()
    end
end)
Events.OnCreatePlayer.Add(startTestTick)
Events.OnKeyStartPressed.Add(function(key)
    if key == TCFET.keyToggleSound then
        playOrStop()
    elseif key == TCFET.keyInPlace then
        if TCFET.attachMode == "player" then
            TCM.Debug.log(TCFET.attachMode)
            TCFET.attachMode = nil
        else
            TCM.Debug.log(TCFET.attachMode)
            refreshEmitterAnchor()
            TCFET.attachMode = "player"
        end
    end
end)
