--rouge5玩法流程管理
---@class XTheatre5FlowController : XControl
---@field private _Model XTheatre5Model
---@field private _MainControl XTheatre5Control
local XTheatre5FlowController = XClass(XControl, 'XTheatre5FlowController')
local PVEStroryLineLink = require('XModule/XTheatre5/PVE/Rouge/XTheatre5PVELink')
local Theatre5FlowNodeBlackBoard = require('XModule/XTheatre5/PVE/Rouge/XTheatre5FlowNodeBlackBoard')

local _UIUid = 0
function XTheatre5FlowController.GenNodeUid()
    _UIUid = _UIUid + 1
    return _UIUid
end
---@param mainAgency XTheatre5Agency
function XTheatre5FlowController:Ctor()
    self._IsEntering = false
    ---------------------pve-------------------------
    ---@type XTheatre5PVELink
    self._PVEStroryLineLink = nil
    self._WaitOpenUI = nil --等待打开的界面
    self._PVEFlowNodeBlackBoard = nil
    self._IsEnteringStoryLine = false

end

function XTheatre5FlowController:OnInit()
    self._PVEFlowNodeBlackBoard = Theatre5FlowNodeBlackBoard.New()
    self._PVEStroryLineLink = self:AddSubControl(PVEStroryLineLink)
end

function XTheatre5FlowController:AddAgencyEvent()
    XEventManager.AddEventListener(XMVCA.XTheatre5.EventId.EVENT_STORY_LINE_PROCESS_UPDATE, self.UpdateStoryLineProcess, self)
    XEventManager.AddEventListener(XMVCA.XTheatre5.EventId.EVENT_WHOLE_BATTLE_EXIT, self.OnBattleChapterAdvanceSettle, self)
    XEventManager.AddEventListener(XMVCA.XTheatre5.EventId.EVENT_WHOLE_BATTLE_AGAIN, self.OnAgainBattle, self)
end

function XTheatre5FlowController:RemoveAgencyEvent()
    XEventManager.RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_STORY_LINE_PROCESS_UPDATE, self.UpdateStoryLineProcess, self)
    XEventManager.RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_WHOLE_BATTLE_EXIT, self.OnBattleChapterAdvanceSettle, self)
    XEventManager.RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_WHOLE_BATTLE_AGAIN, self.OnAgainBattle, self)
end

--进入模式玩法
function XTheatre5FlowController:EnterModel()
    if self._IsEntering then
        self:ExitModel()
        XLog.Debug("Theatre5:重新进入玩法")  --战斗退出那里目前没有回调，允许重新进入
    else
        XLog.Debug("Theatre5:进入玩法")
    end
    self._IsEntering = true
    local curTheatre5Model = self._Model:GetCurPlayingMode()
    if curTheatre5Model == XMVCA.XTheatre5.EnumConst.GameMode.PVE then
        self:_EnterPVE()
    elseif curTheatre5Model == XMVCA.XTheatre5.EnumConst.GameMode.PVP then
        self:_EnterPVP()
    end

end

--退出模式玩法
function XTheatre5FlowController:ExitModel()
    if not self._IsEntering then
        return
    end
    self._IsEntering = false
    self:_ExitPVE()
    self:_ExitPVP()
    XLog.Debug("Theatre5:退出玩法")
end

function XTheatre5FlowController:_EnterPVE()
    --先核查有没有贴脸节点
    local haveChapterBattle = self._Model.PVEAdventureData:HaveChapterBattle()
    local endingNodeData = self._Model.PVERougeData:GetStoryLineEndingNodeData()
    if haveChapterBattle then
        self:EnterStroryLineContent(self._Model.PVERougeData:GetCurPveStoryLineId())
        return
    end
    local deduceStoryLineId = self._Model.PVERougeData:GetOneNoCompleteDeduceStoryLineId()
    if XTool.IsNumberValid(deduceStoryLineId) then
        local content = self._Model:GetTheatre5ClientConfigText('EnterDeduceTips')
        XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal,
                function()
                    XLuaUiManager.Open('UiTheatre5ChooseCharacter', XMVCA.XTheatre5.EnumConst.GameMode.PVE)
                end,
                function()
                    self:EnterStroryLineContent(deduceStoryLineId)
                end)
        return
    end
    XLuaUiManager.Open('UiTheatre5ChooseCharacter', XMVCA.XTheatre5.EnumConst.GameMode.PVE)
end

function XTheatre5FlowController:_ExitPVE()
    self:ExitStroryLineContent()
    if self._PVEFlowNodeBlackBoard then
        self._PVEFlowNodeBlackBoard:ClearNodeData()
    end
    self._WaitOpenUI = nil
end

function XTheatre5FlowController:_EnterPVP()

end

function XTheatre5FlowController:_ExitPVP()

end


--进入pve故事线内容节点
function XTheatre5FlowController:EnterStroryLineContent(storyLineId, storyEntranceId, characterId)
    if self._IsEnteringStoryLine then
        XLog.Debug(string.format("Theatre5:重复进入故事线,lastStoryLineId:%s,NowStoryLineId:%s", self._PVEStroryLineLink:GetStoryLineId(), storyLineId))
        return
    end
    self._IsEnteringStoryLine = true
    XLog.Debug(string.format("Theatre5:进入故事线,storyLineId:%s", storyLineId))
    self._PVEStroryLineLink:Enter(storyLineId, storyEntranceId, characterId)
end

