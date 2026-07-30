---@class XUiTheatre6PVPAttackDefend : XLuaUi
---@field _Control XTheatre6Control
---@field BtnFight XUiComponent.XUiButton
local XUiTheatre6PVPAttackDefend = XLuaUiManager.Register(XLuaUi, "UiTheatre6PVPAttackDefend")

local XUiPanelTheatre6PvpArchive = require("XUi/XUiTheatre6/PVP/Panel/XUiPanelTheatre6PvpArchive")
local XUiPanelTheatre6PvpRightAttack = require("XUi/XUiTheatre6/PVP/Panel/XUiPanelTheatre6PvpRightAttack")
local XUiPanelTheatre6PvpRightDefend = require("XUi/XUiTheatre6/PVP/Panel/XUiPanelTheatre6PvpRightDefend")
local XUiPanelTheatre6PvpEnergy = require("XUi/XUiTheatre6/PVP/Panel/XUiPanelTheatre6PvpEnergy")
local XUiCommonDragContext = require("XUi/XUiCommon/XCommonDrag/XUiCommonDragContext")

function XUiTheatre6PVPAttackDefend:OnAwake()
    self.PanelLoading.gameObject:SetActiveEx(false)
    self:InitButtonEvents()
end

---@param mode number LineupMode
---@param enemyData XTheatre6PvpMatchEnemy|nil 敌方玩家数据（仅进攻态）
function XUiTheatre6PVPAttackDefend:OnStart(mode, enemyData)
    -- 设置自动关闭
    self:SetAutoCloseInfo(self._Control:GetPvpActivityEndTime(), function(isClose)
        if isClose then
            XMVCA.XTheatre6:HandlePvpActivityEnd()
        end
    end)

    self._Mode = mode or XEnumConst.Theatre6.Pvp.LineupMode.Attack
    self._EnemyData = enemyData
    self._IsChallenge = self._Control:IsPVPChallengeState()

    ---@type XUiPanelTheatre6PvpArchive
    self._PanelArchive = nil
    ---@type XUiPanelTheatre6PvpRightAttack
    self._PanelRightAttack = nil
    ---@type XUiPanelTheatre6PvpRightDefend
    self._PanelRightDefend = nil
    ---@type XUiPanelTheatre6PvpEnergy
    self._PanelEnergy = nil

    if self:IsDefend() then
        self._Control:SyncPvpDefenseLineup()
    end
end

function XUiTheatre6PVPAttackDefend:OnEnable()
    self:Refresh()
end

function XUiTheatre6PVPAttackDefend:OnGetLuaEvents()
    return {
        XEventId.EVENT_THEATRE6_PVP_LINEUP_CHANGE,
    }
end

function XUiTheatre6PVPAttackDefend:OnNotify(event, ...)
    if event == XEventId.EVENT_THEATRE6_PVP_LINEUP_CHANGE then
        self:RefreshOneClickBtn()
    end
end

function XUiTheatre6PVPAttackDefend:OnDestroy()
    if self._DragContext then
        self._DragContext:Destroy()
        self._DragContext = nil
    end
end

function XUiTheatre6PVPAttackDefend:GetLineupMode()
    return self._Mode
end

---@return Theatre6FileData[]
function XUiTheatre6PVPAttackDefend:GetFileDataList()
    local battleData = self._EnemyData and self._EnemyData.BattleData
    local fileDataList = self._Control:GetEnemySaveFiles(battleData)
    return fileDataList
end

function XUiTheatre6PVPAttackDefend:GetMistNum()
    return self._EnemyData and self._EnemyData.MistNum or 0
end

function XUiTheatre6PVPAttackDefend:HasDefenseBuffId()
    local defenseBuffId = self._EnemyData and self._EnemyData.BattleData and self._EnemyData.BattleData.DefenseBuffId or 0
    return XTool.IsNumberValid(defenseBuffId)
end

function XUiTheatre6PVPAttackDefend:GetCurSelectedIndex()
    if self:IsDefend() then
        return self._PanelRightDefend and self._PanelRightDefend:GetCurSelectedIndex()
    else
        return self._PanelRightAttack and self._PanelRightAttack:GetCurSelectedIndex()
    end
end

function XUiTheatre6PVPAttackDefend:IsDefend()
    return self._Mode == XEnumConst.Theatre6.Pvp.LineupMode.Defend
