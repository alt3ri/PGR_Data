local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025219 : XTheatre6BuffBase
local XBuffScript1025219 = XDlcScriptManager.RegBuffScript(1025219, "XBuffScript1025219", XTheatre6BuffBase)


--效果说明：自身每损失10%生命值，受到伤害降低1%。

function XBuffScript1025219:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    ------------配置------------
    --self.magicId = 1015335
    --self.magicKind = 1015335
    --self.attrib = ENpcAttrib.HealAmpP
    ------------执行------------
    self.curHealth = 0             --当前生命值
    self.maxHealth = 0             --最大生命值
    self.curStacks = 0             --减伤层数（已损失生命% ÷ 10）
    self.recordStacks = 0          --上一次受伤记录的减伤层数
    self.deltaStacks = 0           --减伤层数差值
    self.reduceDmgBuffId = 1025909 --减伤buffId
end

function XBuffScript1025219:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)
end

function XBuffScript1025219:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage,
                                             elementType, realDamage, isCritical, skillActionId, magicTags, customValue)
    if targetId == self._npcUUID then
        self.curHealth = self._proxy:GetNpcAttribValue(self._npcUUID, ENpcAttrib.Life)
        self.maxHealth = self._proxy:GetNpcAttribMaxValue(self._npcUUID, ENpcAttrib.Life)
        --根据当前损失生命百分比计算层数
        self.curStacks = ((self.maxHealth - self.curHealth) * 100 / self.maxHealth) // 10
        self.deltaStacks = self.curStacks - self.recordStacks                                                  --记录下层数差值
        if self.deltaStacks > 0 then
            self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.reduceDmgBuffId, 1, 0, self.deltaStacks) --发对应差值的减伤效果
        elseif self.deltaStacks < 0 then
            self._proxy:RemoveBuffByKindAndCount(self._npcUUID, self.reduceDmgBuffId, -self.deltaStacks)
        end
        self.recordStacks = self.curStacks --刷新一下层数记录
    end
end

return XBuffScript1025219
