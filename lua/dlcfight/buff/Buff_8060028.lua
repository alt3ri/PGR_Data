local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript8060028 : XBuffBase
local XBuffScript8060028 = XDlcScriptManager.RegBuffScript(8060028, "XBuffScript8060028", Base)
--效果说明：自动复活有CD

function XBuffScript8060028:Ctor()
    self.magicId=8060029 --复活BUFF
    self.rebornCds={300,280,260,240,220,210,200,190,180,170,160,150,140,130,120,100} --秒
end

function XBuffScript8060028:ScriptInit(isGainControl)
    --初始化
    Base.ScriptInit(self,isGainControl)
    ------------配置------------
    self.magicLevel=1 --等新接口直接获取自己的BUFF等级
    self.timer=0 --计时器
    self.hasBuff=false
    self.hasLevel=false
    ------------执行------------
end

---@param dt number @ delta time
function XBuffScript8060028:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    if not self._proxy :CheckNpc(self._uuid)  then return end

    if self.hasLevel==false then
        self.hasLevel,self.magicLevel=self._proxy:TryQueryBuffLevel(self._uuid,8060028)--获取自身的BUFF等级
        self.cd=self.rebornCds[self.magicLevel] --拿等级确认CD
        self.hasLevel=true
    end

    if self._proxy:GetFightTime(self._uuid)>=self.timer and self.hasBuff==false then --到点加BUFF
        self._proxy:ApplyMagic(self._uuid,self._uuid,self.magicId,self.magicLevel)
        self.hasBuff=true
    end

end

--region EventCallBack
function XBuffScript8060028:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcGuardianAngelConsume)
end

function XBuffScript8060028:OnNpcGuardianAngelConsume(npcUUID, npcPlaceId, npcKind, isPlayer, buffTemplateId)
    if buffTemplateId~=self.magicId then return end
    if npcUUID==self._uuid then
        self.timer=self._proxy:GetFightTime(self._uuid)+self.cd --重新加BUFF
        self.hasBuff=false
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript8060028:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript8060028:Terminate()
    Base.Terminate(self)
end

return XBuffScript8060028
