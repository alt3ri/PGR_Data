local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025301 : XTheatre6BuffBase
local XBuffScript1025301 = XDlcScriptManager.RegBuffScript(1025301, "XBuffScript1025301", XTheatre6BuffBase)

--效果说明：造成【击飞】时，自身【攻击】属性在本场战斗中提升3点。

function XBuffScript1025301:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    ------------配置------------
    --self.magicId = 1015335
    --self.magicKind = 1015335
    --self.attrib = ENpcAttrib.HealAmpP
    --self.signalId = 1025101
    ------------执行------------
    self.Check = 0
    self:LogError("301注册")
end


function XBuffScript1025301:OnLuaAffixHitFly(eventArgs )
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self.Check == 1 then return end
    self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, 1025904,1,0, 3)
    self:LogError("301抓到了击飞效果"..self._npcUUID)
    self.Check = 1 --一个技能只检测一次
end

function XBuffScript1025301:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    self.Check = 0
end

return XBuffScript1025301

    