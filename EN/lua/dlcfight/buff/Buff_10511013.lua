local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript10511013 : XBuffBase
local XBuffScript10511013 = XDlcScriptManager.RegBuffScript(10511013, "XBuffScript10511013", Base)

--效果说明：添加该buff时检测自身伤口层数，让buff来源创建子弹攻击怪物

function XBuffScript10511013:ScriptInit(isGainControl)
    --初始化
    Base.ScriptInit(self, isGainControl)
    ------------配置------------
    self.CureEquipdelayTime = 0.13
    self.DelayTime = 0.5
    self._cureEquipSwitch = false
    ------------执行------------
    self.CureEquipdelayTimer = self._proxy:GetFightTime() + self.DelayTime

    --存储Timer信息到黑板值
    if isGainControl then
        local hasKey, val = self._proxy:TryGetBBFloat(XVarDomain.Npc,self._uuid, 10511013)
        if hasKey then
            self.CureEquipdelayTimer = val
        end
    else
        self._proxy:RegisterBBSync(XVarDomain.Npc, self._uuid, 10511013)
        self._proxy:SetBBFloat(XVarDomain.Npc, self._uuid, 10511013, self.CureEquipdelayTimer)
    end

    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)
end

---@param dt number @ delta time 
function XBuffScript10511013:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    if self._cureEquipSwitch then
        --判断NPC是否存活
        if self._proxy:CheckNpcFullActionState(self._uuid, ENpcAction.Death, -1) then
            return
        end
        if self._proxy:CheckBuffByKind(self._uuid, 10511012) then
            self._cureEquipSwitch = false
            self._proxy:RemoveBuffByKindAndCount(self._uuid,10511012,1)
        else
            self._proxy:RemoveBuff(self._uuid, 10511013)
        end
    end
    if (self._proxy:GetFightTime() > self.CureEquipdelayTimer) then
        self._cureEquipSwitch = true
        self.CureEquipdelayTimer = self._proxy:GetFightTime() + self.CureEquipdelayTime
        self._proxy:SetBBFloat(1, self._uuid, 10511013, self.CureEquipdelayTimer)
    end
end

--region EventCallBack
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript10511013:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript10511013:Terminate()
    Base.Terminate(self)
end

function XBuffScript10511013:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId) --删除buff事件

end

return XBuffScript10511013
