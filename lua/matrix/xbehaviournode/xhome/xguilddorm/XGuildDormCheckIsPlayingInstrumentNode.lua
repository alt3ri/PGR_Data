---@class XGuildDormCheckIsPlayingInstrumentNode : XLuaBehaviorNode 公会宿舍下检测指定乐器是否正在演奏
---@field AgentProxy XGuildDormCharAgent
local XGuildDormCheckIsPlayingInstrumentNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "GuildDormCheckIsPlayingInstrument", CsBehaviorNodeType.Condition, true, false)

function XGuildDormCheckIsPlayingInstrumentNode:OnAwake()
    if self.Fields == nil or self.Fields["FurnitureId"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end
    
    self.FurnitureId = self.Fields["FurnitureId"]
end

function XGuildDormCheckIsPlayingInstrumentNode:OnEnter()
    local res = self.AgentProxy:CheckIsInstrumentPlayingAudio(self.FurnitureId)
    if res then
        self.Node.Status = CsNodeStatus.SUCCESS
    else
        self.Node.Status = CsNodeStatus.FAILED
    end
end