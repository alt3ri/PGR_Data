--- 超难关关卡入口
---@class XUiGridActivityBossSingle: XUiNode
local XUiGridActivityBossSingle = XClass(XUiNode, "XUiGridActivityBossSingle")
--- UI网格初始化回调，注册按钮事件监听
function XUiGridActivityBossSingle:OnStart()
    self:AutoAddListener()
end

function XUiGridActivityBossSingle:OnDestroy()
    self:_ClearScoreAnimationTimer()
    self:_ClearHardLevelAnimTimer()
end

function XUiGridActivityBossSingle:AutoAddListener()
    self.BtnStage.CallBack = function()
        self:OnBtnStageClick()
    end
end

function XUiGridActivityBossSingle:Refresh(stageId, index)
    self.StageId = stageId
    self.Index = index
    --刷新是否解锁
    local isUnLock = XDataCenter.FubenActivityBossSingleManager.IsChallengeUnlockByStageId(stageId)
    self.BtnStage:SetButtonState(isUnLock and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    self.BtnStage:SetNameByGroup(0, XFubenActivityBossSingleConfigs.GetBossChallengeDetailTitle(stageId))
    local bgMaskName = "Img" .. index .. "BgMask"
    if self.Parent[bgMaskName] then
        self.Parent[bgMaskName].gameObject:SetActiveEx(isUnLock)
    end
    self.IsUnLock = isUnLock
    --刷新红点显示
    local starMap = XDataCenter.FubenActivityBossSingleManager.GetStageStarMap(stageId)
    for i = 1, #starMap do
        self["ImgOn" .. i].gameObject:SetActiveEx(starMap[i])
        self["ImgOff" .. i].gameObject:SetActiveEx(not starMap[i]) 
    end


    --刷新是否通关显示
    local isPassed = XDataCenter.FubenActivityBossSingleManager.IsChallengePassedByStageId(stageId)
    self.PanelKillParent.gameObject:SetActiveEx(isPassed)

 

    if not XDataCenter.FubenActivityBossSingleManager.IsHardBossLevel(stageId) or not isUnLock then
        self.goHardRoot.gameObject:SetActiveEx(false)
    else
        self.goHardRoot.gameObject:SetActiveEx(true)

        self.goHardLv1.gameObject:SetActiveEx(false)
        self.goHardLv2.gameObject:SetActiveEx(false)
        self.goHardLv3 .gameObject:SetActiveEx(false)

        self.PanelBgNorma01.gameObject:SetActiveEx(false)
        self.PanelBgNorma02.gameObject:SetActiveEx(false)
        self.PanelBgNorma03.gameObject:SetActiveEx(false)

        local curScore = XDataCenter.FubenActivityBossSingleManager.GetCurDifficultScoreRecord(stageId)
        local lastScore =  XDataCenter.FubenActivityBossSingleManager.GetLastDifficultScoreRecord(stageId)
        XDataCenter.FubenActivityBossSingleManager.GetLastDifficultScoreRecord(stageId,curScore)
        
        self:_ClearScoreAnimationTimer()
        if curScore == nil then
            self.txtScore.text = tostring(0)
        elseif lastScore == nil or lastScore >= curScore then
            self.txtScore.text = tostring(curScore)
        else -- 上次刷新了记录
            self.txtScore.text = tostring(lastScore) 

            self._ScoreAnimationTimerId = XUiHelper.Tween(1, function(progress)
                if XTool.UObjIsNil(self.Transform) then
                    return
                end
                self.txtScore.text = tostring( math.floor(CS.UnityEngine.Mathf.Lerp(lastScore, curScore, progress)) )
            end, function()
                self._ScoreAnimationTimerId = nil
                if XTool.UObjIsNil(self.Transform) then
                    return
                end
                self.txtScore.text = tostring(curScore)
            end)

            local curLevelCO = XFubenActivityBossSingleConfigs.GetBossLevelScoreCOByScore(curScore)
            local laseLevelCO = XFubenActivityBossSingleConfigs.GetBossLevelScoreCOByScore(lastScore)
            self:_PlayHardLevelChangeAnim(curLevelCO.Id, laseLevelCO.Id)
        end
        local levelCO = XFubenActivityBossSingleConfigs.GetBossLevelScoreCOByScore(curScore)
        local hardLevel = levelCO.Id
        if hardLevel == 1 then
            self.goHardLv1.gameObject:SetActiveEx(true)
        elseif hardLevel == 2 then
            self.goHardLv2.gameObject:SetActiveEx(true)
        if isUnLock then
            local hardLevel = levelCO.Id
            if hardLevel == 1 then
                self.goHardLv1.gameObject:SetActiveEx(true)
                self.PanelBgNorma01.gameObject:SetActiveEx(true)
            elseif hardLevel == 2 then
                self.goHardLv2.gameObject:SetActiveEx(true)
                self.PanelBgNorma02.gameObject:SetActiveEx(true)
            else
                self.goHardLv3.gameObject:SetActiveEx(true)
                self.PanelBgNorma03.gameObject:SetActiveEx(true)
            end
        else
            self.goHardLv3.gameObject:SetActiveEx(true)
        end
        self.txtHardDesc.text =  levelCO.Des
    end
end

function XUiGridActivityBossSingle:OnBtnStageClick()
    if self.IsUnLock == false then
        XUiManager.TipText("ActivityBossOpenTip")
        return
    end
    
    XLuaUiManager.Open('UiActivityBossSinglePopupStageDetail', self.StageId)
end


---@param curHardLevel number 当前难度等级
---@param lastHardLevel number 上次难度等级
function XUiGridActivityBossSingle:_PlayHardLevelChangeAnim(curHardLevel, lastHardLevel)
    self:_ClearHardLevelAnimTimer()
    self._HardLevelAnimTimerId = XScheduleManager.ScheduleOnce(function()
        self._HardLevelAnimTimerId = nil
        if XTool.UObjIsNil(self.Transform) then
            return
        end
        self:_DoPlayHardLevelChangeAnim(curHardLevel, lastHardLevel)
    end, 2000)
end

function XUiGridActivityBossSingle:_DoPlayHardLevelChangeAnim(curHardLevel, lastHardLevel)
    if  self.AnimTab1To2 == nil then return end -- 预制体还没触发打包

    self.AnimTab1To2.gameObject:SetActiveEx(false)
    self.AnimTab2To3.gameObject:SetActiveEx(false)
    self.AnimHard3Loop.gameObject:SetActiveEx(false)

    local anim
    if curHardLevel ~= lastHardLevel then
        if curHardLevel == 2 then
            anim = self.AnimTab1To2
        elseif curHardLevel == 3 then
            anim = self.AnimTab2To3
        end
    end

    if curHardLevel == 3 then
        self.AnimHard3Loop.gameObject:SetActiveEx(true)
        self.AnimHard3Loop:Play()
    end

    if anim then
        anim.gameObject:SetActiveEx(true)
        anim:Play()
    end
end


function XUiGridActivityBossSingle:_ClearScoreAnimationTimer()
    if self._ScoreAnimationTimerId then
        XScheduleManager.UnSchedule(self._ScoreAnimationTimerId)
        self._ScoreAnimationTimerId = nil
    end
end

function XUiGridActivityBossSingle:_ClearHardLevelAnimTimer()
    if self._HardLevelAnimTimerId then
        XScheduleManager.UnSchedule(self._HardLevelAnimTimerId)
        self._HardLevelAnimTimerId = nil
    end
end

return XUiGridActivityBossSingle