function XTheatre5FlowController:ExitStroryLineContent()
    -- if self._WaitOpenUI then
    --     XLuaUiManager.Open(self._WaitOpenUI.UIName,table.unpack(self._WaitOpenUI.Params))
    --     self._WaitOpenUI = nil
    -- end    
    if self._IsEnteringStoryLine and self._PVEStroryLineLink then
        XLog.Debug(string.format("Theatre5:退出故事线,storyLineId:%s", self._PVEStroryLineLink:GetStoryLineId()))
        self._PVEStroryLineLink:Exit()
    end
    self._IsEnteringStoryLine = false
end

--打开界面会触发的故事线，提前拦截
function XTheatre5FlowController:CheckChatTrigger(chatTriggerType, name, chatCompletedCallback)
    local haveChapterBattle = self._Model.PVEAdventureData:HaveChapterBattle()
    if haveChapterBattle then
        --有正在进行的章节战斗时，不能触发其他的故事线对话节点
        return
    end
    if self._IsEnteringStoryLine then
        --有正在执行的节点不触发
        return
    end

    local storyLineDic = self._Model.PVERougeData:GetPveStoryLines()
    if XTool.IsTableEmpty(storyLineDic) then
        return
    end
    for _, pveStoryLineData in pairs(storyLineDic) do
        local isStoryLineCompleted = self._Model.PVERougeData:IsStoryLineCompleted(pveStoryLineData.StoryLineId)
        if not isStoryLineCompleted and XTool.IsNumberValid(pveStoryLineData.CurContentId) then
            local storyLineContentCfg = self._Model:GetStoryLineContentCfg(pveStoryLineData.CurContentId)
            if storyLineContentCfg then
                if storyLineContentCfg.ContentType == XMVCA.XTheatre5.EnumConst.PVEChapterType.Chat then
                    --self._WaitOpenUI = {UIName = uiName, Params = table.pack(...)}
                    local chatStoryPoolCfg = self._Model:GetPveSceneChatStoryPoolCfg(storyLineContentCfg.ContentId)
                    if chatStoryPoolCfg.Type == chatTriggerType and chatStoryPoolCfg.Param == name then
                        --多个时只执行一个
                        self:EnterStroryLineContentWithCb(pveStoryLineData.StoryLineId, nil, nil, XMVCA.XTheatre5.EnumConst.PVENodeType.Chat, chatCompletedCallback)
                        return true
                    end
                end
            end
        end
    end
end

function XTheatre5FlowController:CheckEndingTrigger()
    local endingNodeData = self._Model.PVERougeData:GetStoryLineEndingNodeData()
    if endingNodeData then
        self:EnterStroryLineContent(endingNodeData.StoryLineId)
        return true
    end
    return false
end

function XTheatre5FlowController:EnterStroryLineContentWithCb(storyLineId, storyEntranceId, characterId, nodeType, cb)
    self:EnterStroryLineContent(storyLineId, storyEntranceId, characterId)
    if self._PVEStroryLineLink then
        self._PVEStroryLineLink:AddCurNodeCompletedCallback(nodeType, cb)
    end
end

function XTheatre5FlowController:OpenPVEChat(chatGroupId, characters, cb)
    XEventManager.DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_PVE_OPEN_OR_CLOSE_CHAT, true, characters)
    XLuaUiManager.Open("UiTheatre5Movie", chatGroupId, characters, function()
        XEventManager.DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_PVE_OPEN_OR_CLOSE_CHAT, false, characters)
        if cb then
            cb()
        end
    end)
end

function XTheatre5FlowController:LockControl()
    self._MainControl:LockRef()
end

function XTheatre5FlowController:UnLockControl()
    self._MainControl:UnLockRef()
end

function XTheatre5FlowController:ReturnTheatre5Main()
    self._MainControl:ReturnTheatre5Main()
end

function XTheatre5FlowController:GetCurRunningNodeStoryLineId()
    return self._PVEStroryLineLink and self._PVEStroryLineLink:GetCurRunningNodeStoryLineId()
end

function XTheatre5FlowController:GetCurRunningNodeStoryLineContentId()
    return self._PVEStroryLineLink and self._PVEStroryLineLink:GetCurRunningNodeStoryLineContentId()
end

function XTheatre5FlowController:GetCurRunningNodeState()
    return self._PVEStroryLineLink and self._PVEStroryLineLink:GetCurRunningNodeState()
end

function XTheatre5FlowController:UpdateStoryLineProcess()
    self:ExitStroryLineContent()
end

--战斗章节在主界面结束
function XTheatre5FlowController:OnBattleChapterAdvanceSettle()
    if self._IsEntering then
        return
    end
    self._MainControl:ReturnTheatre5Main()
end

function XTheatre5FlowController:OnAgainBattle(resultData)
    if self._IsEntering then
        return
    end
    local storyLineId = self._Model.PVERougeData:GetCurPveStoryLineId()
    local characterId = self._Model.PVEAdventureData:GetCharacterId() --此时数据还没有清，直接拿缓存数据
    local beforeStoryEntranceId
    if resultData and resultData.XAutoChessGameplayResult then
        beforeStoryEntranceId = resultData.XAutoChessGameplayResult.BeforeStoryEntranceId
    end

    --初始化获得战斗章节数据直接进入模式
    XMVCA.XTheatre5.PVEAgency:RequestPveChapterEnter(beforeStoryEntranceId, storyLineId, characterId, function(sucess)
        if sucess then
            self:EnterModel()
        end
    end)
end

function XTheatre5FlowController:GetPVEFlowModeBlackBoard()
    return self._PVEFlowNodeBlackBoard
end

function XTheatre5FlowController:OnRelease()
    self:ExitModel()
    self._WaitOpenUI = nil
    self._IsEntering = false
    self._IsEnteringStoryLine = false
    self._PVEFlowNodeBlackBoard = nil
end

return XTheatre5FlowController