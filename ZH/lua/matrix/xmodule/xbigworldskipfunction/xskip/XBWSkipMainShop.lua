local XBWSkipBase = require("XModule/XBigWorldSkipFunction/XSkip/XBase/XBWSkipBase")
---@class XBWSkipMainShop : XBWSkipBase
local XBWSkipMainShop = XClass(XBWSkipBase, "XBWSkipMainShop")

-- 重写Skip方法
function XBWSkipMainShop:Skip(skipParams)
    local params = self:GetParams()
    if not self:_CheckParamsValid() then
        return false
    end
    self._ShopType = params[1]
    self._ShopId = params[2]
    --1为不弹出跳转2次确认框
    --0为弹出
    --默认弹出
    self.isNoTips = params[3] == 1
    local data = XMVCA.XBigWorldCommon:GetPopupConfirmData()
    local tip = skipParams.tipKey and XMVCA.XBigWorldService:GetText(skipParams.tipKey) or
                    XMVCA.XBigWorldService:GetText("WordTipExit")
    local exitCb = function()
        if skipParams.sureCallback then
            skipParams.sureCallback()
        end
        self:_DoExitAndSkip()
    end
    data:InitInfo(nil, tip):InitSureClick(nil, exitCb):InitToggleActive(false)
    -- 配置表强制跳转时不弹出确认框 或 代码不传tipKey时也不弹出确认框
    local needSkipPopup = self.isNoTips or string.IsNilOrEmpty(skipParams.tipKey)
    if needSkipPopup then
        XMVCA.XBigWorldUI:OpenConfirmPopup(data)
    else
        exitCb()
    end
    return true
end

function XBWSkipMainShop:_CheckParamsValid()
    local params = self:GetParams()
    if not XTool.IsTableEmpty(params) then
        if not params[1] then
            XLog.Error("XBWSkipMainShop:Skip 商店类型不能为空")
            return false
        end
        if not params[2] then
            XLog.Error("XBWSkipMainShop:Skip 商店ID不能为空")
            return false
        end
    end
    return true
end

function XBWSkipMainShop:_DoExitAndSkip()
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon) then
        XMVCA.XBigWorldGamePlay:ExitWorld()
        XLuaUiManager.Open("UiShop", self._ShopType, nil, self._ShopId)
    end
end

return XBWSkipMainShop
