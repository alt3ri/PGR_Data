local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1052904 : XBuffBase
local XBuffScript1052904 = XDlcScriptManager.RegBuffScript(1052904, "XBuffScript1052904", Base)

--效果说明：七实T;战吼（技能）;延长战吼增益时间，增加嘲讽持续时间；获得对嘲讽目标伤害提升，提升造成伤害仇恨系数

function XBuffScript1052904:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052822,1) --仇恨系数提升
    XLog.Warning("Buff脚本1052904")
end

---@param dt number @ delta time 
function XBuffScript1052904:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

end

--region EventCallBack
function XBuffScript1052904:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    XLog.Warning("注册添加buff事件")
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff) --注册添加buff事件
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1052904:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1052904:Terminate()
    Base.Terminate(self)
end

function XBuffScript1052904:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId) --创建buff事件
    Base.OnNpcAddBuffEvent(self,casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --XLog.Warning("添加强攻时")
    if casterNpcUUID == self._uuid then
        if buffId == 1052254 then --添加强攻时
            XLog.Warning("添加强攻时")
            self._proxy:ChangeBuffTimeByTemplateId(1052254,3,EBuffModifyType.Value,EBuffValueRefType.BornTime)
            XLog.Warning("修改强攻时间")
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052823,1) --添加对嘲讽目标造成额外伤害magic
        end

        if buffId == 105257 then --添加嘲讽时
            XLog.Warning("修改嘲讽时间")
            self._proxy:ChangeBuffTimeByTemplateId(105257,3,EBuffModifyType.Value,EBuffValueRefType.BornTime)
        end

    end

end






return XBuffScript1052904
