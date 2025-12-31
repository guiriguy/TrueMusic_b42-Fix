require "TimedActions/ISBaseTimedAction"
require "TM/State"
require "TM/AudioManager/Sessions"
require "TCMusicClientFunctions"
require "TM/AudioManager/Runtime"
require "TM/Helpers/Power"
require "TM/Helpers/Media"

ISTCBoomboxAction = ISBaseTimedAction:derive("ISTCBoomboxAction")

local function closeSession(self)
    local key = TM.Sessions.keyFromDevice(self.character, self.device, self.deviceData)
    if key then TM.State.removeSession(key) end
end

function ISTCBoomboxAction:actionWhenPlaying()
    -- Disabled legacy: We passed to manage by TM.State + ClientAudio
    return
end

function ISTCBoomboxAction:isValid()
    if self.character and self.device and self.deviceData and self.mode then
        if self["isValid" .. self.mode] then
            return self["isValid" .. self.mode](self);
        end
    end
end

function ISTCBoomboxAction:update()
    if self.character and self.deviceData and self.deviceData:isIsoDevice() then
        self.character:faceThisObject(self.deviceData:getParent())
    end
end

function ISTCBoomboxAction:perform()
    if self.character and self.device and self.deviceData and self.mode then
        if self["perform" .. self.mode] then
            self["perform" .. self.mode](self);
        end
    end
    ISBaseTimedAction.perform(self)
end

-- ToggleOnOff
function ISTCBoomboxAction:isValidToggleOnOff()
    if not self.deviceData then return false end

    --Battery devices
    if self.deviceData:getIsBatteryPowered() then
        return self.deviceData:getPower() > 0
    end

    -- Iso devices
    local ok, powered = pcall(function()
        return self.deviceData:canBePoweredHere()
    end)
    return ok and powered or false
end

function ISTCBoomboxAction:performToggleOnOff()
    if not self:isValidToggleOnOff() then return end

    local tmMusic = self.device:getModData().tcmusic
    if tmMusic and tmMusic.isPlaying then
        tmMusic.isPlaying = false
        closeSession(self)
    end

    self.deviceData:setIsTurnedOn(not self.deviceData:getIsTurnedOn())
end

-- RemoveBattery
function ISTCBoomboxAction:isValidRemoveBattery()
    return self.deviceData:getIsBatteryPowered() and self.deviceData:getHasBattery();
end

function ISTCBoomboxAction:performRemoveBattery()
    if not self:isValidRemoveBattery() then return end

    -- Legacy
    if self.deviceData:getHasBattery() then
        self.deviceData:setIsTurnedOn(not self.deviceData:getIsTurnedOn());
    end
    if self.character:getInventory() then
        self.deviceData:getBattery(self.character:getInventory());
    end

    -- New
    local tmMusic = self.device:getModData().tcmusic
    if tmMusic and tmMusic.deviceType == "InventoryItem" then
        if tmMusic.isPlaying then
            tmMusic.isPlaying = false
            closeSession(self)
        end
    end
end

-- AddBattery
function ISTCBoomboxAction:isValidAddBattery()
    return self.deviceData:getIsBatteryPowered() and self.deviceData:getHasBattery() == false;
end

function ISTCBoomboxAction:performAddBattery()
    if self:isValidAddBattery() and self.secondaryItem then
        self.deviceData:addBattery(self.secondaryItem);
    end
end

-- SetVolume
function ISTCBoomboxAction:isValidSetVolume()
    if not self.secondaryItem or type(self.secondaryItem) ~= "number" or self.secondaryItem < 0 or self.secondaryItem > 1 then
        return false;
    end
    return self.deviceData:getIsTurnedOn() and self.deviceData:getPower() > 0;
end

function ISTCBoomboxAction:performSetVolume()
    if self:isValidSetVolume() then
        self.deviceData:setDeviceVolume(self.secondaryItem)
        if self.device:getModData().tcmusic.deviceType == "InventoryItem" then
            local tcmusicid = self.character:getModData().tcmusicid
            if tcmusicid then
                self.character:getEmitter():setVolume(tcmusicid, self.deviceData:getDeviceVolume() * 0.4)
            end
        elseif self.device:getModData().tcmusic.deviceType == "VehiclePart" then
            -- Громкость контролирует файл TCTickCheckMusic.lua
        else
            local emitter = self.deviceData:getEmitter()
            if emitter then
                self.deviceData:getEmitter():setVolumeAll(self.deviceData:getDeviceVolume() * 0.4)
            end
        end
        self:actionWhenPlaying()
    end
end

-- RemoveHeadphones
function ISTCBoomboxAction:isValidRemoveHeadphones()
    return self.deviceData:getHeadphoneType() >= 0;
end

