local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript8060018 : XBuffBase
local XBuffScript8060018 = XDlcScriptManager.RegBuffScript(8060018, "XBuffScript8060018", Base)
--效果说明：血量越高攻击加成越高

function XBuffScript8060018:Ctor()
    self.magicIds={8060019,8060020,8060021,8060022} --各个血量区间的攻击BUFF
    self.hpRate01=0.8
    self.hpRate02=0.59
    self.hpRate03=0.39
    self.hpRate04=0.19
end

function XBuffScript8060018:ScriptInit(isGainControl)
    --初始化
    Base.ScriptInit(self,isGainControl)
    ------------配置------------
    self.magicLevel=1 --等新接口直接获取自己的BUFF等级
    self.openBuff=false
    self.hasLevel=false
    ------------执行------------
end

---@param dt number @ delta time
function XBuffScript8060018:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    if not self._proxy :CheckNpc(self._uuid)  then return end

    if self.hasLevel==false then
        self.hasLevel,self.magicLevel=self._proxy:TryQueryBuffLevel(self._uuid,8060018)--获取自身的BUFF等级
    end

    local hpRate =self._proxy :GetNpcAttribRate(self._uuid,0) --血量比例
    if hpRate<self.hpRate04 and self.openBuff==true then --血量小于最小区间就移除BUFF
        for _,magicId in ipairs(self.magicIds) do
            if self._proxy:CheckBuffByKind(self._uuid,magicId) then
                self._proxy:RemoveBuff(self._uuid,magicId)
                self.openBuff=false
            end
        end
    end

    if hpRate>=self.hpRate01
            and not self._proxy :CheckBuffByKind(self._uuid,self.magicIds[1])
    then
        self._proxy :ApplyMagic(self._uuid,self._uuid,self.magicIds[1],self.magicLevel)--直接加BUFF，BUFF本身会对其他区间BUFF进行覆盖
        self.openBuff=true
    elseif hpRate >=self.hpRate02
            and hpRate <self.hpRate01
            and not self._proxy :CheckBuffByKind(self._uuid,self.magicIds[2])
    then
        self._proxy :ApplyMagic(self._uuid,self._uuid,self.magicIds[2],self.magicLevel)
        self.openBuff=true
    elseif hpRate >=self.hpRate03
            and hpRate <self.hpRate02
            and not self._proxy :CheckBuffByKind(self._uuid,self.magicIds[3])
    then
        self._proxy :ApplyMagic(self._uuid,self._uuid,self.magicIds[3],self.magicLevel)
        self.openBuff=true
    elseif hpRate >=self.hpRate04
            and hpRate<self.hpRate03
            and not self._proxy :CheckBuffByKind(self._uuid,self.magicIds[4])
    then
        self._proxy :ApplyMagic(self._uuid,self._uuid,self.magicIds[4],self.magicLevel)
        self.openBuff=true
    end
    --
end

--region EventCallBack
function XBuffScript8060018:InitEventCallBackRegister()
    --按需求解除注释进行注册
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript8060018:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript8060018:Terminate()
    Base.Terminate(self)
end

return XBuffScript8060018
