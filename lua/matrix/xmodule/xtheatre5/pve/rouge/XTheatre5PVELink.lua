---@class XTheatre5PVELink : XControl
---@field private _Model XTheatre5Model
---@field private _MainControl XTheatre5FlowControl
local XTheatre5PVELink = XClass(XControl, "XTheatre5PVELink")
local NodeTypeToClass = {
    [XMVCA.XTheatre5.EnumConst.PVENodeType.Chat] = require("XModule/XTheatre5/PVE/Rouge/XTheatre5PVEChatNode"),
    [XMVCA.XTheatre5.EnumConst.PVENodeType.AVG] = require("XModule/XTheatre5/PVE/Rouge/XTheatre5PVEAVGNode"),
    [XMVCA.XTheatre5.EnumConst.PVENodeType.Battle] = require("XModule/XTheatre5/PVE/Rouge/XTheatre5PVEBattleNode"),
    [XMVCA.XTheatre5.EnumConst.PVENodeType.Deduce] = require("XModule/XTheatre5/PVE/Rouge/XTheatre5PVEDeduceNode"),
    [XMVCA.XTheatre5.EnumConst.PVENodeType.Event] = require("XModule/XTheatre5/PVE/Rouge/XTheatre5PVEEventNode"),
    [XMVCA.XTheatre5.EnumConst.PVENodeType.StoryLineEnd] = require("XModule/XTheatre5/PVE/Rouge/XTheatre5PVEStoryLineEndNode"),
    [XMVCA.XTheatre5.EnumConst.PVENodeType.BattleChapterMain] = require("XModule/XTheatre5/PVE/Rouge/XTheatre5PVEBattleChapterMainNode"),
    [XMVCA.XTheatre5.EnumConst.PVENodeType.ItemBoxSelect] = require("XModule/XTheatre5/PVE/Rouge/XTheatre5ItemBoxSelectNode"),
    [XMVCA.XTheatre5.EnumConst.PVENodeType.BattleChapterInit] = require("XModule/XTheatre5/PVE/Rouge/XTheatre5BattleChapterInitNode"),
    --[XMVCA.XTheatre5.EnumConst.PVENodeType.SelectRelic] = require("XModule/XTheatre5/PVE/Rouge/XTheatre5SelectRelicNode"),
}

function XTheatre5PVELink:Ctor()
    ---@type XTheatre5PVENode
    self._HeadNode = nil --头节点
    self._CurStoryLineId = nil
    self._CurStoryLineContentId = nil
end

function XTheatre5PVELink:OnInit()

end

function XTheatre5PVELink:GetStoryLineId()
    return self._CurStoryLineId
end

function XTheatre5PVELink:Enter(storyLineId, storyEntranceId, characterId)
    XEventManager.AddEventListener(XMVCA.XTheatre5.EventId.EVENT_CHAPTER_BATTLE_PROMOTE, self.OnChapterBattlePromote, self)
    self._CurStoryLineId = storyLineId
    self:_AddStartNode(storyLineId, storyEntranceId, characterId)
    self:Excute()
