require "TM/Helpers/Tags"

TM = TM or {}
TM.Media = TM.Media or {}

function TM.Media.canInsert(deviceData, item, exisitingMediaItem, playerTag)
    if not deviceData or not item then return false end
    if exisitingMediaItem then return false end

    --Make sure the tags exisitingMediaItem
    if TM.Tags and TM.Tags.resolve then TM.Tags.resolve() end

    if playerTag == "truemusic:tm_player_vinyl" then
        return TM.Tags.has(item, "truemusic:tm_media_vinyl")
    elseif playerTag == "truemusic:tm_player_cassette" then
        return TM.Tags.has(item, "truemusic:tm_media_cassette")
    end

    -- Fallback
    local mediaType = (deviceData.getMediaType and deviceData:getMediaType()) or 0 -- 0 = Cassette, 1 = Vinyl
    if mediaType == 1 then
        return TM.Tags.has(item, "truemusic:tm_media_vinyl")
    else
        return TM.Tags.has(item, "truemusic:tm_media_cassette")
    end
end
