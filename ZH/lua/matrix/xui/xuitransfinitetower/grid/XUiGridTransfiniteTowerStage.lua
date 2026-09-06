---@class XUiGridTransfiniteTowerStage : XUiNode
---@field private _Control XTransfiniteTowerControl
---@field Parent XUiTransfiniteTowerMain
---@field BtnStage XUiComponent.XUiButton
---@field ImgComplete UnityEngine.UI.Image
local XUiGridTransfiniteTowerStage = XClass(XUiNode, "XUiGridTransfiniteTowerStage")

-- BtnStage 文本分组 id（对应 prefab 上 SetNameByGroup 的组）
local TxtGroup = {
    TowerName = 0,      -- 入口名称
    StageProgress = 1,  -- 通关进度 X/Y
    UnlockTime = 2,     -- 未解锁时的解锁时间
}

function XUiGridTransfiniteTowerStage:OnStart()
    self.BtnStage:AddEventListener(handler(self, self.OnBtnStageClick))
end

---刷新单座塔入口
---@param towerCfgId number 塔配置id
function XUiGridTransfiniteTowerStage:Refresh(towerCfgId)
    self.TowerCfgId = towerCfgId

    local isUnlock = self._Control:IsTowerEntranceUnlock(towerCfgId)
    local isComplete = self._Control:IsTowerEntranceComplete(towerCfgId)

    -- 入口名称
    self.BtnStage:SetNameByGroup(TxtGroup.TowerName, self._Control:GetTowerEntranceName(towerCfgId))
    -- 通关进度 X/Y（X=当前层，Y=最高层）
    self.BtnStage:SetNameByGroup(TxtGroup.StageProgress, self._Control:GetTowerProgressText(towerCfgId))
    -- 解锁时间（未解锁时显示）
    self.BtnStage:SetNameByGroup(TxtGroup.UnlockTime, self._Control:GetTowerUnlockTimeText(towerCfgId))

    -- 未开放时置灰
    self.BtnStage:SetDisable(not isUnlock)
    -- 通关标记
    self.ImgComplete.gameObject:SetActiveEx(isComplete)
end

function XUiGridTransfiniteTowerStage:OnBtnStageClick()
    if not self._Control:IsTowerEntranceUnlock(self.TowerCfgId) then
        XUiManager.TipMsg(self._Control:GetTowerLockedTip(self.TowerCfgId))
        return
    end
    self._Control:OpenTower(self.TowerCfgId)
end

return XUiGridTransfiniteTowerStage
