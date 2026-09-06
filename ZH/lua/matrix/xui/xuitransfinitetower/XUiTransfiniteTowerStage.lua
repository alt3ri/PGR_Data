local XUiGridTowerStage = require("XUi/XUiTransfiniteTower/Grid/XUiGridTowerStage")
local XUiPanelTransfiniteTowerTraitTips = require("XUi/XUiTransfiniteTower/Panel/XUiPanelTransfiniteTowerTraitTips")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

---@class XUiTransfiniteTowerStage : XLuaUi
---@field _Control XTransfiniteTowerControl
---@field TopControl UnityEngine.RectTransform
---@field BtnHelp XUiComponent.XUiButton
---@field BtnEarlySettlement XUiComponent.XUiButton
---@field BtnResetProgress XUiComponent.XUiButton
---@field BtnTeach XUiComponent.XUiButton
---@field ScrollView UnityEngine.RectTransform
---@field GridTowerStage UnityEngine.GameObject
---@field GridTowerBoss UnityEngine.GameObject
---@field BtnLocateTop XUiComponent.XUiButton
---@field BtnLocateBottom XUiComponent.XUiButton
---@field TxtTowerName UnityEngine.UI.Text
---@field TxtTowerTip UnityEngine.UI.Text
---@field PanelTrait UnityEngine.GameObject
---@field PanelTraitTips01 UnityEngine.GameObject
---@field PanelTraitTips02 UnityEngine.GameObject
---@field BtnBattlePreparation XUiComponent.XUiButton
---@field BtnRollback XUiComponent.XUiButton
---@field PanelFormationTips UnityEngine.GameObject
---@field TxtFormationTips UnityEngine.UI.Text
---@field PanelTime UnityEngine.GameObject
---@field TxtTime02 UnityEngine.UI.Text
local XUiTransfiniteTowerStage = XLuaUiManager.Register(XLuaUi, "UiTransfiniteTowerStage")

function XUiTransfiniteTowerStage:OnAwake()
    self:InitTopControl()
    self:InitRoleModel()
    self:InitDynamicTable()
    self:InitTraitPanels()
    self:RegisterButtonEvent()
end

---@param towerCfgId number 由主界面进入时传入的塔配置id
function XUiTransfiniteTowerStage:OnStart(towerCfgId)
    self.TowerCfgId = towerCfgId
    local endTime = XMVCA.XTransfiniteTower:GetTowerUnlockEndTime(towerCfgId)
    if endTime > 0 then
        self:SetAutoCloseInfo(endTime, handler(self, self.OnTowerClosed))
    end
end

function XUiTransfiniteTowerStage:OnTowerClosed(isClose)
    if not isClose then
        return
    end
    XUiManager.TipMsg(XUiHelper.GetText("TransfiniteTowerTowerClosed"))
    self:Close()
end

function XUiTransfiniteTowerStage:OnEnable()
    -- 结算/回溯/重置后服务端推单章节数据，靠该事件即时刷新本界面
    XEventManager.AddEventListener(XEventId.EVENT_TRANSFINITE_TOWER_DATA_CHANGE, self.Refresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_TRANSFINITE_TOWER_GUIDE_SCROLL_STAGE, self.RollToStageIndex, self)
    XMVCA.XTransfiniteTower:SetStageUiTowerCfgId(self.TowerCfgId)
    self._NeedRollToTop = true
    self:Refresh()
end

function XUiTransfiniteTowerStage:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_TRANSFINITE_TOWER_DATA_CHANGE, self.Refresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TRANSFINITE_TOWER_GUIDE_SCROLL_STAGE, self.RollToStageIndex, self)
    XMVCA.XTransfiniteTower:SetStageUiTowerCfgId(nil)
end

--region 初始化

function XUiTransfiniteTowerStage:InitTopControl()
    self._TopControl = XUiHelper.NewPanelTopControl(self, self.TopControl)
end

function XUiTransfiniteTowerStage:InitRoleModel()
    local root = self.UiModelGo.transform
    self._UiModelParent = root:FindTransform("PanelRoleModel")
    ---@type XUiPanelRoleModel
    self._RoleModel = XUiPanelRoleModel.New(self._UiModelParent)
end

