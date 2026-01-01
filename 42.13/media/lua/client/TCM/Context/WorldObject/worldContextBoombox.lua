require "TCMusicDefenitions"
require "TCM/Patches/DeviceOptionsFinalizer"

TCM = TCM or {}
if TCM.__world_context_loaded then return end
TCM.__world_context_loaded = true

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

    for _, wO in ipairs(worldobjects or {}) do
        -- Click on radio
        if wO and instanceof(wO, "IsoRadio") then
            TCM.queueDeviceOptionsFix(context, playerObj, wO, nil)
            return
        end

        -- If clicked an item on the floor liked to IsoRadio
        if wO and instanceof(wO, "IsoWorldInventoryObject") then
            local item = wO:getItem()
            if item and instanceof(item, "Radio") and not isWalkman(item) then
                local iso = resolveIsoRadioFromFloorItem(item)
                if iso then
                    TCM.queueDeviceOptionsFix(context, playerObj, iso, item)
                end
            end
        end
    end
end

if TCFillContextMenu then
    Events.OnFillWorldObjectContextMenu.Add(TCFillContextMenu);
end
