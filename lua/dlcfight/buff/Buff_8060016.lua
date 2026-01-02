local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript8060016 : XBuffBase
local XBuffScript8060016 = XDlcScriptManager.RegBuffScript(8060016, "XBuffScript8060016", Base)
--效果说明：对破韧状态下的敌人造成更多伤害

function XBuffScript8060016:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicLevel=1 --等新接口直接获取自己的BUFF等级
    self.magicId=8060017
    self.hasLevel=false
end

---@param dt number @ delta time
function XBuffScript8060016:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行-------------
    if self.hasLevel==false then
        self.hasLevel,self.magicLevel=self._proxy:TryQueryBuffLevel(self._uuid,8060016)--获取自身的BUFF等级
    end
end
    --region EventCallBack
function XBuffScript8060016:InitEventCallBackRegister()
        --按需求解除注释进行注册
        self._proxy:RegisterEvent(EWorldEvent.NpcBrokenAfter)
        self._proxy:RegisterEvent(EWorldEvent.NpcRecoverBrokenAfter)
end

function XBuffScript8060016:OnNpcBrokenAfter(launcherUUID, targetUUID, magicId) --怪进入破韧
        if not self._proxy:CheckBuffByKind(self._uuid,self.magicId) then
            self._proxy:ApplyMagic(self._uuid,self._uuid,self.magicId,self.magicLevel) --破韧加增伤
        end
end

function XBuffScript8060016:OnNpcRecoverBrokenAfter(targetUUID) --怪韧性恢复
    if self._proxy:CheckBuffByKind(self._uuid,self.magicId) then
        self._proxy:RemoveBuff(self._uuid,self.magicId) --移除增伤
    end
end
--endregion
---@param eventType number
---@param eventArgs userdata
function XBuffScript8060016:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript8060016:Terminate()
    Base.Terminate(self)
end

return XBuffScript8060016
