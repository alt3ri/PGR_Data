local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025203 : XTheatre6BuffBase
local XBuffScript1025203 = XDlcScriptManager.RegBuffScript(1025203, "XBuffScript1025203", XTheatre6BuffBase)

--效果说明：【拼刀成功技能】造成的伤害提升10%，且被【格挡】时不会降低伤害。

function XBuffScript1025203:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    ------------配置------------
    self._blockController = self:GetNpc():GetBlockController()
    self._stackbuff = 1025105 --格挡buff
    ------------执行------------
    self.BuffId = 1025202 --增伤10%
end

function XBuffScript1025203:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillType ~= Wrestle then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.BuffId, 1)
    if self._proxy:CheckBuffByKind(self._enemyUUID,self._stackbuff) then
        self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.BuffId, 10)
    end
end

function XBuffScript1025203:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._skillType ~= Wrestle then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    --if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._proxy:RemoveBuffByKindAndCount(self._npcUUID, self.BuffId, 99)
    --self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.BuffId, 1)
end

return XBuffScript1025203