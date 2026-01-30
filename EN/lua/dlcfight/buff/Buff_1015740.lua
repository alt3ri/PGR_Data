local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015740 : XBuffBase
local XBuffScript1015740 = XDlcScriptManager.RegBuffScript(1015740, "XBuffScript1015740", Base)
--效果说明：带有【概率触发】条件的效果触发时，自身额外获得3秒X%的伤害提升（注意，不吃定时的效果翻倍，因为这个效果不带有【每隔X秒】条件）

function XBuffScript1015740:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicIdArr = { 1015744, 1015745, 1015746, 1015747 }    --全属性伤害提升Buff
    self.runeId = 20740             --符纹ID赋值
    self.magicLevel = 1             --初始buff等级1级
    self.signalId = 1015743         --【概率触发】标记
    ------------执行------------
end

---@param dt number @ delta time
function XBuffScript1015740:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

end


--region EventCallBack
function XBuffScript1015740:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
end

function XBuffScript1015740:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --如果自身添加了【概率触发】标记，则触发效果，并打开宝珠特效
    if self._uuid == npcUUID and self.signalId == buffId then
        --根据添加的标记层数确定属性提升Buff等级
        local calMagicLevel = self._proxy:GetBuffStacks(self._uuid,self.signalId)
        for _, magicId in ipairs(self.magicIdArr) do
            self._proxy:ApplyMagic(self._uuid, self._uuid, magicId, calMagicLevel)
        end
        self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeId)
    end
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015740:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015740:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015740
