local XGuideProxy = require("XGuide/Proxy/XGuideProxy")
---@class XSkyGardenGuideProxy : XGuideProxy
local XSkyGardenGuideProxy = XClass(XGuideProxy, "XSkyGardenGuideProxy")

function XSkyGardenGuideProxy:Active()
    --屏蔽大世界
    self._DisableFlag = XDataCenter.GuideManager.GuideDisableFlag.BigWorld
    
    XGuideProxy.Active(self)
    self._GuideTemplates = self:GetAvailableGuideTemplates(self:GetAllGuideGroupTemplate())
end

function XSkyGardenGuideProxy:InActive()
    XGuideProxy.InActive(self)
end

function XSkyGardenGuideProxy:IsIntercept()
    --if not XMVCA.XBigWorldFunction:IsFunctionEventFree() then
    --    return true
    --end
    --return false
end

function XSkyGardenGuideProxy:OpenUiObtain(...)
    XMVCA.XBigWorldUI:OpenBigWorldRewardGoods(...)
end

function XSkyGardenGuideProxy:GetGuideGroupTemplate(guideId)
    return XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetBigWorldGuideGroupTemplateById(guideId)
end

function XSkyGardenGuideProxy:GetAllGuideGroupTemplate()
    return XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetBigWorldGuideGroupTemplates()
end

function XSkyGardenGuideProxy:GetGuideCompleteTemplate(completeId)
    return XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetBigWorldGuideCompleteTemplateById(completeId)
end

function XSkyGardenGuideProxy:GetAllGuideCompleteTemplate()
    return XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetBigWorldGuideCompleteTemplates()
end

function XSkyGardenGuideProxy:CheckCondition(conditionId, ...)
    return XMVCA.XBigWorldService:CheckCondition(conditionId, ...)
end

function XSkyGardenGuideProxy:OnGuideStart()
    if not self._ChangeInput then
        self._ChangeInput = true
        XMVCA.XBigWorldGamePlay:ChangeSystemInput()
    end
end

function XSkyGardenGuideProxy:OnGuideEnd()
    if self._ChangeInput then
        self._ChangeInput = false
        XMVCA.XBigWorldGamePlay:ChangeFightInput()
    end
end

function XSkyGardenGuideProxy:OnGuideReset()
    if self._ChangeInput then
        self._ChangeInput = false
        XMVCA.XBigWorldGamePlay:ChangeFightInput()
    end
end

function XSkyGardenGuideProxy:GetGuideTextTemplate(textId)
    return XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetBigWorldGuideTextTemplate(textId)
end

function XSkyGardenGuideProxy:GetGuideIcon(iconId)
    return XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetBigWorldGuideIcon(iconId)
end

return XSkyGardenGuideProxy