end
function XTheatre5PVELink:_AddStartNode(storyLineId, storyEntranceId, characterId)
    local curContentId = self._Model.PVERougeData:GetStoryLineContentId(storyLineId)
    self._CurStoryLineContentId = curContentId
    --章节战斗中：多类型的故事线还有复刷章节
    local chapterBattleData = self._Model.PVEAdventureData:GetCurChapterBattleData()
    if chapterBattleData then
        -- 进入商店后, 才选择饰品
        -- 选择饰品
        --if XMVCA.XTheatre5:HasRelicToSelect() then
        --    self:AddSelectRelicNode()
        --    return
        --end
        local itemBoxSelectData = self._Model.PVEAdventureData:GetItemBoxSelectData()
        local hasItemBoxSelect = not XTool.IsTableEmpty(itemBoxSelectData)
        if hasItemBoxSelect then
            --先三选一,取第一个
            self:AddItemBoxSelectNode()
            return
        end
        local canPveBattle = self._Model.PVEAdventureData:CanPveBattle()
        if canPveBattle then
            --可以战斗了
            self:AddBattleNode(chapterBattleData)
            if self._Model.PVEAdventureData:IsEventNoStart() then
                XLog.Warning("[XTheatre5PVELink] 修复因为策划去掉事件, 导致的战斗出来后黑屏的问题")
            end
            return
        end
        local isEventNoStart = self._Model.PVEAdventureData:IsEventNoStart()
        if isEventNoStart then
            --章节最开始的状态
            self:AddChapterMainNode(chapterBattleData)
            return
        end
        --执行事件
        local curEventId = self._Model.PVEAdventureData:GetCurEventId()
        self:AddEventNode(curEventId)
        return
    end
    --开始复刷章节   
    local isStoryLineCompleted = self._Model.PVERougeData:IsStoryLineCompleted(storyLineId)
    if isStoryLineCompleted and XTool.IsNumberValid(storyEntranceId) then
        self:AddChapterBattleInitNode(characterId, storyEntranceId)  --只有副刷章节传入口id
        return
    end
    if not XTool.IsNumberValid(curContentId) then
        XLog.Error(string.format("故事线未解锁,storyLineId:%s", storyLineId))
        return
    end
    local contentCfg = self._Model:GetStoryLineContentCfg(curContentId)
    if contentCfg.ContentType == XMVCA.XTheatre5.EnumConst.PVEChapterType.Deduce then
        self:AddDeduceNode()
    elseif contentCfg.ContentType == XMVCA.XTheatre5.EnumConst.PVEChapterType.Chat then
        self:AddChatNode()
    elseif contentCfg.ContentType == XMVCA.XTheatre5.EnumConst.PVEChapterType.AVG then
        self:AddAVGNode()
    elseif contentCfg.ContentType == XMVCA.XTheatre5.EnumConst.PVEChapterType.StoryLineEnd then
        self:AddStoryLineEndNode()
    elseif contentCfg.ContentType == XMVCA.XTheatre5.EnumConst.PVEChapterType.DeduceBattle then
        self:AddChapterBattleInitNode(characterId)
    elseif contentCfg.ContentType == XMVCA.XTheatre5.EnumConst.PVEChapterType.NormalBattle then
        self:AddChapterBattleInitNode(characterId)
    end
end

--推演
function XTheatre5PVELink:AddDeduceNode()
    self:_AddNode(XMVCA.XTheatre5.EnumConst.PVENodeType.Deduce)
end

--对话
-- sceneChatStoryId ： PveSceneChatObjectPool.Id
function XTheatre5PVELink:AddChatNode()
    self:_AddNode(XMVCA.XTheatre5.EnumConst.PVENodeType.Chat)
end

--AVG
function XTheatre5PVELink:AddAVGNode()
    self:_AddNode(XMVCA.XTheatre5.EnumConst.PVENodeType.AVG)
end

--故事线结束
function XTheatre5PVELink:AddStoryLineEndNode(stroryLineContentId)
    self:_AddNode(XMVCA.XTheatre5.EnumConst.PVENodeType.StoryLineEnd, stroryLineContentId)
end

--主章节
function XTheatre5PVELink:AddChapterMainNode(...)
    self:_AddNode(XMVCA.XTheatre5.EnumConst.PVENodeType.BattleChapterMain, ...)
end

--战斗
function XTheatre5PVELink:AddBattleNode(...)
    self:_AddNode(XMVCA.XTheatre5.EnumConst.PVENodeType.Battle, ...)
end

--事件
function XTheatre5PVELink:AddEventNode(eventId)
    self:_AddNode(XMVCA.XTheatre5.EnumConst.PVENodeType.Event, eventId)
end

--宝箱三选一
function XTheatre5PVELink:AddItemBoxSelectNode()
    self:_AddNode(XMVCA.XTheatre5.EnumConst.PVENodeType.ItemBoxSelect)
end

--选择饰品
--function XTheatre5PVELink:AddSelectRelicNode()
--    self:_AddNode(XMVCA.XTheatre5.EnumConst.PVENodeType.SelectRelic)
--end

--章节战斗初始化
function XTheatre5PVELink:AddChapterBattleInitNode(storyEntranceId, characterId)
    self:_AddNode(XMVCA.XTheatre5.EnumConst.PVENodeType.BattleChapterInit, storyEntranceId, characterId)
end

function XTheatre5PVELink:AddCurNodeCompletedCallback(nodeType, cb)
    if not self._HeadNode then
        return
    end
    if self._HeadNode:GetPveNodeState() == XMVCA.XTheatre5.EnumConst.PVENodeState.Running and
            self._HeadNode.NodeType == nodeType then
        self._HeadNode:AddCurNodeCompletedCallback(cb)
    end
end

function XTheatre5PVELink:GetCurRunningNodeStoryLineId(nodeType)
    return self._HeadNode and self._HeadNode:GetStoryLineId()
end

