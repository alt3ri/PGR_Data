---@class XUiGridConcertPreHeatingStageTab : XUiNode
---@field _Control XConcertPreHeatingControl
---@field Parent XUiConcertPreHeatingMain
local XUiGridConcertPreHeatingStageTab = XClass(XUiNode, "XUiGridConcertPreHeatingStageTab")

function XUiGridConcertPreHeatingStageTab:OnStart()
    self._NormalUi = XTool.InitUiObjectByUi({}, self.Normal)
    self._SelectUi = XTool.InitUiObjectByUi({}, self.Select)
    self._DisabledUi = XTool.InitUiObjectByUi({}, self.Disabled)

    XUiHelper.RegisterClickEvent(self, self.BtnSelf, self.OnBtnSelfClick)
end

-- 刷新页签格子
function XUiGridConcertPreHeatingStageTab:Refresh(index, stageId)
    self._StageId = stageId

    local stageName = self._Control:GetStageName(stageId)
    local entranceImg = self._Control:GetStageEntranceImg(stageId)
    local isFinished = self._Control:IsStageFinished(stageId)

    if not string.IsNilOrEmpty(entranceImg) then
        self.BtnSelf:SetRawImage(entranceImg)
    end
    self.BtnSelf:ShowTag(isFinished)

    self._NormalUi.TxtStageName.gameObject:SetActiveEx(true)
    self._SelectUi.TxtStageName.gameObject:SetActiveEx(true)
    self._DisabledUi.TxtStageName.gameObject:SetActiveEx(true)
    self._NormalUi.TxtStageName.text = stageName
    self._SelectUi.TxtStageName.text = stageName
    self._DisabledUi.TxtStageName.text = stageName
    self:RefreshRedPoint()
end

function XUiGridConcertPreHeatingStageTab:RefreshButtonState(isSelect)
    local isOpen = self._Control:IsStageOpen(self._StageId)
    -- 避开 XUiButton 自动切 State，页签视觉状态统一由节点显隐控制。
    self.Normal.gameObject:SetActiveEx(isOpen and not isSelect)
    self.Select.gameObject:SetActiveEx(isOpen and isSelect)
    self.Disabled.gameObject:SetActiveEx(not isOpen)
    self:RefreshRedPoint()
end

function XUiGridConcertPreHeatingStageTab:RefreshRedPoint()
    XRedPointManager.CheckOnceByButton(self.BtnSelf, { XRedPointConditions.Types.CONDITION_CONCERT_PRE_HEATING_NEW_STAGE }, self._StageId)
end

function XUiGridConcertPreHeatingStageTab:OnBtnSelfClick()
    self.Parent:OnGridClickStageTab(self.Index)
end

return XUiGridConcertPreHeatingStageTab
