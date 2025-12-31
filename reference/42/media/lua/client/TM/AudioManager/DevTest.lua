require "TM/Debug"
require "TM/State"

local function initTest()
  if not (TM.Config and TM.Config.Debug) then return end
  if not TM.Config.TestSoundEvent then
    TM.Debug.warn("Set TM.Config.TestSoundEvent to a real event name to test speaker 3D.")
    return
  end

  local p = getSpecificPlayer(0)
  if not p then return end

  local px, py, pz = p:getX(), p:getY(), p:getZ()

  TM.State.ActiveSpeakerDevices[1] = {
    key = "TM:TEST:SPEAKER",
    mode = "speaker",
    sound = TM.Config.TestSoundEvent,
    volume = 1.0,
    pos = { x = px + 6, y = py, z = pz },
    maxDist = TM.State.Const.SPEAKER_MAX_DIST,
  }

  TM.Debug.log("DevTest speaker placed at", {x=px+6, y=py, z=pz}, "sound=", TM.Config.TestSoundEvent)
end

-- Events.OnGameStart.Add(initTest) //Only for testing