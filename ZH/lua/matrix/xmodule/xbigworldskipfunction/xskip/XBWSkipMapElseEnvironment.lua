local XBWSkipBase = require("XModule/XBigWorldSkipFunction/XSkip/XBase/XBWSkipBase")

---@class XBWSkipMapElseEnvironment: XBWSkipBase 跳转到生态图钉，如果生态没执勤，则打开生态弹窗
local XBWSkipMapElseEnvironment = XClass(XBWSkipBase, "XBWSkipMapElseEnvironment")

function XBWSkipMapElseEnvironment:Skip()
    local params = self:GetParams()

    if XTool.IsTableEmpty(params) then
        XLog.Error("跳转失败, 参数异常!")
        return false
    end

    local worldId = params[1] or 0
    local levelId = params[2] or 0
    local pinId = params[3] or 0
    local openAiMemory = params[4] or 0
    local environmentId = params[5] or 0

    if XMVCA.XBigWorldMap:CheckPinDisplay(levelId, pinId) then
        return XMVCA.XBigWorldMap:OpenBigWorldMapUiWithPinId(worldId, levelId, pinId, openAiMemory)
    end

    local confirmData = XMVCA.XBigWorldCommon:GetPopupConfirmData()

    confirmData:InitInfo(nil, XMVCA.XBigWorldService:GetText("EnvironmentalStoryUnDutyTip"))
    confirmData:InitSureClick(nil, function()
        XMVCA.XBigWorldQuest:OpenEnvironmentPopupView(environmentId)
    end):InitToggleActive(false)

    XMVCA.XBigWorldUI:OpenConfirmPopup(confirmData)

    return true
end

return XBWSkipMapElseEnvironment
