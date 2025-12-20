local Base = require("Character/BigWorld/XBigWorldEcologyCharBase")

---空花生态露西亚角色脚本
---@class XNPC_Lucia : XBigWorldEcologyCharBase
local XNPC_Lucia = XDlcScriptManager.RegCharScript(6075, "XNPC_Lucia", Base)

function XNPC_Lucia:Init()
    Base.Init(self)
    -- 填入冲突的露西亚NPC的PlaceId,在关卡编辑器里找
    -- 只用填这行
    self._oppositeNpcPlaceIdDict = {
        [700007] = true,
        [600010] = true,
        [600017] = true,
        [600018] = true,
        [600021] = true,
        [700004] = true,
        [900002] = true,
    }
    -- 参数1:QuestId, 参数2:开始ObjectiveId, 参数3:Objective状态, 参数4:结束ObjectiveId, 参数5:Objective状态,
    -- 在任务2002下，开始的目标2002014，目标状态开始，结束的目标2002063，目标状态结束
    -- 在任务2004下，开始的目标20040101，目标状态开始，结束的目标20040102，目标状态结束
    -- 在此状态下，露西亚誓炎NPC屏蔽
    self:AddOppositeQuest(2002, 2002014, self.QuestObjectiveState.InActive, 2002063, self.QuestObjectiveState.Finished)
    self:AddOppositeQuest(2004, 20040101, self.QuestObjectiveState.InActive, 20040102, self.QuestObjectiveState.Finished)
end

---@param dt number @ delta time
function XNPC_Lucia:Update(dt)
    Base.Update(self, dt)
end

---@param eventType number
---@param eventArgs userdata
function XNPC_Lucia:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XNPC_Lucia:Terminate()
    Base.Terminate(self)
end

return XNPC_Lucia
