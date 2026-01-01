require "TCMusicDefenitions"
-- TrueMusic fix (B42.13) - v1
TCM = TCM or {}

-- Avoid double loadstring
if TCM.__boostrapped_v1 then
    return TCM
end
TCM.__boostrapped_v1 = true

-- Keep a tiny "optional require" helper as we rewrite
local function req(path)
    local ok, err = pcall(require, path)
    if not ok then
        -- Fail softly so we don't kill the game mid-rewrite
        print(("[TCTrueMusic] require failed: %s | %s"):format(tostring(path), tostring(err)))
        return false
    end
    return true
end

-- 0) Legacy-friendly basics (Keep if used)
req("TCM/Config")
req("TCM/Debug")

-- 1) Contract-first core (shared)
req("TCM/shared/Contracts")
req("TCM/shared/Util")

req("TCM/Registry/MediaRegistry")
req("TCM/Registry/DeviceRegistry")
req("TCM/Resolve/MediaResolve")
req("TCM/Resolve/DeviceResolve")
req("TCM/Compat/Rules")

-- 2) Built-in registrations (our content mapping)
-- This replaces old "TCMusicDefenitions" idea
req("TCM/Builtins/Tsarcraft")


-- 3) Replacements
req("TCM/TCMusicClientFunctions")
req("TCM/TCTickCheckMusic")
req("TCM/Context/Inventory/InvContextBoombox")
req("TCM/Context/WorldObject/WorldContextBoombox")

-- Client-Only
if not isServer() then
    --req("TCM/client/UI/ContextMenu")
    --req("TCM/client/Audio/ClientAudio")
end

print("[TrueMusic] Bootstrapped v1 (contract-first)")
return TCM
