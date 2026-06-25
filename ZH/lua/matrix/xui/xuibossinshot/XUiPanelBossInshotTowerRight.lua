local XUiPanelBossInshotTowerScoreTip = require(
    "XUi/XUiBossInshot/XUiPanelBossInshotTowerScoreTip")

local XUiPanelBossInshotTowerRight = XClass(
    XUiNode, "XUiPanelBossInshotTowerRight")

function XUiPanelBossInshotTowerRight:OnStart(args)
    self._AnimationNode = args.AnimationNode
    self._CacheDifficultyIndexAndSkillIndex =
        args.CacheDifficultyIndexAndSkillIndex

    self.VideoPlayerUgui.gameObject:SetActiveEx(false)
    self.GridDots = { self.GridDot }
    self:RegisterUiEvents()
end

function XUiPanelBossInshotTowerRight:RefreshAsTower(bossInfo)
    self._BossInfo = bossInfo

    self.BtnFightTeach.gameObject:SetActiveEx(false)
    self.BtnTeaching.gameObject:SetActiveEx(true)
    self.BtnFight.gameObject:SetActiveEx(true)
    self.BtnPlayback.gameObject:SetActiveEx(self._Control:GetIsShowPlayback())

    if not self._TowerScoreTip then
        self._TowerScoreTip = XUiPanelBossInshotTowerScoreTip.New(
            self.PanelTowerTips,
            self)
    end

    self._TowerScoreTip:Open()

    self._TowerScoreTip:SetLevel(
        bossInfo.TowerLevelConfig,
        bossInfo.TowerData,
        bossInfo.AllClear,
        self._Control:IsTowerFinalLevel(bossInfo.TowerLevelConfig.Id))

    self:RefreshTowerBossSkill(bossInfo.SelectedTowerStageId)
end

function XUiPanelBossInshotTowerRight:RefreshAsNormal(bossInfo)
    self._BossInfo = bossInfo

    if self._TowerScoreTip then
        self._TowerScoreTip:Close()
    else
        self.PanelTowerTips.gameObject:SetActiveEx(false)
    end


    -- 回放按钮
    local isShowPlayback = self._Control:GetIsShowPlayback()
    self.BtnPlayback.gameObject:SetActiveEx(isShowPlayback)

    -- 挑战和教学按钮
    local isTeachPass = self._Control:IsTeachStagePass()
    self.BtnTeaching.gameObject:SetActiveEx(isTeachPass)
    self.BtnFight.gameObject:SetActiveEx(isTeachPass)
    self.BtnFightTeach.gameObject:SetActiveEx(not isTeachPass)

    -- Boss名称
    self.TxtBossNameDetail.text = self._Control:GetBossName(bossInfo.BossId)

    -- 技能
    self:_RefreshSkillInfo()

end

function XUiPanelBossInshotTowerRight:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnPlayback, self._OnBtnPlaybackClick, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnTeaching, self._OnBtnTeachingClick, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnFight, self._OnBtnFightClick, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnLeft, self._OnBtnLeftClick, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnRight, self._OnBtnRightClick, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnPractice, self._OnBtnPracticeClick, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnFightTeach, self._OnBtnTeachingClick, nil, true)
end

function XUiPanelBossInshotTowerRight:OnDisable()
    self:_StopSkillVideo()
end

function XUiPanelBossInshotTowerRight:_OnBtnPlaybackClick()
    XLuaUiManager.Open("UiBossInshotPlayback", self._BossInfo.BossId)
end

function XUiPanelBossInshotTowerRight:_OnBtnTeachingClick()
    local activityId = self._Control:GetActivityId()
    local stageId = self._Control:GetActivityTeachStageId(activityId)
    local proxy = require("XUi/XUiBossInshot/XUiBossInshotBattleRoleRoom")
    XMVCA.XFuben:OpenUiBattleRoleRoom(stageId, nil, proxy)
end

function XUiPanelBossInshotTowerRight:_OnBtnFightClick()
    if self._BossInfo.TowerMode then
        self:_EnterBattleRoleRoomTower()
    else
        self:_OnBtnFightClickNormal()
    end
end


function XUiPanelBossInshotTowerRight:_OnBtnFightClickNormal()
    -- 教学关未完成
    local isTeachPass = self._Control:IsTeachStagePass()
    if not isTeachPass then
        -- 二次确认前往教学关
        local txtTitle = XUiHelper.GetText("TipTitle")
        local txtContent = XUiHelper.GetText("BossInshotFightTips")
        XUiManager.DialogTip(txtTitle, txtContent, XUiManager.DialogType.Normal, nil, function()
            self:_OnBtnTeachingClick()
        end)
        return
    end
    self:_EnterBattleRoleRoomNormal()
end

function XUiPanelBossInshotTowerRight:_OnBtnLeftClick()
    if self._BossInfo.SkillIndex > 1 then
        self._BossInfo.SkillIndex = self._BossInfo.SkillIndex - 1
    else
        self._BossInfo.SkillIndex = #self._BossInfo.SkillIds
    end
    self:_RefreshSkillInfo()
    self._AnimationNode:PlayAnimation("QieHuan")
end

function XUiPanelBossInshotTowerRight:_OnBtnRightClick()
    local skillCnt = #self._BossInfo.SkillIds
    if self._BossInfo.SkillIndex < skillCnt then
        self._BossInfo.SkillIndex = self._BossInfo.SkillIndex + 1
    else
        self._BossInfo.SkillIndex = 1
    end
    self:_RefreshSkillInfo()
    self._AnimationNode:PlayAnimation("QieHuan")
