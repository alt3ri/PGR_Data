local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025207 : XTheatre6BuffBase
local XBuffScript1025207 = XDlcScriptManager.RegBuffScript(1025207, "XBuffScript1025207", XTheatre6BuffBase)

--效果说明：自身首次出手前，受到的攻击伤害降低20%，自身首次获得出手权期间，造成的攻击伤害提升20%。

function XBuffScript1025207:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    ------------配置------------
    --self._blockController = self:GetNpc():GetBlockController()
    ------------执行------------
    self.originAttrib1 = 0
    self.originAttrib2 = 0
    self.Count = 0
    self.AddDamage = 20
    self.SubtractDamage = 20
    self.Chance = 0
    self.AddDamageBuffId = 1025906
    self.SubtractDamageBuffId = 1025909
end

function XBuffScript1025207:OnLuaAttackerChange(eventArgs)
    ------------执行------------
    if eventArgs._newAttackerUUID == self._npcUUID then  --玩家如果是新的攻击方，则给玩家发加伤，如果曾经给玩家发过减伤，则去除减伤
        self.Count = self.Count + 1
        if self.Chance == 0 then  --判断是不是已经给玩家发过一次效果了
            if self.Count <= 2 then
                self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.AddDamageBuffId, 1,1,self.AddDamage)
                self.Chance = 1
            end
        end
        if self.Chance == 1 then
            if self.Count > 2 then
                self._proxy:RemoveBuffByKindAndCount(self._npcUUID, self.SubtractDamageBuffId, self.SubtractDamage)
                self.Chance = 2
            end
        end
    end
    if eventArgs._newDefenderUUID == self._npcUUID then --玩家如果是新的防守方，则给玩家发减伤，如果曾经给玩家发过加伤，则去除加伤
        self.Count = self.Count + 1
        if self.Chance == 0 then
            if self.Count <= 2 then
                self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.SubtractDamageBuffId, 1,1,self.SubtractDamage)
                self.Chance = 1
            end
        end
        if self.Chance == 1 then
            if self.Count > 2 then
                self._proxy:RemoveBuffByKindAndCount(self._npcUUID, self.AddDamageBuffId, self.AddDamage)
                self.Chance = 2
            end
        end
    end
end

return XBuffScript1025207