TCM = TCM or {}
TCM.Contracts = TCM.Contracts or {}

TCM.Contracts.CONTRACT_VERSION = 1

-- Namespace ModData key (cache only, not source of truth)
TCM.Contracts.MODDATA_ROOT_KEY = "tcmusic"

TCM.Contracts.MEDIA_KINDS = {
    CASSETTE = "cassette",
    VINYL    = "vinyl",
}

TCM.Contracts.DEVICE_KINDS = {
    BOOMBOX       = "boombox",
    WALKMAN       = "walkman",
    VINYL_PLAYER  = "vinyl_player",
    VEHICLE_RADIO = "vehicle_radio",
}

return TCM.Contracts
