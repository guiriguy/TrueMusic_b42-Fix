require "TM/State"
require "TM/AudioManager/Runtime"

local function updateItemSpeakerPosition()
    local player = getSpecificPlayer(0)
    if not player then return end

    local map = TM.Runtime.DeviceByKey
    if not map then return end

    local primary = player:getPrimaryHandItem()
    local secondary = player:getSecondaryHandItem()

    for key, item in pairs(map) do
        local session = TM.State.Active and TM.State.Active[key]

        --If no sessions, clean the references
        if not session then
            map[key] = nil
        else
            -- Only for InventoryItem sessions
            if session.kind ~= "item" then
                map[key] = nil
            else
                -- Invalid item refrence
                if not item or not item.getWorldItem then
                    TM.State.removeSession(key)
                    map[key] = nil
                else
                    if session.mode == "headphones" then
                        session.pos = { x = player:getX(), y = player:getY(), z = player:getZ() }
                    else
                        -- Speaker Item: either on ground or in hands
                        local wI = item:getWorldItem()
                        local square = wI and wI.getSquare and wI:getSquare()

                        if square then
                            session.pos = { x = square:getX(), y = square:getY(), z = square:getZ() }
                        elseif item == primary or item == secondary then
                            session.pos = { x = player:getX(), y = player:getY(), z = player:getZ() }
                        else
                            TM.State.removeSession(key)
                            map[key] = nil
                        end
                    end
                end
            end
        end
    end
end

local function updateVehicleSpeakerPosition()
    if not TM.State.Active then return end

    for key, session in pairs(TM.State.Active) do
        if session.kind == "vehicle" and session.vehId then
            local veh = getVehicleById(session.vehId)
            if veh then
                session.pos = { x = veh:getX(), y = veh:getY(), z = veh:getZ() }
            end
        end
    end
end

Events.OnTick.Add(updateItemSpeakerPosition)
Events.OnTick.Add(updateVehicleSpeakerPosition)
