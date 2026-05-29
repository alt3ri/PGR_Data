---@class XUiGridBWQuestSmall : XUiNode
---@field ComponentGroup XUiComponent.XUiComponentGroup
local XUiGridBWQuestSmall = XClass(XUiNode, "XUiGridBWQuestSmall")

function XUiGridBWQuestSmall:OnStart()
    self.BtnClick:AddEventListener(handler(self, self.OnClick))
end

function XUiGridBWQuestSmall:Update(questId)
    self._QuestId = questId

    self.ComponentGroup:SetTextWithGroup(0, XMVCA.XBigWorldQuest:GetQuestText(questId))
    local isFinish = XMVCA.XBigWorldQuest:CheckQuestFinish(questId)
    local location = ""
    local isInActive
    if not isFinish then
        local questData = XMVCA.XBigWorldQuest:GetQuestData(questId)
        local step = questData:GetActiveStepData()
        if step then
            location = XMVCA.XBigWorldQuest:GetStepLocation(step:GetId())
        end
        isInActive = questData:GetState() == XMVCA.XBigWorldQuest.QuestState.InActive
    end
    self.ComponentGroup:SetTextWithGroup(1, location)
    self.ComponentGroup:SetImageWithGroup(0, XMVCA.XBigWorldQuest:GetQuestIcon(questId))
    self.PanelFinish.gameObject:SetActiveEx(isFinish)
    self.PanelLock.gameObject:SetActiveEx(not isFinish and isInActive)
    self.PanelNormal.gameObject:SetActiveEx(not isFinish and not isInActive)
    self.BtnClick.gameObject:SetActiveEx(not isFinish)
    self._IsInActive = isInActive
    self._IsFinish = isFinish
end

function XUiGridBWQuestSmall:RefreshSkip(skipId)
    self._SkipId = skipId
    local isFinish = XMVCA.XBigWorldSkipFunction:CheckFinish(skipId)
    local isActive = XMVCA.XBigWorldSkipFunction:CheckUnlock(skipId)
    self.PanelFinish.gameObject:SetActiveEx(isFinish)
    self.PanelLock.gameObject:SetActiveEx(not isFinish and not isActive)
    self.PanelNormal.gameObject:SetActiveEx(not isFinish and isActive)
    self.BtnClick.gameObject:SetActiveEx(not isFinish)

    self.ComponentGroup:SetTextWithGroup(0, XMVCA.XBigWorldSkipFunction:GetSkipNameBySkipId(skipId))
    
    self._IsInActive = not isActive
    self._IsFinish = isFinish
end

function XUiGridBWQuestSmall:SetClickCallback(cb)
    self._ClickCallback = cb
end

function XUiGridBWQuestSmall:OnClick()
    if self._ClickCallback then
        self._ClickCallback(self._QuestId or self._SkipId)
        return
    end
    if self._SkipId then
        self:SkipTo()
    elseif self._QuestId then
        self:SkipToQuest()
    end
end

function XUiGridBWQuestSmall:SkipToQuest()
    if self._IsFinish then
        return
    end
    if self._IsInActive then
        XUiManager.TipMsg(XMVCA.XBigWorldService:GetText("QuestIsInActiveTip"))
        return
    end
    local questId = self._QuestId
    XMVCA.XBigWorldQuest:OpenQuestMain(1, questId)
end

function XUiGridBWQuestSmall:SkipTo()
    XMVCA.XBigWorldSkipFunction:SkipTo(self._SkipId)
end

return XUiGridBWQuestSmall