function ISTCBoomboxAction:performRemoveHeadphones()
    if not self:isValidRemoveHeadphones() then return end

    if self.character:getInventory() then
        self.deviceData:getHeadphones(self.character:getInventory());

        local tcmusicid = self.character:getModData().tcmusic
        if tcmusicid.deviceType == "InventoryItem" and self.device:getFullType() and TCMusic.WalkmanPlayer[self.device:getFullType()] then
            if tcmusicid.isPlaying then
                tcmusicid.isPlaying = false
                closeSession(self)
            end
        end
        --self:actionWhenPlaying()
    end
end

-- AddHeadphones
function ISTCBoomboxAction:isValidAddHeadphones()
    return self.deviceData:getHeadphoneType() < 0;
end

function ISTCBoomboxAction:performAddHeadphones()
    if self:isValidAddHeadphones() and self.secondaryItem then
        self.deviceData:addHeadphones(self.secondaryItem);
        --self:actionWhenPlaying()
    end
end

-- TogglePlayMedia
function ISTCBoomboxAction:isValidTogglePlayMedia()
    if (self.deviceData:getIsTurnedOn() or self.device:getModData().tcmusic.isTurnedOn) and self.device:getModData().tcmusic.mediaItem then
        if self.device:getModData().tcmusic.deviceType == "InventoryItem" and TCMusic.WalkmanPlayer[self.device:getFullType()] and (self.deviceData:getHeadphoneType() < 0) then
            return false
        end
        if not self.device:getModData().tcmusic.needSpeaker or self.device:getModData().tcmusic.connectTo then
            return true
        else
            return false
        end
    end
end

function ISTCBoomboxAction:performTogglePlayMedia()
    if not self:isValidTogglePlayMedia() then return end

    local tmMusic = self.device:getModData().tcmusic
    if not tmMusic or not tmMusic.mediaItem then return end

    local vol = (self.deviceData:getDeviceVolume() or 1.0) * 0.4
    local media = tmMusic.mediaItem

    -- Vehicle code

    if tmMusic.deviceType == "VehiclePart" then
        local veh = self.device:getVehicle()
        if not veh then return end

        local vehID = veh:getId()
        local key = TM.Sessions.keyVehicle(vehID)

        if tmMusic.isPlaying then
            tmMusic.isPlaying = false
            closeSession(self)

            -- Keep legacy server sync command slightly modified
            sendClientCommand(self.character, 'truemusic', 'setMediaItemToVehiclePart', {
                vehicle = vehID, mediaItem = media, isPlaying = false
            })
        else
            tmMusic.isPlaying = true

            -- Speaker session at vehicle position is updated in:
            local pos = { x = veh:getX(), y = veh:getY(), z = veh:getZ() }
            TM.State.setSession(key, TM.Sessions.sessionSpeaker(key, media, vol, pos, TM.State.Const.SPEAKER_MAX_DIST))


            -- Keep legacy server sync command slightly modified
            sendClientCommand(self.character, 'truemusic', 'setMediaItemToVehiclePart', {
                vehicle = vehID, mediaItem = media, isPlaying = true
            })
        end

        return
    end

    -- InHand item code (Boombox/walkman)
    if tmMusic.deviceType == "InventoryItem" then
        local key = TM.Sessions.keyItem(self.device)

        if tmMusic.isPlaying then
            tmMusic.isPlaying = false
            TM.Runtime.DeviceByKey[key] = nil
            TM.State.removeSession(key)
        else
            tmMusic.isPlaying = true
            TM.Runtime.DeviceByKey[key] = self.device

            local hasHeadphones = (self.deviceData:getHeadphoneType() >= 0)
            local isWalkman = (self.device:getFullType() and TCMusic.WalkmanPlayer[self.device:getFullType()]) and true or
                false
            local ownerID = self.character:getOnlineID() or 0

            if hasHeadphones or isWalkman then
                TM.State.setSession(key, TM.Sessions.sessionHeadphones(key, media, vol, ownerID))
            else
                local pos = { x = self.character:getX(), y = self.character:getY(), z = self.character:getZ() }
                TM.State.setSession(key,
                    TM.Sessions.sessionSpeaker(key, media, vol, pos, TM.State.Const.SPEAKER_MAX_DIST))
            end
        end

        return
    end

    --Floored items code
    do
        local key = TM.Sessions.keyWorld(self.device)

        if tmMusic.isPlaying then
            tmMusic.isPlaying = false
            closeSession(self)
        else
            tmMusic.isPlaying = true
            local pos = { x = self.device:getX(), y = self.device:getY(), z = self.device:getZ() }
            TM.State.setSession(key, TM.Sessions.sessionSpeaker(key, media, vol, pos, TM.State.Const.SPEAKER_MAX_DIST))
        end

        self.device:transmitModData()
    end
end

