local Base = require("Character/BigWorld/XBigWorldEcologyCharBase")

---空花生态薇拉角色脚本
---@class XNPC_Vera : XBigWorldEcologyCharBase
local XNPC_Vera = XDlcScriptManager.RegCharScript(6074, "XNPC_Vera", Base)

function XNPC_Vera:Init()
    Base.Init(self)
    -- 填入冲突的薇拉NPC的PlaceId,在关卡编辑器里找
    self._oppositeNpcPlaceIdDict = {
        [600015] = true,
        [600020] = true,
        [600022] = true,
        [700002] = true,
    }
    -- 参数1:QuestId, 参数2:开始ObjectiveId, 参数3:Objective状态, 参数4:结束ObjectiveId, 参数5:Objective状态,
    -- 在任务2005下，开始的目标20050101，目标状态开始，结束的目标20050102，目标状态结束
    -- 在此状态下，薇拉NPC屏蔽
    self:AddOppositeQuest(2005, 20050101, self.QuestObjectiveState.InActive, 20050102, self.QuestObjectiveState.Finished)
end

---@param dt number @ delta time
function XNPC_Vera:Update(dt)
    Base.Update(self, dt)
end

---@param eventType number
---@param eventArgs userdata
function XNPC_Vera:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XNPC_Vera:Terminate()
    Base.Terminate(self)
end

return XNPC_Vera
