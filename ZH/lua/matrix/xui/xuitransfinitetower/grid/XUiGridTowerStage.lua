local XUiGridMemberSlot = require("XUi/XUiTransfiniteTower/Grid/XUiGridMemberSlot")

---@class XUiGridTowerStage : XUiNode
---@field private _Control XTransfiniteTowerControl
---@field Parent XUiTransfiniteTowerStage
---@field GridTowerStage XUiComponent.XUiButton
---@field GridTowerBoss XUiComponent.XUiButton
---@field TxtStageNum UnityEngine.UI.Text
---@field ImgBoss UnityEngine.UI.Image
---@field PanelMembers UnityEngine.GameObject
---@field GridMemberSlot_1 UnityEngine.GameObject
---@field GridMemberSlot_2 UnityEngine.GameObject
---@field GridMemberSlot_3 UnityEngine.GameObject
---@field ImgSelect UnityEngine.GameObject
---@field Disable UnityEngine.GameObject
---@field ImgComplete UnityEngine.GameObject
---@field TxtClearTime UnityEngine.UI.Text
---@field GroupTrait UnityEngine.GameObject
---@field ImgTrait1 UnityEngine.UI.Image
---@field ImgTrait2 UnityEngine.UI.Image
---@field TagRollback UnityEngine.GameObject
---@field ImgRollbackBg UnityEngine.GameObject
local XUiGridTowerStage = XClass(XUiNode, "XUiGridTowerStage")

local MemberSlotNodeNames = {
    "GridMemberSlot_1",
    "GridMemberSlot_2",
    "GridMemberSlot_3",
}

function XUiGridTowerStage:OnStart()
    self:InitMemberSlots()
    -- 根节点即按钮：列表项实例为 GridTowerStage，固定最终层实例为 GridTowerBoss
    self._RootBtn = self.GridTowerStage or self.GridTowerBoss
    self._RootBtn:AddEventListener(handler(self, self.OnClick))
end

function XUiGridTowerStage:OnClick()
    self.Parent:OnStageGridSelected(self, self.StageCfgId)
end

function XUiGridTowerStage:InitMemberSlots()
    ---@type XUiGridMemberSlot[]
    self._MemberSlots = {}
    for i = 1, #MemberSlotNodeNames do
        self._MemberSlots[i] = XUiGridMemberSlot.New(self[MemberSlotNodeNames[i]], self)
    end
end

---刷新塔层项
---@param stageCfgId number 关卡配置id
function XUiGridTowerStage:Refresh(stageCfgId)
    self.StageCfgId = stageCfgId

    local isPass = self._Control:IsStagePass(stageCfgId)
    local isUnlock = self._Control:IsStageUnlock(stageCfgId)

    self:RefreshStageNum()
    self:RefreshBoss()
    self:RefreshMembers()
    self:RefreshComplete(isPass)
    self:RefreshTrait(isPass)
    self:RefreshRollbackTag()
    self:RefreshLockState(isUnlock)
    -- 动态列表复用时按当前选中层纠正选中态，避免滚动后旧选中框残留
    self:SetSelect(self.Parent:IsStageSelected(stageCfgId))
end

function XUiGridTowerStage:RefreshStageNum()
    self.TxtStageNum.text = self._Control:GetStageOrderText(self.StageCfgId)
end

function XUiGridTowerStage:RefreshBoss()
    local icon = self._Control:GetStageBossIcon(self.StageCfgId)
    local hasIcon = not string.IsNilOrEmpty(icon)
    self.ImgBoss.gameObject:SetActiveEx(hasIcon)
    if hasIcon then
        self.ImgBoss:SetRawImage(icon)
    end
end

function XUiGridTowerStage:RefreshMembers()
    for i = 1, #self._MemberSlots do
        local slotData = self._Control:GetStageMemberSlotData(self.StageCfgId, i)
        self._MemberSlots[i]:Refresh(slotData)
    end
end

---通关标签 + 通关时间（15层塔额外显示时间）
function XUiGridTowerStage:RefreshComplete(isPass)
    self.ImgComplete.gameObject:SetActiveEx(isPass)

    -- 仅 15 层塔的层且通关时显示通关时间
    local isNeedClearTime = isPass and self._Control:IsRecordTimeStage(self.StageCfgId)
    self.TxtClearTime.gameObject:SetActiveEx(isNeedClearTime)
    if isNeedClearTime then
        self.TxtClearTime.text = self._Control:GetStageClearTimeText(self.StageCfgId)
    end
end

---词缀标签（通关后隐藏，避免与通关标签位置冲突）；单词缀显示 ImgTrait1，双词缀显示 ImgTrait1/2
function XUiGridTowerStage:RefreshTrait(isPass)
    if isPass then
        self.GroupTrait.gameObject:SetActiveEx(false)
        return
    end
    local traits = self._Control:GetStageTraitList(self.StageCfgId)
    local traitCount = #traits
    self.GroupTrait.gameObject:SetActiveEx(traitCount > 0)

    self.ImgTrait1.gameObject:SetActiveEx(traitCount >= 1)
    if traitCount >= 1 then
        self.ImgTrait1:SetRawImage(traits[1].Icon)
    end
    self.ImgTrait2.gameObject:SetActiveEx(traitCount >= 2)
    if traitCount >= 2 then
        self.ImgTrait2:SetRawImage(traits[2].Icon)
    end
end

---回溯标签（右上）：回溯生效中紫色亮起，否则关闭
function XUiGridTowerStage:RefreshRollbackTag()
    local isRollbackLayer = self._Control:IsRollbackLayer(self.StageCfgId)
    self.TagRollback.gameObject:SetActiveEx(isRollbackLayer)
    if isRollbackLayer then
        self.ImgRollbackBg.gameObject:SetActiveEx(self._Control:IsRollbackPointActive(self.StageCfgId))
    end
end

---未解锁态：整体置灰并显示锁（由根按钮的状态实现）
function XUiGridTowerStage:RefreshLockState(isUnlock)
    self._IsUnlock = isUnlock
    self:_RefreshBtnState()
end

---选中态切换（由主界面统一管理选中）
function XUiGridTowerStage:SetSelect(isSelect)
    self._IsSelected = isSelect
    self:_RefreshBtnState()
end

function XUiGridTowerStage:_RefreshBtnState()
    if not self._IsUnlock then
        self._RootBtn:SetButtonState(CS.UiButtonState.Disable)
    else
        self._RootBtn:SetButtonState(CS.UiButtonState.Normal)
    end
    self.ImgSelect.gameObject:SetActiveEx(self._IsSelected == true)
end

return XUiGridTowerStage
