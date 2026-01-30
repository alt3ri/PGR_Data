local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1052285 : XBuffBase
local XBuffScript1052285 = XDlcScriptManager.RegBuffScript(1052285, "XBuffScript1052285", Base)

--效果说明：添加是进行距离检测，若合理，则添加通过标记，用以吸附

function XBuffScript1052285:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    --XLog.Warning("脚本1052285")
    self:CheckTargetDistanceForAttackMove()

end

---@param dt number @ delta time 
function XBuffScript1052285:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

end

--region EventCallBack
function XBuffScript1052285:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1052285:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1052285:Terminate()
    Base.Terminate(self)
end

function XBuffScript1052285:CheckTargetDistanceForAttackMove()
    --XLog.Warning("想吸附了")
    local locktargetid,npcid = self._proxy:GetLockTarget()
    if npcid == 0 or npcid == nil then
        --XLog.Warning("哥们返回了")
        return
    end
    local distance = self._proxy:CalcNpcDistance(self._uuid,npcid)
    --XLog.Warning("打印间距"..distance)
    if self._proxy:CheckNpcDistance(self._uuid,npcid,20) then
        --XLog.Warning("与锁定目标距离小于5m，该吸过去了")
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052286,1,1)
    end
end
return XBuffScript1052285
