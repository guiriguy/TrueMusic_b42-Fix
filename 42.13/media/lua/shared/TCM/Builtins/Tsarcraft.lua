-- File: 42/media/lua/shared/builtins/Tsarcraft.lua
TCM = TCM or {}
require "TCM/Legacy/Bridge"

local cassetteBank = "tsarcraft_music_01_62"
local vinylBank    = "tsarcraft_music_01_63"

-- Media keys MUST be item:getType() (no module).
TCM.Legacy.registerMediaType("CassetteMainTheme", cassetteBank)
TCM.Legacy.registerMediaType("VinylMainTheme", vinylBank)

-- Inventory devices
TCM.Legacy.registerDeviceInventory("Tsarcraft.TCBoombox", cassetteBank, false)
TCM.Legacy.registerDeviceInventory("Tsarcraft.TCWalkman", cassetteBank, true)
--TCM.Legacy.registerDeviceInventory("Tsarcraft.TCVinylplayer", vinylBank, false)

-- Vehicle radios (legacy maps these to cassette bank)
TCM.Legacy.registerDeviceVehicle("Base.HamRadio1", cassetteBank)
TCM.Legacy.registerDeviceVehicle("Base.HamRadio2", cassetteBank)
TCM.Legacy.registerDeviceVehicle("Base.RadioBlack", cassetteBank)
TCM.Legacy.registerDeviceVehicle("Base.RadioRed", cassetteBank)

-- World sprite IDs from original legacy mapping
TCM.Legacy.registerDeviceWorld("tsarcraft_music_01_34", cassetteBank)
TCM.Legacy.registerDeviceWorld("tsarcraft_music_01_35", cassetteBank)
TCM.Legacy.registerDeviceWorld("tsarcraft_music_01_62", cassetteBank)

TCM.Legacy.registerDeviceWorld("tsarcraft_music_01_36", vinylBank)
TCM.Legacy.registerDeviceWorld("tsarcraft_music_01_37", vinylBank)
TCM.Legacy.registerDeviceWorld("tsarcraft_music_01_63", vinylBank)

-- Original also had these in WorldMusicPlayer (we keep them)
TCM.Legacy.registerDeviceWorld("Tsarcraft.TCBoombox", cassetteBank)
TCM.Legacy.registerDeviceWorld("Tsarcraft.TCVinylplayer", vinylBank)

return true
