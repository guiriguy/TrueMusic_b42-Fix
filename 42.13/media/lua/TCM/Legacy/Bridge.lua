-- File: 42/media/lua/TCM/Legacy/Bridge.lua
TCM = TCM or {}
TCM.Legacy = TCM.Legacy or {}

function TCM.Legacy.ensureGlobals()
    TCMusic                    = TCMusic or {}
    TCMusic.ItemMusicPlayer    = TCMusic.ItemMusicPlayer or {}
    TCMusic.VehicleMusicPlayer = TCMusic.VehicleMusicPlayer or {}
    TCMusic.WorldMusicPlayer   = TCMusic.WorldMusicPlayer or {}
    TCMusic.WalkmanPlayer      = TCMusic.WalkmanPlayer or {}
    GlobalMusic                = GlobalMusic or {}
end

-- Packs register by item:getType() (no module).
function TCM.Legacy.registerMediaType(itemType, bankId)
    TCM.Legacy.ensureGlobals()
    GlobalMusic[itemType] = bankId
end

function TCM.Legacy.registerDeviceInventory(fullType, bankId, isWalkman)
    TCM.Legacy.ensureGlobals()
    if isWalkman then
        TCMusic.WalkmanPlayer[fullType] = bankId
    else
        TCMusic.ItemMusicPlayer[fullType] = bankId
    end
end

function TCM.Legacy.registerDeviceVehicle(fullType, bankId)
    TCM.Legacy.ensureGlobals()
    TCMusic.VehicleMusicPlayer[fullType] = bankId
end

function TCM.Legacy.registerDeviceWorld(spriteName, bankId)
    TCM.Legacy.ensureGlobals()
    TCMusic.WorldMusicPlayer[spriteName] = bankId
end

return TCM.Legacy
