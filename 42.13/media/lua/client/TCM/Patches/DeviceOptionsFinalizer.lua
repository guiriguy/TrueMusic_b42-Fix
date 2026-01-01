TCM = TCM or {}
if TCM.__deviceoption_finalizer_loaded then return end
TCM.__deviceoption_finalizer_loaded = true

function TCM.openDeviceOptions(playerObj, device)
    if ISTCBoomboxWindow and ISTCBoomboxWindow.activate then
        return ISTCBoomboxWindow.activate(playerObj, device)
    end
    if ISRadioWindow and ISRadioWindow.activate then
        return ISRadioWindow.activate(playerObj, device, true)
    end
end

local function removeAllDeviceOptions(context)
    if not context or not context.options then return end
    local target = getText("IGUI_DeviceOptions")
    for i = #context.options, 1, -1 do
        local opt = context.options[i]
        if opt and opt.name == target then
            if context.removeOptionTsar then
                context:removeOptionTsar(opt)
            elseif context.removeOption then
                context:removeOption(opt)
            else
                table.remove(context.options, i)
            end
        end
    end
end

TCM._deviceoption_queue = TCM._deviceoption_queue or {}

-- Llamas a esto en cada right-click cuando detectes un device TCM
function TCM.queueDeviceOptionsFix(context, playerObj, device, textureItem)
    if not context or not playerObj or not device then return end

    context.__tcm_deviceoption_job = {
        playerObj = playerObj,
        device = device,
        textureItem = textureItem
    }

    if not context.__tcm_deviceoption_queued then
        context.__tcm_deviceoption_queued = true
        table.insert(TCM._deviceoption_queue, context)
    end
end

-- Post-pass: corre en el tick siguiente (por menú/click)
if not TCM.__deviceoption_finalizer_tick then
    TCM.__deviceoption_finalizer_tick = true
    Events.OnTick.Add(function()
        if not TCM._deviceoption_queue or #TCM._deviceoption_queue == 0 then return end

        local queue = TCM._deviceoption_queue
        TCM._deviceoption_queue = {}

        local text = getText("IGUI_DeviceOptions")

        for _, context in ipairs(queue) do
            local job = context.__tcm_deviceoption_job
            context.__tcm_deviceoption_job = nil
            context.__tcm_deviceoption_queued = nil

            if context and job and context.options then
                removeAllDeviceOptions(context)

                local opt
                if context.addOptionOnTop then
                    opt = context:addOptionOnTop(text, job.playerObj, TCM.openDeviceOptions, job.device)
                else
                    opt = context:addOption(text, job.playerObj, TCM.openDeviceOptions, job.device)
                end

                if opt and job.textureItem then
                    opt.itemForTexture = job.textureItem
                end
            end
        end
    end)
end
