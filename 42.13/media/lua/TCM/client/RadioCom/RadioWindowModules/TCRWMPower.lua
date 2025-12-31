--***********************************************************
--**                    THE INDIE STONE                    **
--**				  Author: turbotutone				   **
--***********************************************************
require "RadioCom/RadioWindowModules/RWMPanel"

TCRWMPower = RWMPanel:derive("TCRWMPower");

function TCRWMPower:initialise()
    ISPanel.initialise(self)
end

function TCRWMPower:createChildren()
    self:setHeight(32);

    local xoff = 0;

    self.led = ISLedLight:new (10, (self.height-10)/2, 10, 10);
    self.led:initialise();
    self.led:setLedColor( 1, 0, 1, 0 );
    self.led:setLedColorOff( 1, 0, 0.3, 0 );
    self:addChild(self.led);

    xoff = self.led:getX() + self.led:getWidth();

    local buttonW = getTextManager():MeasureStringX(UIFont.Small, getText("ContextMenu_Turn_Off"))+10;
    self.toggleOnOffButton = ISButton:new(xoff+10, 4, buttonW,self.height-8,getText("ContextMenu_Turn_On"),self, TCRWMPower.toggleOnOff);
    self.toggleOnOffButton:initialise();
    self.toggleOnOffButton.backgroundColor = {r=0, g=0, b=0, a=0.0};
    self.toggleOnOffButton.backgroundColorMouseOver = {r=1.0, g=1.0, b=1.0, a=0.1};
    self.toggleOnOffButton.borderColor = {r=1.0, g=1.0, b=1.0, a=0.3};
    self:addChild(self.toggleOnOffButton);

    xoff = xoff + (self.toggleOnOffButton:getX()-xoff) + self.toggleOnOffButton:getWidth();

    self.itemDropBox = ISItemDropBox:new (xoff+10, 4, self.height-8, self.height-8, false, self, TCRWMPower.addBattery, TCRWMPower.removeBattery, TCRWMPower.verifyItem, nil );
    self.itemDropBox:initialise();
    self.itemDropBox:setBackDropTex( getTexture("Item_Battery"), 0.4, 1,1,1 );
    self.itemDropBox:setDoBackDropTex( true );
    self.itemDropBox:setToolTip( true, getText("IGUI_RadioDragBattery") );
    self:addChild(self.itemDropBox);

    xoff = xoff + (self.itemDropBox:getX()-xoff) + self.itemDropBox:getWidth();

    self.batteryStatus = ISBatteryStatusDisplay:new ( xoff+10, 4, self.width-(20+ xoff), self.height-8, true);
    self.batteryStatus:initialise();
    self:addChild(self.batteryStatus);
end

function TCRWMPower:toggleOnOff()
-- print("toggleOnOff")
    if self:doWalkTo() then
        ISTimedActionQueue.add(ISTCBoomboxAction:new("ToggleOnOff",self.player, self.device ));
    end
end

function TCRWMPower:removeBattery()
    if self:doWalkTo() then
        ISTimedActionQueue.add(ISTCBoomboxAction:new("RemoveBattery",self.player, self.device ));
    end
end

function TCRWMPower:addBattery( _items )
    local item;
    local pbuff = 0;

    for _,i in ipairs(_items) do
        if i:getCurrentUsesFloat() > pbuff then
            item = i;
            pbuff = i:getCurrentUsesFloat()
        end
    end

    if item then
        if self:doWalkTo() then
            ISTimedActionQueue.add(ISRadioAction:new("AddBattery",self.player, self.device, item ));
        end
    end
end

function TCRWMPower:verifyItem( _item )
    if _item:getFullType() == "Base.Battery" then
        return true;
    end
end

function TCRWMPower:clear()
    RWMPanel.clear(self);
end

