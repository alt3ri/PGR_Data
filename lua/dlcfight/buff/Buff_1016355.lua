local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1016355 : XBuffBase
local XBuffScript1016355 = XDlcScriptManager.RegBuffScript(1016355, "XBuffScript1016355", Base)
--效果说明：触发定时或概率次数转伤害提升buff

function XBuffScript1016355:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.buffLevelGroupId= {1016355, 1016356, 1016357, 1016358, 1016359}  --5个等级
    self.magicIds={1016360,1016361,1016362,1016363}   --全属性增伤效果
    self.runeActiveCounterCal={1,1,1,1,1}--符纹每触发x次
    self.currentRuneActiveCounterCal=0
    self.runeActiveCounter=0

    self.battleStartBuffId = 1015992    --战斗开始标记buff
    self.magicLevel = 1
    self.signalAwakeForMissionArr = {1016416,1015595,1015744 } -- 定时、概率触发传递标记buff

    ------------执行------------

end
---@param dt number @ delta time
function XBuffScript1016355:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

end

--region EventCallBack
function XBuffScript1016355:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
end

function XBuffScript1016355:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)

    --开局获取层级
    if npcUUID == self._uuid and buffId == self.battleStartBuffId then
        for thisLevel, buffGroupThisLevel in ipairs(self.buffLevelGroupId) do
            if self._proxy:CheckBuffByKind(self._uuid, buffGroupThisLevel) then
                self.magicLevel = thisLevel
                self.currentRuneActiveCounterCal = self.runeActiveCounterCal[thisLevel]
            end
        end
    end

    --如果不是【定时】标记和【概率触发】标记，则返回
    local signalAwakeForMission = buffId==self.signalAwakeForMissionArr[1] or buffId==self.signalAwakeForMissionArr[2] or buffId==self.signalAwakeForMissionArr[3]
    if npcUUID == self._uuid and signalAwakeForMission then
        self.runeActiveCounter = self.runeActiveCounter + 1
        if self.runeActiveCounter >= self.currentRuneActiveCounterCal then
            for _, magicId in ipairs(self.magicIds) do
                self._proxy:ApplyMagic(self._uuid,self._uuid,magicId, self.magicLevel)
            end
            self.runeActiveCounter = self.runeActiveCounter - self.currentRuneActiveCounterCal
        end
    end

end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1016355:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1016355:Terminate()
    Base.Terminate(self)
end

return XBuffScript1016355
