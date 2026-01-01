require "TCMusicDefenitions"
require "TCM/Patches/DeviceOptionsFinalizer"

ISInventoryMenuElements = ISInventoryMenuElements or {};
TCM = TCM or {}
if TCM and TCM.__inv_context_loaded then return end
TCM.__inv_context_loaded = true

local function removeAllOptionsByName(context, name)
    if not context or not name then return end
    if context.options then
        for i = #context.options, 1, -1 do
            local option = context.options[i]
            TCM.Debug.log("Lets list delete", option.name)
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
        TCM.Debug.log("Lets single delete", name, context:getOptionFromName(name))
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
end

local function unwrapInventoryItem(v)
    if instanceof(v, "InventoryItem") then return v end
    if type(v) == "table" and v.items and v.items[1] and instanceof(v.items[1], "InventoryItem") then
        return v.items[1]
    end
    return nil
end

local function isSupportedPortableRadio(item)
    if not item or not instanceof(item, "Radio") then return false end
    local fullType = item:getFullType() or ""
    local isWalkman = TCMusic and TCMusic.WalkmanPlayer and TCMusic.WalkmanPlayer[fullType] or false
    local isItemPlayer = TCMusic and TCMusic.ItemMusicPlayer and TCMusic.ItemMusicPlayer[fullType] or false
    return isWalkman or isItemPlayer
end

local function resolveIsoRadioFromFloorItem(item)
    if not item or not item:getWorldItem() then return nil end
    local square = item:getWorldItem():getSquare()
    if not square then return nil end

    for i = 0, square:getObjects():size() - 1 do
        local object = square:getObjects():get(i)
        if instanceof(object, "IsoRadio") then
            local radioId = object:getModData() and object:getModData().RadioItemID
            if radioId == item:getID() then
                return object
            end
        end
    end
    return nil
end

Events.OnFillInventoryObjectContextMenu.Add(function(player, context, items)
    if getCore():getGameMode() == "Tutorial" then return end

    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end

    local inv = playerObj:getInventory()

    local function handle(item)
        if not item or not instanceof(item, "Radio") then return end

        local ft = item:getFullType() or ""
        local isWalkman = TCMusic and TCMusic.WalkmanPlayer and TCMusic.WalkmanPlayer[ft]
        local isItemPlayer = TCMusic and TCMusic.ItemMusicPlayer and TCMusic.ItemMusicPlayer[ft]

        if isWalkman or isItemPlayer then
            local inHands =
                (playerObj:getPrimaryHandItem() == item) or
                (playerObj:getSecondaryHandItem() == item) or
                (playerObj.getClothingItem_Back and playerObj:getClothingItem_Back() == item)

            local inInventory = (item:getContainer() == inv)

            if inHands or inInventory then
                TCM.queueDeviceOptionsFix(context, playerObj, item, item)
            end
            return
        end

        -- En suelo: buscamos IsoRadio linkado (RadioItemID)
        local c = item:getContainer()
        if c and c.getType and c:getType() == "floor" and item:getWorldItem() then
            local sq = item:getWorldItem():getSquare()
            if not sq then return end
            for i = 0, sq:getObjects():size() - 1 do
                local obj = sq:getObjects():get(i)
                if instanceof(obj, "IsoRadio") then
                    local md = obj:getModData()
                    if md and md.RadioItemID == item:getID() then
                        TCM.queueDeviceOptionsFix(context, playerObj, obj, item)
                        return
                    end
                end
            end
        end
    end

    local list = (type(items) == "table") and items or { items }
    for _, v in ipairs(list) do
        local it = v
        if not instanceof(v, "InventoryItem") then
            it = (type(v) == "table" and v.items and v.items[1]) or nil
        end
        if it then handle(it) end
    end
end)
