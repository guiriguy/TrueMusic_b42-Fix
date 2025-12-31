-- v1: single source of truth is TCM.Config, but we keep TM.Config as a mirror for legacy.

TCM                         = TCM or {}
TCM.Config                  = TCM.Config or {}

-- Defaults (v1)
TCM.Config.EnableRewrite    = true
TCM.Config.Debug            = true
TCM.Config.DebugDepth       = 2
TCM.Config.DebugMaxItems    = 50
TCM.Config.TestSoundEvent   = "CassetteMainTheme"
TCM.Config.TickInterval     = 10
TCM.Config.DisableTickCheck = true

-- Feature flags (useful while migrating)
TCM.Config.DisableTickCheck = false -- if true, TCTickCheckMusic.lua should early-return

return TCM.Config
