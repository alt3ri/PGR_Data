---@class XTheatre5PVENode
---@field NextNode XTheatre5PVENode
---@field private _MainControl XTheatre5FlowController
---@field _MainModel XTheatre5Model
local XTheatre5PVENode = XClass(nil, "XTheatre5PVENode")

function XTheatre5PVENode:Ctor(mainControl,completedCallback,completedCallbackObj,storyLineId,storyLineContentId,nodeType)
    self._MainControl = mainControl
    self._MainModel = mainControl._Model
    self._CompletedCallback = completedCallback  --节点完成返回上层的回调
    self._CompletedCallbackObj = completedCallbackObj
    self._StoryLineId = storyLineId
    self._StoryLineContentId = storyLineContentId
    ---@type XTheatre5FlowNodeBlackBoard
    self._FlowNodeBlackBoard = self._MainControl:GetPVEFlowModeBlackBoard() 

    self.NodeType = nodeType --节点类型
    self.NextNode = nil --下一个节点

    self._PveChapterType = nil
    self._PveChapterProcess = nil --判断是否是头尾
    self._PveNodeState = XMVCA.XTheatre5.EnumConst.PVENodeState.Idle
    self._NodeCompletedCallback = nil
    self._Uid = mainControl.GenNodeUid()
end

function XTheatre5PVENode:SetData(...)
    
end

function XTheatre5PVENode:GetUid()
    return self._Uid
end

function XTheatre5PVENode:Enter()
    XLog.Debug(string.format("Theatre5:进入故事线节点,NodeType:%s,StoryLineId:%s,StoryLineContentId:%s", self.NodeType, self._StoryLineId, self._StoryLineContentId))
    self._PveNodeState = XMVCA.XTheatre5.EnumConst.PVENodeState.Running
    self:_OnEnter()
end

function XTheatre5PVENode:_OnEnter()
    
end

function XTheatre5PVENode:Exit()
    XLog.Debug(string.format("Theatre5:退出故事线节点,NodeType:%s,StoryLineId:%s,StoryLineContentId:%s", self.NodeType, self._StoryLineId, self._StoryLineContentId))
    self:_OnExit()
    self._PveNodeState = XMVCA.XTheatre5.EnumConst.PVENodeState.Completed
    self:_Completed()
    self:Release()
end

function XTheatre5PVENode:_OnExit()
    
end

function XTheatre5PVENode:GetStoryLineId()
    return self._StoryLineId
end

function XTheatre5PVENode:GetStoryLineContentId()
    return self._StoryLineContentId
end

function XTheatre5PVENode:AddCurNodeCompletedCallback(cb)
    self._NodeCompletedCallback = cb
end

function XTheatre5PVENode:RecodeNodeData(uiName, battleNodeState)
    self._FlowNodeBlackBoard:RecodeNodeData(self._StoryLineId, self.NodeType, uiName, battleNodeState)
end

function XTheatre5PVENode:GetNodeUiName()
    return self._FlowNodeBlackBoard:GetNodeUiName()
end

function XTheatre5PVENode:ClearNodeData()
    return self._FlowNodeBlackBoard:ClearNodeData()
end

function XTheatre5PVENode:OpenUiPanel(uiName, ...)
    local topUiName = XLuaUiManager.GetUIStackTopUiName()
    --local topUiName =  XLuaUiManager.GetTopUiName()
    --主界面不能关闭
    if topUiName == "UiTheatre5Main" then
        XLuaUiManager.Open(uiName, ...)
    else
        XLuaUiManager.PopThenOpen(uiName, ...)
    end
end

---章节战斗节点推进
function XTheatre5PVENode:ChapterBattlePromote(nextNodeType, ...)
    XEventManager.DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_CHAPTER_BATTLE_PROMOTE,
        self:GetUid(), nextNodeType, ...)
end

function XTheatre5PVENode:Release()
    self._MainControl = nil
    self._MainModel = nil
    self._CompletedCallback = nil
    self._CompletedCallbackObj = nil
    self._StoryLineId = nil
    self._StoryLineContentId = nil

    self.NodeType = nil
    self.NextNode = nil

    self._PveChapterType = nil
    self._PveChapterProcess = nil
    self._PveNodeState = nil
    self._NodeCompletedCallback = nil
    self._FlowNodeBlackBoard  = nil  
    self._Uid = nil
    self:_OnRelease()
end

function XTheatre5PVENode:_OnRelease()
    
end

function XTheatre5PVENode:GetPveChapterType()
    return self._PveChapterType
end

function XTheatre5PVENode:GetPveChapterProcess()
    return self._PveChapterProcess
end

function XTheatre5PVENode:GetPveNodeState()
    return self._PveNodeState
end

function XTheatre5PVENode:_Completed()
    if self._CompletedCallback then
        if self._CompletedCallbackObj then
            self._CompletedCallback(self._CompletedCallbackObj,self)
        else
            self._CompletedCallback(self)  
        end
    end
    self.NextNode = nil
    self._CompletedCallback = nil
    self._CompletedCallbackObj = nil         
end


return XTheatre5PVENode