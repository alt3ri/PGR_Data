local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025605 : XTheatre6BuffBase
local XBuffScript1025605 = XDlcScriptManager.RegBuffScript(1025605, "XBuffScript1025605", XTheatre6BuffBase)

--效果说明：进入战斗时，造成3层【剧毒】。

function XBuffScript1025605:Init()
    --初始化
    ------------配置------------
    XTheatre6BuffBase.Init(self)
    --self.magicId = 1015335
    --self.magicKind = 1015335
    --self.attrib = ENpcAttrib.HealAmpP
    --公用的击倒id
    ------------执行------------
end


function XBuffScript1025605:OnEnterLevel(levelId)
    XTheatre6BuffBase.OnEnterLevel(self, levelId)
    self._poisonedController = self:GetEnemyNpc():GetPoisonedController()
    self._poisonedController:CastStackBuff(3, self._enemyUUID)
end

return XBuffScript1025605