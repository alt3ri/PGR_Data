---@class XUiGridDyeMergeStage: XUiNode
---@field protected _Control
---@field Parent
local XUiGridDyeMergeStage = XClass(XUiNode, "XUiGridDyeMergeStage")

function XUiGridDyeMergeStage:OnStart(clickCb)
    self.ClickCb = clickCb
    
    self.GridBtn:AddEventListener(handler(self, self._OnBtnClickEvent))
end

--- 刷新自己的状态，不改变自身所关联的关卡
function XUiGridDyeMergeStage:RefreshOwnState()
    self:Refresh(self.StageId, self.OwnChapterId)
end

function XUiGridDyeMergeStage:Refresh(stageId, ownChapterId)
    self.StageId = stageId
    self.OwnChapterId = ownChapterId

    local stageCfg = XMVCA.XDyeMergeGame:GetTableDyeMergeStageById(self.StageId)

    if stageCfg and not string.IsNilOrEmpty(stageCfg.Name) then
        self.GridBtn:SetNameByGroup(0, stageCfg.Name)
    end
    
    local unlock = XMVCA.XDyeMergeGame:GetIsStageUnlockById(self.StageId)
    local passed = XMVCA.XDyeMergeGame:CheckPassedByStageId(self.StageId)
    
    self.GridBtn:SetButtonState((unlock or passed) and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    
    self.ImgBgFinish.gameObject:SetActiveEx(passed)
end

function XUiGridDyeMergeStage:SetTransformParent(parent, keepPos)
    self.Transform.parent = parent

    if not keepPos then
        self.Transform:SetLocalPosition(0, 0, 0)
    end
end

function XUiGridDyeMergeStage:_OnBtnClickEvent()
    if self.ClickCb then
        self.ClickCb(self.StageId)
    end
end

return XUiGridDyeMergeStage