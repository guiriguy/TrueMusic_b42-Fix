require "TCMusicDefenitions"

TCM = TCM or {}
if TCM.__world_context_loaded then return end
TCM.__world_context_loaded = true

local function removeAllOptionsByName(context, name)
    if not context or not name then return end
    if context.options then
        for i = #context.options, 1, -1 do
            local option = context.options[i]
            if option and option.name == name then
                if context.removeOptionTsar then
                    context:removeOptionTsar(option)
                elseif context.removeOption then
                    context:removeOption(option)
                else
                    table.remove(context.options, i)
                end
            end
        end
        return
    end

    if context.getOptionFromName and (context.removeOptionTsar or context.removeOption) then
        local option = context:getOptionFromName(name)
        if option then
            if context.removeOptionTsar then context:removeOptionTsar(option) else context:removeOption(option) end
        end
    end
end

local function activateDeviceOptions(playerObj, device)
    if ISTCBoomboxWindow and ISTCBoomboxWindow.activate then
        ISTCBoomboxWindow.activate(playerObj, device)
        return
    end
    if ISRadioWindow and ISRadioWindow.activate then
        ISRadioWindow.activate(playerObj, device, true)
    end
end

local function resolveIsoRadioFromFloorItem(item)
    if not item or not item:getWorldItem() then return nil end
    local square = item:getWorldItem():getSquare()
    if not square then return nil end

    for i = 0, square:getObjects():size() - 1 do
        local object = square:getObjects():get(i)
        if instanceof(object, "IsoRadio") then
            local radioId = object:getModData() and object.getModData().RadioItemID
            if radioId == item:getID() then
                return object
            end
        end
    end
    return nil
end

local function isWalkman(item)
    if not item or not item.getFullType then return false end
    local ft = item:getFullType() or ""
    return (TCMusic and TCMusic.WalkmanPlayer and TCMusic.WalkmanPlayer[ft]) and true or false
end

function TCFillContextMenu(player, context, worldobjects, test)
    if test and ISWorldObjectContextMenu.Test then
        return true
    end

    if getCore():getGameMode() == "LastStand" then
        return
    end

    if test then
        return ISWorldObjectContextMenu.setTest()
    end

    local playerObj = getSpecificPlayer(player);
    if not playerObj then return end
    if playerObj:getVehicle() then return end

    if context.tcmusic_device_options_added then return end

    local deviceOptionText = getText("IGUI_DeviceOptions")

    local option

    for _, wO in ipairs(worldobjects or {}) do
        if wO and instanceof(wO, "IsoRadio") then
            removeAllOptionsByName(context, deviceOptionText)
            option = context:addOptionOnTop(deviceOptionText, playerObj, activateDeviceOptions, wO)
            option.itemForTexture = wO
            --context.tcmusic_device_options_added = true
            return
        end

        if wO and instanceof(wO, "IsoWorldInventoryObject") then
            local item = wO:getItem()
            if item and instanceof(item, "Radio") and not isWalkman(item) then
                local iso = resolveIsoRadioFromFloorItem(item)
                if iso then
                    removeAllOptionsByName(context, deviceOptionText)
                    option = context:addOptionOnTop(deviceOptionText, playerObj, activateDeviceOptions, iso)
                    option.itemForTexture = item
                    --context.tcmusic_device_options_added = true
                end
            end
        end
    end
end

if TCFillContextMenu then
    Events.OnFillWorldObjectContextMenu.Add(TCFillContextMenu);
end