function TCRWMPower:readFromObject( _player, _deviceObject, _deviceData, _deviceType )
    if _deviceData:getIsBatteryPowered()==false then
        return false;
    end
    local read =  RWMPanel.readFromObject(self, _player, _deviceObject, _deviceData, _deviceType );

    if self.player then
        self.itemDropBox.mouseEnabled = true;
        if JoypadState.players[self.player:getPlayerNum()+1] then
            self.itemDropBox.mouseEnabled = false;
        end
    end

    return read;
end

local updCntr = 0;
function TCRWMPower:powerUpdateSimulation()
    updCntr = updCntr + 1;
    if updCntr > 20 then
        local pwr = self.deviceData:getPower();
        pwr = pwr - 0.01;
        if pwr < 0 then pwr = 0 end
        self.deviceData:setPower(pwr);
        updCntr = 0;
    end
end

function TCRWMPower:update()
    ISPanel.update(self);

    if self.player and self.device and self.deviceData then
        local isOn = self.deviceData:getIsTurnedOn();
        self.led:setLedIsOn(isOn);

        if isOn then
            self.toggleOnOffButton:setTitle(getText("ContextMenu_Turn_Off"));
        else
            self.toggleOnOffButton:setTitle(getText("ContextMenu_Turn_On"));
        end

        --if isOn then
            --self:powerUpdateSimulation();                               --FIXME remove testing thing -----------------------------------<<<
        --end
        self.batteryStatus:setPower( self.deviceData:getPower() );

        if self.deviceData:getHasBattery() then
            self.itemDropBox:setStoredItemFake( self.batteryTex );
        else
            self.itemDropBox:setStoredItemFake( nil );
        end
    end
end

function TCRWMPower:prerender()
    ISPanel.prerender(self);
end


function TCRWMPower:render()
    ISPanel.render(self);
    --if self.batteryTex then
        --self:drawTextureScaled(self.batteryTex, (10+self.removeBatButton:getWidth()+5)+2, 4+2, self:getHeight()-8-4, self:getHeight()-8-4, 1.0, 1.0, 1.0, 1.0);

        --local c = self.borderColor;
        --self:drawRectBorder(10+self.removeBatButton:getWidth()+5, 4, self:getHeight()-8, self:getHeight()-8, c.a, c.r, c.g, c.b);
    --end
end

function TCRWMPower:onJoypadDown(button)
    if button == Joypad.AButton then
        self:toggleOnOff()
    elseif button == Joypad.BButton then
        if self.deviceData:getHasBattery() then
            self:removeBattery();
        else
            local inventory = self.player:getInventory();
            local list = inventory:FindAll("Base.Battery");
            if list and list:size()>0 then
                local batTable = {};
                for i=0,list:size()-1 do
                    table.insert(batTable, list:get(i));
                end
                self:addBattery( batTable );
            end
        end
    end
end

function TCRWMPower:getAPrompt()
    if self.deviceData:getIsTurnedOn() then
        return getText("ContextMenu_Turn_Off");
    else
        return getText("ContextMenu_Turn_On");
    end
end
function TCRWMPower:getBPrompt()
    if self.deviceData:getHasBattery() then
        return getText("ContextMenu_Remove_Battery");
    else
        local inventory = self.player:getInventory();
        local list = inventory:FindAll("Base.Battery");
        if list and list:size()>0 then
            return getText("ContextMenu_AddBattery");
        end
    end
    return nil;
end
function TCRWMPower:getXPrompt()
    return nil;
end
function TCRWMPower:getYPrompt()
    return nil;
end


function TCRWMPower:new (x, y, width, height)
    local o = RWMPanel:new(x, y, width, height);
    setmetatable(o, self)
    self.__index = self
    o.x = x;
    o.y = y;
    o.background = true;
    o.backgroundColor = {r=0, g=0, b=0, a=0.0};
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1};
    o.width = width;
    o.height = height;
    o.anchorLeft = true;
    o.anchorRight = false;
    o.anchorTop = true;
    o.anchorBottom = false;
    o.fontheight = getTextManager():MeasureStringY(UIFont.Small, "AbdfghijklpqtyZ")+2;
    o.batteryTex = getTexture("Item_Battery");
    return o
end

