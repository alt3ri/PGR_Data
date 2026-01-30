local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1052901 : XBuffBase
local XBuffScript1052901 = XDlcScriptManager.RegBuffScript(1052901, "XBuffScript1052901", Base)

--（金）效果说明：七实C;电锯（核心）;增强电锯表现；电锯流程增加霸体，减伤，增加电锯状态下破韧效果

function XBuffScript1052901:Init()
    --初始化
    Base.Init(self)
    ------------配置------------

end

---@param dt number @ delta time 
function XBuffScript1052901:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

end

--region EventCallBack
function XBuffScript1052901:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    self._proxy:RegisterEvent(EWorldEvent.NpcBrokenAfter) --注册破韧事件
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff) --注册添加buff事件
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff) --注册移除buff事件
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1052901:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1052901:Terminate()
    Base.Terminate(self)
end

function XBuffScript1052901:OnNpcBrokenAfter(launcherUUID, targetUUID, magicId)
    Base.OnNpcBrokenAfter(self,launcherUUID, targetUUID, magicId)
    --XLog.Warning("怪物破韧时,获得伤害提升")
    if  self._proxy:CheckBuffByKind(self._uuid,1057015) then
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052809,1)
    else
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052808,1)
    end
end
function XBuffScript1052901:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId) --创建buff事件
    Base.OnNpcAddBuffEvent(self,casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if buffId == 105218 then
        --XLog.Warning("加霸体，减伤，破韧效率")
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052805,1) --霸体
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052806,1) --减伤
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052807,1) --破韧提升
    end
end

function XBuffScript1052901:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId) --删除buff事件
    Base.OnNpcRemoveBuffEvent(self,casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if buffId == 105218 then
        --XLog.Warning("移除霸体，减伤，破韧效率")
        self._proxy:RemoveBuffByKindAndCount(self._uuid,1052805)
        self._proxy:RemoveBuffByKindAndCount(self._uuid,1052806)
        self._proxy:RemoveBuffByKindAndCount(self._uuid,1052807)
    end
end

return XBuffScript1052901
