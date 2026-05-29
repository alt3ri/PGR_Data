local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025405 : XTheatre6BuffBase
local XBuffScript1025405 = XDlcScriptManager.RegBuffScript(1025405, "XBuffScript1025405", XTheatre6BuffBase)

--效果说明：每成功触发【格挡】2次技能，本场战斗中自身【超算】属性提升1点，【体力】属性提升3点。

function XBuffScript1025405:Init()
    --初始化
    ------------配置------------
    XTheatre6BuffBase.Init(self)
    --self.magicId = 1015335
    --self.magicKind = 1015335
    --self.attrib = ENpcAttrib.HealAmpP
    --公用的击倒id
    self.originAttrib1 = 0
    self.stackCS = 1
    self.stackTL = 3
    ------------执行------------
end

function XBuffScript1025405:OnLuaAffixBlock(eventArgs)
    --self:LogError(".....抓到格挡")
    if self.SkillChanceCheck == 0 then
        self.originAttrib1 = self.originAttrib1 + 1
        self.SkillChanceCheck = 1
        if self.originAttrib1 >= 2 then
            self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, 1025902,1,0, self.stackCS) --给玩家加超算
            self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, 1025903,1,0, self.stackTL) --给玩家加体力
            self.originAttrib1 = 0
        end
    end
end

function XBuffScript1025405:OnLuaSkillStart(eventArgs)
    ------------执行------------
    self.SkillChanceCheck = 0
end


return XBuffScript1025405