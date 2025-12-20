--- pvp匹配界面
---@class XUiTheatre5Loading: XLuaUi
---@field private _Control XTheatre5Control
local XUiTheatre5Loading = XLuaUiManager.Register(XLuaUi, 'UiTheatre5Loading')

function XUiTheatre5Loading:OnStart(enemyData)
    self._DelayTimeId = nil
    XMVCA.XTheatre5:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_FIGHT_ENTER_FINISHED, self.OnFinishFightEnter, self)
    self:RefreshEnemyInfo(enemyData)
    if self._Control:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameMode.PVE then
        self:PVELoading()
    else
        self:PVPLoading()
    end        
end

function XUiTheatre5Loading:OnDisable()
    self:StopCheckTimeDelayTimer()
end

function XUiTheatre5Loading:RefreshEnemyInfo(enemyData)
    if not enemyData then
        return
    end    
    self.TxtName.text = enemyData.Name
    if enemyData.HeadPortraitId and enemyData.HeadFrameId then
        XUiPlayerHead.InitPortrait(enemyData.HeadPortraitId, enemyData.HeadFrameId, self.Head)
    end     
    
    local matchImg = nil

    local fashionId
    if XTool.IsNumberValid(enemyData.IsUseSkin) then
        fashionId = enemyData.IsUseSkin
    elseif XTool.IsNumberValid(enemyData.CharacterId) then
        fashionId = self._Control.CharacterControl:GetDefaultFashionIdByCharacterId(enemyData.CharacterId)
    end        

    if XTool.IsNumberValid(fashionId) then
        matchImg = self._Control.CharacterControl:GetMatchImgByFashionId(fashionId)
    end
    
    if not string.IsNilOrEmpty(matchImg) then
        self.RImgCharacter:SetRawImage(matchImg)

        if self.RImgCharacterGrey then
            self.RImgCharacterGrey:SetRawImage(matchImg)
        end
    end
end

function XUiTheatre5Loading:PVELoading()
    local level = 0
    local chapterData = self._Control.PVEControl:GetCurChapterBattleData()
    if chapterData and chapterData.CurPveChapterLevel then
        level = chapterData.CurPveChapterLevel.Level
    end

    -- 允许延时一定时间再请求和进入战斗，确保前半段有一小段时间流程播放匹配动画
    local delayTime = self._Control:GetClientConfigMatchLoadingDelay(false)
    if not XTool.IsNumberValid(delayTime) then
        delayTime = 0
    end    

    XMVCA.XTheatre5.BattleCom:RequestDlcSingleEnterFight(level, nil, function(worldData)
        if worldData and worldData.AutoChessGameplayData and worldData.AutoChessGameplayData.EnemyData then
            self:RefreshPVEEnemyInfo(worldData.AutoChessGameplayData.EnemyData)
        end
    end, delayTime * XScheduleManager.SECOND)
end

function XUiTheatre5Loading:RefreshPVEEnemyInfo(enemyData)
    if not enemyData or not enemyData.AutoChessData then
        return
    end       
    local characterCfg = self._Control:GetTheatre5CharacterCfgById(enemyData.AutoChessData.CharacterId, true)
    if not characterCfg then
        return
    end    
    self.TxtName.text = characterCfg.Name
    if self.PanelHead then
        self.PanelHead.gameObject:SetActiveEx(false)
    end    
    if XTool.IsTableEmpty(characterCfg.FashionIds) then
        return
    end    
    local matchImg = self._Control.CharacterControl:GetMatchImgByFashionId(characterCfg.FashionIds[1])
     if not string.IsNilOrEmpty(matchImg) then
        self.RImgCharacter:SetRawImage(matchImg)

        if self.RImgCharacterGrey then
            self.RImgCharacterGrey:SetRawImage(matchImg)
        end
    end
end

function XUiTheatre5Loading:PVPLoading()
    self._CheckTimeTimerId = XScheduleManager.ScheduleOnce(function()
        self._Control.PVPControl:StartPVPTimer(function()
            CsXUiManager.Instance:SetRevertAllLock(false)
            self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_PVP_END_IN_MATCH)
            self:Close()
        end)
    end, XScheduleManager.SECOND)
    
    -- 允许延时一定时间再请求和进入战斗，确保前半段有一小段时间流程播放匹配动画
    local delayTime = self._Control:GetClientConfigMatchLoadingDelay(false)
    
    local func = function()
        self._Control.PVPControl:StopPVPTimer()
        self:StopCheckTimeDelayTimer()
        
        -- 请求前再补检查一次时间
        if self._Control.PVPControl:CheckPVPInTime() then
            XMVCA.XTheatre5.BattleCom:RequestDlcSingleEnterFight(nil, nil, nil, nil, function()
                CsXUiManager.Instance:SetRevertAllLock(false)
                self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_PVP_END_IN_MATCH)
                if not self._Control.PVPControl:CheckPVPInTime() then
                    self._Control.PVPControl:DoTickoutCallBack()
                else
                    XLuaUiManager.CloseAllUpperUiWithCallback('UiTheatre5Main')
                    self:Close()
                end
            end)
        else
            CsXUiManager.Instance:SetRevertAllLock(false)
            self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_PVP_END_IN_MATCH)
            if not self._Control.PVPControl:CheckPVPInTime() then
                self._Control.PVPControl:DoTickoutCallBack()
            else
                XLuaUiManager.CloseAllUpperUiWithCallback('UiTheatre5Main')
                self:Close()
            end
        end
    end

    if XTool.IsNumberValid(delayTime) then
        self._DelayTimeId = XScheduleManager.ScheduleOnce(func, delayTime * XScheduleManager.SECOND)
    else
        func()
    end
end

function XUiTheatre5Loading:OnDestroy()
    XMVCA.XTheatre5:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_FIGHT_ENTER_FINISHED, self.OnFinishFightEnter, self)

    if self._DelayTimeId then
        XScheduleManager.UnSchedule(self._DelayTimeId)
        self._DelayTimeId = nil
    end
end

function XUiTheatre5Loading:OnFinishFightEnter()
    -- 先暂停战斗
    if CS.StatusSyncFight.XFightClient.FightInstance then
        CS.StatusSyncFight.XFightClient.FightInstance:OnPauseForClient()
    end
    
    self:PlayFightEnterAnim()
end

function XUiTheatre5Loading:PlayFightEnterAnim()
    local isAnimaStarSuccess = false

    self:PlayAnimation('ProfileDissolve', function()
        local delayTime = self._Control:GetClientConfigMatchLoadingDelay(true)

        if XTool.IsNumberValid(delayTime) then
            self._DelayTimeId = XScheduleManager.ScheduleOnce(function()
                self._DelayTimeId = nil
                self:Close()
                self:_ResumeFight()
            end, delayTime * XScheduleManager.SECOND)
        else
            self:Close()
            self:_ResumeFight()
        end
    end, function() 
        isAnimaStarSuccess = true
    end)

    if not isAnimaStarSuccess then
        -- 因为动画丢失、改名等原因没有播放成功，则直接关闭界面，不阻断流程
        self:Close()
        -- 恢复战斗
        self:_ResumeFight()
    end
end

function XUiTheatre5Loading:_ResumeFight()
    if CS.StatusSyncFight.XFightClient.FightInstance then
        CS.StatusSyncFight.XFightClient.FightInstance:OnResumeForClient()
    end
end

function XUiTheatre5Loading:StopCheckTimeDelayTimer()
    if self._CheckTimeTimerId then
        XScheduleManager.UnSchedule(self._CheckTimeTimerId)
        self._CheckTimeTimerId = nil
    end
end

return XUiTheatre5Loading