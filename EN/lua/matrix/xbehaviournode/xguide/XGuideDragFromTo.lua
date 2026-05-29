---@class XGuideDragFromTo : XLuaBehaviorNode 拖拽引导节点
---@field AgentProxy XGuideAgent
local XGuideDragFromTo = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "GuideDragFromTo", CsBehaviorNodeType.Action, true, false)

function XGuideDragFromTo:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end
    
    self.UiName = self.Fields["UiName"]
    self.FromNode = self.Fields["FromNode"]
    self.ToNode = self.Fields["ToNode"]
    
    local index = self.Fields["FromChildIndex"]
    self.FromChildIndex = (index and index > 0) and index or false
    index = self.Fields["ToChildIndex"]
    self.ToChildIndex = (index and index > 0) and index or false
    
    local offset = self.Fields["FromOffset"]
    if offset then
        self.FromOffset = Vector2(offset.X, offset.Y)
    end
    
    offset = self.Fields["ToOffset"]
    if offset then
        self.ToOffset = Vector2(offset.X, offset.Y)
    end
    -- 通过判定，1为拖拽，2为点击
    -- 遮罩开启后，仅识别高亮区域内的拖拽事件，在高亮区域外拖拽无效
    -- 判定类型为1时，玩家指针从Index[1]选中开始判定，于Index[2]松开判定成功，事件通过
    -- 判定类型为2时，点击非遮罩地区，事件通过
    self.PassType = self.Fields["PassType"]
end

function XGuideDragFromTo:OnEnter()
    if not self.AgentProxy:DragFromTo(self.UiName, self.FromNode, self.FromChildIndex, 
            self.FromOffset, self.ToNode, self.ToChildIndex, self.ToOffset, self.PassType) then
        self.Node.Status = CsNodeStatus.ERROR
    end
end

function XGuideDragFromTo:OnGetEvents()
    return { CS.XEventId.EVENT_GUIDE_DRAG_FROM_TO }
end

function XGuideDragFromTo:OnNotify(evt)
    if evt == CS.XEventId.EVENT_GUIDE_DRAG_FROM_TO then
        if self.AgentProxy then
            self.AgentProxy:ResetDragPanel()
        end
        self.Node.Status = CsNodeStatus.SUCCESS
    end
end