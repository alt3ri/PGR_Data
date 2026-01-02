local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript8060026 : XBuffBase
local XBuffScript8060026 = XDlcScriptManager.RegBuffScript(8060026, "XBuffScript8060026", Base)
--效果说明：支援时获得减伤

function XBuffScript8060026:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicLevel=1 --等新接口直接获取自己的BUFF等级
    self.magicId=8060027 --减伤BUFF
    self.hasLevel=false
    ------------执行------------
end

---@param dt number @ delta time
function XBuffScript8060026:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    if not self._proxy :CheckNpc(self._uuid)  then return end

    if self.hasLevel==false then
        self.hasLevel,self.magicLevel=self._proxy:TryQueryBuffLevel(self._uuid,8060026)--获取自身的BUFF等级
    end

    if self._proxy:GetNpcIsAid(self._uuid) and not self._proxy:CheckBuffByKind(self._uuid,self.magicId) then
        self._proxy:ApplyMagic(self._uuid,self._uuid,self.magicId,self.magicLevel)
    elseif not self._proxy:GetNpcIsAid(self._uuid) and self._proxy:CheckBuffByKind(self._uuid,self.magicId) then
        self._proxy:RemoveBuff(self._uuid,self.magicId)
    end
end

--region EventCallBack
function XBuffScript8060026:InitEventCallBackRegister()
    --按需求解除注释进行注册
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript8060026:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript8060026:Terminate()
    Base.Terminate(self)
end

return XBuffScript8060026
