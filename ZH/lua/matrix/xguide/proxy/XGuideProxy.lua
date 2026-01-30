---@class XGuideProxy
---@field _GuideTemplates table<number, XTableGuideGroup>
local XGuideProxy = XClass(nil, "XGuideProxy")

local tableSort = table.sort

function XGuideProxy:Ctor(flag)
    self._GuideFlag = flag
    self._DisableFlag = 0
    self._GuideTemplates = false
    self._SortCb = handler(self, self.SortGuideGroup)
end

function XGuideProxy:Active()
    self._ActiveGuide = {}
end

function XGuideProxy:InActive()
    self._ActiveGuide = nil
end

function XGuideProxy:OnGuideStart()
end

function XGuideProxy:OnGuideEnd()
end

function XGuideProxy:OnGuideReset()
end

function XGuideProxy:IsIntercept()
end

function XGuideProxy:OpenUiObtain(...)
    XUiManager.OpenUiObtain(...)
end

---@param template XTableGuideGroup
function XGuideProxy:ExecuteGuide(template, isUiOpen)
    if not template then
        return
    end
    XDataCenter.GuideManager.ExecuteGuide(template)
end

---@return XTableGuideGroup
function XGuideProxy:GetGuideGroupTemplate(guideId)
    return XGuideConfig.GetGuideGroupTemplatesById(guideId)
end

---@return table<number, XTableGuideGroup>
function XGuideProxy:GetAllGuideGroupTemplate()
    return XGuideConfig.GetGuideGroupTemplates()
end

function XGuideProxy:GetGuideCompleteTemplate(guideId)
    return XGuideConfig.GetGuideCompleteTemplatesById(guideId)
end

---@return table<number, XTableGuideGroup>
function XGuideProxy:GetAllGuideCompleteTemplate()
    return XGuideConfig.GetGuideCompleteTemplates()
end

function XGuideProxy:GetGuideIcon(iconId)
    return XGuideConfig.GetGuideIcon(iconId)
end

function XGuideProxy:GetGuideTextTemplate(textId)
    return XGuideConfig.GetGuideTextTemplate(textId)
end

---@param guideGroupTemplates table<number, XTableGuideGroup>
function XGuideProxy:GetAvailableGuideTemplates(guideGroupTemplates)
    local dict = {}
    for guideId, template in pairs(guideGroupTemplates) do
        --无效引导 或者 已经完成
        if template.Ignore ~= 0 or XDataCenter.GuideManager.CheckIsGuide(guideId) then
            goto continue
        end
        dict[guideId] = template

        :: continue ::
    end
    return dict
end

function XGuideProxy:CheckCondition(conditionId, ...)
    return XConditionManager.CheckCondition(conditionId, ...)
end

--- 找到可以启动的引导
---@return XTableGuideGroup[]
function XGuideProxy:FindActiveGuide()
    if XTool.IsTableEmpty(self._GuideTemplates) then
        return
    end
    local startIndex = 0
    local passed = true
    for guideId, template in pairs(self._GuideTemplates) do
        if template.Ignore ~= 0 or XDataCenter.GuideManager.CheckIsGuide(guideId) then
            goto continue
        end
        passed = true
        for _, conditionId in pairs(template.ConditionId) do
            if conditionId and conditionId ~= 0 then
                passed = self:CheckCondition(conditionId)
                if not passed then
                    break
                end
            end
        end
        if passed then
            startIndex = startIndex + 1
            self._ActiveGuide[startIndex] = template
            passed = false
        end

        :: continue ::
    end
    --清除掉多余的引导
    for i = #self._ActiveGuide, startIndex + 1, -1 do
        table.remove(self._ActiveGuide, i)
    end
    tableSort(self._ActiveGuide, self._SortCb)
    return self._ActiveGuide
end

--- 排序
---@param guideGroupTemplatesA XTableGuideGroup
---@param guideGroupTemplatesB XTableGuideGroup
---@return boolean
function XGuideProxy:SortGuideGroup(guideGroupTemplatesA, guideGroupTemplatesB)
    local pA = guideGroupTemplatesA and guideGroupTemplatesA.Priority or math.maxinteger
    local pB = guideGroupTemplatesB and guideGroupTemplatesB.Priority or math.maxinteger
    if pA ~= pB then
        return pA < pB
    end
    local idA = guideGroupTemplatesA and guideGroupTemplatesA.Id or math.maxinteger
    local idB = guideGroupTemplatesB and guideGroupTemplatesB.Id or math.maxinteger
    
    return idA < idB
end

function XGuideProxy:CheckDisableGuide()
    return (self._GuideFlag & self._DisableFlag) ~= 0
end

function XGuideProxy:ChangeDisableGuide(flag)
    self._GuideFlag = flag
end

function XGuideProxy:GetTopUiName(skipCheckUiNameDict)
    --栈顶UiName
    local uiName = CsXUiManager.Instance:GetTopParentUiName()
    local index = 1
    --过滤掉不需要引导的UI
    while true do
        --保底
        if string.IsNilOrEmpty(uiName) then
            break
        end
        --战斗的UI不参与系统引导
        if not (skipCheckUiNameDict[uiName] or XUiManager.IsFightUi(uiName)) then
            break
        end
        uiName = CsXUiManager.Instance:GetTopXUiName(index)
        index = index + 1
    end
    
    return uiName
end

return XGuideProxy