end

function XUiPanelBossInshotTowerRight:_OnBtnPracticeClick()
    local skillId = self._BossInfo.SkillIds[self._BossInfo.SkillIndex]
    local skillCfg = self._Control:GetConfigBossInshotSkill(skillId)
    if skillCfg.PracticeStageId ~= 0 then
        if not self._BossInfo.TowerMode then
            self._CacheDifficultyIndexAndSkillIndex(self.DifficultyIndex, self.SkillIndex)
        end
        XMVCA.XBossInshot:BossInshotSelectSkillRequest(skillCfg.PracticeStageId, skillCfg.FightEventId)
        local team = self._Control:GetTeam()
        local proxy = require("XUi/XUiBossInshot/XUiBossInshotBattleRoleRoom")
        XMVCA.XFuben:OpenUiBattleRoleRoom(skillCfg.PracticeStageId, team, proxy)
    end
end

-- 刷新技能信息
function XUiPanelBossInshotTowerRight:_RefreshSkillInfo()
    -- 技能描述
    local skillId = self._BossInfo.SkillIds[self._BossInfo.SkillIndex]
    self.TxtSkillName.text = self._Control:GetSkillName(skillId)
    self.TxtSkillTips.text = self._Control:GetSkillTips(skillId)
    self.TxtSkillDetail.text = self._Control:GetSkillDesc(skillId)

    -- 技能视频
    self:_StopSkillVideo()
    local videoUrl = self._Control:GetSkillVideoUrl(skillId)
    self.VideoComponent = XUiHelper.Instantiate(self.VideoPlayerUgui, self.VideoPlayerUgui.transform.parent)
    self.VideoComponent.gameObject:SetActiveEx(true)
    self.VideoComponent:SetVideoFromRelateUrl(videoUrl)
    self.VideoComponent:Play()

    -- 点列表
    local isShowDot = #self._BossInfo.SkillIds > 1
    self.PanelDot.gameObject:SetActiveEx(isShowDot)
    if isShowDot then
        for _, dot in ipairs(self.GridDots) do
            dot.gameObject:SetActiveEx(false)
        end
        local CSInstantiate = CS.UnityEngine.Object.Instantiate
        for i, _ in ipairs(self._BossInfo.SkillIds) do
            local dot = self.GridDots[i]
            if not dot then
                local go = CSInstantiate(self.GridDot.gameObject, self.PanelDot.transform)
                dot = go:GetComponent("UiObject")
                self.GridDots[i] = dot
            end
            dot.gameObject:SetActiveEx(true)
            local isSelect = i == self._BossInfo.SkillIndex
            dot:GetObject("ImgOn").gameObject:SetActiveEx(isSelect)
            dot:GetObject("ImgOff").gameObject:SetActiveEx(not isSelect)
        end
    end

    -- 练习关按钮
    local practiceStageId = self._Control:GetSkillPracticeStageId(skillId)
    local isShowPractice = practiceStageId ~= 0
    self.BtnPractice.gameObject:SetActiveEx(isShowPractice)
end

function XUiPanelBossInshotTowerRight:RefreshTowerBossSkill(stageId)
    if not stageId or stageId == 0 then
        return
    end
    local bossId = self._Control:GetTowerBossIdByStageId(stageId)
    self._BossInfo.BossId = bossId
    self.TxtBossNameDetail.text = self._Control:GetBossName(bossId)
    self._BossInfo.SkillIds = self._Control:GetBossSkillIds(bossId)
    self._BossInfo.SkillIndex = 1
    self:_RefreshSkillInfo()
end

function XUiPanelBossInshotTowerRight:_StopSkillVideo()
    if self.VideoComponent then
        self.VideoComponent:Stop()
        self.VideoComponent.gameObject:SetActiveEx(false)
        CS.UnityEngine.Object.Destroy(self.VideoComponent.gameObject)
        self.VideoComponent = nil
    end
end

-- 进入战斗房间界面
function XUiPanelBossInshotTowerRight:_EnterBattleRoleRoomNormal()
    self._CacheDifficultyIndexAndSkillIndex(self._BossInfo.DifficultyIndex, self._BossInfo.SkillIndex)

    local difficultyStageId = self._BossInfo.StageIds[self._BossInfo.DifficultyIndex]
    local stageId = self._Control:GetStageStageId(difficultyStageId)
    local team = self._Control:GetTeam()
    local proxy = require("XUi/XUiBossInshot/XUiBossInshotBattleRoleRoom")
    XMVCA.XFuben:OpenUiBattleRoleRoom(stageId, team, proxy)
end

function XUiPanelBossInshotTowerRight:_EnterBattleRoleRoomTower()
    local proxy = require("XUi/XUiBossInshot/XUiBossInshotTowerBattleRoleRoom")

    local team = self._Control:GetTeam()

    XMVCA.XFuben:OpenUiBattleRoleRoom(
        self._BossInfo.SelectedTowerStageId,
        team,
        proxy,
        nil,
        nil,
        {
            TowerLevelConfig = self._BossInfo.TowerLevelConfig,
            CurrentLevelId = self._Control:GetBossTowerCurrentLevel(),
        })
end

return XUiPanelBossInshotTowerRight
