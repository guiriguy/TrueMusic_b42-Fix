require "TM/Helpers/Devices"
require "ISTCBoomboxWindow"
require "TCMusicClientFunctions"

TM = TM or {}
TM.UI = TM.UI or {}
TM.UI.ContextMenu = TM.UI.ContextMenu or {}

local function unwrapInventoryMenyEntry(v)
    if instanceof(v, "InventoryItem") then return v end
    if type(v) == "table" and v.items and v.items[1] and instanceof(v.items[1], "InventoryItem") then
        return v.items[1]
    end
    return nil
end

local function removeExistingDeviceOptions(context)
    if not context or not context.options then return end
    local text = getText("IGUI_DeviceOptions")
    local option = context:getOptionFromName(text)

    if context.removeOptionTsar then context:removeOptionTsar(option) end
    if context.removeOption then context:removeOption(option) end
end
--Vinyl functionality
local function findOurWaveSignalOnSquare(square)
    if not square then return nil end
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local o = objects:get(i)
        if instanceof(o, "IsoWaveSignal") then
            local sprite = o:getSprite()
            if sprite and TCMusic and TCMusic.WorldMusicPlayer and TCMusic.WorldMusicPlayer[sprite:getName()] then
                return o
            end
        end
    end
    return nil
end
local function openDeviceOptions(playerObj, worldObj, invItem)
    if invItem and TM.Devices.isVinylPlayer(invItem) then
        local square = nil
        if worldObj and worldObj.getSquare then square = worldObj:getSquare() end
        if (not square) and invItem.getWorldItem and invItem:getWorldItem() and invItem:getWorldItem():getSquare() then
            square = invItem:getWorldItem():getSquare()
        end

        local wave = findOurWaveSignalOnSquare(square)
        if wave then
            ISTCBoomboxWindow.activate(playerObj, wave)
            return
        end
    end

    ISTCBoomboxWindow.activate(playerObj, invItem)
end

local function addDeviceOptions(context, playerObj, invItem, worldObj)
    removeExistingDeviceOptions(context)
    local label = getText("IGUI_DeviceOptions")
    local myOption = context:addOptionOnTop(label, playerObj, function()
        openDeviceOptions(playerObj, worldObj, invItem)
    end)
    myOption.itemForTexture = invItem
end

--Inventory context (ONLY if in hands)
local function onFillInventory(playerNum, context, items)
    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj or not context or not items then return end

    local didAdd = false
    local function tryAdd(item)
        if not item then return end
        if item ~= playerObj:getPrimaryHandItem() and item ~= playerObj:getSecondaryHandItem() then
            return false
        end
        if TM.Devices.isOurDevice(item) and TM.Devices.canOpenUI(playerObj, item) then
            addDeviceOptions(context, playerObj, item)
            return true
        end
        return false
    end

    -- Single case
    if instanceof(items, "InventoryItem") then
        didAdd = tryAdd(items)
    else
        for _, v in ipairs(items) do
            local item = unwrapInventoryMenyEntry(v)
            if tryAdd(item) then
                didAdd = true; break
            end
        end
    end

    if didAdd then return end

    if not didAdd then
        local primary = playerObj:getPrimaryHandItem()
        if TM.Devices.isOurDevice(primary) and TM.Devices.canOpenUI(playerObj, primary) then
            addDeviceOptions(context, playerObj, primary)
            return
        end
        local secondary = playerObj:getSecondaryHandItem()
        if TM.Devices.isOurDevice(secondary) and TM.Devices.canOpenUI(playerObj, secondary) then
            addDeviceOptions(context, playerObj, secondary)
            return
        end
    end
end

--World Objects (On the ground)
local function onFillWorld(playerNum, context, worldObjects)
    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj or not context or not worldObjects then return end

    for i = 1, #worldObjects do
        local wO = worldObjects[i]
        if wO and wO.getItem then
            local item = wO:getItem()
            -- Dropped boombox/walkman is still and InventoryItem (Radio)
            if item and TM.Devices.isOurDevice(item) then
                addDeviceOptions(context, playerObj, item, wO)
                return
            end
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(onFillInventory)
Events.OnFillWorldObjectContextMenu.Add(onFillWorld)
