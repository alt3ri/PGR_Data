local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025513 : XTheatre6BuffBase
local XBuffScript1025513 = XDlcScriptManager.RegBuffScript(1025513, "XBuffScript1025513", XTheatre6BuffBase)

--效果说明：每次使用【主动技能】时，每有20点【体力】属性，获得25点【护盾】。

function XBuffScript1025513:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    ------------配置------------
    self.magicId = 1027513         --护盾id
    self.magicPerTL = 20           --重复触发开关，每个技能仅能触发1次
    ------------执行------------
end

function XBuffScript1025513:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._skillType ~= ETheatre6SkillType.Main then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    --if self._proxy:GetBuffStacks(self._npcUUID, self.BlockBuffId) >= 0 then
        --self._proxy:AddNpcGameplayAttribAdditive(self._npcUUID,ETheatre6AttribType.WrestlePoint,self.WrestleAdd,0)
    --end
    local stack = self._proxy:GetNpcGameplayAttribMaxValue(self._npcUUID,ETheatre6AttribType.Stamina) // self.magicPerTL
    self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.magicId, 1, 0, stack)
end

return XBuffScript1025513
