local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025503 : XTheatre6BuffBase
local XBuffScript1025503 = XDlcScriptManager.RegBuffScript(1025503, "XBuffScript1025503", XTheatre6BuffBase)

--效果说明：在持有<坚毅>时使用【插入式技能】，使自身【拼刀】属性提升5点。

function XBuffScript1025503:Init()
    --初始化
    ------------配置------------
    XTheatre6BuffBase.Init(self)
    self.BlockBuffId = 1025105
    self.WrestleAdd = 5
    ------------执行------------
end

function XBuffScript1025503:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._skillType ~= ETheatre6SkillType.Insert then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self._proxy:GetBuffStacks(self._npcUUID, self.BlockBuffId) > 0 then
        self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, 1025901,1,0, self.WrestleAdd) --给玩家加拼刀
    end
end

return XBuffScript1025503
