-- TCMusicDefenitions.lua
-- Fix-first, mod-friendly)
-- Keeps the de-facto public API used by music packs:
--   - GlobalMusic[item:getType()] = bankId
--   - TCMusic.ItemMusicPlayer / WorldMusicPlayer / VehicleMusicPlayer / WalkmanPlayer

-- Guard: avoid double init when multiple files require it
TCM = TCM or {}
if TCM.__legacy_definitions_loaded then
    return
end
TCM.__legacy_definitions_loaded = true

-- 1) Ensure legacy globals exist
TCMusic                         = TCMusic or {}
TCMusic.ItemMusicPlayer         = TCMusic.ItemMusicPlayer or {}
TCMusic.VehicleMusicPlayer      = TCMusic.VehicleMusicPlayer or {}
TCMusic.WorldMusicPlayer        = TCMusic.WorldMusicPlayer or {}
TCMusic.WalkmanPlayer           = TCMusic.WalkmanPlayer or {}

GlobalMusic                     = GlobalMusic or {}

-- 2) Load minimal core
--    We fail-soft so packs don't crash if rewrite is mid-progress.
local function req(path)
    local ok, err = pcall(require, path)
    if not ok then
        print(("[TCTrueMusic] require failed: %s | %s"):format(tostring(path), tostring(err)))
        return false
    end
    return true
end

-- Core (generic)
req("TCM/Contracts")
req("TCM/Registry/MediaRegistry")
req("TCM/Registry/DeviceRegistry")
req("TCM/Resolve/MediaResolve")
req("TCM/Resolve/DeviceResolve")
req("TCM/Compat/Rules")

-- Legacy bridge (source-of-truth for v1 compatibility)
req("TCM/Legacy/Bridge")

-- 3) Builtins: Tsarcraft defaults (registers banks into TCMusic/GlobalMusic via the bridge)
req("shared/builtins/Tsarcraft")

-- That's it: other mods can now safely do:
--   require "TCMusicDefenitions"
--   GlobalMusic["SomeCassetteType"] = "tsarcraft_music_01_62"
-- without us wiping anything.
return
