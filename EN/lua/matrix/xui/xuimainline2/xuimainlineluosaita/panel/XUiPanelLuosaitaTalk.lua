---@class XUiPanelLuosaitaTalk
---@field _Control XMainLineLuosaitaControl
---@field Parent XUiMainLineLuosaitaMain
local XUiPanelLuosaitaTalk = XClass(XUiNode, "XUiPanelLuosaitaTalk")

function XUiPanelLuosaitaTalk:OnStart()
    self.TipsBlack.gameObject:SetActiveEx(false)
    self.TipsGreen.gameObject:SetActiveEx(false)
    self.TipsRed.gameObject:SetActiveEx(false)
    
    self.AutoTalkTime = self._Control:GetConfig():GetConfigNumber("MessageShowTime", 1) / XScheduleManager.SECOND
    self.AutoTalkDurationTime = self._Control:GetConfig():GetConfigNumber("MessageShowTime", 2) / XScheduleManager.SECOND
end

function XUiPanelLuosaitaTalk:OnEnable()
    self:UpdateLastOperationTime()
    self:StartTimer()
end

function XUiPanelLuosaitaTalk:OnDisable()
    self:StopTimer()
end

function XUiPanelLuosaitaTalk:Refresh(talkType, context)
    if self.IsTalking and self.lastType == talkType and self.lastContext == context then
        return
    end
    self.lastContext = context
    self.lastType = talkType
    self.TipsBlack.gameObject:SetActiveEx(false)
    self.TipsGreen.gameObject:SetActiveEx(false)
    self.TipsRed.gameObject:SetActiveEx(false)
    if talkType == XMVCA.XMainLineLuosaita.EnumConst.TALK_TYPE.NORMAL then
        self.TipsBlack.gameObject:SetActiveEx(true)
        self.TxtBlackTips.text = context
    elseif talkType == XMVCA.XMainLineLuosaita.EnumConst.TALK_TYPE.INFO then
        self.TipsGreen.gameObject:SetActiveEx(true)
        self.TxtGreenTips.text = context
    elseif talkType == XMVCA.XMainLineLuosaita.EnumConst.TALK_TYPE.WARNING then
        self.TipsRed.gameObject:SetActiveEx(true)
        self.TxtRedTips.text = context
    end
    self.IsTalking = true
    self.AutoCloseTime = nil
end

-- 清除当前讲话内容
function XUiPanelLuosaitaTalk:ClearTalk()
    if self.TipsBlack.gameObject.activeSelf then
        self.TipsBlackAnimDisEnable = self.TipsBlackAnimDisEnable or self.TipsBlack:FindTransform("AnimDisEnable"):GetComponent(typeof(CS.UnityEngine.Playables.PlayableDirector))
        self.TipsBlackAnimDisEnable.gameObject:PlayTimelineAnimation(function()
            self.TipsBlack.gameObject:SetActiveEx(false)
        end)
    end
    if self.TipsGreen.gameObject.activeSelf then
        self.TipsGreenAnimDisEnable = self.TipsGreenAnimDisEnable or self.TipsGreen:FindTransform("AnimDisEnable"):GetComponent(typeof(CS.UnityEngine.Playables.PlayableDirector))
        self.TipsGreenAnimDisEnable.gameObject:PlayTimelineAnimation(function()
            self.TipsGreen.gameObject:SetActiveEx(false)
        end)
    end
    if self.TipsRed.gameObject.activeSelf then
        self.TipsRedAnimDisEnable = self.TipsRedAnimDisEnable or self.TipsRed:FindTransform("AnimDisEnable"):GetComponent(typeof(CS.UnityEngine.Playables.PlayableDirector))
        self.TipsRedAnimDisEnable.gameObject:PlayTimelineAnimation(function()
            self.TipsRed.gameObject:SetActiveEx(false)
        end)
    end
    self.IsTalking = false
    self.AutoCloseTime = nil
    self:UpdateLastOperationTime()
end

-- 更新最后操作时间
function XUiPanelLuosaitaTalk:UpdateLastOperationTime()
    self.LastOperationTime = XTime.GetServerNowTimestamp()
end

function XUiPanelLuosaitaTalk:StartTimer()
    self:StopTimer()
    self._Timer = XScheduleManager.ScheduleForever(function()
        self:UpdateTime()
    end, 100)
end

function XUiPanelLuosaitaTalk:UpdateTime()
    local nowTime = XTime.GetServerNowTimestamp()
    if self.IsTalking then
        if self.AutoCloseTime and nowTime > self.AutoCloseTime then
            self:ClearTalk()
        end
        return 
    end
    if self.Parent:IsPanelPositionDetailShow() then 
        self:UpdateLastOperationTime()
        return 
    end
    if self.Parent:IsPanelFightShow() then
        self:UpdateLastOperationTime()
        return 
    end

    if nowTime - self.LastOperationTime < self.AutoTalkTime then return end
    local sectionId = self.Parent:GetCurSectionId()
    local messageId = self._Control:GetSectionMessageId(sectionId)
    if messageId then
        local text = self._Control:GetConfig():GetMessageText(messageId)
        self:Refresh(XMVCA.XMainLineLuosaita.EnumConst.TALK_TYPE.NORMAL, text)
        self.AutoCloseTime = nowTime + self.AutoTalkDurationTime
    else
        self:UpdateLastOperationTime()
    end
end

function XUiPanelLuosaitaTalk:StopTimer()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

return XUiPanelLuosaitaTalk
