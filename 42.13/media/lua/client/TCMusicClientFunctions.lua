--- @filename TCMusicClientFunctions.lua

require "TCMusicDefenitions"

--- Поиск WO-бумбокса вокруг Item-бумбокса и запись ссылки на него в ModData
-- @param _item - Item-бумбокс
-- @param dx - дельта по x
-- @param dy - дельта по y
-- function TCMusic.searchBoombox (_item, dx, dy)
    -- local square = _item:getWorldItem():getSquare()
    -- if square == nil then return end
    -- for y=square:getY() - dy, square:getY() + dy do
        -- for x=square:getX() - dx, square:getX() + dx do
            -- local square2 = getCell():getGridSquare(x, y, square:getZ())
            -- if square2 ~= nil then
                -- for i=1,square2:getObjects():size() do
                    -- local object = square2:getObjects():get(i-1)
                    -- if instanceof( object, "IsoWaveSignal") then
                        -- local sprite = object:getSprite()
                        -- if sprite ~= nil then
                            -- local name_sprite = object:getSprite():getName()
                            -- if TCMusic.WorldMusicPlayer[name_sprite] == TCMusic.WorldMusicPlayer[_item:getFullType()] then
                                -- if object:getModData().tcmusic and 
                                        -- object:getModData().tcmusic.itemid == 
                                        -- _item:getWorldItem():getSquare():getX() .. 
                                        -- _item:getWorldItem():getSquare():getY() .. 
                                        -- _item:getWorldItem():getSquare():getZ() then
                                    -- -- print("Boombox found!")
                                    -- if not _item:getModData().tcmusic then
                                        -- _item:getModData().tcmusic = {}
                                    -- end
                                    -- _item:getModData().tcmusic.worldObj = object
                                    -- return
                                -- end
                            -- end
                        -- end
                    -- end
                -- end
            -- end
        -- end
    -- end
-- end

-- --- Удаление невидимого WO-бумбокса
function TCMusic.OnObjectAboutToBeRemovedAux(object)
    if instanceof(object, "IsoWorldInventoryObject") then
        -- print("IsoWorldInventoryObject")
        _item = object:getItem()
        if _item and instanceof(_item, "Radio") and TCMusic.WorldMusicPlayer[_item:getFullType()] then
            -- print("search")
            local square = object:getSquare()
            local _obj = nil
            for i=0, square:getObjects():size()-1 do
                local tObj = square:getObjects():get(i)
                if instanceof(tObj, "IsoRadio") then
                    -- print(tObj:getModData().RadioItemID)
                    if tObj:getModData().RadioItemID == _item:getID() .. "tm" then
                        _obj = tObj
                        -- print("obj found")
                        break
                    end
                end
            end
            if _obj ~= nil then
                if _obj:getModData().tcmusic then
                    _item:getModData().tcmusic = _obj:getModData().tcmusic
                    -- print("copy tcmusic")
                else
                    _item:getModData().tcmusic = {}
                    -- print("new tcmusic")
                end
                _item:getModData().tcmusic.isPlaying = false
                _item:getModData().tcmusic.deviceType = "InventoryItem"
                
                local deviceData = _obj:getDeviceData()
                if deviceData then
                    _item:setDeviceData(deviceData)
                end
                _item:getDeviceData():setIsTurnedOn(false)
                sendClientCommand(getPlayer(), 'truemusic', 'deleteWO', { 
                    x = _obj:getX(), 
                    y = _obj:getY(), 
                    z = _obj:getZ(),
                    nameSprite = TCMusic.WorldMusicPlayer[_item:getFullType()],
                })
                -- square:transmitRemoveItemFromSquare(_obj)
                -- square:RecalcProperties();
                -- square:RecalcAllWithNeighbours(true);
            end
        end
    -- TODO обработка случая, если "невидимое" радио было уничтожено
    elseif instanceof(object, "IsoRadio") then
        -- local sprite = object:getSprite()
        -- if sprite ~= nil then
            -- local name_sprite = object:getSprite():getName()
            -- if TCMusic.WorldMusicPlayer[name_sprite] then
                
            -- end
        -- end
    end
end

--- Активация расширенного меню управления звуками
function TCMusic.AdvancedSoundOptions()
    SystemDisabler.setEnableAdvancedSoundOptions(true)
end

function TCMusic.OnObjectAboutToBeRemoved(object)
    TCMusic.OnObjectAboutToBeRemovedAux(object)
end

Events.OnObjectAboutToBeRemoved.Add(TCMusic.OnObjectAboutToBeRemoved)
Events.OnGameBoot.Add(TCMusic.AdvancedSoundOptions)