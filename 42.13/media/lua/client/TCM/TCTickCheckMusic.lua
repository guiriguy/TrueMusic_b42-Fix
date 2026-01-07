-- @filename - TCTickCheckMusic.lua

require "TCM/TCMusicClientFunctions"
require "TM/Config"
require "TCM/Audio/ClientAudio"

local ENABLE_NOWPLAY_LOOP  = true
local ENABLE_LEGACY__WORLD = false

TCM                        = TCM or {}
TCM.Config                 = TCM.Config or TM.Config or {}
if TCM.__tick_music_loaded then return end
TCM.__tick_music_loaded = true

if TCM.Config.DisableTickCheck then
    return
end

local localWoMusicTable = {}
local localPlayerMusicTable = {}
local localVehicleMusicTable = {}
TCM._ended_handheld = TCM._ended_handheld or {}
local ENDED_HANDHELD = TCM._ended_handheld
local ENDED_COOLDOWN = 5 / 3600
local GRACE = 2 / 3600

-- Сокращает количество срабатываний скрипта. Больше число - меньше срабатываний
-- Reduces how often the script runs. Higher value = fewer executions.
local tickControl = 5
local tickStart = 0

local function makeHandheldKey(musicId, msd)
    local startedAt = msd and (msd.startedAt or msd.started_at or 0) or 0
    local itemid = msd and msd.itemid or ""
    local name = msd and msd.musicName or ""
    return tostring(musicId) .. "|" .. tostring(startedAt) .. "|" .. tostring(itemid) .. "|" .. tostring(name)
end

local function TCM_KillVanillaRadioNoise(emitter, isVehicle)
    if not emitter then return end
    if not emitter.stopSoundByName then return end

    -- Objetos / radios en mundo
    emitter:stopSoundByName("RadioStatic")
    emitter:stopSoundByName("RadioTalk")

    -- Vehículos (en algunos builds el “mumble/program” y el “static” van separados)
    if isVehicle then
        emitter:stopSoundByName("VehicleRadioStatic")
        emitter:stopSoundByName("VehicleRadioProgram")
    end
end

-- For SP and Host and MP(?)
local function resolvePlayerByMusicId(musicId)
    local id = tostring(musicId)
    for playerNum = 0, getNumActivePlayers() - 1 do
        local p = getSpecificPlayer(playerNum)
        if p then
            if p:getUsername() == id then return p end
            if p.getOnlineID and tostring(p:getOnlineID()) == id then return p end
            if p.getPlayerNum and tostring(p:getPlayerNum()) == id then return p end
        end
    end
    return nil
end

local function canWriteNowPlay(musicId)
    -- server / host / singleplayer: yes
    if isServer() or (not isClient()) then return true end

    -- cliente MP: Only if it's your own entry (username o onlineID)
    local p = getPlayer()
    if not p then return false end
    local id = tostring(musicId)
    if p:getUsername() == id then return true end
    if p.getOnlineID and tostring(p:getOnlineID()) == id then return true end
    return false
end

