TM = TM or {}
TM.Tags = TM.Tags or {}

local function getTag(id)
    local resourceLoc = ResourceLocation.of(id)
    return ItemTag.get(resourceLoc)
end

function TM.Tags.resolve()
    TM.Tags.PLAYER_VINYL = TM.Tags.PLAYER_VINYL or getTag("truemusic:tm_player_vinyl")
    TM.Tags.PLAYER_CASSETTE = TM.Tags.PLAYER_CASSETTE or getTag("truemusic:tm_player_cassette")
    TM.Tags.MEDIA_VINYL = TM.Tags.MEDIA_VINYL or getTag("truemusic:tm_media_vinyl")
    TM.Tags.MEDIA_CASSETTE = TM.Tags.MEDIA_CASSETTE or getTag("truemusic:tm_media_cassette")
end

function TM.Tags.has(item, tagObj)
    return item and tagObj and item:hasTag(tagObj) or false
end
