local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025201 : XTheatre6BuffBase
local XBuffScript1025201 = XDlcScriptManager.RegBuffScript(1025201, "XBuffScript1025201", XTheatre6BuffBase)

--效果说明：【拼刀成功技能】造成的伤害提升20%，若对方处于【格挡】时额外获得增伤。（原效果：若对方处于【格挡】时不会降低伤害。）

function XBuffScript1025201:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    ------------配置------------
    self._blockController = self:GetNpc():GetBlockController()
    self.baseStacks = 20          --基础增伤20%
    self.blockStacks = 100        --格挡增伤100%
    self._stackbuff = 1025105     --格挡buff
    self.extraDmgBuffId = 1025906 --增伤buff
    self.checkBlock = 0           --检查是否有格挡
end

function XBuffScript1025201:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillType ~= ETheatre6SkillType.Wrestle then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    local buffStacks = self.baseStacks
    --如果有格挡，额外增伤层数生效
    self.checkBlock = self._proxy:CheckBuffByKind(self._enemyUUID, self._stackbuff)
    if self.checkBlock then buffStacks = self.baseStacks + self.blockStacks end
    self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.extraDmgBuffId, 1, 1, buffStacks)
end

function XBuffScript1025201:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._skillType ~= ETheatre6SkillType.Wrestle then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    local buffStacks = self.baseStacks
    --如果有格挡，删除时考虑额外层数
    if self.checkBlock then buffStacks = self.baseStacks + self.blockStacks end
    self._proxy:RemoveBuffByKindAndCount(self._npcUUID, self.extraDmgBuffId,buffStacks)
end

return XBuffScript1025201
