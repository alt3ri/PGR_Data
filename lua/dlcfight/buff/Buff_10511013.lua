local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript10511013 : XBuffBase
local XBuffScript10511013 = XDlcScriptManager.RegBuffScript(10511013, "XBuffScript10511013", Base)

--效果说明：添加该buff时检测自身伤口层数，让buff来源创建子弹攻击怪物

function XBuffScript10511013:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.CureEquipdelayTime = 0.13
    self.DelayTime = 0.5
    self._cureEquipSwitch = false
    --设置核心插件子弹发射ID
    self._lunchId = {}
    self._lunchId[1] = 10511011
    self._lunchId[2] = 10511012
    self._lunchId[3] = 10511013
    self._lunchId[4] = 10511014

    ------------执行------------
    self.CureEquipdelayTimer = self._proxy:GetFightTime() + self.DelayTime
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)
end

---@param dt number @ delta time 
function XBuffScript10511013:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    if self._cureEquipSwitch then
        if self._proxy:CheckBuffByKind(self._uuid, 10511012) then
            if self._proxy:CheckBuffByKind(self._casterUUID,1051101) then
                self._proxy:LaunchMissile(self._casterUUID, self._uuid, self._lunchId[self._proxy:Random(1,4)], 10511011, 1)
            end
            if self._proxy:CheckBuffByKind(self._casterUUID,1051102) then
                self._proxy:LaunchMissile(self._casterUUID, self._uuid, self._lunchId[self._proxy:Random(1,4)], 10511021, 1)
            end
            self._cureEquipSwitch = false
            self._proxy:RemoveBuffByKindAndCount(self._uuid,10511012,1)
        else
            self._proxy:RemoveBuff(self._uuid, 10511013)
        end
    end
    if (self._proxy:GetFightTime() > self.CureEquipdelayTimer) then
        self._cureEquipSwitch = true
        self.CureEquipdelayTimer = self._proxy:GetFightTime() + self.CureEquipdelayTime
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
