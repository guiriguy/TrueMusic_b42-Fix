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

local function findLinkedFloorItemForIsoRadio(isoRadio)
    if not isoRadio then return nil end
    local md = isoRadio:getModData()
    local rid = md and md.RadioItemID
    if not rid then return nil end

    local square = isoRadio:getSquare()
    if not square then return nil end

    for i = 0, square:getObjects():size() - 1 do
        local obj = square:getObjects():get(i)
        if instanceof(obj, "IsoWorldInventoryObject") then
            local it = obj:getItem()
            if it and it:getID() == rid then
                return it
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

    local isoRadios = {}
    local floorItems = {}

    for _, wO in ipairs(worldobjects or {}) do
        if wO and instanceof(wO, "IsoRadio") then
            table.insert(isoRadios, wO)
        elseif wO and instanceof(wO, "IsoWorldInventoryObject") then
            local invItem = wO:getItem()
            if invItem then table.insert(floorItems, invItem) end
            return
        end
    end

    -- 1) Priority: IsoRadio that has RadioItemID and we can link to the item on the floor
    for _, iso in ipairs(isoRadios) do
        local linked = findLinkedFloorItemForIsoRadio(iso)
        if linked then
            TCM.queueDeviceOptionsFix(context, playerObj, iso, linked)
        end
    end

    -- 2) Fallback for boombox: if the item on the floor is a Radio
    for _, invItem in ipairs(floorItems) do
        if instanceof(invItem, "Radio") and not isWalkman(invItem) then
            local iso = resolveIsoRadioFromFloorItem(invItem)
            if iso then
                TCM.queueDeviceOptionsFix(context, playerObj, iso, invItem)
                return
            end
        end
    end

    -- 3) Last resouce...
    if isoRadios[1] then
        TCM.queueDeviceOptionsFix(context, playerObj, isoRadios[1], nil)
    end
end

if TCFillContextMenu then
    Events.OnFillWorldObjectContextMenu.Add(TCFillContextMenu);
end
