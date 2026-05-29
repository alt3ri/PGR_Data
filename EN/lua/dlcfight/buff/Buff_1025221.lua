local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025221 : XTheatre6BuffBase
local XBuffScript1025221 = XDlcScriptManager.RegBuffScript(1025221, "XBuffScript1025221", XTheatre6BuffBase)


--效果说明：双方每次造成【格挡】【暴击】时，自身【生命】属性提升25点，并恢复等量【生命值】。--我草，格挡通知呢。哦找到了。

function XBuffScript1025221:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    ------------配置------------
    --self.magicId = 1015335
    --self.magicKind = 1015335
    --self.attrib = ENpcAttrib.HealAmpP
    ------------执行------------
    self.originAttrib4 = 0
end

function XBuffScript1025221:OnLuaAffixCritDamage(eventArgs)
    --self:LogError(".....抓到暴击")
    if self.SkillChanceCheck == 0 then
    self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, 1025905, 1,1,25)
    self.SkillChanceCheck = 1
    end
end

function XBuffScript1025221:OnLuaAffixBlock(eventArgs)
    --self:LogError(".....抓到暴击")
    if self.SkillChanceCheck == 0 then
        self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, 1025905, 1,1,25)
        self.SkillChanceCheck = 1
    end
end

function XBuffScript1025221:OnLuaSkillStart(eventArgs)
    ------------执行------------
    self.SkillChanceCheck = 0
end

return XBuffScript1025221