end

function XUiTheatre6PVPAttackDefend:SelectArchive(characterId, slotId)
    if self._PanelArchive then
        self._PanelArchive:SelectArchive(characterId, slotId)
    end
end

function XUiTheatre6PVPAttackDefend:RefreshArchiveOther()
    if self._PanelArchive then
        self._PanelArchive:RefreshBtn()
    end
end

function XUiTheatre6PVPAttackDefend:RefreshArchiveTips()
    if self._PanelArchive then
        self._PanelArchive:RefreshTips()
    end
end

--region 初始化
function XUiTheatre6PVPAttackDefend:InitButtonEvents()
    self.BtnBack:AddEventListener(handler(self, self.OnBtnBackClick))
    self.BtnFight:AddEventListener(handler(self, self.OnBtnFightClick))
    self.BtnConfirm:AddEventListener(handler(self, self.OnBtnConfirmClick))
    self.BtnOneClick:AddEventListener(handler(self, self.OnBtnOneClickClick))
    self.BtnOneClick02:AddEventListener(handler(self, self.OnBtnOneClickRemoveClick))
end
--endregion

--region 刷新
function XUiTheatre6PVPAttackDefend:Refresh()
    self:RefreshPanelArchive()
    self:RefreshPanelRight()
    self:RefreshPanelEnergy()
    self:RefreshBtn()
end

function XUiTheatre6PVPAttackDefend:RefreshPanelArchive()
    if not self._PanelArchive then
        self._PanelArchive = XUiPanelTheatre6PvpArchive.New(self.PanelArchive, self)
    end
    self._PanelArchive:Open()
    self._PanelArchive:Refresh()
end

function XUiTheatre6PVPAttackDefend:RefreshPanelRight()
    local isDefend = self:IsDefend()
    self.PanelRightAttack.gameObject:SetActiveEx(not isDefend)
    self.PanelRightDefend.gameObject:SetActiveEx(isDefend)
    if isDefend then
        self:RefreshPanelRightDefend()
    else
        self:RefreshPanelRightAttack()
    end
end

function XUiTheatre6PVPAttackDefend:RefreshPanelRightAttack()
    if not self._PanelRightAttack then
        self._PanelRightAttack = XUiPanelTheatre6PvpRightAttack.New(self.PanelRightAttack, self)
    end
    self._PanelRightAttack:Open()
    self._PanelRightAttack:Refresh()
end

function XUiTheatre6PVPAttackDefend:RefreshPanelRightDefend()
    if not self._PanelRightDefend then
        self._PanelRightDefend = XUiPanelTheatre6PvpRightDefend.New(self.PanelRightDefend, self)
    end
    self._PanelRightDefend:Open()
    self._PanelRightDefend:Refresh()
end

function XUiTheatre6PVPAttackDefend:RefreshPanelEnergy()
    -- 防守态不显示体力面板；挑战态虽然是进攻但也不显示体力面板
    local needShow = not self:IsDefend() and not self._IsChallenge
    if not needShow then
        if self._PanelEnergy then
            self._PanelEnergy:Close()
        else
            self.PanelPVPEnergy.gameObject:SetActiveEx(false)
        end
        return
    end
    if not self._PanelEnergy then
        self._PanelEnergy = XUiPanelTheatre6PvpEnergy.New(self.PanelPVPEnergy, self)
    end
    self._PanelEnergy:Open()
    self._PanelEnergy:Refresh()
end

function XUiTheatre6PVPAttackDefend:RefreshBtn()
    local isDefend = self:IsDefend()
    self.BtnFight.gameObject:SetActiveEx(not isDefend)
    self.BtnConfirm.gameObject:SetActiveEx(isDefend)
    self:RefreshOneClickBtn()

    local showActionPoint = not isDefend and not self._IsChallenge
    self.BtnFight:ActiveTextByGroup(1, showActionPoint)
    self.BtnFight:SetSpriteVisible(showActionPoint)
    if showActionPoint then
        local curActionPoint = self._Control:GetPvpCurActionPoint()
        local colorIndex = curActionPoint > 0 and 1 or 2
        local colorStr = self._Control:GetPvpClientConfigValue("ActionPointColor", colorIndex)
        self.BtnFight:SetTxtColorByGroup(1, XUiHelper.Hexcolor2Color(colorStr))
    end
