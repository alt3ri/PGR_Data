local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1016345 : XBuffBase
local XBuffScript1016345 = XDlcScriptManager.RegBuffScript(1016345, "XBuffScript1016345", Base)
--效果说明：进入绝命时速无敌x秒

function XBuffScript1016345:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.buffLevelGroupId= {1016345, 1016346, 1016347, 1016348, 1016349}  --5个等级
    self.mutekiBuffGroupId= {1016350, 1016351, 1016352, 1016353, 1016354}  --真是无无又敌敌啊
    self.notMuteki = true

    self.battleStartBuffId = 1015992    --战斗开始标记buff
    self.targetId = 0
    self.magicLevel = 1
    self.signal1Id = 1015909         --【疲劳】状态标记，标记管理脚本见1015908
    self.signal1CtrlId = 1015908     --【疲劳】状态管理Buff
    ------------执行------------

end
---@param dt number @ delta time
function XBuffScript1016345:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

end

--region EventCallBack
function XBuffScript1016345:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
end

function XBuffScript1016345:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --开局时，获得目标
    if npcUUID == self._uuid and buffId == self.battleStartBuffId then
        self.targetId = self._proxy:GetFightTargetId(self._uuid)
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.signal1CtrlId, 1)   --为自己添加【浑身】管理Buff
    end

    --疲劳时套无敌
    if npcUUID == self._uuid and buffId == self.signal1Id and self.notMuteki then
        for thisLevel, buffGroupThisLevel in ipairs(self.buffLevelGroupId) do
            if self._proxy:CheckBuffByKind(self._uuid, buffGroupThisLevel) then
                self._proxy:ApplyMagic(self._uuid, self._uuid, self.mutekiBuffGroupId[thisLevel], 1)   --为自己添加【浑身】管理Buff
                self.notMuteki = false
            end
        end
    end

end



--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1016345:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1016345:Terminate()
    Base.Terminate(self)
end

return XBuffScript1016345
