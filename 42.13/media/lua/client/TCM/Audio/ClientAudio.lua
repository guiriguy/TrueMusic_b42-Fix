-- Client-side audio session manager for world devices.
-- Plays server now_play entries locally with distance-based volume curve and hysteresis
-- to avoid hard cuts and re-trigger spam.

TCM                       = TCM or {}
TCM.ClientAudio           = TCM.ClientAudio or {}

-- local sessions: [musicId] = { sid, name, lastVol }
local SESS                = TCM.ClientAudio._sessions or {}
TCM.ClientAudio._sessions = SESS

-- Tuning knobs
local MAX_DIST            = 60    -- where volume goes to ~0 (your "fade out" range)
local START_DIST          = 60    -- start only if closer than this
local STOP_DIST           = 65    -- stop only if farther than this (hysteresis)
local SILENCE             = 0.001 -- below this we stop

local function clamp(v, a, b)
    if v < a then return a end
    if v > b then return b end
    return v
end

-- Smooth curve: 1 at dist=0 -> 0 at dist>=MAX_DIST
local function volumeCurve(dist)
    local t = clamp(1 - (dist / MAX_DIST), 0, 1)
    return t * t * t -- cubic
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

local function stopSession(playerEmitter, musicId)
    local s = SESS[musicId]
    if not s then return end
    if playerEmitter and s.sid then
        playerEmitter:stopSound(s.sid)
    end
    SESS[musicId] = nil
end

local function ensurePlaying(playerEmitter, musicId, soundName)
    local s = SESS[musicId]
    if s and s.sid and s.name == soundName then
        return s
    end

    -- If the track changed, stop old
    if s and s.sid then
        playerEmitter:stopSound(s.sid)
    end

    local sid = playerEmitter:playSoundImpl(soundName, nil)
    if not sid then
        -- can't start, keep no session
        SESS[musicId] = nil
        return nil
    end

    if playerEmitter.set3D then
        playerEmitter:set3D(sid, true)
    end

    s = { sid = sid, name = soundName, lastVol = -1 }
    SESS[musicId] = s
    return s
end

-- Call this from your main OnTick handler
function TCM.ClientAudio.updateFromNowPlay(playerObj)
    if not playerObj then return end
    local emitter = playerObj:getEmitter()
    if not emitter then return end

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

        if coord and soundName then
            local x, y = parseCoord(coord)
            if x and y then
                local d = dist2D(px, py, x, y)

                local s = SESS[musicId]
                if (not s) then
                    -- only start when close enough
                    if d <= START_DIST then
                        s = ensurePlaying(emitter, musicId, soundName)
                    end
                else
                    -- track changed?
                    if s.name ~= soundName then
                        s = ensurePlaying(emitter, musicId, soundName)
                    end
                end

                if s then
                    s._seen = true

                    -- Fade volume with distance; stop when far enough (hysteresis)
                    local gain = baseVol * volumeCurve(d)

                    if (d >= STOP_DIST) or (gain <= SILENCE) then
                        stopSession(emitter, musicId)
                    else
                        -- update volume only if it changed enough (avoid spam)
                        if math.abs(gain - (s.lastVol or -1)) > 0.01 then
                            emitter:setVolume(s.sid, gain)
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
            stopSession(emitter, musicId)
        end
    end
end
