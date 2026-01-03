require "TimedActions/ISBaseTimedAction"
require "TCMusicClientFunctions"
require "TCM/Audio/ClientAudio"

ISTCBoomboxAction = ISBaseTimedAction:derive("ISTCBoomboxAction")

function ISTCBoomboxAction:actionWhenPlaying()
    if self.device:getModData().tcmusic.isPlaying then
        local musicId = nil
        if not (self.device:getModData().tcmusic.deviceType == "VehiclePart") then
            if self.device:getModData().tcmusic.deviceType == "InventoryItem" then
                if isClient() then
                    musicId = self.character:getOnlineID()
                else
                    musicId = self.character:getUsername()
                end
            else
                musicId = "#" .. self.device:getX() .. "-" .. self.device:getY() .. "-" .. self.device:getZ()
            end
            ModData.getOrCreate("trueMusicData")["now_play"][musicId] = {
                volume = self.deviceData:getDeviceVolume(),
                headphone = self.deviceData:getHeadphoneType() >= 0,
                timestamp = "update",
                musicName = self.device:getModData().tcmusic.mediaItem,
            }
            if self.device:getModData().tcmusic.deviceType == "InventoryItem" then
                ModData.getOrCreate("trueMusicData")["now_play"][musicId]["itemid"] = self.device:getID()
            end
            if isClient() then ModData.transmit("trueMusicData") end
        end
    end
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
    return self.deviceData:getIsBatteryPowered() and self.deviceData:getPower() > 0 or self.deviceData:canBePoweredHere();
end

function ISTCBoomboxAction:performToggleOnOff()
    if self:isValidToggleOnOff() then
        if self.device:getModData().tcmusic and (self.device:getModData().tcmusic.deviceType == "VehiclePart") then
            sendClientCommand(self.character, 'truemusic', 'setMediaItemToVehiclePart',
                { vehicle = self.device:getVehicle():getId(), mediaItem = self.device:getModData().tcmusic.mediaItem, isPlaying = false })
        end
        if self.device:getModData().tcmusic.deviceType == "InventoryItem" then
            if self.device:getModData().tcmusic.isPlaying then
                self.device:getModData().tcmusic.isPlaying = false
                self.character:getEmitter():stopSound(self.character:getModData().tcmusicid)
                local musicId = isClient() and self.character:getOnlineID() or self.character:getUsername()
                ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
            end
        end
        self.deviceData:setIsTurnedOn(not self.deviceData:getIsTurnedOn());
    end
end

-- RemoveBattery
function ISTCBoomboxAction:isValidRemoveBattery()
    return self.deviceData:getIsBatteryPowered() and self.deviceData:getHasBattery();
end

function ISTCBoomboxAction:performRemoveBattery()
    if self.deviceData:getHasBattery() then
        self.deviceData:setIsTurnedOn(not self.deviceData:getIsTurnedOn());
    end
    if self:isValidRemoveBattery() and self.character:getInventory() then
        self.deviceData:getBattery(self.character:getInventory());
    end
    if self.device:getModData().tcmusic.deviceType == "InventoryItem" then
        if self.device:getModData().tcmusic.isPlaying then
            self.device:getModData().tcmusic.isPlaying = false
            self.character:getEmitter():stopSound(self.character:getModData().tcmusicid)
            local musicId = isClient() and self.character:getOnlineID() or self.character:getUsername()
            ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
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
    if self:isValidRemoveHeadphones() and self.character:getInventory() then
        self.deviceData:getHeadphones(self.character:getInventory());
        if self.device:getModData().tcmusic.deviceType == "InventoryItem" and self.device:getFullType() and TCMusic.WalkmanPlayer[self.device:getFullType()] then
            if self.device:getModData().tcmusic.isPlaying then
                self.device:getModData().tcmusic.isPlaying = false
                self.character:getEmitter():stopSound(self.character:getModData().tcmusicid)
                local musicId = isClient() and self.character:getOnlineID() or self.character:getUsername()
                ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
            end
        end
        self:actionWhenPlaying()
    end
end

-- AddHeadphones
function ISTCBoomboxAction:isValidAddHeadphones()
    return self.deviceData:getHeadphoneType() < 0;
