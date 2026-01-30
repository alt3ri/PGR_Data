
---@class XUiBigWorldTaskObtainDrama : XBigWorldUi
---@field _Control XBigWorldQuestControl
local XUiBigWorldTaskObtainDrama = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldTaskObtainDrama")

local OpType = XMVCA.XBigWorldQuest.QuestOpType

local Duration

function XUiBigWorldTaskObtainDrama:OnAwake()
    self:InitUi()
    self:InitCb()
    Duration = XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetInt("QuestBigPopUpDisplayTime")
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, OpType.PopupBegin)
end

function XUiBigWorldTaskObtainDrama:OnStart(questId, isFinish)
    local systemModuleId = XMVCA.XBigWorldQuest:GetQuestSystemUiStyleId(questId)
    XMVCA.XBigWorldUI:ChangeTheme(XMVCA.XBigWorldUI.UiThemeModule.Quest, systemModuleId)
    self._QuestId = questId
    self._IsFinish = isFinish
    self:InitView()
    self:StartTimer()

    self:PlayAnimation("Enable")

    XMVCA.XBigWorldFunction:FreezeFunctionEvent()
end

function XUiBigWorldTaskObtainDrama:OnDestroy()
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, OpType.PopupEnd)
    self:StopTimer()
    self:SendCmd()

    XMVCA.XBigWorldFunction:UnFreezeFunctionEvent()
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_FUNCTION_EVENT_COMPLETE)
end

function XUiBigWorldTaskObtainDrama:InitUi()
end

function XUiBigWorldTaskObtainDrama:InitCb()
    self._AnimCloseCb = function(isFinish)
        if isFinish then
            self:Close()
        end
    end
    self.BtnClose:AddEventListener(handler(self, self.Close))
end

function XUiBigWorldTaskObtainDrama:InitView()
    local questId = self._QuestId
    local typeId = self._Control:GetQuestType(questId)
    self.TxtTaskType.text = self._Control:GetQuestTypeName(typeId)
    local bigIcon = self._Control:GetQuestTypeBigIcon(typeId)
    if not string.IsNilOrEmpty(bigIcon) then
        self.ImgDrama:SetRawImage(bigIcon)
    end
    local isFinish = self._IsFinish
    self.TxtTaskComplete.gameObject:SetActiveEx(isFinish)
    self.TxtTaskStart.gameObject:SetActiveEx(not isFinish)

    local cueId = isFinish and 5600015 or 5600013
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, cueId)
    self.TxtTaskTitle.text = self._Control:GetQuestName(questId)
    if self.TxtExtraDetail then
        local extraDetail = XMVCA.XBigWorldQuest:GetQuestFinishTip(questId)
        local valid = not string.IsNilOrEmpty(extraDetail)
        self.TxtExtraDetail.gameObject:SetActiveEx(valid)
        if valid then
            self.TxtExtraDetail.text = extraDetail
        end
    end
end

function XUiBigWorldTaskObtainDrama:SendCmd()
    local questId = self._QuestId
    local state = self._IsFinish and 2 or 1
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_QUEST_POPUP_CLOSED, {
        QuestId = questId,
        State = state
    })
end

function XUiBigWorldTaskObtainDrama:StartTimer()
    if self._TimerId then
        self:StopTimer()
    end
    self._TimerId = XScheduleManager.ScheduleOnce(function()
        self:Close()
    end, Duration)
end

function XUiBigWorldTaskObtainDrama:StopTimer()
    if not self._TimerId then
        return
    end
    XScheduleManager.UnSchedule(self._TimerId)
    self._TimerId = nil
end

return XUiBigWorldTaskObtainDrama