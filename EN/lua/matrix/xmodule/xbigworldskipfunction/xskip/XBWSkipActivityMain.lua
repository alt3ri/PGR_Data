local XBWSkipBase = require("XModule/XBigWorldSkipFunction/XSkip/XBase/XBWSkipBase")

---@class XBWSkipActivityMain : XBWSkipBase 跳转到玩法主界面
local XBWSkipActivityMain = XClass(XBWSkipBase, "XBWSkipActivityMain")


function XBWSkipActivityMain:Skip()
    local params = self:GetParams()
    if XTool.IsTableEmpty(params) then
        XLog.Error("跳转失败, 参数异常!")
        return
    end
    self:OpenMainUi()
end

function XBWSkipActivityMain:OpenMainUi()
    local params = self:GetParams()
    local data = {
        BigWorldActivityId = params[1],
        Args = self:GetParamsWithStart(2)
    }
    XMVCA.XBigWorldGamePlay:OnOpenMainUi(data)
    
end

function XBWSkipActivityMain:GetParamsWithStart(start)
    local params = self:GetParams()
    local args = {}
    local index = 0
    for i = start, #params do
        args[index] = params[i]
        index = index + 1
    end
    return args
end

--function XBWSkipActivityMain:AddEvent()
--    XEventManager.AddEventListener(DlcEventId.EVENT_MAP_PIN_END_TELEPORT, self.OnEndTeleport, self)
--    XEventManager.AddEventListener(DlcEventId.EVENT_FIGHT_LEVEL_BEGIN_UPDATE, self.OnUpdateLevel, self)
--end
--
--function XBWSkipActivityMain:RemoveEvent()
--    XEventManager.RemoveEventListener(DlcEventId.EVENT_MAP_PIN_END_TELEPORT, self.OnEndTeleport, self)
--    XEventManager.RemoveEventListener(DlcEventId.EVENT_FIGHT_LEVEL_BEGIN_UPDATE, self.OnUpdateLevel, self)
--end
--
--function XBWSkipActivityMain:OnEndTeleport()
--    XMVCA.XBigWorldLoading:CloseBlackMaskLoading()
--    self:OpenMainUi()
--    self:RemoveEvent()
--end
--
--function XBWSkipActivityMain:OnUpdateLevel()
--    self:OpenMainUi()
--    self:RemoveEvent()
--end

return XBWSkipActivityMain