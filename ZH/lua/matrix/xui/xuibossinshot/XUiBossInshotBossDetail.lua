local XUiPanelBossInshotTowerRight = require(
    "XUi/XUiBossInshot/XUiPanelBossInshotTowerRight")

local XUiPanelBossInshotTowerLevelSelector = require(
    "XUi/XUiBossInshot/XUiPanelBossInshotTowerLevelSelector")

local XUiPanelBossInshotTowerChooseBossBeforeAllClear = require(
    "XUi/XUiBossInshot/XUiPanelBossInshotTowerChooseBossBeforeAllClear")

---@class XUiBossInshotBossDetail:XLuaUi
---@field private _Control XBossInshotControl
local XUiBossInshotBossDetail = XClass(XUiNode, "XUiBossInshotBossDetail")

function XUiBossInshotBossDetail:OnStart(switchBossModel, showBlackHole)
    self._SwitchBossModel = switchBossModel
    self._ShowBlackHole = showBlackHole

    self:RegisterUiEvents()
    local towerPanelRightArgs = {
        AnimationNode = self.Parent,
        CacheDifficultyIndexAndSkillIndex = handler(
            self.Parent,
            self.Parent.CacheDifficultyIndexAndSkillIndex)
    }

    self._PanelTowerRightTowerHigh = XUiPanelBossInshotTowerRight.New(
        self.PanelRightHigh,
        self,
        towerPanelRightArgs)

    self._PanelTowerRightTowerLow = XUiPanelBossInshotTowerRight.New(
        self.PanelRightLow,
        self,
        towerPanelRightArgs)

    self._PanelTowerRightTowerHigh:Close()
    self._PanelTowerRightTowerLow:Close()
end

function XUiBossInshotBossDetail:OnDisable()
    if self._UiTowerLevelSelector then self._UiTowerLevelSelector:Close() end
    if self._UiPanelChooseBoss then self._UiPanelChooseBoss:Close() end
    if self._PanelTowerRightTowerHigh then self._PanelTowerRightTowerHigh:Close() end
    if self._PanelTowerRightTowerLow then self._PanelTowerRightTowerLow:Close() end
end

function XUiBossInshotBossDetail:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnChangeBoss, self.OnBtnChangeBossClick, nil, true)

    local btns = { self.BtnDifficulty1, self.BtnDifficulty2, self.BtnDifficulty3 }
    self.PanelDifficulty:Init(btns, function(index)
        self:_OnBtnDifficultyClick(index)
    end)
end

function XUiBossInshotBossDetail:_OnBtnDifficultyClick(index)
    -- 所选难度关卡未解锁
    local stageId = self._BossInfo.StageIds[index]
    local isUnlock, desc = self._Control:IsStageUnlock(stageId)
    if not isUnlock then
        XUiManager.TipError(desc)
        return
    end

    -- 刷新选中状态
    local Select = CS.UiButtonState.Select
    local Normal = CS.UiButtonState.Normal
    local Disable = CS.UiButtonState.Disable
    for i, sId in ipairs(self._BossInfo.StageIds) do
        local state = Disable
        local isUnlock, _ = self._Control:IsStageUnlock(sId)
        if isUnlock then
            state = i == index and Select or Normal
        end
        self["BtnDifficulty" .. tostring(i)]:SetButtonState(state)
    end
    self._BossInfo.DifficultyIndex = index
end



function XUiBossInshotBossDetail:OnBtnChangeBossClick()
    if not self.TowerMode then return end

    XLuaUiManager.Open(
        "UiBossInshotPopupChangeBoss",
        self._Control,
        self._Control:GetBossTowerData(self.TowerLevelConfig.Id),
        self.TowerLevelConfig.Stages,
        function(selectedStageId)
            self._Control:TowerSelectStageAfterAllClear(
                self.TowerLevelConfig.Id,
                selectedStageId,
                function(resp)
                    if resp.Code ~= XCode.Success then
                        XUiManager.TipCode(resp.Code)
                        return
                    end

                    self:OnTowerSelectLevel(
                        self.TowerLevelConfig,
                        self._Control:GetBossTowerData(self.TowerLevelConfig.Id))

                    self._UiTowerLevelSelector:Refresh(true)
                end)
        end)
end

function XUiBossInshotBossDetail:RefreshAsTower()
    self.TowerMode = true
    self.PanelDifficulty.gameObject:SetActiveEx(false)

    -- 摄像机镜头
    self.Parent:SwitchCamera("UiModeCamFarDetail", "UiModeCamNearDetail")

    if not self._UiTowerLevelSelector then
        -- 首次创建前需激活 GameObject，InitNode 中 activeSelf 为 true 时会自动调用 Open()
        self.PanelTowerTab.gameObject:SetActiveEx(true)
        self._UiTowerLevelSelector = XUiPanelBossInshotTowerLevelSelector.New(
            self.PanelTowerTab,
            self,
            handler(self, self.OnTowerSelectLevel),
            self._Control)
    else
        -- 已有实例时通过节点系统打开，保持 _IsNodeShow 状态正确
        self._UiTowerLevelSelector:Open()
    end

    self._UiTowerLevelSelector:Refresh()
end

