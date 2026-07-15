---@class XUiGridDyeMergeStage: XUiNode
---@field protected _Control
---@field Parent
local XUiGridDyeMergeStage = XClass(XUiNode, "XUiGridDyeMergeStage")

function XUiGridDyeMergeStage:OnStart(clickCb)
    self.ClickCb = clickCb
    
    self.GridBtn:AddEventListener(handler(self, self._OnBtnClickEvent))
end

--- 刷新自己的状态，不改变自身所关联的关卡
---@param progressStageId number|nil 当前进度关卡Id（由上层统一计算下发，避免每格重复全量查询）
function XUiGridDyeMergeStage:RefreshOwnState(progressStageId)
    self:Refresh(self.StageId, self.OwnChapterId, progressStageId)
end

function XUiGridDyeMergeStage:Refresh(stageId, ownChapterId, progressStageId)
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

    self:_RefreshMascot(passed, progressStageId)
end

--- 刷新吉祥物显隐：仅当自身是当前进度关卡且未通关时显示
---@param passed boolean 自身是否已通关
---@param progressStageId number|nil 当前进度关卡Id，未传时回退到实时查询
function XUiGridDyeMergeStage:_RefreshMascot(passed, progressStageId)
    if not self.RImgMascot then
        return
    end

    if progressStageId == nil then
        progressStageId = XMVCA.XDyeMergeGame:GetLatestProgressStageId()
    end

    local isProgress = progressStageId and self.StageId == progressStageId and not passed

    self.RImgMascot.gameObject:SetActiveEx(isProgress)
end

function XUiGridDyeMergeStage:SetTransformParent(parent, keepPos)
    self.Transform:SetParent(parent)

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