end

-- 满阵时显示"一键下阵"按钮，否则显示"一键上阵"按钮
function XUiTheatre6PVPAttackDefend:RefreshOneClickBtn()
    local isFull = self._Control:GetPvpCurrentLineupCount(self:GetLineupMode()) >= 3
    self.BtnOneClick.gameObject:SetActiveEx(not isFull)
    self.BtnOneClick02.gameObject:SetActiveEx(isFull)
end
--endregion

--region 按钮事件
function XUiTheatre6PVPAttackDefend:OnBtnBackClick()
    --防守模式且阵容有变更时弹二次确认
    if not self:IsDefend() or not self._Control:CheckPvpDefenseLineupChange() then
        self:Close()
        return
    end
    self._Control:ShowPopup(self._Control:GetPvpClientConfigValue("DefendBackConfirm"),
        function()
            self:OnBtnConfirmClick()
        end,
        function()
            self._Control:SyncPvpDefenseLineup()
            self:Close()
        end)
end

-- 一键上阵按钮（仅未满阵时显示）
function XUiTheatre6PVPAttackDefend:OnBtnOneClickClick()
    local fileDataList = self._PanelArchive:GetFileDataList()
    if XTool.IsTableEmpty(fileDataList) then
        return
    end
    local doOneClick = function()
        local isSuccess = self._Control:OneClickPvpLineup(self:GetLineupMode(), fileDataList)
        if isSuccess then
            self._Control:ShowTip(self._Control:GetPvpClientConfigValue("OneClickReplaceSuccessTip"))
            self:Refresh()
        end
    end
    -- 已有上阵但未满：二次确认；全空：直接上阵
    local curLineupCount = self._Control:GetPvpCurrentLineupCount(self:GetLineupMode())
    if curLineupCount > 0 then
        self._Control:ShowPopup(self._Control:GetPvpClientConfigValue("OneClickReplaceConfirm"), doOneClick)
    else
        doOneClick()
    end
end

-- 一键下阵按钮（仅满阵时显示）：直接清空全部槽位
function XUiTheatre6PVPAttackDefend:OnBtnOneClickRemoveClick()
    if self._Control:ClearPvpCurrentLineupInfo(self:GetLineupMode()) then
        self._Control:ShowTip(self._Control:GetPvpClientConfigValue("OneClickRemoveSuccessTip"))
        self:Refresh()
    end
end

function XUiTheatre6PVPAttackDefend:OnBtnFightClick()
    if not self._EnemyData then
        return
    end
    local curLineupCount = self._Control:GetPvpCurrentLineupCount(self:GetLineupMode())
    if curLineupCount < 3 then
        self._Control:ShowTip(self._Control:GetPvpClientConfigValue("AttackSlotLimitTip"))
        return
    end
    if not self._IsChallenge then
        local actionPoint = self._Control:GetPvpCurActionPoint()
        if actionPoint <= 0 then
            self._Control:ShowTip(self._Control:GetPvpClientConfigValue("ActionPointNotEnoughTip"))
            return
        end
    end
    local lineupInfoList = self._Control:GetPvpCurrentLineupInfo(self:GetLineupMode())
    local buffId = self._Control:GetPvpCurrentLineupBuffId(self:GetLineupMode())
    if not self:CheckBuffIdValid(buffId) then
        return
    end
    self._Control:RequestPvpStartFight(self._EnemyData.Uid, lineupInfoList, buffId, function()
        XLuaUiManager.Open("UiTheatre6PVPLoading", self:GetLineupMode()) --UiTheatre6PVPLoading是TopMask类型，不能PopThenOpen
    end)
end

function XUiTheatre6PVPAttackDefend:OnBtnConfirmClick()
    local curLineupCount = self._Control:GetPvpCurrentLineupCount(self:GetLineupMode())
    local maxLimit = self._Control:GetPvpMaxSlotDefenseLineupLimit()
    if XTool.IsNumberValid(maxLimit) and curLineupCount < maxLimit then
        self._Control:ShowTip(self._Control:GetPvpClientConfigValue("DefendSlotLimitTip"))
        return
    end
    local lineupInfoList = self._Control:GetPvpCurrentLineupInfo(self:GetLineupMode())
    local buffId = self._Control:GetPvpCurrentLineupBuffId(self:GetLineupMode())
    if not self:CheckBuffIdValid(buffId) then
        return
    end
    self._Control:RequestPvpUpdateDefense(buffId, lineupInfoList, function()
        self._Control:ShowTip(self._Control:GetPvpClientConfigValue("DefendSaveSuccessTip"))
        self:Close()
    end)
