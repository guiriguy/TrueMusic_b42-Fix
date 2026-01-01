require "TCMusicDefenitions"
require "TCM/Patches/DeviceOptionsFinalizer"

ISInventoryMenuElements = ISInventoryMenuElements or {};
TCM = TCM or {}
if TCM and TCM.__inv_context_loaded then return end
TCM.__inv_context_loaded = true

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
        local isPlaceable = TCMusic and TCMusic.Pla

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
