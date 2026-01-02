local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript8060008 : XBuffBase
local XBuffScript8060008 = XDlcScriptManager.RegBuffScript(8060008, "XBuffScript8060008", Base)
--效果说明：有护盾加攻

function XBuffScript8060008:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicLevel=1 --等新接口直接获取自己的BUFF等级
    self.magicId=8060009
    ------------执行------------
    self.hasLevel=false
end

---@param dt number @ delta time
function XBuffScript8060008:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行-------------
    if not self._proxy:CheckNpc(self._uuid) then return end
    if self.hasLevel==false then
        self.hasLevel,self.magicLevel=self._proxy:TryQueryBuffLevel(self._uuid,8060008)--获取自身的BUFF等级
    end

    local protector =self._proxy:GetNpcProtector(self._uuid)
    if protector>0 and not self._proxy:CheckBuffByKind(self._uuid,self.magicId) then --有护盾且没BUFF
        self._proxy:ApplyMagic(self._uuid,self._uuid,self.magicId,self.magicLevel) --上BUFF
    elseif protector<=0 and self._proxy:CheckBuffByKind(self._uuid,self.magicId) then
        self._proxy:RemoveBuff(self._uuid,self.magicId) --移除BUFF
    end
end

---@param eventType number
---@param eventArgs userdata
function XBuffScript8060008:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript8060008:Terminate()
    Base.Terminate(self)
end

return XBuffScript8060008
