---@class XBigWorldSettle 大世界副本结算
local XBigWorldSettle = XClass(nil, "XBigWorldSettle")

function XBigWorldSettle:Ctor()
    self._SettleType = {
        --带星级挑战
        StarRating = 1
    }
    
    --默认主题
    self._DefaultTheme = 1
end

function XBigWorldSettle:DoSettle(settleData)
    if not settleData then
        XLog.Error("打开结算界面失败! 结算数据为空!")
        return
    end
    
    local settleType = settleData.SettleType or 0
    if not settleType or settleType <= 0 then
        XLog.Error("打开结算界面失败! 结算类型无效!")
        return
    end
    
    local theme = settleData.Theme or self._DefaultTheme
    local settleId = self:GetSettleId(settleType, theme)
    local uiName = XMVCA.XBigWorldInstance:GetSettleUiName(settleId)
    if string.IsNilOrEmpty(uiName) then
        XLog.Error(string.format("打开结算界面失败! 结算类型=%s, 结算主题=%s", settleType, theme))
        return
    end
    XMVCA.XBigWorldUI:Open(uiName, settleData)
end

function XBigWorldSettle:DoSettleClosed()
end

function XBigWorldSettle:GetSettleId(settleType, settleTheme)
    return settleType * 1000 + settleTheme
end

return XBigWorldSettle