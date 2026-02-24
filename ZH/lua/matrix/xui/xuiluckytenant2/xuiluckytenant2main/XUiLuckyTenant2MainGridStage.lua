---@class XUiLuckyTenant2MainGridStage : XUiNode
local XUiLuckyTenant2MainGridStage = XClass(XUiNode, "XUiLuckyTenant2MainGridStage")

function XUiLuckyTenant2MainGridStage:OnStart(...)
    self:InitComponents()
    self:Update()
end

function XUiLuckyTenant2MainGridStage:InitComponents()
    -- 绑定点击事件
    if self.BtnChapter then
        XUiHelper.RegisterClickEvent(self, self.BtnChapter, self.OnClick, nil, true)
    end
    if self.BtnEndGame then
        XUiHelper.RegisterClickEvent(self, self.BtnEndGame, self.OnClickEndGame, nil, true)
    end
    self._Timer = false
end

function XUiLuckyTenant2MainGridStage:OnEnable()
end

function XUiLuckyTenant2MainGridStage:OnDisable()
end

function XUiLuckyTenant2MainGridStage:OnDestroy()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XUiLuckyTenant2MainGridStage:UpdateRemainTime()
    local data = self._Data
    if not data then
        return
    end
    
    if data.IsCanChallenge then
        if self.BtnChapter then
            self.BtnChapter:SetButtonState(CS.UiButtonState.Normal)
        end
        if self.TxtTips then
            self.TxtTips.text = ""
        end
    else
        if self.BtnChapter then
            self.BtnChapter:SetButtonState(CS.UiButtonState.Disable)
        end
        local currentTime = XTime.GetServerNowTimestamp()
        local remainTime = XFunctionManager.GetStartTimeByTimeId(data.TimeId) - currentTime
        if remainTime >= 0 and data.TimeId and data.TimeId > 0 then
            local timeStr = XUiHelper.GetTime(math.max(remainTime, 1), XUiHelper.TimeFormatType.ACTIVITY)
            if self.TxtTips then
                self.TxtTips.text = XUiHelper.GetText("LuckyTenant2UnlockAfterTime", timeStr)
            end
            if not self._Timer then
                self._Timer = XScheduleManager.ScheduleForever(function()
                    self:UpdateRemainTime()
                end, 1000)
            end
            return
        end
        if not data.IsPreStagePass and self.TxtTips then
            self.TxtTips.text = XUiHelper.GetText("LuckyTenant2PreStageNotClear")
        end
    end
    
    if self._Timer then
        -- 检查是否已解锁，如果解锁则取消定时器
        if data.IsCanChallenge then
            XScheduleManager.UnSchedule(self._Timer)
            self._Timer = false
        end
    end
end

function XUiLuckyTenant2MainGridStage:Update(data)
    if not data then
        return
    end
    
    self._Data = data
    
    -- 背景图（未选中时显示）
    if self.RImgBgNormal then
        self.RImgBgNormal.gameObject:SetActiveEx(not (data.IsSelected or false))
    end
    
    -- 通关标记（普通通关）
    if self.CommonFuBenClear then
        self.CommonFuBenClear.gameObject:SetActiveEx(data.IsNormalClear or false)
    end
    
    -- 锁定面板
    if self.PanelLock then
        self.PanelLock.gameObject:SetActiveEx(not (data.IsCanChallenge or false))
    end
    
    -- 进行中标记
    if self.TagOngoing then
        self.TagOngoing.gameObject:SetActiveEx(data.IsPlaying or false)
    end
    
    -- 标题（使用序号格式，如 "01"）
    if self.TxtTitle then
        local index = data.Index or 0
        self.TxtTitle.text = string.format("%02d", index)
    end
    
    -- 分数
    if self.TxtScore then
        self.TxtScore.text = tostring(data.BestScore or 0)
    end
    
    -- 更新解锁时间提示
    self:UpdateRemainTime()
    
    -- 封面图
    if self.RawImage and data.CoverImage and data.CoverImage ~= "" then
        self.RawImage:SetRawImage(data.CoverImage)
    end
    
    -- 结束游戏按钮（游玩中时显示）
    if self.BtnEndGame then
        self.BtnEndGame.gameObject:SetActiveEx(data.IsPlaying or false)
    end
    
    -- 红点
    if self.RedPoint then
        self.RedPoint.gameObject:SetActiveEx(false)
    end
end

function XUiLuckyTenant2MainGridStage:OnClick()
    if not self._Data then
        return
    end
    
    if self._Data.IsOtherStagePlaying then
        XUiManager.TipText("LuckyTenant2OtherStagePlaying")
        return
    end
    
    if self._Data.IsCanChallenge then
        if self.Parent then
            self.Parent:OnClickStage(self._Data)
        end
    else
        if not self._Data.IsOnTime then
            local currentTime = XTime.GetServerNowTimestamp()
            local remainTime = XFunctionManager.GetStartTimeByTimeId(self._Data.TimeId) - currentTime
            if remainTime > 0 then
                local timeStr = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.ACTIVITY)
                XUiManager.TipMsg(XUiHelper.GetText("LuckyTenant2UnlockAfterTime", timeStr))
            end
        else
            XUiManager.TipText("LuckyTenant2PreStageNotPass")
        end
    end
end

---点击结束游戏按钮
function XUiLuckyTenant2MainGridStage:OnClickEndGame()
    if not self._Data then
        return
    end
    
    if not self._Data.IsPlaying then
        return
    end
    
    local stageId = self._Data.Id
    if not stageId or stageId <= 0 then
        return
    end
    
    -- 请求结束游戏（通过 XMVCA 访问 Agency）
    if XMVCA and XMVCA.XLuckyTenant2 then
        XMVCA.XLuckyTenant2:RequestEndGame(stageId, nil, function(success)
            if success then
                -- 然后刷新界面
                self.Parent:Update()
            end
        end)
    end
end

return XUiLuckyTenant2MainGridStage
