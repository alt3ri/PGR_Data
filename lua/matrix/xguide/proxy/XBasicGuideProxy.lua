local XGuideProxy = require("XGuide/Proxy/XGuideProxy")
---@class XBasicGuideProxy : XGuideProxy
local XBasicGuideProxy = XClass(XGuideProxy, "XBasicGuideProxy")

function XBasicGuideProxy:Active()
    --屏蔽主干
    self._DisableFlag = XDataCenter.GuideManager.GuideDisableFlag.Trunk
    
    XGuideProxy.Active(self)
    self._GuideTemplates = self:GetAvailableGuideTemplates(XGuideConfig.GetGuideGroupTemplates())
end

function XBasicGuideProxy:InActive()
    XGuideProxy.InActive(self)
    self._GuideTemplates = false
end

function XBasicGuideProxy:IsIntercept()
    if XDataCenter.FunctionEventManager.IsPlaying() then
        return true
    end
    return false
end

return XBasicGuideProxy