local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1052905 : XBuffBase
local XBuffScript1052905 = XDlcScriptManager.RegBuffScript(1052905, "XBuffScript1052905", Base)

--效果说明：七实C;剑冲（技能）;剑冲替换为充能型技能，普攻第三段时，点击剑冲，获得强化派生，获得较高核心能量

function XBuffScript1052905:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    XLog.Warning("buff脚本加载1052905")
end

---@param dt number @ delta time 
function XBuffScript1052905:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

end

--region EventCallBack
function XBuffScript1052905:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    XLog.Warning("注册添加buff事件")
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff) --注册添加buff事件
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff) --注册移除buff事件
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1052905:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1052905:Terminate()
    Base.Terminate(self)
end

function XBuffScript1052905:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId) --创建buff事件
    Base.OnNpcAddBuffEvent(self,casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if buffId == 1052834 then
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball2,105717)
        XLog.Warning("设置为强化派生动作")
    end

    if buffId == 1052835 then
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball2,105718)
    end
end

function XBuffScript1052905:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId) --删除buff事件
    Base.OnNpcRemoveBuffEvent(self,casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if buffId == 1052834 then
        if not self._proxy:CheckNpcCurrentAction(self._uuid,105781) or not self._proxy:CheckBuffByKind(self._uuid,1052835) then
            self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball2,105704)
        end
    end

    if buffId == 1052835 then
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball2,105704)
    end
end

return XBuffScript1052905