function XUiTransfiniteTowerStage:InitDynamicTable()
    self._DynamicTable = XDynamicTableNormal.New(self.ScrollView.gameObject)
    self._DynamicTable:SetProxy(XUiGridTowerStage, self)
    self._DynamicTable:SetDelegate(self)
    self.GridTowerStage.gameObject:SetActiveEx(false)
    -- 监听滚动，实时刷新定位按钮显隐
    self._DynamicTable:GetImpl().ScrRect.onValueChanged:AddListener(handler(self, self.OnListScroll))
end

function XUiTransfiniteTowerStage:OnListScroll()
    self:RefreshLocateButtons()
end

function XUiTransfiniteTowerStage:InitTraitPanels()
    ---@type XUiPanelTransfiniteTowerTraitTips[] 下标即词缀序号
    self._TraitPanels = {
        XUiPanelTransfiniteTowerTraitTips.New(self.PanelTraitTips01, self),
        XUiPanelTransfiniteTowerTraitTips.New(self.PanelTraitTips02, self),
    }
end

function XUiTransfiniteTowerStage:RegisterButtonEvent()
    self.BtnEarlySettlement:AddEventListener(handler(self, self.OnBtnEarlySettlementClick))
    self.BtnResetProgress:AddEventListener(handler(self, self.OnBtnResetProgressClick))
    self.BtnTeach:AddEventListener(handler(self, self.OnBtnTeachClick))
    self.BtnBattlePreparation:AddEventListener(handler(self, self.OnBtnBattlePreparationClick))
    self.BtnRollback:AddEventListener(handler(self, self.OnBtnRollbackClick))
    self.BtnLocateTop:AddEventListener(handler(self, self.OnBtnLocateClick))
    self.BtnLocateBottom:AddEventListener(handler(self, self.OnBtnLocateClick))
    self:BindHelpBtn(self.BtnHelp, "TransfiniteTowerHelp")
end

--endregion

--region 刷新

function XUiTransfiniteTowerStage:Refresh()
    if self._Control:IsTowerClosed(self.TowerCfgId) then
        XUiManager.TipMsg(XUiHelper.GetText("TransfiniteTowerTowerClosed"))
        self:Close()
        return
    end
    self:RefreshDefaultSelect()
    self:RefreshStageList()
    self:RefreshBossGrid()
    self:RefreshTitle()
    self:RefreshRoleModel()
    self:RefreshTrait()
    self:RefreshFormationTips()
    self:RefreshBottomButtons()
    self:RefreshLocateButtons()
    self:RefreshTimePanel()
end

---累计用时：仅 15 层塔显示（排行塔计时）
function XUiTransfiniteTowerStage:RefreshTimePanel()
    local isShow = self._Control:IsLastSettleTower(self.TowerCfgId)
    self.PanelTime.gameObject:SetActiveEx(isShow)
    if isShow then
        self.TxtTime02.text = XUiHelper.GetTime(
            self._Control:GetSettleTotalClearTime(self.TowerCfgId),
            XUiHelper.TimeFormatType.MINUTE_SECOND)
    end
end

function XUiTransfiniteTowerStage:RefreshRoleModel()
    local modelName = self._Control:GetStageModelName(self._SelectedStageCfgId)
    if string.IsNilOrEmpty(modelName) or modelName == self._CurModelName then
        return
    end
    self._CurModelName = modelName
    self._RoleModel:UpdateRoleModel(modelName, nil, self.Name, nil, nil, true)
end

---首次打开默认选中当前最高层，否则标题/词缀/底部按钮没有选中层依据
function XUiTransfiniteTowerStage:RefreshDefaultSelect()
    if XTool.IsNumberValid(self._SelectedStageCfgId) then
        return
    end
    self._SelectedStageCfgId = self._Control:GetTopStageCfgId(self.TowerCfgId)
end

function XUiTransfiniteTowerStage:RefreshStageList()
    self._StageCfgIds = self._Control:GetTowerStageCfgIds(self.TowerCfgId)
    -- 最高层下标随通关进度变化，列表刷新时算一次；滚动回调只比对可视区间
    self._TopStageIndex = self:CalcTopStageIndex()
    self._DynamicTable:SetDataSource(self._StageCfgIds)
    self._DynamicTable:ReloadDataSync(1)
end

