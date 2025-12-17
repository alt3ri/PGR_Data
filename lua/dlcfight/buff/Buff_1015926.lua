local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015926 : XBuffBase
local XBuffScript1015926 = XDlcScriptManager.RegBuffScript(1015926, "XBuffScript1015926", Base)

--效果说明：敌人首次触发斩杀时，提高自身最大生命值

function XBuffScript1015926:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015927       --属性提升Buff
    self.runeId = 20926          --符纹ID赋值
    self.magicLevel = 1
    self.signalId = 1015905     --【斩杀】状态标记，标记管理脚本见1015904
    self.signalCtrlId = 1015904 --【斩杀】状态管理Buff
    self.enhBuffIdArray = {
        1015790           --增强Buff[1]：开局效果提升（2级效果）
    }
    --Buff强化配置【Buff1】，效果说明：有此Buff时，读取2级数值
    self.magicLevelEnhance = 2          --强化后的Buff等级
    ------------执行------------
    self._proxy:ApplyMagic(self._uuid, self._uuid, self.signalCtrlId, 1)   --为自己添加【斩杀】管理Buff

end

---@param dt number @ delta time 
function XBuffScript1015926:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015926:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
end

function XBuffScript1015926:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --如果自身添加了【斩杀】标记，则触发效果，并打开宝珠特效
    if self._uuid == npcUUID and self.signalId == buffId then
        --如果有增强Buff[1]存在，则将Buff等级替换为2级
        local isEnhBuff1Active = self._proxy:CheckBuffByKind(self._uuid,self.enhBuffIdArray[1])
        if isEnhBuff1Active then
            self.magicLevel = self.magicLevelEnhance
        end
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
        self._proxy:SetAutoChessGemActiveState(self._uuid,self.runeId)
    end
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015926:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015926:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015926
