-- Client-side audio session manager for world devices.
-- Plays server now_play entries locally with distance-based volume curve and hysteresis
-- to avoid hard cuts and re-trigger spam.

TCM                       = TCM or {}
TCM.ClientAudio           = TCM.ClientAudio or {}

-- local sessions: [musicId] = { sid, name, lastVol , emitter, obj}
local SESS                = TCM.ClientAudio._sessions or {}
TCM.ClientAudio._sessions = SESS

-- Tuning knobs
local MAX_DIST            = 18      -- where volume goes to ~0 (your "fade out" range)
local START_DIST          = 22      -- start only if closer than this
local STOP_DIST           = 22      -- stop only if farther than this (hysteresis)
local WORLD_VOL_SCALE     = 0.4
local SILENCE             = 0.00001 -- below this we stop

local function clamp(v, a, b)
    if v < a then return a end
    if v > b then return b end
    return v
end

-- Smooth curve: 1 at dist=0 -> 0 at dist>=MAX_DIST
local function volumeCurve(dist)
    local t = clamp(1 - (dist / MAX_DIST), 0, 1)
    return t * t * t
end

local function parseCoord(coord)
    if type(coord) ~= "string" then return nil end

    -- x,y,z
    local x, y, z = coord:match("(%-?%d+),(%-?%d+),(%-?%d+)")
    if x then return tonumber(x), tonumber(y), tonumber(z) end

    -- x-y-z
    x, y, z = coord:match("(%-?%d+)%-(%-?%d+)%-(%-?%d+)")
    if x then return tonumber(x), tonumber(y), tonumber(z) end

    return nil
end

local function dist2D(ax, ay, bx, by)
    local dx, dy = ax - bx, ay - by
    return math.sqrt(dx * dx + dy * dy)
end

local function findWorldDeviceAt(x, y, z)
    local sq = getSquare(x, y, z or 0)
    if not sq then return nil end

    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)

        if instanceof(o, "IsoWaveSignal") then
            local dd = o:getDeviceData()
            local em = dd and dd.getEmitter and dd:getEmitter() or nil
            if em then
                -- Si tienes el mapa de sprites de TrueMusic, úsalo para filtrar
                if TCMusic and TCMusic.WorldMusicPlayer then
                    local spr = o:getSprite()
                    local n = spr and spr:getName()
                    if n and TCMusic.WorldMusicPlayer[n] then
                        return o, em
                    end
                else
                    -- fallback (menos preciso)
                    return o, em
                end
            end
        end
    end

    return nil
end


local function stopSession(musicId)
    local s = SESS[musicId]
    if not s then return end
    if s.emitter and s.sid then
        s.emitter:stopSound(s.sid)
    end
    SESS[musicId] = nil
end

local function ensurePlaying(emitter, obj, musicId, soundName)
    local s = SESS[musicId]
    if s and s.sid and s.name == soundName and s.emitter == emitter then
        return s
    end

    -- If the track changed, stop old
    if s and s.sid and s.emitter then
        s.emitter:stopSound(s.sid)
    end

    local sid = emitter:playSoundImpl(soundName, obj)
    if not sid then
        -- can't start, keep no session
        SESS[musicId] = nil
        return nil
    end

    s = { sid = sid, name = soundName, lastVol = -1, emitter = emitter, obj = obj }
    SESS[musicId] = s
    return s
end

-- Call this from your main OnTick handler
function TCM.ClientAudio.updateFromNowPlay(playerObj)
    if not playerObj then return end

    local nowPlay = ModData.getOrCreate("trueMusicData")["now_play"] or {}

    -- Mark all as unseen; we'll clear after loop
    for id, s in pairs(SESS) do
        s._seen = false
    end

    local px, py = playerObj:getX(), playerObj:getY()

    for musicId, data in pairs(nowPlay) do
        local coord = (data and data.coord) or musicId
        local soundName = data and data.musicName
        local baseVol = data and data.volume or 1.0

        local x, y, z = parseCoord(coord)
        if x and y and soundName then
            local d = dist2D(px, py, x, y)

            local s = SESS[musicId]

            -- hard stop por distancia
            if s and d >= STOP_DIST then
                stopSession(musicId)
            elseif d <= START_DIST then
                local obj, devEmitter = findWorldDeviceAt(x, y, z or playerObj:getZ())
                if obj and devEmitter then
                    -- start / restart si hace falta
                    if (not s) or (s.name ~= soundName) or (s.emitter ~= devEmitter) then
                        s = ensurePlaying(devEmitter, obj, musicId, soundName)
                    end

                    if s then
                        s._seen = true

                        -- volumen base (sin curva; el motor hace la distancia)
                        local gain = baseVol * WORLD_VOL_SCALE * volumeCurve(d)
                        if math.abs(gain - (s.lastVol or -1)) > SILENCE then
                            s.emitter:setVolume(s.sid, gain)
                            s.lastVol = gain
                        end
                    end
                end
            end
        end
    end

    -- Stop any sessions that the server no longer reports
    for musicId, s in pairs(SESS) do
        if not s._seen then
            stopSession(musicId)
        end
    end
end
