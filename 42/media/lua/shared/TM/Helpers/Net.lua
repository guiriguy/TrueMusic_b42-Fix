TM = TM or {}
TM.Net = TM.Net or {}

function TM.Net.transmitIsoObject(iso)
    if not iso or not isClient() then return end

    -- If still not deprecated then
    if iso.transmitCompleteItemToServer then
        iso:transmitCompleteItemToServer()
        return
    end

    -- Fallback
    if iso.TransmitCompleteItem then
        iso:transmitCompleteItem()
        return
    end

    if iso.transmitModData then
        iso:transmitModData()
    end
end
