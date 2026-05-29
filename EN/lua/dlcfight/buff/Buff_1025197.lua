local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025197 : XTheatre6BuffBase
local XBuffScript1025197 = XDlcScriptManager.RegBuffScript(1025197, "XBuffScript1025197", XTheatre6BuffBase)


--效果说明：进入战斗时，损失45%生命值

function XBuffScript1025197:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    ------------配置------------
    self.magicId = 10251502
    self.startBuffId = 1025112 --正式开始战斗标记
    self.timer = 2             --扣血演出时间节点
    self.isDone = false        --是否已经操作扣血
    ------------执行------------
    self.dmgRatio = 0.45       --损失生命值比例
end

function XBuffScript1025197:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageAfter, self._npcUUID)
end

function XBuffScript1025197:Update(dt)
    if self.isDone then return end
    local timeTrigger = self._proxy:GetNpcTime(self._npcUUID) >= self.timer
    if timeTrigger then
        self._proxy:Theatre6PlaySanEffect(self._npcUUID)
        self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.magicId, 1, 0, 1)
        self.isDone = true
    end
end

function XBuffScript1025197:AfterDamageCalc(eventArgs)
    if eventArgs.Id ~= self.magicId then return end

    local lifeMaxValue = self._proxy:GetNpcAttribMaxValue(self._npcUUID, ENpcAttrib.Life)
    local dmg = lifeMaxValue * self.dmgRatio
    self._proxy:SetAfterDamageMagicContext(eventArgs.ContextId, dmg, eventArgs.ElementDamage,
        eventArgs.FinalHackDamage)
end

return XBuffScript1025197
