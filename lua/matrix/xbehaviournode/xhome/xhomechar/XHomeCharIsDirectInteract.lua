---@class XHomeCharIsDirectInteract : XLuaBehaviorNode 是否直接交互
---@deprecated 使用公共参数IsDirectInteract控制。只在进入公会时有玩家已经在交互的时候设置Agent的公共参数VarDic["IsDirectInteract"] = true 默认为false
local XHomeCharIsDirectInteract = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeCharIsDirectInteract", CsBehaviorNodeType.Condition, true, true)

function XHomeCharIsDirectInteract:OnEnter()
    self.PlayerId = self.AgentProxy:GetPlayerId()
end

function XHomeCharIsDirectInteract:OnUpdate(dt)
    local result = self.AgentProxy:CheckIsDirectInteract()
    if result then
        self.Node.Status = CsNodeStatus.SUCCESS
    else
        self.Node.Status = CsNodeStatus.FAILED
    end
end