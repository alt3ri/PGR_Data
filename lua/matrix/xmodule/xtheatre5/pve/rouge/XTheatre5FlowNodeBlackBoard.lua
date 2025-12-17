---故事线黑板数据记录
---节点之间传参传参不定，会使接口冗余，故使用黑板传参
---@class XTheatre5FlowNodeBlackBoard
local XTheatre5FlowNodeBlackBoard = XClass(nil, "XTheatre5FlowNodeBlackBoard")

function XTheatre5FlowNodeBlackBoard:Ctor()
    self._StoryLineId = nil
    self._NodeType = nil
    self._UiName = nil --节点退出时对应的UI载体， 一个节点操作的UI界面有多个，但是退出时的UI载体只有一个
    self._BattleNodeState = nil -- 战斗节点有多种退出状态
end

--记录当前节点数据，数据供下个节点使用
function XTheatre5FlowNodeBlackBoard:RecodeNodeData(storyLineId, nodeType, uiName, battleNodeState)
    self._StoryLineId = storyLineId
    self._NodeType = nodeType
    self._UiName = uiName
    self._BattleNodeState = battleNodeState
end

function XTheatre5FlowNodeBlackBoard:GetNodeStoryLineId()
    return self._StoryLineId
end

function XTheatre5FlowNodeBlackBoard:GetNodeType()
    return self._NodeType
end

function XTheatre5FlowNodeBlackBoard:GetNodeUiName()
    return self._UiName
end

function XTheatre5FlowNodeBlackBoard:GetBattleNodeState()
    return self._BattleNodeState
end

function XTheatre5FlowNodeBlackBoard:ClearNodeData()
    self._StoryLineId = nil
    self._NodeType = nil
    self._UiName = nil
    self._BattleNodeState = nil
end

return XTheatre5FlowNodeBlackBoard