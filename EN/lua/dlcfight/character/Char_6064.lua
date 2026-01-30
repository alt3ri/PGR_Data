local Base = require("Character/BigWorld/XBigWorldEcologyCharBase")

---空花生态丽芙角色脚本
---@class XNPC_Lifu : XBigWorldEcologyCharBase
local XNPC_Lifu = XDlcScriptManager.RegCharScript(6064, "XNPC_Lifu", Base)

function XNPC_Lifu:CommonInit()
    Base.CommonInit(self)
    -- 神丽芙NPC冲突屏蔽脚本
    -- 参数1:QuestId, 参数2:开始ObjectiveId, 参数3:Objective状态, 参数4:结束ObjectiveId, 参数5:Objective状态,
    -- 在任务2002下，开始的目标2002014，目标状态开始，结束的目标2002051，目标状态结束
    -- 在此状态下，神丽芙NPC屏蔽
    self:AddOppositeQuest(2002, 2002014, self.QuestObjectiveState.InActive, 2002051, self.QuestObjectiveState.Finished)
end

---@param dt number @ delta time
function XNPC_Lifu:Update(dt)
    Base.Update(self, dt)
end

---@param eventType number
---@param eventArgs userdata
function XNPC_Lifu:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XNPC_Lifu:Terminate()
    Base.Terminate(self)
end

return XNPC_Lifu
