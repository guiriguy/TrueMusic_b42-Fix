require "TCMusicDefenitions"
TCM = TCM or {}
if TCM.__world_context_loaded then return end
TCM.__world_context_loaded = true
function TCFillContextMenu(player, context, worldobjects, test)
    if test and ISWorldObjectContextMenu.Test then
        return true;
    end
    if getCore():getGameMode() == "LastStand" then
        return;
    end
    if test then
        return ISWorldObjectContextMenu.setTest();
    end
    local playerObj = getSpecificPlayer(player);
    if not playerObj then
        return;
    end
    local playerNum = playerObj:getPlayerNum();
    if playerObj:getVehicle() then
        return;
    end
    local squares = {};
    local doneSquare = {};
    for i, v in ipairs(worldobjects or {}) do
        if v and v.getSquare and v:getSquare() and not doneSquare[v:getSquare()] then
            doneSquare[v:getSquare()] = true;
            table.insert(squares, v:getSquare());
        end
    end
    if #squares == 0 then
        return false;
    end
    local worldObjects = {};
    if JoypadState.players[playerNum + 1] then
        for _, square in ipairs(squares) do
            if square and square.getWorldObjects then
                local squareObjects = square:getWorldObjects();
                for i = 1, squareObjects:size() do
                    local worldObject = squareObjects:get(i - 1);
                    if worldObject then
                        table.insert(worldObjects, worldObject);
                    end
                end
            end
        end
    else
        local squares2 = {};
        for k, v in pairs(squares) do
            squares2[k] = v;
        end
        local radius = 1;
        for _, square in ipairs(squares2) do
            if square and context.x and context.y and square.getZ then
                local success, worldX, worldY = pcall(function()
                    return screenToIsoX(playerNum, context.x, context.y, square:getZ()),
                        screenToIsoY(playerNum, context.x, context.y, square:getZ());
                end);
                if success then
                    if ISWorldObjectContextMenu.getSquaresInRadius then
                        ISWorldObjectContextMenu.getSquaresInRadius(worldX, worldY, square:getZ(), radius, doneSquare,
                            squares);
                    end
                end
            end
        end
        for _, square in pairs(squares) do
            if square and square.getWorldObjects then
                local squareObjects = square:getWorldObjects();
                for i = 1, squareObjects:size() do
                    local worldObject = squareObjects:get(i - 1);
                    if worldObject then
                        table.insert(worldObjects, worldObject);
                    end
                end
            end
        end
    end
    if #worldObjects == 0 then
        return false;
    end
    local itemList = {};
    for _, worldObject in ipairs(worldObjects) do
        local itemName = "???";
        if worldObject and instanceof(worldObject, "IsoWorldInventoryObject") then
            local success, name = pcall(function()
                if worldObject.getName and worldObject:getName() then
                    return worldObject:getName();
                elseif worldObject.getItem and worldObject:getItem() and worldObject:getItem().getName and worldObject:getItem():getName() then
                    return worldObject:getItem():getName();
                else
                    return "???";
                end
            end);
            if success then
                itemName = name or "???";
            end
        end
        if not itemList[itemName] then
            itemList[itemName] = {};
        end
        table.insert(itemList[itemName], worldObject);
    end
    for name, items in pairs(itemList) do
        local item = items[1] and items[1].getItem and items[1]:getItem() or nil;
        local square = items[1] and items[1].getSquare and items[1]:getSquare() or nil;
        if item and instanceof(item, "Radio") then
            local itemType = nil;
            local success, typeResult = pcall(function()
                return item.getFullType and item:getFullType() or "";
            end);
            if success then
                itemType = typeResult;
            end
            if TCMusic and TCMusic.WalkmanPlayer and TCMusic.WalkmanPlayer[itemType] then
                if context.getOptionFromName and context:getOptionFromName(getText("IGUI_DeviceOptions")) then
                    local opt = context:getOptionFromName(getText("IGUI_DeviceOptions"));
                    if context.removeOptionTsar then
                        context:removeOptionTsar(opt);
                    elseif context.removeOption then
                        context:removeOption(opt);
                    end
                end
            else
                local obj = nil;
                if square and square.getObjects then
                    local objs = square:getObjects();
                    local itemID = nil;
                    local success, idResult = pcall(function()
                        return item.getID and item:getID() or 0;
                    end);
                    if success then
                        itemID = idResult;
                    end
                    local link = itemID;
                    for i = 0, objs:size() - 1 do
                        local tObj = objs:get(i);
                        if instanceof(tObj, "IsoRadio") then
                            local md = nil;
                            local success, modData = pcall(function()
                                return tObj.getModData and tObj:getModData() or {};
                            end);
                            if success then
                                md = modData;
                            end
                            local radioItemID = md and md.RadioItemID and tonumber(md.RadioItemID) or nil;
                            if radioItemID and radioItemID == link then
                                obj = tObj;
                                break;
                            end
                        end
                    end
                end
                if obj then
                    context:addOptionOnTop(
                        getText("IGUI_DeviceOptions"),
                        playerObj, ISInventoryMenuElements.ContextRadio().createMenu(obj));
                end
            end
        end
    end
end

if TCFillContextMenu then
    Events.OnFillWorldObjectContextMenu.Add(TCFillContextMenu);
end
