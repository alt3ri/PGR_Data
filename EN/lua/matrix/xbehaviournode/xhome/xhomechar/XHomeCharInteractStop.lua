---@class XHomeCharInteractStop : XLuaBehaviorNode 交互中断
---@deprecated 监听消息EVENT_DORM_INTERACT_STOP，收到该消息后，args[1] == self.PlayerId时，返回SUCCESS 并且设置Agent的公共参数VarDic["InteractStopSuccess"] = true
local XHomeCharInteractStop = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeCharInteractStop", CsBehaviorNodeType.Condition, true, false)


function XHomeCharInteractStop:OnGetEvents()
    return { XEventId.EVENT_DORM_INTERACT_STOP }
end

function XHomeCharInteractStop:OnEnter()
    self.PlayerId = self.AgentProxy:GetPlayerId()
end

function XHomeCharInteractStop:OnNotify(evt, ...)
    local args = { ... }

    if evt == XEventId.EVENT_DORM_INTERACT_STOP and args[1] == self.PlayerId then
        self.Node.Status = CsNodeStatus.SUCCESS
        if not XTool.UObjIsNil(self.Agent) then
            self.Agent:SetVarDicByKey("InteractStopSuccess", true)
        else
            XLog.Debug("行为树节点HomeCharInteractStop Agent为nil PlayerId:" .. self.PlayerId)
        end
    end
end