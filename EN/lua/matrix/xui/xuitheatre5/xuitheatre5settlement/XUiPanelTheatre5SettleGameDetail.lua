--- 最终结算的局内详情，包括进度、角色、装备等
---@class XUiPanelTheatre5SettleGameDetail: XUiNode
---@field protected _Control XTheatre5Control
local XUiPanelTheatre5SettleGameDetail = XClass(XUiNode, 'XUiPanelTheatre5SettleGameDetail')
local XUiPanelTheatre5SettleSkill = require('XUi/XUiTheatre5/XUiTheatre5Settlement/XUiPanelTheatre5SettleSkill')
local XUiPanelTheatre5SettleGem = require('XUi/XUiTheatre5/XUiTheatre5Settlement/XUiPanelTheatre5SettleGem')
local XUiGridTheatre5Container = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/UiGridItems/XUiGridTheatre5Container')
local XUiGridTheatre5Relic = require("XUi/XUiTheatre5/XUiTheatre5BattleShop/UiGridItems/XUiGridTheatre5Relic")
local XUiTheatre5GridTaskDetail = require('XUi/XUiTheatre5/XUiTheatre5ChooseTask/XUiTheatre5GridTaskDetail')

local RewardStateEnum = {
    InProgress = 'InProgress',
    Complete = 'Complete',
}

---@param resultData XDlcFightSettleData
function XUiPanelTheatre5SettleGameDetail:OnStart(resultData)
    self.ResultData = resultData

    ---@type XUiPanelTheatre5Skill
    self.PanelSkill = XUiPanelTheatre5SettleSkill.New(self.ListSkillBag, self, XUiGridTheatre5Container)
    ---@type XUiPanelTheatre5Gem
    self.PanelGem = XUiPanelTheatre5SettleGem.New(self.PanelGem, self)

    self.PanelSkill:Open()
    self.PanelGem:Open()

    self.BtnName.CallBack = handler(self, self.OnBtnNameClickEvent)
    self.BtnBagMaskDetailShow.CallBack = handler(self, self.OnBtnMaskDetailShowClickEvent)
    self.BtnNextPage.CallBack = handler(self, self.OnBtnNextPageClickEvent)

    self:InitCharacter()

    self._GridRelics = {}
    self.RelicContainer = self.RelicContainer or XUiHelper.TryGetComponent(self.Transform, "PanelRight/PanelListRelic/PanelRelic/RelicContainer", "RectTransform")
    if self.RelicContainer then
        self.RelicContainer.gameObject:SetActiveEx(false)
        local relics = self._Control:GetUiDataRelics()
        for i = #relics, 1, -1 do
            if not relics[i].IsUnlock then
                table.remove(relics, i)
            end
        end
        XTool.UpdateDynamicItem(self._GridRelics, relics, self.RelicContainer, XUiGridTheatre5Relic, self)
    end

    self:RefreshMissionShow()

    if self.BtnReward then
        self.BtnReward:AddEventListener(function()
            if self.Mission then
                self.TaskDetail:Open()
                if self.Mission.MissionState == XMVCA.XTheatre5.EnumConst.Theatre5MissionState.HasFinish or self.Mission.MissionState == XMVCA.XTheatre5.EnumConst.Theatre5MissionState.HasReward then
                    self.TaskDetail:Refresh(XMVCA.XTheatre5.EnumConst.UITaskDetailShowType.InComplete, self.Mission, self.Mission.MissionRelicId)
                else
                    self.TaskDetail:Refresh(XMVCA.XTheatre5.EnumConst.UITaskDetailShowType.InProgress, self.Mission)
                end
                self.BtnMissionDetailClose.gameObject:SetActiveEx(true)
            end
        end)
    end

    if self.BtnMissionDetailClose then
        self.BtnMissionDetailClose:AddEventListener(function()
            self.TaskDetail:CloseWithAnimation()
            self.BtnMissionDetailClose.gameObject:SetActiveEx(false)
        end)
        self.BtnMissionDetailClose.gameObject:SetActiveEx(false)
    end

    if self.UiTheatre5GridTaskDetail then
        self.UiTheatre5GridTaskDetail.gameObject:SetActiveEx(false)
        ---@type XUiTheatre5GridTaskDetail
        self.TaskDetail = XUiTheatre5GridTaskDetail.New(self.UiTheatre5GridTaskDetail, self)
    end
