require "TCM/Bootstrap"
do return end

require "TCMusicDefenitions"
ISInventoryMenuElements = ISInventoryMenuElements or {};
function ISInventoryMenuElements.ContextBoombox()
    print("TTTTTT")
    local self = ISMenuElement.new();
    self.invMenu = ISContextManager.getInstance().getInventoryMenu();
    function self.init()
    end

    function self.createMenu(_item)
        if getCore():getGameMode() == "Tutorial" then
            return;
        end
        if not _item or not instanceof(_item, "Radio") then
            return;
        end
        local itemType = _item:getFullType() or "";
        local container = _item:getContainer() or nil;
        local isWalkman = TCMusic and TCMusic.WalkmanPlayer and TCMusic.WalkmanPlayer[itemType] or false;
        local isItemMusicPlayer = TCMusic and TCMusic.ItemMusicPlayer and TCMusic.ItemMusicPlayer[itemType] or false;
        if isWalkman or isItemMusicPlayer then
            if container and self.invMenu.player and container == self.invMenu.player:getInventory() then
                local context = self.invMenu.context;
                local deviceOptionText = getText("IGUI_DeviceOptions");
                if context.getOptionFromName and context:getOptionFromName(deviceOptionText) then
                    local opt = context:getOptionFromName(deviceOptionText);
                    if context.removeOptionTsar then
                        context:removeOptionTsar(opt);
                    elseif context.removeOption then
                        context:removeOption(opt);
                    end
                end
                local option = nil
                if context.addOptionOnTop then
                    option = context:addOptionOnTop(deviceOptionText, self.invMenu, self.openPanel, _item);
                else
                    option = context:addOption(deviceOptionText, self.invMenu, self.openPanel, _item);
                end
                option.itemForTexture = _item
            end
        elseif container and container:getType() == "floor" and not isWalkman then
            local square = _item:getWorldItem():getSquare();
            local _obj = nil;
            for i = 0, square:getObjects():size() - 1 do
                local tObj = square:getObjects():get(i);
                if instanceof(tObj, "IsoRadio") then
                    local md = tObj:getModData().RadioItemID or {};
                    if md == _item:getID() then
                        _obj = tObj
                        break;
                    end
                end
            end
            if _obj ~= nil then
                local option = self.invMenu.context:addOptionOnTop(getText("IGUI_DeviceOptions"), self.invMenu,
                    self.openPanel, _obj);
                option.itemForTexture = _item
            end
        end
    end

    function self.openPanel(_p, _item)
        if ISRadioWindow and ISRadioWindow.activate then
            ISRadioWindow.activate(_p.player, _item, true);
        end
    end

    return self;
end

if ISInventoryMenuElements.ContextBoombox then
    Events.OnFillInventoryObjectContextMenu.Add(function(player, context, items)
        local boomboxContext = ISInventoryMenuElements.ContextBoombox();
        if type(items) == "table" then
            for _, v in ipairs(items) do
                local item = v;
                if not instanceof(v, "InventoryItem") then
                    item = v.items and v.items[1] or nil;
                end
                if item then
                    boomboxContext.createMenu(item);
                end
            end
        else
            boomboxContext.createMenu(items);
        end
    end);
end
