local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015594 : XBuffBase
local XBuffScript1015594 = XDlcScriptManager.RegBuffScript(1015594, "XBuffScript1015594", Base)
--效果说明：厄难节拍与赌命戏法符纹触发时，2秒内受到伤害减少

function XBuffScript1015594:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015595   --全属性伤害提升Buff
    self.runeId = 20594            --符纹ID赋值
    self.magicLevel = 1 --初始buff等级1级
    self.signalIdArr = {
        1015911, --【定时】状态标记，标记管理脚本见1015910
        1015743         --【概率触发】标记
    }
    ------------执行------------
end

---@param dt number @ delta time
function XBuffScript1015594:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

end


--region EventCallBack
function XBuffScript1015594:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
end

function XBuffScript1015594:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if self._uuid ~= npcUUID then
        return
    end
    --如果不是【定时】标记和【概率触发】标记，则返回
    local isSignalAdd = buffId==self.signalIdArr[1] or buffId ==self.signalIdArr[2]
    if isSignalAdd then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
        self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeId)
        self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
    end
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015594:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015594:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015594
