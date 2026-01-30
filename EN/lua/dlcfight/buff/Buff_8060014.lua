local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript8060014 : XBuffBase
local XBuffScript8060014 = XDlcScriptManager.RegBuffScript(8060014, "XBuffScript8060014", Base)
--效果说明：对OD状态下的敌人造成更多伤害

function XBuffScript8060014:Ctor()
    self.magicId=8060015
end

function XBuffScript8060014:ScriptInit(isGainControl)
    --初始化
    Base.ScriptInit(self,isGainControl)
    ------------配置------------
    self.magicLevel=1 --等新接口直接获取自己的BUFF等级
    self.hasLevel=false
end

---@param dt number @ delta time
function XBuffScript8060014:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行-------------
    if self.hasLevel==false then
        self.hasLevel,self.magicLevel=self._proxy:TryQueryBuffLevel(self._uuid,8060014)--获取自身的BUFF等级
    end
end
    --region EventCallBack
function XBuffScript8060014:InitEventCallBackRegister()
        --按需求解除注释进行注册
        self._proxy:RegisterEvent(EWorldEvent.NpcEnterOverDrive)
        self._proxy:RegisterEvent(EWorldEvent.NpcODExitBreakAfter)
end

function XBuffScript8060014:OnNpcEnterOverDrive(targetUUID) --怪进入OD
        if not self._proxy:CheckBuffByKind(self._uuid,self.magicId) then
            self._proxy:ApplyMagic(self._uuid,self._uuid,self.magicId,self.magicLevel) --进OD加增伤
        end
end

function XBuffScript8060014:OnNpcODExitBreakAfter(targetUUID) --怪Break结束
    if self._proxy:CheckBuffByKind(self._uuid,self.magicId) then
        self._proxy:RemoveBuff(self._uuid,self.magicId) --移除增伤
    end
end
--endregion
---@param eventType number
---@param eventArgs userdata
function XBuffScript8060014:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript8060014:Terminate()
    Base.Terminate(self)
end

return XBuffScript8060014