end

function XUiPanelTheatre5SettleGameDetail:OnEnable()
    self:RefreshCharacterShow()
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_OPEN_ITEM_DETAIL, self.OnItemDetailOpenEvent, self)
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_HIDE_ITEM_DETAIL, self.OnItemDetailHideEvent, self)
end

function XUiPanelTheatre5SettleGameDetail:OnDisable()
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_OPEN_ITEM_DETAIL, self.OnItemDetailOpenEvent, self)
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_HIDE_ITEM_DETAIL, self.OnItemDetailHideEvent, self)
end

function XUiPanelTheatre5SettleGameDetail:InitCharacter()
    ---@type XTableTheatre5Character
    local characterCfg = self._Control:GetCurCharacterCfg()

    if characterCfg then
        self.BtnName:SetNameByGroup(0, characterCfg.Name)

        local matchImg = self._Control.CharacterControl:GetMatchImgByCharacterIdCurMode(characterCfg.Id)

        if not string.IsNilOrEmpty(matchImg) then
            self.ImgHead:SetRawImage(matchImg)
        end
    end

    local level = self._Control:GetCharacterLevel()
    if self.TxtNum then
        self.TxtNum.text = level
    end
end

function XUiPanelTheatre5SettleGameDetail:RefreshGameProgressShow()
    if self._Control:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameMode.PVP then
        -- PVP奖杯进度
        local cupsNum = self.ResultData.XAutoChessGameplayResult.TrophyNum
        local targetCount = self._Control.PVPControl:GetPVPTargetCountFromConfig()
        local isPvpExtra = self.ResultData.XAutoChessGameplayResult.IsPvpExtra

        self.ListCup.gameObject:SetActiveEx(not isPvpExtra)
        self.PanelOvertime.gameObject:SetActiveEx(isPvpExtra)

        if isPvpExtra then
            local extraTargetCount = self._Control.PVPControl:GetPvpExtraTargetCount()
            -- 额外杯
            local extraCupsNum = math.max(0, cupsNum - targetCount)
            self._CupOvertimeList = XUiHelper.RefreshUiObjectList(self._CupOvertimeList, self.ListCupOvertime, self.GridCupOvertime, extraTargetCount, function(index, grid)
                if grid.ImgOn then
                    grid.ImgOn.gameObject:SetActiveEx(index <= extraCupsNum)
                end
            end)
        else
            self._CupList = XUiHelper.RefreshUiObjectList(self._CupList, self.ListCup, self.GridCup, targetCount, function(index, grid)
                if grid.ImgOn then
                    grid.ImgOn.gameObject:SetActiveEx(index <= cupsNum)
                end
            end)
        end

        -- 显示最终血量
        local healthMax = self._Control.PVPControl:GetPVPHealthMaxFromConfig()

        self.TxtLifeNum.text = XUiHelper.FormatText(self._Control.PVPControl:GetHealthShowTextFromClientConfig(), self.ResultData.XAutoChessGameplayResult.Health, healthMax)
    else
        local chapterIdCompleted = self._Control.PVEControl:GetChapterIdCompleted()
        local chapterLevelCompleted = self._Control.PVEControl:GetChapterLevelCompleted()
        local chapterCfg = self._Control.PVEControl:GetPveChapterCfg(chapterIdCompleted)
        local chapterLevelCfgs = self._Control.PVEControl:GetPveChapterLevelCfgs(chapterCfg.LevelGroup)
        local targetCount = #chapterLevelCfgs
        local curChapterLevel = chapterLevelCompleted
        if curChapterLevel == -1 then
            curChapterLevel = targetCount + 1
        end
        self._CupList = XUiHelper.RefreshUiObjectList(self._CupList, self.ListCup, self.GridCup, targetCount, function(index, grid)
            if grid.ImgOn then
                grid.ImgOn.gameObject:SetActiveEx(index < curChapterLevel)
            end
        end)

        local chapterIdCompleted = self._Control.PVEControl:GetChapterIdCompleted()
        if XTool.IsNumberValid(chapterIdCompleted) then
            local chapterCfg = self._Control.PVEControl:GetPveChapterCfg(chapterIdCompleted)
            self.TxtLifeNum.text = string.format("%d/%d", self.ResultData.XAutoChessGameplayResult.Health, chapterCfg.Hp)
        end

    end
