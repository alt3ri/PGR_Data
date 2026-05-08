local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript1025201 : XTheatre6SkillBase
local XBuffScript1025201 = XDlcScriptManager.RegBuffScript(1025201, "XBuffScript1025201", XTheatre6SkillBase)

--效果说明：【拼刀成功技能】造成的伤害提升10%，且被【格挡】时不会降低伤害。

function XBuffScript1025201:Init()
    --初始化
    XTheatre6SkillBase.Init(self)
    ------------配置------------
    self._blockController = self:GetNpc():GetBlockController()
    self._stackbuff = 1025105 --格挡buff
    ------------执行------------
    self.BuffId = 1025202 --增伤10%
end

function XBuffScript1025201:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillType ~= ETheatre6SkillType.Wrestle then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.BuffId, 1,1,1)
    if self._proxy:CheckBuffByKind(self._enemyUUID,self._stackbuff) then
        self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.BuffId, 1,1,11)
    end
end

function XBuffScript1025201:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._skillType ~= ETheatre6SkillType.Wrestle then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    --if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._proxy:RemoveBuffByKindAndCount(self._npcUUID, self.BuffId, 99)
    --self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.BuffId, 1)
end

return XBuffScript1025201