local Base = require("Common/XBigWorldCharBase")

---@class XBigWorldEcologyCharQuestInfo
---@field StartQuestObjectiveId
---@field StartQuestObjectiveState
---@field EndQuestObjectiveId
---@field EndQuestObjectiveState

---生态角色脚本-角色占用功能还没完成前的替代方案
---@class XBigWorldEcologyCharBase : XBigWorldCharBase
---@field _oppositeNpcPlaceIdDict table<number, number> 冲突的PlaceId字典 key:PlaceId, value:是否在level内
---@field _oppositeQuestInfoDict table<number, XBigWorldEcologyCharQuestInfo> 冲突的QuestId字典 key:QuestId, value:XBigWorldEcologyCharQuestInfo
local XBigWorldEcologyCharBase = XClass(Base, "XBigWorldEcologyCharBase")

---@param dt number @ delta time
function XBigWorldEcologyCharBase:Update(dt)
    self:CheckCharCanShow()
end

function XBigWorldEcologyCharBase:Terminate()
    self._oppositeNpcPlaceIdDict = nil
    self._oppositeQuestInfoDict = nil
    Base.Terminate(self)
end


--region Lua基础生命周期函数
function XBigWorldEcologyCharBase:CommonInit()
    Base.CommonInit(self)
    self._oppositeNpcPlaceIdDict = { }
    self._oppositeQuestInfoDict = { }
    ---任务目标状态
    self.QuestObjectiveState = {
        ---【不活跃/未激活】时和之后
        InActive = 1,
        ---【进行中】时和之后
        InProcess = 2,
        ---【已完成】时和之后
        Finished = 3
    }
    self._isShow = false
end
--endregion

function XBigWorldEcologyCharBase:CheckCharCanShow()
    local isShow = true
    for placeId, value in pairs(self._oppositeNpcPlaceIdDict) do
        local targetUid = self._proxy:GetNpcUUID(placeId)
        if value and targetUid > 0 then
            isShow = false
        end
    end
    for questId, info in pairs(self._oppositeQuestInfoDict) do
        local isAfterStart = false
        local isBeforeEnd = false
        if info.StartQuestObjectiveId and info.StartQuestObjectiveId > 0 then
            isAfterStart = self:CheckQuestObjectiveState(questId, info.StartQuestObjectiveId, info.StartQuestObjectiveState, false)
        end
        if info.EndQuestObjectiveId and info.EndQuestObjectiveId > 0 then
            isBeforeEnd = self:CheckQuestObjectiveState(questId, info.EndQuestObjectiveId, info.EndQuestObjectiveState, true)
        end
        if isAfterStart and isBeforeEnd then
            isShow = false
        end
    end
    if self._isShow ~= isShow or isShow ~= self._proxy:GetNpcActive(self._uuid) then
        self._proxy:SetNpcActive(self._uuid, isShow)
        self._isShow = isShow
    end
end

--region NpcPlaceId冲突
function XBigWorldEcologyCharBase:SetAndCheckOppositeNpcPlaceId(oppositeNpcPlaceId, isAdd)
    -- 不是互斥NpcPlaceId直接跳过
    if not self._oppositeNpcPlaceIdDict[oppositeNpcPlaceId] then
        return
    end
    self._oppositeNpcPlaceIdDict[oppositeNpcPlaceId] = isAdd
    self:CheckCharCanShow()
end
--endregion

--region 任务冲突
function XBigWorldEcologyCharBase:AddOppositeQuest(questId, startObjectiveId, startObjectiveState, endObjectiveId, endObjectiveState)
    ---@type XBigWorldEcologyCharQuestInfo
    local oppositeQuestInfo = {}
    oppositeQuestInfo.StartQuestObjectiveId = startObjectiveId
    oppositeQuestInfo.StartQuestObjectiveState = startObjectiveState
    oppositeQuestInfo.EndQuestObjectiveId = endObjectiveId
    oppositeQuestInfo.EndQuestObjectiveState = endObjectiveState
    self._oppositeQuestInfoDict[questId] = oppositeQuestInfo;
end

---@private
---@param questId number 任务Id
---@param questObjectiveId number 任务目标Id
---@param questObjectiveState number 任务目标状态:XBigWorldEcologyCharBase.QuestObjectiveState
---@param isBefore bool
function XBigWorldEcologyCharBase:CheckQuestObjectiveState(questId, questObjectiveId, questObjectiveState, isBefore)
    if not self._proxy:IsInQuest(questId) then
        return false
    end
    local state = 0
    if self._proxy:IsQuestObjectiveInActive(questObjectiveId) then
        state = self.QuestObjectiveState.InActive
    elseif (not self._proxy:IsQuestObjectiveInActive(questObjectiveId)) and (not self._proxy:IsQuestObjectiveFinished(questObjectiveId)) then
        state = self.QuestObjectiveState.InProcess
    elseif self._proxy:IsQuestObjectiveFinished(questObjectiveId) then
        state = self.QuestObjectiveState.Finished
    end
    if isBefore then
        return questObjectiveState > state
    else
        return questObjectiveState < state
    end
end
--endregion

return XBigWorldEcologyCharBase