-- AddMedia
function ISTCBoomboxAction:isValidAddMedia()
    if not self.device or not self.secondaryItem then return false end
    local media = self.secondaryItem
    if not media or not media.hasTag then return false end

    local devItem = nil
    local dType = self.device:getModData().tcmusic and self.device:getModData().tcmusic.deviceType

    if dType == "InventoryItem" then
        devItem = self.device
    elseif dType == "VehiclePart" then
        devItem = self.device:getInventoryItem()
    elseif dType == "IsoObject" then
        local tmMusic = self.device:getModData().tcmusic
        if not tmMusic or not tmMusic.playerTag then return false end
        local playerTag = tmMusic.playerTag

        local ok = (playerTag == "truemusic:tm_player_vinyl" and TM.Tags.has(media, "truemusic:tm_media_vinyl"))
            or (playerTag == "truemusic:tm_player_cassette" and TM.Tags.has(media, "truemusic:tm_media_cassette"))
        return ok and (not tmMusic.mediaItem)
    end

    if not devItem or not devItem.hasTag then return false end

    local acceptsVinyl = TM.Tags.has(devItem, "truemusic:tm_player_vinyl")
    local acceptsCassette = TM.Tags.has(devItem, "truemusic:tm_player_cassette")

    local isVinyl = TM.Tags.has(media, "truemusic:tm_media_vinyl")
    local isCassette = TM.Tags.has(media, "truemusic:tm_media_cassette")

    return (not self.device:getModData().tcmusic.mediaItem)
        and ((acceptsVinyl and isVinyl) or (acceptsCassette and isCassette))
end

function ISTCBoomboxAction:performAddMedia()
    if not (self:isValidAddMedia() and self.secondaryItem) then return end

    local inventoryItem = self.secondaryItem
    local container = inventoryItem:getContainer()
    if not container then return end

    if container:getType() == "floor" and inventoryItem:getWorldItem() and inventoryItem:getWorldItem():getSquare() then
        local sq = inventoryItem:getWorldItem():getSquare()
        sq:transmitRemoveItemFromSquare(inventoryItem:getWorldItem())
        sq:getWorldObjects():remove(inventoryItem:getWorldItem())
        sq:getChunk():recalcHashCodeObjects()
        sq:getObjects():remove(inventoryItem:getWorldItem())
        inventoryItem:setWorldItem(nil)
    end

    local mediaType = inventoryItem:getType()
    local mediaFullType = inventoryItem:getFullType()

    local tm = self.device:getModData().tcmusic
    if tm.deviceType == "IsoObject" then
        tm.mediaItem = mediaType
        if self.device.transmitModData then self.device:transmitModData() end
    elseif tm.deviceType == "VehiclePart" then
        sendClientCommand(self.character, "truemusic", "setMediaItemToVehiclePart", {
            vehicle = self.device:getVehicle():getId(),
            mediaItem = mediaType,
            isPlaying = false
        })
    else
        -- InventoryItem device (boombox/walkman/vinyl-as-item)
        tm.mediaItem = mediaType

        if isClient() and self.device.transmitCompleteItemToServer then
            self.device:transmitCompleteItemToServer()
        end
    end

    if not inventoryItem:isInPlayerInventory() then
        container:removeItemOnServer(inventoryItem)
    end
    container:DoRemoveItem(inventoryItem)
end

-- RemoveMedia
function ISTCBoomboxAction:isValidRemoveMedia()
    if self.device:getModData().tcmusic.mediaItem then
        return true
    else
        return false
    end
end

function ISTCBoomboxAction:performRemoveMedia()
    if not self:isValidRemoveMedia() then return end

    local tmMusic = self.device:getModData().tcmusic
    local full = tmMusic.mediaItemFullType or ("Tsarcraft." .. tmMusic.mediaItem)
    local itemTape = instanceItem(full)
    if self.character:getInventory() then
        if itemTape then
            self.character:getInventory():AddItem(itemTape)
        end
        if tmMusic.deviceType == "VehiclePart" then
            if self.device:getVehicle() and self.device:getVehicle():getEmitter() then
                self.device:getVehicle():getEmitter():stopAll()
                closeSession(self)
            end
        else
            local emitter = self.deviceData:getEmitter()
            if emitter then
                self.deviceData:getEmitter():stopAll()
                closeSession(self)
            end
        end
        tmMusic.mediaItem = nil
        tmMusic.mediaItemFullType = nil
        tmMusic.isPlaying = false
        if tmMusic.deviceType == "IsoObject" then
            self.device:transmitModData()
        elseif tmMusic.deviceType == "VehiclePart" then
            sendClientCommand(self.character, 'truemusic', 'setMediaItemToVehiclePart',
                { vehicle = self.device:getVehicle():getId(), mediaItem = "nil", isPlaying = false })
        end
    end
end

function ISTCBoomboxAction:new(mode, character, device, secondaryItem)
    local o = {};
    setmetatable(o, self);
    self.__index = self;
    o.mode = mode;
    o.character = character;
    o.device = device;
    o.deviceData = device and device:getDeviceData();
    o.secondaryItem = secondaryItem;
    o.stopOnWalk = false;
    o.stopOnRun = true;
    o.maxTime = 30;
    return o;
end
