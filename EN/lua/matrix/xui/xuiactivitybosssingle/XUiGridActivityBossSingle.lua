--- 超难关关卡入口
---@class XUiGridActivityBossSingle: XUiNode
local XUiGridActivityBossSingle = XClass(XUiNode, "XUiGridActivityBossSingle")
--- UI网格初始化回调，注册按钮事件监听
function XUiGridActivityBossSingle:OnStart()
    self:AutoAddListener()
end

function XUiGridActivityBossSingle:OnDestroy()
    self:_ClearScoreAnimationTimer()
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

 
    if not XDataCenter.FubenActivityBossSingleManager.IsHardBossLevel(stageId) then
        self.goHardRoot.gameObject:SetActiveEx(false)
    else
        self.goHardRoot.gameObject:SetActiveEx(true)

        self.goHardLv1.gameObject:SetActiveEx(false)
        self.goHardLv2.gameObject:SetActiveEx(false)
        self.goHardLv3 .gameObject:SetActiveEx(false)

        
        local curScore = XDataCenter.FubenActivityBossSingleManager.GetCurDifficultScoreRecord(stageId)
        local lastScore =  XDataCenter.FubenActivityBossSingleManager.GetLastDifficultScoreRecord(stageId)
        XDataCenter.FubenActivityBossSingleManager.GetLastDifficultScoreRecord(stageId,curScore)
        
        self:_ClearScoreAnimationTimer()
        if lastScore == nil or lastScore >= curScore then
            self.txtScore.text = tostring(curScore)
        else
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
        end

        local levelCO = XFubenActivityBossSingleConfigs.GetBossLevelScoreCOByScore(curScore)
        local hardLevel = levelCO.Id
        if hardLevel == 1 then
            self.goHardLv1.gameObject:SetActiveEx(true)
        elseif hardLevel == 2 then
            self.goHardLv2.gameObject:SetActiveEx(true)
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

function XUiGridActivityBossSingle:_ClearScoreAnimationTimer()
    if self._ScoreAnimationTimerId then
        XScheduleManager.UnSchedule(self._ScoreAnimationTimerId)
        self._ScoreAnimationTimerId = nil
    end
end

return XUiGridActivityBossSingle