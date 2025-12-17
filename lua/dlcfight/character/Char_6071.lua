local Base = require("Character/BigWorld/XBigWorldEcologyCharBase")

---空花生态卡列角色脚本
---@class XNPC_Karenina : XBigWorldEcologyCharBase
local XNPC_Karenina = XDlcScriptManager.RegCharScript(6071, "XNPC_Karenina", Base)

function XNPC_Karenina:Init()
    Base.Init(self)
    -- 卡列妮娜NPC冲突屏蔽脚本
    -- 参数1:QuestId, 参数2:开始ObjectiveId, 参数3:Objective状态, 参数4:结束ObjectiveId, 参数5:Objective状态,
    -- 在任务2001下，开始的目标20010102，目标状态开始，结束的目标20010105，目标状态结束
    -- 在此状态下，卡列妮娜辉晓NPC屏蔽
    self:AddOppositeQuest(2001, 20010102, self.QuestObjectiveState.InActive, 20010105, self.QuestObjectiveState.Finished)
end

---@param dt number @ delta time
function XNPC_Karenina:Update(dt)
    Base.Update(self, dt)
end

---@param eventType number
---@param eventArgs userdata
function XNPC_Karenina:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XNPC_Karenina:Terminate()
    Base.Terminate(self)
end

return XNPC_Karenina
