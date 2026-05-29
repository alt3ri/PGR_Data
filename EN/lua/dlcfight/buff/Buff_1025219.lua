local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025219 : XTheatre6BuffBase
local XBuffScript1025219 = XDlcScriptManager.RegBuffScript(1025219, "XBuffScript1025219", XTheatre6BuffBase)


--效果说明：自身每损失5%生命值，受到伤害降低1%。

function XBuffScript1025219:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    ------------配置------------
    --self.magicId = 1015335
    --self.magicKind = 1015335
    --self.attrib = ENpcAttrib.HealAmpP
    ------------执行------------
    self.originAttrib4 = 0
end

function XBuffScript1025219:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)
end

function XBuffScript1025219:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical, skillActionId, magicTags, customValue)
    self.originAttrib1 = self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.Life)
    self.originAttrib2 = self._proxy:GetNpcAttribMaxValue(self._uuid,ENpcAttrib.Life)
    self.originAttrib3 = ((self.originAttrib2 - self.originAttrib1) * 100 / self.originAttrib2) // 5
    self.originAttrib5 = self.originAttrib3 - self.originAttrib4 --记录下层数差值
    self._proxy:ApplyMagic(self._uuid, self._uuid, 1025909,1,0, self.originAttrib3)  --发对应差值的减伤效果
    self.originAttrib4 = self.originAttrib3 --刷新一下层数记录
end

return XBuffScript1025219
