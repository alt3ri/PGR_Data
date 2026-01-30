local Base = require("Character/BigWorld/XBigWorldEcologyCharBase")

---首席指挥官角色脚本
---@class XCharEcologyTest : XBigWorldEcologyCharBase
local XCharEcologyTest = XDlcScriptManager.RegCharScript(3006, "XCharEcologyTest", Base)

function XCharEcologyTest:CommonInit()
    Base.CommonInit(self)
    -- 冲突的PlaceId
    self._oppositeNpcPlaceIdDict = {
        [100016] = true,
    }
    -- 参数1:QuestId, 参数2:开始ObjectiveId, 参数3:Objective状态, 参数4:结束ObjectiveId, 参数5:Objective状态,
    self:AddOppositeQuest(2002, 2002014, self.QuestObjectiveState.InActive, 2002063, self.QuestObjectiveState.Finished)
end

---@param dt number @ delta time
function XCharEcologyTest:Update(dt)
    Base.Update(self, dt)
end

---@param eventType number
---@param eventArgs userdata
function XCharEcologyTest:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XCharEcologyTest:Terminate()
    Base.Terminate(self)
end

return XCharEcologyTest