function XUiBossInshotBossDetail:OnTowerSelectLevel(levelConf, towerData)
    assert(levelConf.Id == towerData.TowerId)

    local allClear = self._Control:IsTowerAllClear()
    local isChallengeTower = levelConf.Type == 2

    if isChallengeTower then
        self._PanelTowerRightTowerLow:Close()
        self._PanelTowerRightTower = self._PanelTowerRightTowerHigh
    else
        self._PanelTowerRightTowerHigh:Close()
        self._PanelTowerRightTower = self._PanelTowerRightTowerLow
    end

    if towerData.SelectStageId == 0 then    -- 尚未选择Boss，打开Boss选择界面
        self._PanelTowerRightTower:Close()

        self.BtnChangeBoss.gameObject:SetActiveEx(false)
        if not self._UiPanelChooseBoss  then
            self._UiPanelChooseBoss =
                XUiPanelBossInshotTowerChooseBossBeforeAllClear.New(
                    self.PanelChooseBoss,
                    self,
                    self._SwitchBossModel,
                    self._ShowBlackHole)
        end

        self._UiPanelChooseBoss:Open()

        self._UiPanelChooseBoss:SetData(
            levelConf,
            towerData,
            function(selectedStageId)
                self._Control:TowerSelectStage(
                    levelConf.Id,
                    selectedStageId,
                    function(resp)
                        if resp.Code ~= XCode.Success then
                            XUiManager.TipCode(resp.Code)
                            return
                        end

                        self:OnTowerSelectLevel(levelConf, towerData)
                        self._UiTowerLevelSelector:Refresh()
                end)
            end)

    else
        if self._UiPanelChooseBoss then
            self._UiPanelChooseBoss:Close()
        else
            self.PanelChooseBoss.gameObject:SetActiveEx(false)
        end

        self.BtnChangeBoss.gameObject:SetActiveEx(allClear and #levelConf.Stages > 1)
        local selectStageId = towerData.SelectStageId

        if allClear
            and towerData.SelectStageIdAfterAllPass
            and towerData.SelectStageIdAfterAllPass ~= 0 then

            selectStageId = towerData.SelectStageIdAfterAllPass
        end

        self.TowerLevelConfig = levelConf
        local bossId = self._Control:GetTowerBossIdByStageId(selectStageId)
        if self._SwitchBossModel then self._SwitchBossModel(bossId) end

        self._BossInfo = {
            TowerMode = true,
            TowerLevelConfig = levelConf,
            TowerData = towerData,
            AllClear = allClear,
            BossId = bossId,
            StageIds = self._Control:GetBossStageIds(bossId),
            SelectedTowerStageId = selectStageId,
            SkillIds = self._Control:GetBossSkillIds(bossId),
            SkillIndex = 1
        }

        self._PanelTowerRightTower:Open()
        self._PanelTowerRightTower:RefreshAsTower(self._BossInfo)
    end
end

function XUiBossInshotBossDetail:RefreshAsNormal(bossId, difficultyIndex, skillIndex)
    self.BtnChangeBoss.gameObject:SetActiveEx(false)

    if self._UiTowerLevelSelector then
        -- 通过节点系统关闭，保持 _IsNodeShow 状态正确，避免下次 Open() 时 EnableChildNodes 误触发
        self._UiTowerLevelSelector:Close()
    else
        self.PanelTowerTab.gameObject:SetActiveEx(false)
    end

    self.PanelDifficulty.gameObject:SetActiveEx(true)

    difficultyIndex = difficultyIndex or 1

    self._BossInfo = {
        BossId = bossId,
        StageIds = self._Control:GetBossStageIds(bossId),
        DifficultyIndex = difficultyIndex,
        SkillIndex = skillIndex or 1,
        SkillIds = self._Control:GetBossSkillIds(bossId)
    }

    -- 难度列表
    local Select = CS.UiButtonState.Select
    local Normal = CS.UiButtonState.Normal
    local Disable = CS.UiButtonState.Disable
    for i, inshotStageId in ipairs(self._BossInfo.StageIds) do
        local btn = self["BtnDifficulty".. i]
        local stageName = self._Control:GetStageName(inshotStageId)
        btn:SetNameByGroup(0, stageName)

        local state = Disable
        local isUnlock, _ = self._Control:IsStageUnlock(inshotStageId)
        if isUnlock then
            state = i == difficultyIndex and Select or Normal
        end
        btn:SetButtonState(state)

        -- 关卡评分
        local stageId = self._Control:GetStageStageId(inshotStageId)
        local stageData = self._Control:GetPassStageData(stageId)
        btn:SetRawImageVisible(stageData ~= nil)
        if stageData then
            local difficulty = self._Control:GetStageDifficulty(inshotStageId)
            local levelIcon = self._Control:GetScoreLevelIcon(difficulty, stageData.MaxScore)
            btn:SetRawImage(levelIcon)
            btn:SetNameByGroup(1, stageData.MaxScore)
        else
            btn:SetNameByGroup(1, "")
        end
    end

    -- 摄像机镜头
    self.Parent:SwitchCamera("UiModeCamFarDetail", "UiModeCamNearDetail")

    self._PanelTowerRightTowerHigh:Close()
    self._PanelTowerRightTower = self._PanelTowerRightTowerLow
    self._PanelTowerRightTower:Open()
    self._PanelTowerRightTower:RefreshAsNormal(self._BossInfo)
end


return XUiBossInshotBossDetail