end

function ISTCBoomboxAction:performAddHeadphones()
    if self:isValidAddHeadphones() and self.secondaryItem then
        self.deviceData:addHeadphones(self.secondaryItem);
        self:actionWhenPlaying()
    end
end

-- TogglePlayMedia
function ISTCBoomboxAction:isValidTogglePlayMedia()
    if self.deviceData:getIsTurnedOn() and self.device:getModData().tcmusic.mediaItem then
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
    if self:isValidTogglePlayMedia() then
        if isClient() then
            -- ModData.request("trueMusicData")
        end
        local now = getGameTime():getWorldAgeHours()
        self._lastPlayToggle = self._lastPlayToggle or 0
        if (now - self._lastPlayToggle) < (0.3 / 3600) then
            return
        end
        self._lastPlayToggle = now
        if self.device:getModData().tcmusic.deviceType == "VehiclePart" then
            if self.device:getModData().tcmusic.isPlaying then
                self.device:getVehicle():getEmitter():stopAll()
                sendClientCommand(self.character, 'truemusic', 'setMediaItemToVehiclePart',
                    { vehicle = self.device:getVehicle():getId(), mediaItem = self.device:getModData().tcmusic.mediaItem, isPlaying = false })
            elseif self.device:getVehicle():getEmitter() then
                getSoundManager():StopMusic()
                self.deviceData:setChannelRaw(100)
                sendClientCommand(self.character, 'truemusic', 'setMediaItemToVehiclePart',
                    { vehicle = self.device:getVehicle():getId(), mediaItem = self.device:getModData().tcmusic.mediaItem, isPlaying = true })
            end
        elseif self.device:getModData().tcmusic.deviceType == "InventoryItem" then
            local musicId = nil
            if isClient() then
                musicId = self.character:getOnlineID()
            else
                musicId = self.character:getUsername()
            end
            if self.device:getModData().tcmusic.isPlaying then
                self.device:getModData().tcmusic.isPlaying = false
                if self.character:getModData().tcmusicid then
                    self.character:getEmitter():stopSound(self.character:getModData().tcmusicid)
                    self.character:getModData().tcmusicid = nil
                end
                ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
            else
                getSoundManager():StopMusic()
                self.device:getModData().tcmusic.isPlaying = true
                if self.character:getModData().tcmusicid then
                    self.character:getEmitter():stopSound(self.character:getModData().tcmusicid)
                end
                self.character:getModData().tcmusicid = self.character:getEmitter():playSoundImpl(
                    self.device:getModData().tcmusic.mediaItem, nil)
                self.character:getEmitter():setVolume(self.character:getModData().tcmusicid,
                    self.deviceData:getDeviceVolume() * 0.4)
                ModData.getOrCreate("trueMusicData")["now_play"][musicId] = {
                    volume = self.deviceData:getDeviceVolume(),
                    headphone = self.deviceData:getHeadphoneType() >= 0,
                    timestamp = "update",
                    musicName = self.device:getModData().tcmusic.mediaItem,
                    startedAt = os.time() * 1000,
                }
                if self.device:getModData().tcmusic.deviceType == "InventoryItem" then
                    ModData.getOrCreate("trueMusicData")["now_play"][musicId]["itemid"] = self.device:getID()
                end
            end
        else
            local musicId = nil
            musicId = "#" .. self.device:getX() .. "-" .. self.device:getY() .. "-" .. self.device:getZ()
            if self.device:getModData().tcmusic.isPlaying then
                self.device:getModData().tcmusic.isPlaying = false
                local emitter = self.deviceData:getEmitter()
                if emitter then
                    self.deviceData:getEmitter():stopAll()
                end
                ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
            else
                getSoundManager():StopMusic()
                self.device:getModData().tcmusic.isPlaying = true
                local emitter = self.deviceData:getEmitter()
                if emitter then
                    self.deviceData:getEmitter():stopAll()
                    self.deviceData:setNoTransmit(false)
                    --self.deviceData:playSound(self.device:getModData().tcmusic.mediaItem,
                    --self.deviceData:getDeviceVolume() * 0.4, false)
                end
                ModData.getOrCreate("trueMusicData")["now_play"][musicId] = {
                    volume = self.deviceData:getDeviceVolume(),
                    headphone = self.deviceData:getHeadphoneType() >= 0,
                    timestamp = "update",
                    musicName = self.device:getModData().tcmusic.mediaItem,
                    startedAt = os.time() * 1000,
                }
                if self.device:getModData().tcmusic.deviceType == "InventoryItem" then
                    ModData.getOrCreate("trueMusicData")["now_play"][musicId]["itemid"] = self.device:getID()
                end
            end
            self.device:transmitModData()
        end
        if isClient() then ModData.transmit("trueMusicData") end
    end