function OnRenderTickClientCheckMusic()
    if TCM and TCM.ClientAudio and TCM.ClientAudio.updateFromNowPlay then
        TCM.ClientAudio.updateFromNowPlay(getPlayer())
    end
    tickStart = tickStart + 1
    if tickStart % tickControl == 0 then
        tickStart = 0
        -- Запрашиваем данные с сервера о музыке
        -- Request music state from the server.
        if isClient() then
            ModData.request("trueMusicData")
        end

        -- проверяем играет ли музыка в машинах, рядом с нами
        -- Check if nearby vehicles are playing music.
        local vehicles = getCell():getVehicles()
        for i = 0, vehicles:size() - 1 do
            local vehicle = vehicles:get(i)
            local vehicleRadio = vehicle:getPartById("Radio")
            -- Ищем рядом авто, которые должны играть музыку
            -- Find nearby vehicles that should be playing music.
            if vehicleRadio and vehicleRadio:getModData().tcmusic then
                if vehicleRadio:getModData().tcmusic.mediaItem and
                    vehicleRadio:getModData().tcmusic.isPlaying then
                    -- если найдено
                    -- If found.
                    --vehicle:updateParts(); -- Выполнить обновление деталей, тем самым, вызвав функцию на сервере Vehicle.Update.Radio
                    -- print("updateParts")

                    if not localVehicleMusicTable[vehicle:getSqlId()] then
                        -- если авто нет в локальной таблице, значит музыка не играет. Включаем музыку и записываем авто в таблицу.
                        -- If the vehicle is in the local table, we assume it is playing.
                        local id = vehicle:getEmitter():playSoundImpl(vehicleRadio:getModData().tcmusic.mediaItem,
                            IsoObject.new())
                        local vol = vehicleRadio:getDeviceData():getDeviceVolume()
                        local vol3d = true
                        if vehicle == getPlayer():getVehicle() then -- Если текущий игрок сидит в "играющей" машине для него повышается громкость и выключается 3д-эффект
                            vol = vol * 5
                            vol3d = false
                        elseif vehicleRadio:getModData().tcmusic.windowsOpen then
                            -- Открытые/разбитые окна влияют на громкость музыку и дальность приманивания зомби
                            vol = vol * 3
                        end
                        localVehicleMusicTable[vehicle:getSqlId()] = {
                            obj = vehicle,
                            localmusicid = id,
                            volume = vol,
                        }
                        vehicle:getEmitter():setVolume(localVehicleMusicTable[vehicle:getSqlId()]["localmusicid"],
                            vol / 5)
                        vehicle:getEmitter():set3D(localVehicleMusicTable[vehicle:getSqlId()]["localmusicid"], vol3d)
                    else
                        -- если авто есть в локальной таблице, значит музыка играет

                        if localVehicleMusicTable[vehicle:getSqlId()]["obj"]:getEmitter() and
                            localVehicleMusicTable[vehicle:getSqlId()]["obj"]:getEmitter():isPlaying(localVehicleMusicTable[vehicle:getSqlId()]["localmusicid"]) then
                            -- если музыка играет, продолжаем контролировать громкость и необходимость вкл/выкл 3д-эффекта
                            local vol = vehicleRadio:getDeviceData():getDeviceVolume()
                            if vehicle == getPlayer():getVehicle() then
                                vol = vol * 5
                                vehicle:getEmitter():set3D(localVehicleMusicTable[vehicle:getSqlId()]["localmusicid"],
                                    false)
                            else
                                if vehicleRadio:getModData().tcmusic.windowsOpen then
                                    vol = vol * 3
                                end
                                vehicle:getEmitter():set3D(localVehicleMusicTable[vehicle:getSqlId()]["localmusicid"],
                                    true)
                            end
                            if localVehicleMusicTable[vehicle:getSqlId()]["volume"] ~= vol then
                                vehicle:getEmitter():setVolume(
                                    localVehicleMusicTable[vehicle:getSqlId()]["localmusicid"], vol / 5)
                                localVehicleMusicTable[vehicle:getSqlId()]["volume"] = vol
                            end
                        else
                            -- если музыка перестала играть, отправляем информацию на сервер и очищаем локальную таблицу
                            sendClientCommand(getPlayer(), 'truemusic', 'setMediaItemToVehiclePart',
                                {
                                    vehicle = localVehicleMusicTable[vehicle:getSqlId()]["obj"]:getId(),
                                    mediaItem =
                                        localVehicleMusicTable[vehicle:getSqlId()]["obj"]:getPartById("Radio")
                                        :getModData()
                                        .tcmusic.mediaItem,
                                    isPlaying = false
                                })
                            localVehicleMusicTable[vehicle:getSqlId()] = nil
                        end
                    end
                else
                    if localVehicleMusicTable[vehicle:getSqlId()] then -- авто не должно играть музыка, но оно есть в локальной таблице
                        if localVehicleMusicTable[vehicle:getSqlId()]["obj"] and localVehicleMusicTable[vehicle:getSqlId()]["obj"]:getEmitter() then
                            localVehicleMusicTable[vehicle:getSqlId()]["obj"]:getEmitter():stopSound(
                                localVehicleMusicTable[vehicle:getSqlId()]["localmusicid"])
                        end
                        localVehicleMusicTable[vehicle:getSqlId()] = nil
                    end
                end
            end
        end

        -- пока в локальной таблице есть авто, мы продолжаем их мониторить
        for musicId, musicVehicleData in pairs(localVehicleMusicTable) do
            if not musicVehicleData["obj"] then
                localVehicleMusicTable[musicId] = nil
                -- continue
            else
                if musicVehicleData["obj"]:getPartById("Radio") and
                    musicVehicleData["obj"]:getPartById("Radio"):getModData().tcmusic and
                    musicVehicleData["obj"]:getPartById("Radio"):getModData().tcmusic.mediaItem then
                    -- если авто перестало играть музыку, отправляем информацию на сервер
                    if musicVehicleData["obj"]:getEmitter() and not musicVehicleData["obj"]:getEmitter():isPlaying(musicVehicleData["localmusicid"]) then
                        -- print("VEHICLE STOP MUSIC")
                        -- Из-за команды ниже был баг, когда музыка отключалась для всех, при отдалении одного из игроков
                        -- sendClientCommand(getPlayer(), 'truemusic', 'setMediaItemToVehiclePart', { vehicle = musicVehicleData["obj"]:getId(), mediaItem = musicVehicleData["obj"]:getPartById("Radio"):getModData().tcmusic.mediaItem, isPlaying = false })
                        localVehicleMusicTable[musicId] = nil
                    end
                else
                    musicVehicleData["obj"]:getEmitter():stopSound(musicVehicleData["localmusicid"])
                    localVehicleMusicTable[musicId] = nil
                end
            end
        end

        local musicServerTable = ModData.getOrCreate("trueMusicData")
        if musicServerTable and musicServerTable["now_play"] then
            if ENABLE_NOWPLAY_LOOP then
                for musicId, musicServerData in pairs(musicServerTable["now_play"]) do
                    -- print("IN MODDATA:" .. musicId)
                    local strCoord = tostring(musicId):match("%-?%d+[%-,]%-?%d+[%-,]%-?%d+")

                    -- Автомобильная музыка обрабатывается в коде выше
                    if musicId == "Vehicle" then
                        -- Музыка из мира
                        -- World music (placed devices).
                    elseif strCoord then
                        if ENABLE_LEGACY__WORLD then
                            local musicData = localWoMusicTable
                                [musicId] -- musicId = координаты места где стоит музыкальный проигрыватель

                            -- если проигрывателя нет в локальной таблице, значит музыка не играет. Ищем проигрыватель, включаем музыку и записываем в таблицу.
                            if not (musicData and musicData["obj"]) then
                                local i = string.find(strCoord, "-")
                                local x = tonumber(string.sub(strCoord, 1, i - 1))
                                strCoord = string.sub(strCoord, i + 1)
                                i = string.find(strCoord, "-")
                                local y = tonumber(string.sub(strCoord, 1, i - 1))
                                local z = tonumber(string.sub(strCoord, i + 1))
                                local playerObj = getPlayer()

                                -- если игрок рядом с местом, где играет музыка
                                local isNear = playerObj and
                                    (math.abs(playerObj:getX() - x) <= 60 and math.abs(playerObj:getY() - y) <= 60)
                                if isNear then
                                    local musicSquare = getSquare(x, y, z)
                                    local playerObj = getPlayer()
                                    if musicSquare then
                                        local musicPlayerFound = false
                                        for i = 1, musicSquare:getObjects():size() do
                                            object2 = musicSquare:getObjects():get(i - 1)
                                            if instanceof(object2, "IsoWaveSignal") then
                                                if musicPlayerFound then break end
                                                local sprite = object2:getSprite()
                                                if sprite ~= nil then
                                                    local name_sprite = sprite:getName()
                                                    if TCMusic.WorldMusicPlayer[name_sprite] then
                                                        musicPlayerFound = true
                                                        print("[TCM] localWo entry exists? " ..
                                                            tostring(localWoMusicTable[musicId] ~= nil))
                                                        localWoMusicTable[musicId] = {
                                                            obj = object2,
                                                            volume = object2:getDeviceData():getDeviceVolume()
                                                        }
                                                        print("[TCM] localWo entry now? " ..
                                                            tostring(localWoMusicTable[musicId] ~= nil))
                                                        musicData = localWoMusicTable[musicId]

                                                        local emitter = musicData["obj"]:getDeviceData() and
                                                            musicData["obj"]:getDeviceData():getEmitter()
                                                        if not emitter then break end

                                                        local sid = musicData["localmusicid"]
                                                        local serverName = musicServerData and
                                                            musicServerData.musicName

                                                        -- If server is still reporting the same track, we consider the session valid.
                                                        -- Do NOT re-start just because isPlaying() says false (3D sounds can be virtualized/delayed).
                                                        if musicData.musicName == serverName and musicData.localmusicid then
                                                            -- session exists: only sync volume
                                                            local sid = musicData.localmusicid
                                                            if sid and emitter then
                                                                emitter:setVolume(sid,
                                                                    (musicServerData.volume or 1.0) * 0.4)
                                                            end
                                                        else
                                                            -- stop previous instance only (NOT stopAll)
                                                            if sid then
                                                                emitter:stopSound(sid)
                                                            end

                                                            local media = musicServerData and
                                                                musicServerData["musicName"] or
                                                                nil
                                                            if not media or media == "" then break end

                                                            local newSid = emitter:playSoundImpl(media,
                                                                musicData["obj"])
                                                            musicData["localmusicid"] = newSid
                                                            musicData["musicName"] = media
                                                            musicData["volume"] = (musicServerData and musicServerData["volume"]) or
                                                                musicData["obj"]:getDeviceData():getDeviceVolume()
                                                            -- Store start time: emitter:isPlaying(id) may return false for the first tick after starting.
                                                            musicData["startedAt"] = getGameTime():getWorldAgeHours()

                                                            -- set volume / 3D if we got an id
                                                            if newSid then
                                                                local vol = (musicServerData and musicServerData["volume"] or 1.0) *
                                                                    0.4
                                                                --emitter:setVolume(newSid, vol)
                                                                --emitter:set3D(newSid, true)
                                                            end

                                                            print("[TCM] World start media=" ..
                                                                tostring(media) ..
                                                                " musicId=" ..
                                                                tostring(musicId) .. " sid=" .. tostring(newSid))
                                                            break
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                        -- обработка случае, когда бумбокс уничтожили
                                        -- Handle the case where the boombox/device was destroyed.
                                        if not musicPlayerFound then
                                            if localWoMusicTable[musicId] and localWoMusicTable[musicId].obj then
                                                local e = localWoMusicTable[musicId].obj:getDeviceData() and
                                                    localWoMusicTable[musicId].obj:getDeviceData():getEmitter()
                                                if e then e:stopAll() end
                                                localWoMusicTable[musicId] = nil
                                            end
                                        end
                                    end
                                end

                                -- если проигрыватель есть в локальной таблице
                                -- If the player is in the local table.
                                if musicData then
                                    if musicData and musicData["obj"] then
                                        if musicServerData and musicServerData["musicName"] then
                                            if musicData["obj"]:getDeviceData() and musicData["obj"]:getDeviceData():getEmitter() then
                                                local emitter = musicData["obj"]:getDeviceData():getEmitter()
                                                local sid = musicData["localmusicid"]
                                                local now = getGameTime():getWorldAgeHours()
                                                local startedAt = musicData["startedAt"] or 0
                                                -- Grace period: avoid killing the session immediately after starting (isPlaying(id) may be false for 1-2 ticks).
                                                local grace = 2 / 3600 -- 2 seconds

                                                -- NOTE: emitter:isPlaying(id) can be false for a short time right after start (engine/virtualization).
                                                -- Only treat it as stopped if it stays false after the grace period.
                                                if (not (musicServerData and musicServerData["musicName"])) or (not emitter) or (not sid) then
                                                    if emitter and sid then --emitter:stopSound(sid) end
                                                        localWoMusicTable[musicId] = nil
                                                    elseif (not emitter:isPlaying(sid)) then
                                                        if (now - startedAt) > grace then
                                                            emitter:stopSound(sid)
                                                            localWoMusicTable[musicId] = nil
                                                        else
                                                            -- still within grace period; keep session alive
                                                        end
                                                    else
                                                        if musicData["volume"] ~= musicData["obj"]:getDeviceData():getDeviceVolume() then
                                                            musicData["obj"]:getDeviceData():getEmitter():setVolumeAll(
                                                                musicData
                                                                ["obj"]
                                                                :getDeviceData():getDeviceVolume() * 0.4)
                                                            localWoMusicTable[musicId]["volume"] = musicData["obj"]
                                                                :getDeviceData()
                                                                :getDeviceVolume()
                                                        end
                                                    end
                                                else
                                                    -- print("ERR")
                                                    localWoMusicTable[musicId] = nil
                                                end
                                            else
                                                -- Server no longer reports this entry: stop local sound and forget it
                                                if musicData["obj"]:getDeviceData() and musicData["obj"]:getDeviceData():getEmitter() then
                                                    local emitter = musicData["obj"]:getDeviceData():getEmitter()
                                                    local sid = musicData["localmusicid"]
                                                    if sid then emitter:stopSound(sid) else emitter:stopAll() end
                                                end
                                                localWoMusicTable[musicId] = nil
                                            end
                                        end
                                    end
                                end
                            end
                            -- Музыка "из карманов"
                        end
                    else
                        local player = resolvePlayerByMusicId(musicId)
                        if player and not player:isDead() then
                            local x = player:getX()
                            local y = player:getY()
                            local z = player:getZ()
                            local playerObj = getPlayer()
                            if playerObj then
                                -- разбор случая для локального игрока, у которого в руках играем музыка
                                if playerObj == player then
                                    local musicData = localPlayerMusicTable[musicId]
                                    local inv = playerObj:getInventory()
                                    local itemId = tonumber(musicServerData and musicServerData["itemid"])
                                    local musicplayer = (itemId and inv and inv.getItemById) and
                                        inv:getItemById(itemId) or
                                        nil

                                    -- если игрок выбросил бумбокс, отправляем информацию на сервер
                                    if not musicplayer then
                                        playerObj:getEmitter():stopSound(playerObj:getModData().tcmusicid)
                                        if canWriteNowPlay(musicId) then
                                            ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
                                            if isClient() then ModData.transmit("trueMusicData") end
                                        end
                                        -- если музыка перестала играть, отправляем информацию на сервер
                                    elseif not musicplayer:getModData().tcmusic.mediaItem or
                                        not musicplayer:getDeviceData() or
                                        not musicplayer:getDeviceData():getIsTurnedOn() then
                                        local musicData = localPlayerMusicTable[musicId] or {}
                                        local now = getGameTime():getWorldAgeHours()
                                        local key = makeHandheldKey(musicId, musicServerData)

                                        if musicData.key ~= key then
                                            musicData.key = key
                                            musicData.startedAtLocal = now
                                            localPlayerMusicTable[musicId] = musicData
                                        end

                                        local sid = playerObj:getModData().tcmusicid
                                        if sid and (not playerObj:getEmitter():isPlaying(sid)) then
                                            if (now - (musicData.startedAtLocal or now)) > GRACE then
                                                ENDED_HANDHELD[key] = now
                                                playerObj:getEmitter():stopSound(playerObj:getModData().tcmusicid)
                                                musicplayer:getModData().tcmusic.isPlaying = false
                                                if canWriteNowPlay(musicId) then
                                                    ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
                                                    if isClient() then ModData.transmit("trueMusicData") end
                                                end
                                            end
                                        end
                                    end

                                    -- Анализ остальных игроков, если они в зоне радиуса текущего игрока
                                elseif ((playerObj:getX() >= x - 60 and playerObj:getX() <= x + 60 and
                                        playerObj:getY() >= y - 60 and playerObj:getY() <= y + 60)) then
                                    local musicData = localPlayerMusicTable[musicId]
                                    local musicPlayer = player:getSecondaryHandItem()
                                    -- если игрока с музыкой нет в локальной таблице

                                    if not musicData then
                                        -- проверяем, что проигрыватель всё еще в руках игрока, запускаем музыку, записываем в локальную таблицу
                                        if -- (player:getPrimaryHandItem() and (player:getPrimaryHandItem():getID() == musicServerData["itemid"])) or
                                            (musicPlayer and (musicPlayer:getID() == musicServerData["itemid"])) and
                                            musicPlayer:getDeviceData() and (musicPlayer:getDeviceData():getPower() > 0) then
                                            local id = player:getEmitter():playSoundImpl(
                                                musicServerData["musicName"],
                                                nil)
                                            -- print("MUSIC ID:")
                                            -- print(id)

                                            local koef = 0.4 -- коэффициент отвечающий за наличие наушников
                                            if musicServerData["headphone"] then
                                                koef = 0.02
                                            end
                                            local now = getGameTime():getWorldAgeHours()
                                            local key = makeHandheldKey(musicId, musicServerData)
                                            if ENDED_HANDHELD[key] and (now - ENDED_HANDHELD[key]) < ENDED_COOLDOWN then
                                                -- no reinicies todavía
                                            else
                                                localPlayerMusicTable[musicId] = {
                                                    localmusicid = id,
                                                    volume = musicServerData["volume"] * koef,
                                                    startedAtLocal = now,
                                                    key = key,
                                                }
                                                player:getEmitter():setVolume(
                                                    localPlayerMusicTable[musicId]["localmusicid"],
                                                    musicServerData["volume"] * koef)
                                            end
                                        end
                                    else
                                        -- если игрок в локальной таблице и музыка продолжает играть, контролируем громкость
                                        if player:getEmitter():isPlaying(musicData["localmusicid"]) then
                                            if -- (player:getPrimaryHandItem() and (player:getPrimaryHandItem():getID() == musicServerData["itemid"])) or
                                                (musicPlayer and musicPlayer:getDeviceData() and
                                                    musicPlayer:getDeviceData():getIsTurnedOn() and
                                                    (musicPlayer:getDeviceData():getPower() > 0) and
                                                    (musicPlayer:getID() == musicServerData["itemid"])) then
                                                local koef = 0.4 -- коэффициент отвечающий за наличие наушников
                                                if musicServerData["headphone"] then
                                                    koef = 0.02
                                                end
                                                if musicData["volume"] ~= musicServerData["volume"] * koef then
                                                    player:getEmitter():setVolume(musicData["localmusicid"],
                                                        musicServerData["volume"] * koef)
                                                    musicData["volume"] = musicServerData["volume"] * koef
                                                end

                                                -- если у игрока пропал проигрыватель из рук, отключаем музыку
                                            else
                                                if canWriteNowPlay(musicId) then
                                                    ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
                                                    if isClient() then ModData.transmit("trueMusicData") end
                                                end
                                                player:getEmitter():stopSound(musicData["localmusicid"])
                                                localPlayerMusicTable[musicId] = nil
                                            end

                                            -- если музыка закончилась, отправляем информацию на сервер
                                            if player:getEmitter():isPlaying(musicData["localmusicid"]) then
                                            else
                                                local now = getGameTime():getWorldAgeHours()
                                                local startedAt = musicData.startedAtLocal or now
                                                if (now - startedAt) > GRACE then
                                                    ENDED_HANDHELD[musicData.key or makeHandheldKey(musicId, musicServerData)] =
                                                        now
                                                    player:getEmitter():stopSound(musicData["localmusicid"])
                                                    localPlayerMusicTable[musicId] = nil
                                                    if canWriteNowPlay(musicId) then
                                                        ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
                                                        if isClient() then ModData.transmit("trueMusicData") end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end

                            -- если игрок с музыкой вышел из игры или умер
                        else
                            if player and localPlayerMusicTable[musicId] then
                                player:getEmitter():stopSound(localPlayerMusicTable[musicId]["localmusicid"])
                            end
                            if canWriteNowPlay(musicId) then
                                ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
                                if isClient() then ModData.transmit("trueMusicData") end
                            end
                            localPlayerMusicTable[musicId] = nil
                        end
                    end
                end
            end

            -- очищаем локальные таблицы от "фантомов", о которых не знает сервер
            -- Clean local tables from "ghost" entries no longer present on the server.
            --[[for musicId, musicClientData in pairs(localWoMusicTable) do
            if not ModData.getOrCreate("trueMusicData")["now_play"][musicId] then
                -- print("Must be clear localWoMusicTable")
                if musicClientData["obj"] then
                    if musicClientData["obj"]:getDeviceData() and musicClientData["obj"]:getDeviceData():getEmitter() then
                        musicClientData["obj"]:getDeviceData():getEmitter():stopAll()
                    end
                    if musicClientData["obj"]:getModData() and musicClientData["obj"]:getModData().tcmusic then
                        musicClientData["obj"]:getModData().tcmusic.isPlaying = false
                        if string.match(musicId, '%d*[-]%d*[-]%d*') then
                            musicClientData["obj"]:transmitModData()
                        end
                    end
                end
                localWoMusicTable[musicId] = nil
            end
        end]] --

            --[[for musicId, musicClientData in pairs(localPlayerMusicTable) do
            if not ModData.getOrCreate("trueMusicData")["now_play"][musicId] then
                -- print("Must be clear localPlayerMusicTable")
                local player = nil
                if isClient() then
                    player = getPlayerByOnlineID(musicId)
                else
                    player = getPlayer()
                end
                if player then
                    player:getEmitter():stopSound(musicClientData["localmusicid"])
                    -- print("player stopSound")
                    -- print(musicClientData["localmusicid"])
                end
                localPlayerMusicTable[musicId] = nil
            end
        end]] --
        end
    end
end

function startTrueMusicTick()
    if TCM.__tick_music_started then return end
    TCM.__tick_music_started = true
    Events.OnTick.Add(OnRenderTickClientCheckMusic)
end

Events.OnCreatePlayer.Add(startTrueMusicTick)
