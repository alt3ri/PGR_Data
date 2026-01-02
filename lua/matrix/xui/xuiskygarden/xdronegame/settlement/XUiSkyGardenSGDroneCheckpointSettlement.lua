local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")
local XUiSkyGardenSGDroneSettlementTarget = require(
    "XUi/XUiSkyGarden/XDroneGame/Settlement/XUiSkyGardenSGDroneSettlementTarget")

---@class XUiSkyGardenSGDroneCheckpointSettlement : XUiNode
---@field TxtTeachTitle UnityEngine.UI.Text
---@field TxtScore UnityEngine.UI.Text
---@field PanelGoal UnityEngine.RectTransform
---@field ExtraTargetGroup UnityEngine.RectTransform
---@field PanelRewardGroup UnityEngine.RectTransform
---@field PanelRewardGrid UnityEngine.RectTransform
---@field NoReward UnityEngine.RectTransform
---@field RewardGrid UnityEngine.RectTransform
---@field BtnCancel XUiComponent.XUiButtonExt
---@field BtnConfirm XUiComponent.XUiButtonExt
---@field _Control XSkyGardenDroneGameControl
---@field Parent XUiSkyGardenSGDronePopupSettlement
local XUiSkyGardenSGDroneCheckpointSettlement = XClass(XUiNode, "XUiSkyGardenSGDroneCheckpointSettlement")

function XUiSkyGardenSGDroneCheckpointSettlement:OnStart()
    ---@type XUiSkyGardenSGDroneSettlementTarget[]
    self._TargetGrids = {}

    ---@type XUiGridBWItem[]
    self._RewardGrids = {}

    ---@type XSGDroneStageEntity
    self._StageEntity = false
    ---@type XSGDroneStageEntity
    self._NextStageEntity = false

    self:_Init()
    self:_RegisterButtonClicks()
end

function XUiSkyGardenSGDroneCheckpointSettlement:OnEnable()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiSkyGardenSGDroneCheckpointSettlement:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiSkyGardenSGDroneCheckpointSettlement:OnDestroy()
end

function XUiSkyGardenSGDroneCheckpointSettlement:OnBtnCancelClick()
    self._Control:TryRestoreStageUI(self._StageEntity)

    self.Parent:Close()

    CS.XBigWorldGame.XSkyGarden.XDroneGame.XSGDGInstance.ReleaseGame()
end

function XUiSkyGardenSGDroneCheckpointSettlement:OnBtnConfirmClick()
    self._Control:TryRestoreStageUI(self._NextStageEntity)

    self.Parent:Close()

    CS.XBigWorldGame.XSkyGarden.XDroneGame.XSGDGInstance.ReleaseGame()
end

function XUiSkyGardenSGDroneCheckpointSettlement:Refresh(stageId, score, targetMap)
    self.TxtScore.text = tostring(score)

    self._StageEntity = self._Control:GetStageEntity(stageId)

    if self._StageEntity then
        self._NextStageEntity = self._StageEntity:GetChapterNextStageEntity()
    end

    self:_RefreshTarget(targetMap)
    self:_RefreshReward(stageId, targetMap)

    self.BtnConfirm.gameObject:SetActiveEx(self._NextStageEntity and self._NextStageEntity:IsUnlock())
end

function XUiSkyGardenSGDroneCheckpointSettlement:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self.BtnCancel:AddEventListener(Handler(self, self.OnBtnCancelClick))
    self.BtnConfirm:AddEventListener(Handler(self, self.OnBtnConfirmClick))
end

function XUiSkyGardenSGDroneCheckpointSettlement:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiSkyGardenSGDroneCheckpointSettlement:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiSkyGardenSGDroneCheckpointSettlement:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiSkyGardenSGDroneCheckpointSettlement:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiSkyGardenSGDroneCheckpointSettlement:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiSkyGardenSGDroneCheckpointSettlement:_Init()
    self.ExtraTargetGroup.gameObject:SetActiveEx(false)
    self.RewardGrid.gameObject:SetActiveEx(false)
end

function XUiSkyGardenSGDroneCheckpointSettlement:_RefreshTarget(targetMap)
    local index = 1

    for targetId, isSuccess in pairs(targetMap) do
        local target = targetMap[index]
        local targetScore = self._Control:GetTargetDescription(targetId)

        if not self._TargetGrids[targetId] then
            local targetGrid = XUiHelper.Instantiate(self.ExtraTargetGroup, self.PanelGoal)

            target = XUiSkyGardenSGDroneSettlementTarget.New(targetGrid, self)
            self._TargetGrids[index] = target
        end

        index = index + 1
        target:Open()
        target:Refresh(targetScore, isSuccess)
    end

    for i = index, #self._TargetGrids do
        self._TargetGrids[i]:Close()
    end
end

function XUiSkyGardenSGDroneCheckpointSettlement:_RefreshReward(stageId, targetMap)
    local rewards = self._Control:GetStageRewardsByTargets(stageId, targetMap)

    if not XTool.IsTableEmpty(rewards) then
        local index = 1

        self.NoReward.gameObject:SetActiveEx(false)
        self.PanelRewardGroup.gameObject:SetActiveEx(true)
        for _, rewardData in pairs(rewards) do
            local rewardGrid = self._RewardGrids[index]

            if not rewardGrid then
                local rewardGridUi = XUiHelper.Instantiate(self.RewardGrid, self.PanelRewardGrid)

                rewardGrid = XUiGridBWItem.New(rewardGridUi, self)
                self._RewardGrids[index] = rewardGrid
            end

            rewardGrid:Open()
            rewardGrid:Refresh(rewardData)

            index = index + 1
        end
        for i = index, #self._RewardGrids do
            self._RewardGrids[i]:Close()
        end
    else
        for _, rewardGrid in pairs(self._RewardGrids) do
            rewardGrid:Close()
        end

        self.NoReward.gameObject:SetActiveEx(true)
        self.PanelRewardGroup.gameObject:SetActiveEx(false)
    end
end

return XUiSkyGardenSGDroneCheckpointSettlement