function XUiTransfiniteTowerStage:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self._StageCfgIds[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        if self._NeedRollToTop then
            self:RollToTopStage()
            self._NeedRollToTop = false
        end
    end
end

---最终层：3 层塔隐藏，8/15 层塔显示
function XUiTransfiniteTowerStage:RefreshBossGrid()
    local isShowBoss = self._Control:IsShowBossGrid(self.TowerCfgId)
    self.GridTowerBoss.gameObject:SetActiveEx(isShowBoss)
    if isShowBoss then
        if not self._BossGrid then
            self._BossGrid = XUiGridTowerStage.New(self.GridTowerBoss, self)
        end
        self._BossGrid:Refresh(self._Control:GetTowerBossStageCfgId(self.TowerCfgId))
    end
end

function XUiTransfiniteTowerStage:RefreshTitle()
    self.TxtTowerName.text = self._Control:GetTowerTitle(self.TowerCfgId, self._SelectedStageCfgId)
    self.TxtTowerTip.text = self._Control:GetTowerSubTitle(self._SelectedStageCfgId)
end

function XUiTransfiniteTowerStage:RefreshTrait()
    local traits = self._Control:GetStageTraitList(self._SelectedStageCfgId)
    for i = 1, #self._TraitPanels do
        local trait = traits[i]
        local panel = self._TraitPanels[i]
        panel.GameObject:SetActiveEx(trait ~= nil)
        if trait then
            panel:Open()
            panel:Refresh(trait)
        else
            panel:Close()
        end
    end
end

---上阵要求提示：与编队界面同源，无要求时隐藏
function XUiTransfiniteTowerStage:RefreshFormationTips()
    local tip = self._Control:GetStageFormationTip(self._SelectedStageCfgId)
    local isShow = not string.IsNilOrEmpty(tip)
    self.PanelFormationTips.gameObject:SetActiveEx(isShow)
    if isShow then
        self.TxtFormationTips.text = tip
    end
end

---底部按钮：3 层塔用领航员教学按钮，其余用提前结算/重置进度
function XUiTransfiniteTowerStage:RefreshBottomButtons()
    local isTeachTower = self._Control:IsTeachTower(self.TowerCfgId)
    -- 上轮记录未清时只给重置进度，清掉才能重新开一轮
    local hasLastRecord = self._Control:HasLastStageRecord(self.TowerCfgId)
    local hasPassedAny = self._Control:GetTowerPassedCount(self.TowerCfgId) > 0
    local isCompleted = self._Control:IsCurrentRunCompleted(self.TowerCfgId)
    local titleKey = isCompleted and "TransfiniteTowerSettlementTitle" or "TransfiniteTowerEarlySettlementTitle"

    -- 3 层塔：始终显示领航员教学按钮，无提前结算/重置
    self.BtnTeach.gameObject:SetActiveEx(isTeachTower)
    self.BtnEarlySettlement.gameObject:SetActiveEx(not isTeachTower and not hasLastRecord and hasPassedAny)
    self.BtnEarlySettlement:SetNameByGroup(0, XUiHelper.GetText(titleKey))
    self.BtnResetProgress.gameObject:SetActiveEx(not isTeachTower and hasLastRecord)

    self:RefreshBattlePreparationButton()
    self:RefreshRollbackButton()
end

---作战准备按钮：多态（作战准备/上层未通关/作战完成/重新挑战）
function XUiTransfiniteTowerStage:RefreshBattlePreparationButton()
    local state = self._Control:GetBattlePrepareState(self.TowerCfgId, self._SelectedStageCfgId)
    local BattlePrepareState = self._Control.BattlePrepareState
    -- 仅「可作战」与「重新挑战」为亮起态
    local isEnable = state == BattlePrepareState.Normal or state == BattlePrepareState.Rechallenge
    self.BtnBattlePreparation:SetDisable(not isEnable)

    local textKey
    if state == BattlePrepareState.Normal then
        textKey = "TransfiniteTowerBattlePrepare"       -- 作战准备
    elseif state == BattlePrepareState.PrevNotPass then
        textKey = "TransfiniteTowerBattlePrevNotPass"   -- 上层未通关
    elseif state == BattlePrepareState.Completed then
        textKey = "TransfiniteTowerBattleCompleted"     -- 作战完成
    elseif state == BattlePrepareState.Rechallenge then
        textKey = "TransfiniteTowerBattleRechallenge"   -- 重新挑战
    else
        textKey = "TransfiniteTowerBattleCompleted"     -- NeedReset：塔已终结，待重置
    end
    self.BtnBattlePreparation:SetNameByGroup(0, XUiHelper.GetText(textKey))
end

---回溯按钮：仅回溯层显示，亮灭由回溯点是否可用决定
function XUiTransfiniteTowerStage:RefreshRollbackButton()
    local isRollbackLayer = self._Control:IsRollbackLayer(self._SelectedStageCfgId)
    self.BtnRollback.gameObject:SetActiveEx(isRollbackLayer)
    if isRollbackLayer then
        local isActive = self._Control:IsRollbackBtnActive(self.TowerCfgId, self._SelectedStageCfgId)
        self.BtnRollback:SetDisable(not isActive, isActive)
    end
end

---定位按钮：当前最高层不在可视范围时显示（上方/下方）
function XUiTransfiniteTowerStage:RefreshLocateButtons()
    local topIndex = self._TopStageIndex or 0
    local startIndex = self._DynamicTable:GetStartIndex()
    local endIndex = self._DynamicTable:GetEndIndex()
    -- 无最高层 / 列表布局未就绪时，一律隐藏两个定位按钮
    if topIndex <= 0 or not XTool.IsNumberValid(startIndex) or not XTool.IsNumberValid(endIndex) then
        self.BtnLocateTop.gameObject:SetActiveEx(false)
        self.BtnLocateBottom.gameObject:SetActiveEx(false)
        return
    end
    -- 最高层在可视范围上方 → 显示上方定位按钮；下方 → 显示下方定位按钮；在可视区内则都不显示
    self.BtnLocateTop.gameObject:SetActiveEx(topIndex < startIndex)
    self.BtnLocateBottom.gameObject:SetActiveEx(topIndex > endIndex)
end

---计算当前最高层在关卡列表中的下标（0 表示无/未就绪），仅列表刷新时调用
---@return number
function XUiTransfiniteTowerStage:CalcTopStageIndex()
    local topStageCfgId = self._Control:GetTopStageCfgId(self.TowerCfgId)
    if not XTool.IsNumberValid(topStageCfgId) then
        return 0
    end
    for i = 1, #self._StageCfgIds do
        if self._StageCfgIds[i] == topStageCfgId then
            return i
        end
    end
    return 0
end

--endregion

--region 塔层选中

---选中某塔层：切换选中态并刷新依赖选中层的 UI（标题/词缀/底部按钮）
---@param grid XUiGridTowerStage 被选中的塔层项
---@param stageCfgId number 关卡配置id
function XUiTransfiniteTowerStage:OnStageGridSelected(grid, stageCfgId)
    self:SelectStage(stageCfgId)
end

---选中指定关卡层（点击/定位统一走此逻辑）
---@param stageCfgId number 关卡配置id
function XUiTransfiniteTowerStage:SelectStage(stageCfgId)
    if self._SelectedStageCfgId == stageCfgId then
        return
    end
    self._SelectedStageCfgId = stageCfgId
    self:RefreshAllGridSelect()

    self:RefreshTitle()
    self:RefreshRoleModel()
    self:RefreshTrait()
    self:RefreshFormationTips()
    self:RefreshBottomButtons()
end

---刷新所有 grid（动态列表可见项 + 底部最终层）的选中态
function XUiTransfiniteTowerStage:RefreshAllGridSelect()
    for _, grid in pairs(self._DynamicTable:GetGrids()) do
        grid:SetSelect(self:IsStageSelected(grid.StageCfgId))
    end
    if self._BossGrid then
        self._BossGrid:SetSelect(self:IsStageSelected(self._BossGrid.StageCfgId))
    end
end


---供 grid 在刷新（含动态列表滚动复用）时查询自身是否为当前选中层
function XUiTransfiniteTowerStage:IsStageSelected(stageCfgId)
    return self._SelectedStageCfgId == stageCfgId
end

--endregion

--region 按钮回调

---提前结算：二次确认 → 确认后按塔类型跳转结算
---已通关最后一层时换用「通关结算」文案，否则用「提前结算」文案
function XUiTransfiniteTowerStage:OnBtnEarlySettlementClick()
    local isCompleted = self._Control:IsCurrentRunCompleted(self.TowerCfgId)
    local titleKey = isCompleted and "TransfiniteTowerSettlementTitle" or "TransfiniteTowerEarlySettlementTitle"
    local contentKey = isCompleted and "TransfiniteTowerSettlementContent" or "TransfiniteTowerEarlySettlementContent"
    XUiManager.DialogTip(XUiHelper.GetText(titleKey), XUiHelper.GetText(contentKey),
        XUiManager.DialogType.Normal, nil, handler(self, self.OnEarlySettlementConfirm))
end

function XUiTransfiniteTowerStage:OnEarlySettlementConfirm()
    self._Control:EnterEarlySettlement(self.TowerCfgId)
end

---重置进度：清空上轮记录
function XUiTransfiniteTowerStage:OnBtnResetProgressClick()
    local content = XUiHelper.GetText("TransfiniteTowerReset")
    XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, nil, handler(self, self.OnResetProgressConfirm))
