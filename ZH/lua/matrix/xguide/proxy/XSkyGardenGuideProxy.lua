local XGuideProxy = require("XGuide/Proxy/XGuideProxy")
---@class XSkyGardenGuideProxy : XGuideProxy
local XSkyGardenGuideProxy = XClass(XGuideProxy, "XSkyGardenGuideProxy")

function XSkyGardenGuideProxy:Active()
    self._PrepareToGuide = {}
    --屏蔽大世界
    self._DisableFlag = XDataCenter.GuideManager.GuideDisableFlag.BigWorld
    
    XGuideProxy.Active(self)
    self._GuideTemplates = self:GetAvailableGuideTemplates(self:GetAllGuideGroupTemplate())
end

function XSkyGardenGuideProxy:InActive()
    XGuideProxy.InActive(self)
    self._PrepareToGuide = {}
end

function XSkyGardenGuideProxy:IsIntercept()
    --if not XMVCA.XBigWorldFunction:IsFunctionEventFree() then
    --    return true
    --end
    --return false
end

---@param template XTableBigworldGuideGroup
function XSkyGardenGuideProxy:ExecuteGuide(template, isUiOpen)
    if not template then
        return
    end
    if template.SequentialId == 2 then
        isUiOpen = true
    elseif template.SequentialId == 1 then
        isUiOpen = false
    end
    if isUiOpen then
        XDataCenter.GuideManager.ExecuteGuide(template)
        return
    end
    for _, guideId in pairs(self._PrepareToGuide) do
        --已经进入流水线了，是等被触发的状态
        if guideId == template.Id then
            return
        end
    end
    local id = XMVCA.XBigWorldCommon:AddCommonSequentialJob()
    if id and id > 0 then
        XDataCenter.GuideManager.TryShowGuideMask()
        XMVCA.XBigWorldCommon:AddSequentialJobBehavior(id, function()
            XDataCenter.GuideManager.ExecuteGuide(template)
        end)
        self._PrepareToGuide[id] = template.Id
    else
        XDataCenter.GuideManager.ExecuteGuide(template)
    end
    self._ExecuteGuideId = id
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
    self:ResetGuideJob()
end

function XSkyGardenGuideProxy:OnGuideReset()
    if self._ChangeInput then
        self._ChangeInput = false
        XMVCA.XBigWorldGamePlay:ChangeFightInput()
    end
    self:ResetGuideJob()
end

function XSkyGardenGuideProxy:GetGuideTextTemplate(textId)
    return XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetBigWorldGuideTextTemplate(textId)
end

function XSkyGardenGuideProxy:GetGuideIcon(iconId)
    return XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetBigWorldGuideIcon(iconId)
end

function XSkyGardenGuideProxy:ResetGuideJob()
    if self._ExecuteGuideId then
        XMVCA.XBigWorldCommon:FinishSequentialJob(self._ExecuteGuideId)
        self._PrepareToGuide[self._ExecuteGuideId] = nil
        self._ExecuteGuideId = nil
    end
end

function XSkyGardenGuideProxy:GetTopUiName(skipCheckUiNameDict)
    if not XMVCA.XBigWorldFunction:IsFunctionEventFree() or XMVCA.XBigWorldLoading:IsShowAnyLoading() then
        return false
    end
    return XGuideProxy.GetTopUiName(self, skipCheckUiNameDict)
end

return XSkyGardenGuideProxy