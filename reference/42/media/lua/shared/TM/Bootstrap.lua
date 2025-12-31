TM = TM or {}

require "TM/Config"
require "TM/Debug"
require "TM/AudioManager/SessionUpdater"
require "TCMusicDefenitions"
require "TM/UI/ContextMenu"

TM.Debug.log("Bootstrap loaded")

if isServer() then TM.Debug.log("Server side detected") end

if isClient() then TM.Debug.log("Client side detected") end

if not isServer() then
    require "TM/AudioManager/ClientAudio"
end