end

function XUiTransfiniteTowerStage:OnResetProgressConfirm()
    self._Control:ResetTowerProgress(self.TowerCfgId)
    self:RollToTopStage()
end

---领航员教学：跳转教学界面
function XUiTransfiniteTowerStage:OnBtnTeachClick()
    XLuaUiManager.Open("UiTransfiniteTowerTeach")
end

---作战准备：按当前态处理
function XUiTransfiniteTowerStage:OnBtnBattlePreparationClick()
    local state = self._Control:GetBattlePrepareState(self.TowerCfgId, self._SelectedStageCfgId)
    local BattlePrepareState = self._Control.BattlePrepareState
    if state == BattlePrepareState.PrevNotPass then
        XUiManager.TipMsg(XUiHelper.GetText("TransfiniteTowerPrevStageNotPassTip"))  -- 【请先通关上一层】
    elseif state == BattlePrepareState.NeedReset then
        if self._Control:IsTeachTower(self.TowerCfgId) then return end
    XUiManager.TipMsg(XUiHelper.GetText("TransfiniteTowerNeedResetTip"))  -- 【请先重置进度】
    elseif state == BattlePrepareState.Rechallenge then
        self._Control:RechallengeStage(self.TowerCfgId, self._SelectedStageCfgId)
    elseif state == BattlePrepareState.Normal then
        self._Control:EnterBattlePrepare(self.TowerCfgId, self._SelectedStageCfgId)
    end
