local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025407 : XTheatre6BuffBase
local XBuffScript1025407 = XDlcScriptManager.RegBuffScript(1025407, "XBuffScript1025407", XTheatre6BuffBase)

--效果说明：【格挡】时额外吸取对手5点【体力值】。

function XBuffScript1025407:Init()
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
    self.originAttrib1 = 5
    ------------执行------------
end

function XBuffScript1025407:OnLuaAffixBlock(eventArgs)
    --self:LogError(".....抓到格挡")
    if eventArgs._launcherUUID == self._npcUUID then return end
    if self.SkillChanceCheck == 0 then
        self.SkillChanceCheck = 1
        local selfStamina = self:GetCurStamina(self._npcUUID)
        if selfStamina < 0 then
            --如果当前体力为负值，重置自身体力值为0，避免负值恢复体力无反馈，看着像bug
            --如果重置体力为0影响比较大，可以注释掉if内的代码
            self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, -selfStamina, 0)         
        end
        self._proxy:Theatre6ChangeStaminaValue(self._enemyUUID, -self.originAttrib1, 0) --扣除对手体力
        self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, self.originAttrib1, 0)    --恢复自己体力
    end
end

function XBuffScript1025407:OnLuaSkillStart(eventArgs)
    ------------执行------------
    self.SkillChanceCheck = 0
end

function XBuffScript1025407:GetCurStamina(npcUUID)
    local curStamina = self._proxy:GetNpcGameplayAttribValue(npcUUID, ETheatre6AttribType.Stamina)
    return curStamina
end

return XBuffScript1025407