end

-- AddMedia
function ISTCBoomboxAction:isValidAddMedia()
    local musicPlayer = nil
    if self.device:getModData().tcmusic.deviceType == "InventoryItem" then
        musicPlayer = TCMusic.ItemMusicPlayer[self.device:getFullType()] or
            TCMusic.WalkmanPlayer[self.device:getFullType()]
    elseif self.device:getModData().tcmusic.deviceType == "IsoObject" then
        musicPlayer = TCMusic.WorldMusicPlayer[self.device:getSprite():getName()]
    elseif self.device:getModData().tcmusic.deviceType == "VehiclePart" then
        musicPlayer = TCMusic.VehicleMusicPlayer[self.device:getInventoryItem():getFullType()]
    end
    if self.secondaryItem then
        local music = self.secondaryItem:getType()
        return (not self.device:getModData().tcmusic.mediaItem) and GlobalMusic[music] and
            musicPlayer == GlobalMusic[music];
    end
end

function ISTCBoomboxAction:performAddMedia()
    if self:isValidAddMedia() and self.secondaryItem then
        local inventoryItem = self.secondaryItem
        local container = self.secondaryItem:getContainer()
        if container then
            if (container:getType() == "floor" and inventoryItem:getWorldItem() and inventoryItem:getWorldItem():getSquare()) then
                inventoryItem:getWorldItem():getSquare():transmitRemoveItemFromSquare(inventoryItem:getWorldItem());
                inventoryItem:getWorldItem():getSquare():getWorldObjects():remove(inventoryItem:getWorldItem());
                inventoryItem:getWorldItem():getSquare():getChunk():recalcHashCodeObjects();
                inventoryItem:getWorldItem():getSquare():getObjects():remove(inventoryItem:getWorldItem());
                inventoryItem:setWorldItem(nil);
            end
            if self.device:getModData().tcmusic.deviceType == "IsoObject" then
                self.device:getModData().tcmusic.mediaItem = inventoryItem:getType();
                self.device:transmitModData()
            elseif self.device:getModData().tcmusic.deviceType == "VehiclePart" then
                local mediaItemName = inventoryItem:getType()
                sendClientCommand(self.character, 'truemusic', 'setMediaItemToVehiclePart',
                    { vehicle = self.device:getVehicle():getId(), mediaItem = mediaItemName, isPlaying = false })
            else
                self.device:getModData().tcmusic.mediaItem = inventoryItem:getType();
            end
            if not inventoryItem:isInPlayerInventory() then
                container:removeItemOnServer(inventoryItem)
            end
            container:DoRemoveItem(inventoryItem);
        end
    end
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
    if self:isValidRemoveMedia() and self.character:getInventory() then
        local itemTape = instanceItem("Tsarcraft." .. self.device:getModData().tcmusic.mediaItem)
        if itemTape then
            self.character:getInventory():AddItem(itemTape)
        end
        if self.device:getModData().tcmusic.deviceType == "VehiclePart" then
            if self.device:getVehicle() and self.device:getVehicle():getEmitter() then
                self.device:getVehicle():getEmitter():stopAll()
            end
        else
            local emitter = self.deviceData:getEmitter()
            if emitter then
                self.deviceData:getEmitter():stopAll()
            end
        end
        self.device:getModData().tcmusic.mediaItem = nil
        self.device:getModData().tcmusic.isPlaying = false
        if self.device:getModData().tcmusic.deviceType == "IsoObject" then
            self.device:transmitModData()
        elseif self.device:getModData().tcmusic.deviceType == "VehiclePart" then
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