end

-- 当环境效果生效时，进攻和防守都需要检查buffId是否有效，如果无效则提示玩家选择环境效果
function XUiTheatre6PVPAttackDefend:CheckBuffIdValid(buffId)
    if not self._Control:IsPvpBuffGroupIdValid() or XTool.IsNumberValid(buffId) then
        return true
    end
    self._Control:ShowPopup(self._Control:GetPvpClientConfigValue("BuffNotSelectedTipConfirm"), function()
        if self:IsDefend() then
            if self._PanelRightDefend then
                self._PanelRightDefend:OnBtnEnvironmentClick()
            end
        else
            if self._PanelRightAttack then
                self._PanelRightAttack:OnBtnEnvironmentMeClick()
            end
        end
    end)
    return false
end
--endregion

--region 跨面板拖拽（存档列表 → 上阵槽位）
-- 获取当前激活的右侧面板（进攻 / 防守）
---@return XUiPanelTheatre6PvpRightBase
function XUiTheatre6PVPAttackDefend:GetActiveRightPanel()
    if self:IsDefend() then
        return self._PanelRightDefend
    end
    return self._PanelRightAttack
end

function XUiTheatre6PVPAttackDefend:GetActiveRightTransform()
    if self:IsDefend() then
        return self.PanelRightDefend.transform
    end
    return self.PanelRightAttack.transform
end

-- 初始化跨面板拖拽上下文（供存档格子作为拖拽源使用）
---@return XUiCommonDragContext
function XUiTheatre6PVPAttackDefend:GetDragContext()
    if self._DragContext then
        return self._DragContext
    end

    local panelRoot = self:GetActiveRightTransform()
    ---@type XUiCommonDragContext
    self._DragContext = XUiCommonDragContext.New(self, panelRoot,
        {
            HitTest = XEnumConst.CommonDrag.HitTest.Rect,
            ProgressUi = self.PanelLoading, -- 长按进度条 UI
            ProgressOrder = 5,
            ProgressShowTime = self._Control:GetIntPvpClientConfigValue("ArchiveDragPressDuration"),
        })

    self._DragContext:SetOnHoverChange(function(fileData, toIndex) self:_UpdateHoverState(fileData, toIndex) end)
    self._DragContext:SetOnDrop(function(fileData, toIndex) self:_OnArchiveDrop(fileData, toIndex) end)
    return self._DragContext
end

function XUiTheatre6PVPAttackDefend:_UpdateHoverState(fileData, toIndex)
    local rightPanel = self:GetActiveRightPanel()
    if rightPanel then
        rightPanel:UpdateArchiveHoverState(fileData, toIndex)
    end
end

-- 命中有效槽位则上阵
function XUiTheatre6PVPAttackDefend:_OnArchiveDrop(fileData, toIndex)
    local rightPanel = self:GetActiveRightPanel()
    if rightPanel then
        rightPanel:UpdateArchiveHoverState()
    end
    if not fileData or not XTool.IsNumberValid(toIndex) then
        return
    end
    rightPanel:OnArchiveDrop(fileData, toIndex)
end

-- 存档格子拖拽时创建跟手克隆体
---@param fileData Theatre6FileData|nil PVP存档数据
---@return UnityEngine.RectTransform, XUiGridTheatre6PvpRole 拖拽克隆体
function XUiTheatre6PVPAttackDefend:NewArchiveDragClone(fileData)
    local rightPanel = self:GetActiveRightPanel()
    if not rightPanel then
        return nil
    end
    -- 将当前右侧面板的槽位登记为落点区域
    self._DragContext:ClearDropZones()
    for index = 1, rightPanel:GetMaxSlot() do
        local rect = rightPanel:GetSlotRectTransform(index)
        if rect then
            self._DragContext:AddDropZone(rect, index)
        end
    end
    -- 由右侧面板创建跟手克隆体
    return rightPanel:CreateDragClone(fileData)
end
--endregion

return XUiTheatre6PVPAttackDefend
