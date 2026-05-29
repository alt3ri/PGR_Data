local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025409 : XTheatre6BuffBase
local XBuffScript1025409 = XDlcScriptManager.RegBuffScript(1025409, "XBuffScript1025409", XTheatre6BuffBase)

--效果说明：每次使用【插入式技能】时，获得20点【怒火】

function XBuffScript1025409:Init()
    --初始化
    ------------配置------------
    XTheatre6BuffBase.Init(self)
    --self.magicId = 1015335
    --self.magicKind = 1015335
    --self.attrib = ENpcAttrib.HealAmpP
    --公用的击倒id
    self._AngerController = self:GetNpc():GetAngerController()
    self._angerRecover = 20
    ------------执行------------
end

function XBuffScript1025409:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._skillType ~= ETheatre6SkillType.Insert then return end
    self._AngerController:CastStackBuff(self._angerRecover, self._npcUUID)
end

return XBuffScript1025409