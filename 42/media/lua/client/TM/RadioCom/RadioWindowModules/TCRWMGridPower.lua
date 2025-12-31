require "RadioCom/RadioWindowModules/RWMPanel"
require "TM/Helpers/Power"
require "TM/Helpers/Devices"

TCRWMGridPower = RWMPanel:derive("TCRWMGridPower");

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

function TCRWMGridPower:initialise()
    ISPanel.initialise(self)
end

function TCRWMGridPower:createChildren()
    self:setHeight(32);

    local xoff = 0;

    self.led = ISLedLight:new(10, (self.height - 10) / 2, 10, 10);
    self.led:initialise();
    self.led:setLedColor(1, 0, 1, 0);
    self.led:setLedColorOff(1, 0, 0.3, 0);
    self:addChild(self.led);

    xoff = self.led:getX() + self.led:getWidth();

    local buttonW = getTextManager():MeasureStringX(UIFont.Small, getText("ContextMenu_Turn_Off")) + 10;
    self.toggleOnOffButton = ISButton:new(xoff + 10, 4, buttonW, self.height - 8, getText("ContextMenu_Turn_On"), self,
        TCRWMGridPower.toggleOnOff);
    self.toggleOnOffButton:initialise();
    self.toggleOnOffButton.backgroundColor = { r = 0, g = 0, b = 0, a = 0.0 };
    self.toggleOnOffButton.backgroundColorMouseOver = { r = 1.0, g = 1.0, b = 1.0, a = 0.1 };
    self.toggleOnOffButton.borderColor = { r = 1.0, g = 1.0, b = 1.0, a = 0.3 };
    self:addChild(self.toggleOnOffButton);
end

function TCRWMGridPower:toggleOnOff()
    if self:doWalkTo() then
        ISTimedActionQueue.add(ISTCBoomboxAction:new("ToggleOnOff", self.player, self.device));
    end
end

function TCRWMGridPower:clear()
    RWMPanel.clear(self);
end

function TCRWMGridPower:readFromObject(_player, _deviceObject, _deviceData, _deviceType)
    self.player = _player
    self.device = _deviceObject
    self.deviceData = _deviceData
    self.deviceType = _deviceType
    self.square = nil

    if not _deviceData then return false end
    -- Return if batterybased item
    if _deviceData:getIsBatteryPowered() then return false end

    --InventoryItem (vinyl on ground): Allow GridPower if the square is eletrifying

    if _deviceType == "InventoryItem" then
        local wI = _deviceObject and _deviceObject.getWorldItem and _deviceObject:getWorldItem()
        local square = wI and wI.getSquare and wI:getSquare()
        if not square then return false end
        self.square = square
        return true
    end

    if _deviceObject and _deviceObject.getSquare and not _deviceObject:getSquare() then
        return false
    end

    return true
end

local function isItemWorld(deviceType, device, deviceData)
    if deviceType ~= "InventoryItem" then return false end
    if not device or not device.getWorldItem then return false end
    local wI = device:getWorldItem()
    if not wI or not wI.getSquare or not wI:getSquare() then return false end
    if deviceData and deviceData.getSquare and deviceData:getSquare() then return false end
    return true
end

local function getEmulatedIsOn(device)
    local tmMusic = device and device.getModData and device:getModData()
    local getTM = tmMusic and tmMusic.tcmusic
    return getTM and getTM.isTurnedOn == true
end

function TCRWMGridPower:update()
    ISPanel.update(self);

    if not (self.player and self.device and self.deviceData) then return end

    local isOn
    if isItemWorld(self.deviceType, self.device, self.deviceData) then
        isOn = getEmulatedIsOn(self.device)
    else
        isOn = self.deviceData:getIsTurnedOn()
    end

    self.led:setLedIsOn(isOn)
    self.toggleOnOffButton:setTitle(isOn and getText("ContextMenu_Turn_Off") or getText("ContextMenu_Turn_On"))
end

function TCRWMGridPower:prerender()
    ISPanel.prerender(self);
end

function TCRWMGridPower:render()
    ISPanel.render(self)
    if not self.deviceData then return end

    local powered = TM.Power.canPowerDeviceUI(self.deviceData, self.device, self.deviceType)

    local x = self.toggleOnOffButton:getX() + self.toggleOnOffButton:getWidth() + 5
    local y = (self.height - FONT_HGT_SMALL) / 2
    if powered then
        self:drawText(getText("IGUI_RadioPowerNearby"), x, y, 0, 1, 0, 1, UIFont.Small)
    else
        self:drawText(getText("IGUI_RadioRequiresPowerNearby"), x, y, 1, 0, 0, 1, UIFont.Small)
    end
end

function TCRWMGridPower:onJoypadDown(button)
    if button == Joypad.AButton then
        self:toggleOnOff()
    end
end

function TCRWMGridPower:getAPrompt()
    local isOn
    if isItemWorld(self.deviceType, self.device, self.deviceData) then
        isOn = getEmulatedIsOn(self.device)
    else
        isOn = self.deviceData:getIsTurnedOn()
    end

    return isOn and getText("ContextMenu_Turn_Off") or getText("ContextMenu_Turn_On")
end

function TCRWMGridPower:getBPrompt()
    return nil;
end

function TCRWMGridPower:getXPrompt()
    return nil;
end

function TCRWMGridPower:getYPrompt()
    return nil;
end

function TCRWMGridPower:new(x, y, width, height)
    local o = RWMPanel:new(x, y, width, height);
    setmetatable(o, self)
    self.__index = self
    o.x = x;
    o.y = y;
    o.background = true;
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.0 };
    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 };
    o.width = width;
    o.height = height;
    o.anchorLeft = true;
    o.anchorRight = false;
    o.anchorTop = true;
    o.anchorBottom = false;
    return o
end
