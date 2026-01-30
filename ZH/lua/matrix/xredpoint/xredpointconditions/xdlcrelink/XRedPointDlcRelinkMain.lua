local XRedPointDlcRelinkMain = {}

function XRedPointDlcRelinkMain.Check()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.DlcRelink, true, true) then
        return false
    end

    if not XMVCA.XDlcRelink:GetIsOpen(true) then
        return false
    end

    if XMVCA.XDlcRelink:CheckAllTaskRedPoint() then
        return true
    end

    if XMVCA.XDlcRelink:CheckAllLevelHasNewUnlock() then
        return true
    end
    
    return false
end

return XRedPointDlcRelinkMain