end

function XUiPanelTheatre5SettleGameDetail:RefreshCharacterShow()
    self:RefreshGameProgressShow()

    if self.SkillNone then
        self.SkillNone.gameObject:SetActiveEx(not self._Control:CheckHasEquipSkill())
    end

    if self.GemNone then
        self.GemNone.gameObject:SetActiveEx(not self._Control:CheckHasEquipGem())
    end
end

function XUiPanelTheatre5SettleGameDetail:RefreshMissionShow()
    if self.BtnReward then
        local mission = self._Control.MissionControl:GetCurMission()

        if mission then
            local bountyId = mission.MissionBounty.Bounty
            local level = mission.MissionBounty.BountyLevel
            local missionRelicId = mission.MissionRelicId

            local isRewardGot = mission.MissionState == XMVCA.XTheatre5.EnumConst.Theatre5MissionState.HasReward
            local isComplete = mission.MissionState == XMVCA.XTheatre5.EnumConst.Theatre5MissionState.HasFinish or isRewardGot

            self.BtnReward:SetButtonState(CS.UiButtonState.Normal)
            self.BtnRewardStateCtrl:ChangeState(isComplete and RewardStateEnum.Complete or RewardStateEnum.InProgress)

            -- 奖励图标
            local iconRes = ''

            if isRewardGot and XTool.IsNumberValidEx(missionRelicId) then
                local cfg = self._Control:GetTheatre5ItemCfgById(missionRelicId)

                if cfg then
                    iconRes = cfg.IconRes
                end
            else
                iconRes = self._Control.MissionControl:GetMissionRewardIcon(bountyId, level)
            end

            if not string.IsNilOrEmpty(iconRes) then
                self.BtnReward:SetRawImage(iconRes)
            end

            -- 等级
            self.BtnReward:SetNameByGroup(0, self._Control.MissionControl:GetMissionGridLevelShow(bountyId, level))

            -- 完成情况
            if self.PanelNone then
                self.PanelNone.gameObject:SetActiveEx(not isComplete)

                if not isComplete then
                    if self.NoMissionRelicTxt then
                        self.NoMissionRelicTxt.text = self._Control.MissionControl:GetClientConfigMissionStateLabelInFinalSettle(true)
                    end
                end
            end
        else
            self.BtnReward:SetButtonState(CS.UiButtonState.Disable)
            -- 完成情况
            if self.PanelNone then
                self.PanelNone.gameObject:SetActiveEx(true)

                if self.NoMissionRelicTxt then
                    self.NoMissionRelicTxt.text = self._Control.MissionControl:GetClientConfigMissionStateLabelInFinalSettle(false)
                end
            end
        end

        self.Mission = mission
    end
end

function XUiPanelTheatre5SettleGameDetail:OnBtnNameClickEvent()
    if not XLuaUiManager.IsUiShow('UiTheatre5BubbleCharacterDetail') then
        XLuaUiManager.Open('UiTheatre5BubbleCharacterDetail')
    end
end

function XUiPanelTheatre5SettleGameDetail:OnBtnMaskDetailShowClickEvent()
    self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_HIDE_ITEM_DETAIL)
end

function XUiPanelTheatre5SettleGameDetail:OnItemDetailOpenEvent(itemData, containerType, uiPos)
    if not XLuaUiManager.IsUiShow('UiTheatre5BubbleItemDetail') then
        XLuaUiManager.Open('UiTheatre5BubbleItemDetail', itemData, containerType, uiPos)
    else
        self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_ITEM_DETAIL, itemData, containerType, uiPos)
    end

    self.BtnBagMaskDetailShow.gameObject:SetActiveEx(true)
end

function XUiPanelTheatre5SettleGameDetail:OnItemDetailHideEvent()
    self.BtnBagMaskDetailShow.gameObject:SetActiveEx(false)
end

function XUiPanelTheatre5SettleGameDetail:OnBtnNextPageClickEvent()
    self.Parent:OnGameDetailNextEvent()
end

return XUiPanelTheatre5SettleGameDetail
