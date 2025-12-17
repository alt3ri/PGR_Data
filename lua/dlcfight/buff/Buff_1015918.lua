local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015918 : XBuffBase
local XBuffScript1015918 = XDlcScriptManager.RegBuffScript(1015918, "XBuffScript1015918", Base)
--效果说明：【开局】受到伤害降低80%，结束后20秒内受到的伤害增加40%

function XBuffScript1015918:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015919          --属性提升Buff
    self.runeId = 20918             --符纹ID赋值
    self.magicBuffLevel = 1         --减伤等级
    self.magicDebuffLevel = 2       --增加受到伤害等级
    self.signalId = 1015907         --【开局】状态标记，标记管理脚本见1015906
    self.signalCtrlId = 1015906     --【开局】状态管理Buff
    self.debuffTime = 20            --Debuff持续时间
    self.timer = 0                  --计时器
    ------------执行------------
    self._proxy:ApplyMagic(self._uuid, self._uuid, self.signalCtrlId, 1)   --为自己添加【开局】管理Buff
end

---@param dt number @ delta time
function XBuffScript1015918:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    --当计时器启动，且达到删除Debuff的时间后，删除Debuff
    if self.timer ~=0 and self._proxy:GetNpcTime(self._uuid) > self.timer then
        self._proxy:RemoveBuff(self._uuid,self.magicId)
    end

end


--region EventCallBack
function XBuffScript1015918:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)        -- OnNpcRemoveBuffEvent
end

function XBuffScript1015918:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --如果自身添加了【开局】标记，则触发效果，并打开宝珠特效
    if self._uuid == npcUUID and self.signalId == buffId then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicBuffLevel)
        self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeId)
        self.timer = 0
    end
end

function XBuffScript1015918:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --如果自身移除了【开局】标记，则删除效果，并关闭宝珠特效
    if self._uuid == npcUUID and self.signalId == buffId then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicDebuffLevel)
        self._proxy:SetAutoChessGemData(self._uuid, self.runeId, 0, 0)
        self.timer = self._proxy:GetNpcTime(self._uuid) + self.debuffTime
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015918:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015918:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015918
