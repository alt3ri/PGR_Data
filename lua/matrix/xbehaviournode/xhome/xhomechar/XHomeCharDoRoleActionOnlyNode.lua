---@class XHomeCharDoRoleActionOnlyNode : XLuaBehaviorNode 只播放动画
---@field ActionId number 动作Id
---@field CrossDuration number 融合时间
---@field NeedFadeCross boolean 是否需要融合
---@deprecated 只播放动画，当前节点执行后就会设置当前节点状态为成功
local XHomeCharDoRoleActionOnlyNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeCharDoRoleActionOnly", CsBehaviorNodeType.Action, true, false)

function XHomeCharDoRoleActionOnlyNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["ActionId"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.ActionId = self.Fields["ActionId"]
    self.CrossDuration = self.Fields["CrossDuration"]
    self.NeedFadeCross = self.Fields["NeedFadeCross"]
end

function XHomeCharDoRoleActionOnlyNode:OnEnter()
    self.AgentProxy:DoAction(self.ActionId, self.NeedFadeCross, self.CrossDuration)
    self.Node.Status = CsNodeStatus.SUCCESS
end