end

---回溯：二次确认 → 确认后 toast + 回溯请求
function XUiTransfiniteTowerStage:OnBtnRollbackClick()
    if not self._Control:IsRollbackBtnActive(self.TowerCfgId, self._SelectedStageCfgId) then
        XUiManager.TipMsg(self._Control:GetRollbackDisableTip(self.TowerCfgId, self._SelectedStageCfgId))
        return
    end
    local title = XUiHelper.GetText("TransfiniteTowerRollbackTitle")
    local content = XUiHelper.GetText("TransfiniteTowerRollbackContent")
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, handler(self, self.OnRollbackConfirm))
end

---回溯成功提示由 Control 统一发，界面刷新由数据变更事件驱动
function XUiTransfiniteTowerStage:OnRollbackConfirm()
    self._Control:RollbackToStage(self.TowerCfgId)
end

---定位：滚动列表至当前最高层并选中
function XUiTransfiniteTowerStage:OnBtnLocateClick()
    self:RollToTopStage()
end

function XUiTransfiniteTowerStage:RollToTopStage()
    local topIndex = self._TopStageIndex or 0
    if topIndex <= 0 then
        return
    end
    self:RollToStageIndex(topIndex)
end

---滚动列表到指定下标并选中该层
function XUiTransfiniteTowerStage:RollToStageIndex(index)
    index = tonumber(index)
    local stageCfgId = index and self._StageCfgIds and self._StageCfgIds[index]
    if not stageCfgId then
        return
    end
    self._DynamicTable:UpdateViewSize()
    self._DynamicTable:ScrollToIndex(index, 0.3)
    self:SelectStage(stageCfgId)
end

--endregion

return XUiTransfiniteTowerStage
