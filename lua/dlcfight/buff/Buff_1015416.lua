local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015416 : XBuffBase
local XBuffScript1015416 = XDlcScriptManager.RegBuffScript(1015416, "XBuffScript1015416", Base)

--效果说明：造成冰伤时，基于对方血量提升X%~5X%冰伤，最大值在敌方血量20%时提供（每损失20%获得10点）

------------配置------------
local ConfigMagicIdDict = {
    [1015416] = 1015417,
    [1015454] = 1015455,
    [1015456] = 1015457,
    [1015458] = 1015459,
    [1016142] = 1016143
}
local ConfigRuneIdDict = {
    [1015416] = 20416,
    [1015454] = 20454,
    [1015456] = 20456,
    [1015458] = 20458,
    [1016142] = 20458
}

function XBuffScript1015416:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.triggerCD = 1    --宝珠生效CD
    self.magicId = ConfigMagicIdDict[self._buffId]  --增伤Magic
    self.magicLevel = 1 --魔法等级
    self.magicMinLevel = 1 --最小等级
    self.magicMaxLevel = 5 --最大等级
    self.healthRate = 0.2 --生命比例
    self.enemyId = 0
    self.runeId = ConfigRuneIdDict[self._buffId] --宝珠id，用于ui和记录次数
    ------------执行------------
    self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel) --给目标添加特定类型的效果
    self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeId)
end

---@param dt number @ delta time 
function XBuffScript1015416:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    --如果npc不存在，就不用执行了
    self.enemyId = self._proxy:GetFightTargetId(self._uuid)
    if not self._proxy:CheckNpc(self.enemyId) then
        return
    end
    local rate = self._proxy:GetNpcAttribRate(self.enemyId, ENpcAttrib.Life)       --获取npc生命值
    self.magicLevel = math.max(self.magicMaxLevel - rate // self.healthRate, self.magicMinLevel)      --根据当前血量计算技能等级
    self._proxy:RemoveBuff(self._uuid, self.magicId)              --删除自身
    self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel) --更新目标的效果
end

--region EventCallBack
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015416:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015416:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015416