function XTheatre5PVELink:GetCurRunningNodeStoryLineContentId()
    return self._HeadNode and self._HeadNode:GetStoryLineContentId()
end

function XTheatre5PVELink:GetCurRunningNodeState()
    return self._HeadNode and self._HeadNode:GetPveNodeState()
end

function XTheatre5PVELink:_AddNode(nodeType, ...)
    if nodeType and NodeTypeToClass[nodeType] then
        local node = NodeTypeToClass[nodeType].New(self._MainControl, self.NodeCompleted, self, self._CurStoryLineId, self._CurStoryLineContentId, nodeType)
        node:SetData(...)
        local tail = self:_GetLinkTail()
        if not tail then
            self._HeadNode = node
        else
            tail.NextNode = node
        end
        -- if self:_HasCycle(self._HeadNode) then
        --     self._HeadNode = nil
        --     XLog.Error("rouge5故事线单链表有环")
        -- end    
    end
end

--执行节点
function XTheatre5PVELink:Excute()
    if not self._HeadNode then
        return
    end
    if self._HeadNode:GetPveNodeState() == XMVCA.XTheatre5.EnumConst.PVENodeState.Idle then
        self._HeadNode:Enter()
    elseif self._HeadNode:GetPveNodeState() == XMVCA.XTheatre5.EnumConst.PVENodeState.Completed then
        self:NodeCompleted(self._HeadNode)
    end
end

function XTheatre5PVELink:NodeCompleted(node)
    local nextNode = node.NextNode
    if not nextNode then
        --链表结束了
        return
    end
    if nextNode:GetPveNodeState() == XMVCA.XTheatre5.EnumConst.PVENodeState.Idle then
        self._HeadNode = nextNode
        nextNode:Enter()
    elseif nextNode:GetPveNodeState() == XMVCA.XTheatre5.EnumConst.PVENodeState.Completed then
        self:NodeCompleted(nextNode)
    end
end

-- 用uid解决两个相同类型的节点不能连续添加的问题
function XTheatre5PVELink:OnChapterBattlePromote(curNodeUid, NextNodeType, ...)
    if not self._HeadNode or self._HeadNode:GetPveNodeState() ~= XMVCA.XTheatre5.EnumConst.PVENodeState.Running or self._HeadNode.NextNode then
        -- 这个东西不能打印, 会死循环
        --XLog.Error(self._HeadNode)
        if self._HeadNode then
            XLog.Error(self._HeadNode:GetPveNodeState())
            if self._HeadNode.NextNode then
                XLog.Error(self._HeadNode.NextNode.NodeType)
            end
        end
        return
    end
    if not XTool.IsNumberValid(curNodeUid) or self._HeadNode:GetUid() ~= curNodeUid then
        return
    end
    if NextNodeType == XMVCA.XTheatre5.EnumConst.PVENodeType.BattleChapterMain then
        self:AddChapterMainNode(...)
    elseif NextNodeType == XMVCA.XTheatre5.EnumConst.PVENodeType.Event then
        self:AddEventNode(...)
    elseif NextNodeType == XMVCA.XTheatre5.EnumConst.PVENodeType.ItemBoxSelect then
        self:AddItemBoxSelectNode()
    elseif NextNodeType == XMVCA.XTheatre5.EnumConst.PVENodeType.Battle then
        self:AddBattleNode(...)
    end
    self._HeadNode:Exit()
end

--快慢指针检测单链表是否有环
function XTheatre5PVELink:_HasCycle(head)
    if not head or not head.NextNode then
        return false
    end

    local slow = head
    local fast = head.NextNode
    while fast and fast.NextNode do
        if slow == fast then
            return true  -- 快慢指针相遇，有环
        end
        slow = slow.NextNode
        fast = fast.NextNode.NextNode
    end

    return false
end

function XTheatre5PVELink:_GetLinkTail()
    local tail = self._HeadNode
    while tail and tail.NextNode do
        tail = tail.NextNode
    end
    return tail
end

function XTheatre5PVELink:Exit()
    XEventManager.RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_CHAPTER_BATTLE_PROMOTE, self.OnChapterBattlePromote, self)
    self:_ReleaseNode()
    self._HeadNode = nil
    self._CurStoryLineId = nil
    self._CurStoryLineContentId = nil
end

function XTheatre5PVELink:_ReleaseNode()
    local node = self._HeadNode
    while node do
        local curNode = node
        node = curNode.NextNode
        curNode:Release()
    end
end

function XTheatre5PVELink:OnRelease()

end

return XTheatre5PVELink